rem ptrefpkg.sql
set termout on echo on trimspool on 
spool ptrefpkg
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE ptref AS 
  PROCEDURE pthtml
  (p_recname IN VARCHAR2
  ,p_oracol  IN BOOLEAN DEFAULT FALSE);

  PROCEDURE ptindex;

  PROCEDURE ptxlat
  (p_fieldname IN VARCHAR2);
END ptref;
/
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY ptref AS
----------------------------------------------------------------------------------------------------
k_space CONSTANT VARCHAR2(30) := '&'||'nbsp;';
k_amp   CONSTANT VARCHAR2(10) := '&'||'amp';
k_copy  CONSTANT VARCHAR2(10) := '&'||'copy';
k_key   CONSTANT VARCHAR2(30) := '<img border="0" src="../jpg/key.gif">';
----------------------------------------------------------------------------------------------------
PROCEDURE tablestyle IS
BEGIN
 dbms_output.put_line('<style>');
 dbms_output.put_line('table, th, td { border: 1px solid black; border-collapse: collapse; padding: 1px; vertical-align: top;}');
 dbms_output.put_line('</style>');
END tablestyle;
----------------------------------------------------------------------------------------------------
PROCEDURE pthtml
(p_recname IN VARCHAR2
, p_oracol IN BOOLEAN DEFAULT FALSE) IS
 l_recname        VARCHAR2(15);
 l_recdescr       VARCHAR2(30);
 l_rellangrecname VARCHAR2(15);
 l_parentrecname  VARCHAR2(15);
 l_rectype        INTEGER;
 l_descrlong      CLOB;
 l_newline        BOOLEAN;
 l_toolsrel       VARCHAR2(20 CHAR);

 l_datatype       VARCHAR2(100);
 l_col_def        VARCHAR2(1000 CHAR);

 l_key   VARCHAR2(50);

 l_counter INTEGER;
BEGIN
 SELECT toolsrel
 INTO   l_toolsrel
 FROM   psstatus;

 WITH x AS (
   SELECT object_name recname
   ,      other_xml descrlong
   FROM   plan_table
   WHERE  statement_id = 'PTREF'
   AND    object_type = 'DESCR'
 )
 SELECT r.recname, r.recdescr, r.rellangrecname, r.parentrecname, r.descrlong||' '||x.descrlong
 INTO   l_recname, l_recdescr, l_rellangrecname, l_parentrecname, l_descrlong
 FROM   psrecdefn r
	LEFT OUTER JOIN x ON x.recname = r.recname
 WHERE  r.recname = UPPER(p_recname);

 dbms_output.put_line('<html><head>');
 dbms_output.put_line('<title>'||l_recname||' - '||l_recdescr||' - PeopleTools Table Reference</title>');
 dbms_output.put_line('<base target="_blank">');
 dbms_output.put_line('</head><body>');
 dbms_output.put_line('<table border="0" cellspacing="0" cellpadding="0" width="100%"><tr><td align="left" valign="top"><h1>'||l_recname||'</h1></td>');
 dbms_output.put_line('<td align="right" valign="top"><p align="right"><A HREF="javascript:javascript:history.go(-1)">back</A></td></tr></table>');
 

 IF l_descrlong IS NOT NULL THEN
  dbms_output.put_line(l_descrlong||'<p>');
 END IF;

 IF l_rellangrecname > ' ' THEN
  SELECT rectype INTO l_rectype FROM psrecdefn WHERE recname = l_rellangrecname;
  IF l_rectype = 0 THEN
   dbms_output.put_line('<li>Related language record: <a target="_self" href="'||LOWER(l_rellangrecname)||'.html">'||l_rellangrecname||'</a></li><p>');
  ELSE
   dbms_output.put_line('<li>Related language record: '||l_rellangrecname||'</li><p>');
  END IF;
 ELSE 
  l_counter := 0;
  FOR j IN (
   SELECT DISTINCT r.recname, r.rectype
   FROM   psrecdefn r
-- ,   	  psobjgroup o 
   WHERE  (r.objectownerid = 'PPT' OR r.recname = r.sqltablename)
-- AND    o.objgroupid = 'PEOPLETOOLS'
-- AND    o.entname = r.recname
   AND    r.rellangrecname = l_recname 
   ORDER BY r.recname
  ) LOOP
   IF l_counter = 0 THEN
    dbms_output.put_line('<li>Related language record for');
    l_counter := 1;
   END IF;
   IF j.rectype = 0 THEN
    dbms_output.put_line(' <a target="_self" href="'||j.recname||'.html">'||j.recname||'</a>');  
   ELSE
    dbms_output.put_line(' '||j.recname);  
   END IF;
  END LOOP;
  IF l_counter > 0 THEN
   dbms_output.put_line('</li><p>');
  END IF;
 END IF;

 IF l_parentrecname > ' ' THEN
  SELECT rectype INTO l_rectype FROM psrecdefn WHERE recname = l_parentrecname;
  IF l_rectype = 0 THEN
   dbms_output.put_line('<li>Parent record: <a target="_self" href="'
	||LOWER(l_parentrecname)||'.html">'||l_parentrecname||'</a></li><p>');
  ELSE
   dbms_output.put_line('<li>Parent record: '||l_parentrecname||'</li><p>');
  END IF;
 ELSE 
  l_counter := 0;
  FOR j IN (
   SELECT DISTINCT r.recname, r.rectype
   FROM   psrecdefn r
-- ,   	  psobjgroup o 
   WHERE  (r.objectownerid = 'PPT' OR r.recname = r.sqltablename)
-- AND    o.objgroupid = 'PEOPLETOOLS'
-- AND    o.entname = r.recname
   AND    r.parentrecname = l_recname 
   ORDER BY r.recname
  ) LOOP
   IF l_counter = 0 THEN
    dbms_output.put_line('<li>Parent record of');
    l_counter := 1;
   END IF;
   IF j.rectype = 0 THEN
    dbms_output.put_line(' <a target="_self" href="'||j.recname||'.html">'||j.recname||'</a>');  
   ELSE
    dbms_output.put_line(' '||j.recname);  
   END IF;
  END LOOP;
  IF l_counter > 0 THEN
   dbms_output.put_line('</li><p>');
  END IF;
 END IF;

 dbms_output.put_line('<table border="1" style="border-style:double; border-width:0; padding-left: 0px; padding-right: 0px; padding-top: 0px; padding-bottom: 0px" cellspacing="0" cellpadding="1">');

 IF p_oracol THEN
  dbms_output.put_line('<tr>');
  dbms_output.put_line('<th>'||l_recname||'</th>');
  dbms_output.put_line('<th>DBA_</th>');
  dbms_output.put_line('<th rowspan="3">Description of PeopleTools Column</th>');
  dbms_output.put_line('</tr>');
  dbms_output.put_line('<tr>');
  dbms_output.put_line('<th align="left">PeopleSoft Field Name</th>');
  dbms_output.put_line('<th align="left">Field Type</th>');
  dbms_output.put_line('<th align="left">Corresponding Oracle Column Name</th>');
  dbms_output.put_line('</tr>');
 ELSE
  dbms_output.put_line('<tr>');
  dbms_output.put_line('<th align="left">PeopleSoft Field Name</th>');
  dbms_output.put_line('<th align="left">Field Type</th>');
  dbms_output.put_line('<th align="left">Description</th>');
  dbms_output.put_line('</tr>');
 END IF; 

 l_newline := FALSE;
 FOR i IN (
   WITH x AS (
     SELECT object_type
	 ,      object_name fieldname
     ,      other_xml 
     FROM   plan_table
     WHERE  statement_id = 'PTREF'
     AND    object_type IN('FIELD','XLAT')
   )
   SELECT f.fieldname, f.useedit
   ,      d.fieldtype, d.descrlong, d.length, d.decimalpos
   ,      COALESCE(l1.longname,l2.longname) longname
   ,      f.edittable
   ,      f.setcntrlfld
   ,      f.defrecname, f.deffieldname
   ,      r.rectype erectype
   ,      CASE WHEN (r.objectownerid = 'PPT' OR r.recname = r.sqltablename) THEN 1 ELSE 0 END pt
   ,      x.object_type, x.other_xml
   FROM psrecfielddb f
        LEFT OUTER JOIN x ON x.fieldname = f.fieldname
        LEFT OUTER JOIN psrecdefn r
        ON r.recname = f.edittable
	    LEFT OUTER JOIN psdbfldlabl L1
		ON l1.fieldname = f.fieldname
		AND l1.label_id = f.label_id
		LEFT OUTER JOIN psdbfldlabl L2
		ON l2.fieldname = f.fieldname
		AND l2.default_label = 1
	  , psdbfield d
   WHERE f.fieldname = d.fieldname
   AND   f.recname = l_recname 
   ORDER BY fieldnum
 ) LOOP
 l_col_def := '';
 dbms_output.put_line('<tr>');

 IF MOD(i.useedit,2)=1 THEN
  l_key := k_key;
 ELSE
  l_key := '';
 END IF;
 IF i.other_xml IS NOT NULL THEN
  dbms_output.put_line('<td valign="top">'||l_key||'<a name="'||i.fieldname||'" target="_self" href="'||i.other_xml||'">'||i.fieldname||'</a></td>');
 ELSE
  dbms_output.put_line('<td valign="top">'||l_key||'<a name="'||i.fieldname||'">'||i.fieldname||'</a></td>');
 END IF;

 IF p_oracol THEN 
  dbms_output.put_line('<td valign="top">'||k_space||'</td>');
 END IF;

 IF i.fieldtype = 0 THEN
  l_datatype := 'VARCHAR2';

 ELSIF i.fieldtype IN(1,8,9) THEN
  IF i.length BETWEEN 1 AND 2000 THEN
   l_datatype := 'VARCHAR2';
  ELSE
   l_datatype := 'CLOB';
  END IF;

 ELSIF i.fieldtype IN(4) THEN
  l_datatype := 'DATE';

 ELSIF i.fieldtype IN(5,6) THEN
  l_datatype := 'TIMESTAMP';

 ELSIF i.fieldtype = 2 THEN
  IF i.decimalpos > 0 THEN
   l_datatype := 'DECIMAL';
  ELSE
   IF i.length <= 4 THEN
    l_datatype := 'SMALLINT';
   ELSIF i.length > 8 THEN --20.2.2008 pt8.47??
    l_datatype := 'DECIMAL';
    i.length := i.length + 1;
   ELSE
    l_datatype := 'INTEGER';
   END IF;
  END IF;

 ELSIF i.fieldtype = 3 THEN
  l_datatype := 'DECIMAL';
  IF i.decimalpos = 0 THEN
   i.length := i.length + 1;
  END IF;

 END IF;

 l_col_def := l_datatype;

 IF l_datatype = 'VARCHAR2' THEN 
  l_col_def := l_col_def||'('||i.length||')';
 ELSIF l_datatype = 'DECIMAL' THEN
  IF i.fieldtype = 2 THEN
   l_col_def := l_col_def||'('||(i.length-1);
  ELSE /*type 3*/
   l_col_def := l_col_def||'('||(i.length-2);
  END IF;
  IF i.decimalpos > 0 THEN
   l_col_def := l_col_def||','||i.decimalpos;
  END IF;
  l_col_def := l_col_def||')';
 END IF;

 IF i.fieldtype IN(0,2,3) OR mod(FLOOR(i.useedit/256),2) = 1 THEN
  l_col_def := l_col_def||' NOT NULL';
 END IF;

 dbms_output.put_line('<td valign="top">'||l_col_def||'</td>');

 dbms_output.put_line('<td valign="top">');
 IF i.descrlong IS NOT NULL THEN
  dbms_output.put_line(i.descrlong);
  l_newline := TRUE;
 ELSIF i.longname IS NOT NULL THEN
  dbms_output.put_line(i.longname);
  l_newline := TRUE;
 END IF;

 IF i.object_type = 'XLAT' THEN
  dbms_output.put_line('<a target="_self" href="'||i.other_xml||'">translate values</a>');
 ELSE
  --useeedit bit 9 set if its an xlat field, but we do not check the bit, just list the xlats
  FOR j IN (SELECT x.* FROM psxlatitem x WHERE fieldname = i.fieldname ORDER BY x.fieldvalue) LOOP
   IF l_newline THEN
    dbms_output.put_line('<br>');
   END IF;
   dbms_output.put_line(j.fieldvalue||'='||NVL(j.xlatlongname,j.xlatshortname));
   l_newline := TRUE;
  END LOOP;
  IF NOT l_newline THEN
   dbms_output.put_line(k_space);
  END IF;
 END IF;

 IF BITAND(i.useedit,8192)=8192 THEN
  dbms_output.put_line('<p>Y/N Table Edit');
 END IF;
 IF BITAND(i.useedit,1048576)=1048576 THEN
  dbms_output.put_line('<p>1/0 Table Edit (1=True, 0=False)');
 END IF;
 IF i.deffieldname > ' ' THEN
  dbms_output.put_line('<p>Default: '||(CASE WHEN i.defrecname > ' ' THEN i.defrecname||'.' END)||i.deffieldname);
 END IF;

 IF i.edittable > ' ' THEN
  dbms_output.put_line('<p>Prompt Table:');
  IF i.erectype IN(0,1) AND i.pt = 1 THEN 
   dbms_output.put_line('<a target="_self" href="'
	||LOWER(i.edittable)||'.html">'||i.edittable||'</a>');
   IF i.setcntrlfld > ' ' THEN
    dbms_output.put_line('<br>Set Control Field: <a target="_self" href="'
	||LOWER(i.edittable)||'.html#'||i.setcntrlfld||'">'||i.setcntrlfld||'</a>');
   END IF;
  ELSE
   dbms_output.put_line(i.edittable);
   IF i.setcntrlfld > ' ' THEN
    dbms_output.put_line('<br>Set Control Field: '||i.setcntrlfld);
   END IF;
  END IF;
 END IF;

 dbms_output.put_line('</td>');
 dbms_output.put_line('</tr>');
 END LOOP;
 dbms_output.put_line('</table>');
 dbms_output.put_line('<table border="0" cellspacing="0" cellpadding="0" width="100%"><tr>');

 dbms_output.put_line('<td colspan="2"><p align="right"><font face="Century Gothic"><strong style="font-weight: 400">');
 dbms_output.put_line('<font size="1" face="Century Gothic">PeopleTools '||l_toolsrel||'</font></td></tr><tr>');

 dbms_output.put_line('<td><A HREF="javascript:javascript:history.go(-1)">back</A></td>');
 dbms_output.put_line('<td><font face="Century Gothic"><strong style="font-weight: 400">');
 dbms_output.put_line('</td></tr></table>');

 dbms_output.put_line('</body>');
END pthtml;
----------------------------------------------------------------------------------------------------
PROCEDURE ptindex IS
BEGIN
 dbms_output.put_line('<html><head>');
 dbms_output.put_line('<title>PeopleTools Table Reference - Index</title>');
 tablestyle;
 dbms_output.put_line('</head><body><h1>PeopleTools Records</h1><table>');
 dbms_output.put_line('<tr><th>Tables</th><th>Views</th></tr>');
 FOR i IN (
  SELECT DISTINCT SUBSTR(r.recname,1,CASE WHEN SUBSTR(r.recname,1,2) IN('PS') THEN 3 ELSE 1 END) index_section
  FROM   psrecdefn r
--,	     psobjgroup o
  where  (r.objectownerid = 'PPT' OR r.recname = r.sqltablename)
  and    r.rectype IN(0,1)
--and    o.objgroupid = 'PEOPLETOOLS'
--and    o.entname = r.recname
  ORDER BY 1
 ) LOOP

   --section heading
   dbms_output.put_line('<tr><th colspan="2"><a name="'||i.index_section||'"></a>');
   FOR j IN (
    SELECT DISTINCT SUBSTR(r.recname,1,CASE WHEN SUBSTR(r.recname,1,2) IN('PS') THEN 3 ELSE 1 END) index_section
    FROM   psrecdefn r
--,	       psobjgroup o
    where  (r.objectownerid = 'PPT' OR r.recname = r.sqltablename)
    and    r.rectype IN(0,1)
--  and    o.objgroupid = 'PEOPLETOOLS'
--  and    o.entname = r.recname
    ORDER BY 1
   ) LOOP
     IF i.index_section = j.index_section THEN  
       dbms_output.put_line('<b>'||j.index_section||'</b> ');  
	 ELSE
       dbms_output.put_line('<a target="_self" href="#'||j.index_section||'">'||j.index_section||'</a> ');  
     END IF;
   END LOOP;
   dbms_output.put_line('</th></tr><tr>');
   
   --section context
   FOR j IN 0..1 LOOP 
     dbms_output.put_line('<td>');
     FOR k IN (
       SELECT DISTINCT r.rectype, r.recname, r.recdescr
       FROM   psrecdefn r
       where  (r.objectownerid = 'PPT' OR r.recname = r.sqltablename)
       and    SUBSTR(r.recname,1,CASE WHEN SUBSTR(r.recname,1,2) IN('PS') THEN 3 ELSE 1 END) = i.index_section
       and    r.rectype = j
       ORDER BY r.recname
    ) LOOP
      dbms_output.put_line('<a name="'||k.recname||'" href="'||LOWER(k.recname)||'.html">'||k.recname||'</a> - '||k.recdescr||'<br>');
    END LOOP;
    dbms_output.put_line('</td>');
   END LOOP;
   dbms_output.put_line('</tr>');
 END LOOP;
 dbms_output.put_line('</table></body></html>');
END ptindex;
----------------------------------------------------------------------------------------------------
PROCEDURE ptxlat
(p_fieldname IN VARCHAR2) IS

 l_toolsrel       VARCHAR2(20 CHAR);
 l_descrlong      CLOB;

BEGIN
 SELECT toolsrel
 INTO   l_toolsrel
 FROM   psstatus;

 SELECT NVL(f.descrlong,l2.longname)
 INTO   l_descrlong 
 FROM   psdbfield f
 		LEFT OUTER JOIN psdbfldlabl L2
		ON l2.fieldname = f.fieldname
		AND l2.default_label = 1
WHERE  f.fieldname = p_fieldname;

 dbms_output.put_line('<html>');
 dbms_output.put_line('<head><title>'||p_fieldname||' - '||l_descrlong||' - PeopleTools XLAT Reference</title></head>');
 dbms_output.put_line('<body>');

 dbms_output.put_line('<table border="0" cellspacing="0" cellpadding="0" width="100%"><tr><td align="left" valign="top"><h1>'||p_fieldname||'</h1></td>');
 dbms_output.put_line('<td align="right" valign="top"><p align="right"><A HREF="javascript:javascript:history.go(-1)">back</A></td></tr></table>');

 IF l_descrlong IS NOT NULL THEN
  dbms_output.put_line(l_descrlong||'<p>');
 END IF;

 dbms_output.put_line('<table border="1" style="border-style:double; border-width:0; padding-left: 0px; padding-right: 0px; padding-top: 0px; padding-bottom: 0px" cellspacing="0" cellpadding="1">');
 dbms_output.put_line('<tr>');
 dbms_output.put_line('<th align="left">Translate Value</th>');
 dbms_output.put_line('<th align="left">Short Description</th>');
 dbms_output.put_line('<th align="left">Long Description</th>');
 dbms_output.put_line('</tr>');

 FOR i IN(
   select i.*
   from   psxlatitem i
   where  i.fieldname = p_fieldname
   and    i.eff_status = 'A'
   and    i.effdt = (SELECT MAX(i1.effdt)
                     FROM   psxlatitem i1
                     WHERE  i1.fieldname = p_fieldname
                     AND    i1.fieldvalue = i.fieldvalue)
   ORDER BY fieldvalue, effdt
 ) LOOP
  dbms_output.put_line('<tr>');
  dbms_output.put_line('<td valign="top">'||i.fieldvalue||'</td>');
  dbms_output.put_line('<td valign="top">'||i.xlatshortname||'</td>');
  dbms_output.put_line('<td valign="top">'||i.xlatlongname||'</td>');
  dbms_output.put_line('</tr>');
 END LOOP;

dbms_output.put_line('</table>');

dbms_output.put_line('<table border="0" cellspacing="0" cellpadding="0" width="100%"><tr>');
dbms_output.put_line('<td colspan="2"><p align="right"><font face="Century Gothic"><strong style="font-weight: 400">');
dbms_output.put_line('<font size="1" face="Century Gothic">PeopleTools '||l_toolsrel||'</font></td></tr><tr>');
dbms_output.put_line('<td><A HREF="javascript:javascript:history.go(-1)">back</A></td>');
dbms_output.put_line('<td><font face="Century Gothic"><strong style="font-weight: 400">');
dbms_output.put_line('</td></tr></table>');

END ptxlat;

END ptref;
/
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
show errors
spool off
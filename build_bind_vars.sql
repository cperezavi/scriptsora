-------------------------------------------------------------------------------------------------------
--
-- File name:   build_bind_vars.sql
--
-- Purpose:     Build SQL*Plus test script with variable definitions
--
-- Author:      Jack Augustin and Kerry Osborne
--
-- Description: This script creates a file which can be executed in SQL*Plus. It creates bind variables, 
--              sets the bind variables to the values stored in V$SQL_PLAN.OTHER_XML, and then executes 
--              the statement. The sql_id is used for the file name and is also placed in the statement
--              as a comment. Note that numeric bind variable names are not permited in SQL*Plus, so if
--              the statement has numberic bind variable names, they have an 'N' prepended to them. Also
--              note that CHAR variables are converted to VARCHAR2.
--
-- Usage:       This scripts prompts for two values.
--
--              sql_id:   this is the sql_id of the statement you want to duplicate
--
--              child_no: this is the child cursor number from v$sql 
--                        (the default is 0 second)
--
-- http://kerryosborne.oracle-guy.com/2009/07/creating-test-scripts-with-bind-variables/
-------------------------------------------------------------------------------------------------------
set sqlblanklines on
set trimspool on
set trimout on
set feedback off;
set linesize 255;
set pagesize 50000;
set timing off;
set head off
--
accept sql_id char prompt "Enter SQL ID ==> "
accept child_no char prompt "Enter Child Number ==> " default 0
var isdigits number
col sql_fulltext for a140 word_wrap
--
--
spool &&sql_id\.sql
--
--Check for numeric bind variable names
--
begin
select case regexp_substr(replace(name,':',''),'[[:digit:]]') when replace(name,':','') then 1 end into :isdigits
from
V$SQL_BIND_CAPTURE
where
sql_id='&&sql_id'
and child_number = &&child_no
and rownum < 2;
end;
/
--
-- Create variable statements
--
select
'variable ' ||
   case :isdigits when 1 then replace(name,':','N') else substr(name,2,30) end || ' ' ||
decode(datatype_string,'CHAR(','VARCHAR2(','DATE','VARCHAR2(20)',datatype_string) txt
-- replace(datatype_string,'CHAR(','VARCHAR2(') txt
from
V$SQL_BIND_CAPTURE
where
sql_id='&&sql_id'
and child_number = &&child_no;
--
-- Set variable values from V$SQL_PLAN
--
select 'begin' txt from dual;
select
   case :isdigits when 1 then replace(bind_name,':',':N') else bind_name end ||
-- case regexp_substr(replace(bind_name,':',''),'[[:digit:]]') when replace(bind_name,':','') then 'N' else ' ' end ||
' := ' ||
case when bind_type in (1,12) then '''' else null end ||
case when bind_type = 1 then enkitec.display_raw(bind_data,'VARCHAR2')
when bind_type = 2 then decode(bind_data,null,'to_number(null)',enkitec.display_raw(bind_data,'NUMBER'))
when bind_type = 12 then enkitec.display_raw(bind_data,'DATE')
else bind_data end ||
case when bind_type in (1,12) then '''' else null end || ';' 
|| ' -- bind_type: '|| bind_type || '  raw_bind_data: '|| bind_data
txt
from (
select
extractvalue(value(d), '/bind/@nam') as bind_name,
extractvalue(value(d), '/bind/@dty') as bind_type,
extractvalue(value(d), '/bind') as bind_data
from
xmltable('/*/*/bind'
passing (
select
xmltype(other_xml) as xmlval
from
v$sql_plan
where
sql_id like nvl('&&sql_id',sql_id)
and child_number = &&child_no
and other_xml is not null
)
) d
)
;
select 'end;' txt from dual;
select '/' txt from dual;
--
-- Generate statement
--
select regexp_replace(sql_fulltext,'(select |SELECT )','select /* test &&sql_id */ ',1,1) sql_fulltext from (
select case :isdigits when 1 then replace(sql_fulltext,':',':N') else sql_fulltext end ||';' sql_fulltext
from v$sqlarea
where sql_id = '&&sql_id');
spool off;
-- ed &&sql_id\.sql
undef sql_id
undef child_no
set feedback on;
set head on

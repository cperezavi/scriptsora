----------------------------------------------------------------------------------------
--
-- File name:   flush_sql10p.sql
--
-- Purpose:     Flush a single SQL statement.
-
-- Author:      Kerry Osborne
--
-- Usage:       This scripts prompts for a sql_id.
--
--              sql_id: the sql_id of a statement that is in the shared pool (v$sql)
--
--
-- Description: This scripts creates a SQL Profile on the specified statement and then 
--              drops it. This has the side affect of flushing the statement from the
--              shared pool. Well, not always flushing, but generally marking any existing 
--              children unusable resulting in a parse the next time the statement is 
--              executed. Note, this is the second attempt at this. The first was based
--              on Outlines which was a bit flakey.
--
--              See kerryosborne.oracle-guy.com for additional information.
---------------------------------------------------------------------------------------


accept sql_id -
       prompt 'Enter value for sql_id: ' -
       default 'X0X0X0X0'

set feedback off
set sqlblanklines on
set serveroutput on for wrap

declare
cl_sql_text clob;
begin

select sql_fulltext into cl_sql_text
from v$sql
where sql_id = '&&sql_id'
and rownum < 2;

dbms_sqltune.import_sql_profile(
sql_text => cl_sql_text, 
profile => sqlprof_attr('dummy hint'),
category => 'FLUSH',
name => 'FLUSH_'||'&&sql_id'
);

dbms_sqltune.drop_sql_profile (name   => 'FLUSH_'||'&&sql_id');

dbms_output.put_line(' ');
dbms_output.put_line('sql_id: '||'&&sql_id'||' flushed.');
dbms_output.put_line(' ');

exception
when NO_DATA_FOUND then
  dbms_output.put_line(' ');
  dbms_output.put_line('ERROR: sql_id: '||'&&sql_id'||' not found in v$sqlarea.');
  dbms_output.put_line(' ');

end;
/

undef sql_id

set sqlblanklines off
set feedback on

----------------------------------------------------------------------------------------
--
-- File name:   rsm_html.sql
-- Purpose:     Execute DBMS_SQLTUNE.REPORT_SQL_MONITOR function in html mode.
--
-- Author:      Kerry Osborne
--              
-- Usage:       This scripts prompts for three values, all of which can be left blank.
--
--              If all three parameters are left blank, the last statement monitored
--              for the current session will be reported on.
--
--              If the SID is specified and the other two parameters are left blank,
--              the last statement executed by the specified SID will be reported.
--
--              If the SQL_ID is specified and the other two parameters are left blank,
--              the last execution of the specified statement by the current session
--              will be reported.
--
--              If the SID and the SQL_ID are specifie and the SQL_EXEC_ID is left 
--              blank, the last execution of the specified statement by the specified
--              session will be reported.
--
--              If all three parameters are specified, the specified execution of the
--              specified statement by the specified session will by reported.
--
--              Note:   If a match is not found - the header is printed with no data.
--                      The most common cause for this is when you enter a SQL_ID and
--                      leave the other parameters blank, but the current session has 
--                      not executed the specifid statement.
--
--              Note 2: The serial# is not prompted for, but is setup by the decodei.
--                      The serial# parameter is in here to ensure you don't get data 
--                      for the wrong session, but be aware that you may need to modify 
--                      this script to allow input of a specific serial#.
--
--              Note 3: A file is spooled with the html contents.
---------------------------------------------------------------------------------------
set pagesize 0 echo off timing off linesize 1000 trimspool on trim on long 2000000 longchunksize 2000000 feedback off
col report for a400
accept sid  prompt "Enter value for sid: "
accept sql_id  prompt "Enter value for sql_id: "
accept sql_exec_id  prompt "Enter value for sql_exec_id: " default '16777216'
spool sqlmon_&&sql_id\_&&sql_exec_id\.html
select
DBMS_SQLTUNE.REPORT_SQL_MONITOR(
   session_id=>nvl('&&sid',sys_context('userenv','sid')),
   session_serial=>decode('&&sid',null,null,
sys_context('userenv','sid'),(select serial# from v$session where audsid = sys_context('userenv','sessionid')),
null),
   sql_id=>'&&sql_id',
   sql_exec_id=>'&&sql_exec_id',
   type=>'EM',
   report_level=>'ALL') 
as report
from dual;
spool off
set lines 155
undef SID
undef sql_id
undef sql_exec_id
set feedback on

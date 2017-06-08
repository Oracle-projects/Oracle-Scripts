/*-------------------------------------------------------------------------------------------------
| Purpose:  To kill a Documentum user session
*/-------------------------------------------------------------------------------------------------


SELECT username FROM v$session WHERE username IS NOT NULL ORDER BY username ASC;

SELECT a.sid, a.serial#, b.sql_text FROM v$session a, v$sqlarea b WHERE a.sql_address=b.address and a.username='DOC_TEST1';

--ALTER SYSTEM KILL SESSION '71,14454'; --< PASTE a.sid here

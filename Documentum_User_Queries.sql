/*-------------------------------------------------------------------------------------------------
| Purpose:  To produce a script per docbase to perform various checks.
*/-------------------------------------------------------------------------------------------------

WITH
user_list (GROUPNUM, USER_OS_NAME)
AS
( 
/*-------------------------------------------------------------------------------------------------
| ---------------------------  UPDATE THE LIST OF USERS HERE --------------------------------------
*/-------------------------------------------------------------------------------------------------
SELECT 1 AS GROUPNUM, 'UserName1' AS USER_OS_NAME  FROM DUAL UNION
SELECT 1 AS GROUPNUM, 'UserName2' AS USER_OS_NAME  FROM DUAL UNION
SELECT 1 AS GROUPNUM, 'UserName3' AS USER_OS_NAME  FROM DUAL UNION
SELECT 1 AS GROUPNUM, 'UserName4' AS USER_OS_NAME  FROM DUAL 
)
--SELECT * FROM user_list
,
user_list_multi
AS
(
  --SELECT LISTAGG(LOWER(USER_OS_NAME), ''',''') WITHIN GROUP (ORDER BY GROUPNUM) AS USER_OS_NAME FROM user_list  --<< CONCATENATE USERS HERE TO ONE ROW
  SELECT LISTAGG(UPPER(USER_OS_NAME), ''',''') WITHIN GROUP (ORDER BY GROUPNUM) AS USER_OS_NAME FROM user_list  --<< CONCATENATE USERS HERE TO ONE ROW
)
--SELECT * FROM user_list_multi
, 
script_build
AS
(
  SELECT 
    dba_users.USERNAME
  , 1 AS GROUPNUM
  , ROWNUM AS RowNumber
  , 'SELECT per.USER_NAME, UPPER(per.USER_OS_NAME)AS USER_OS_NAME, per.USER_ADDRESS, per.USER_STATE, per.USER_GROUP_NAME, per.HOME_DOCBASE, per.ACL_DOMAIN, per.LAST_LOGIN_UTC_TIME, per.R_MODIFY_DATE FROM ' || dba_users.USERNAME || '.DM_USER_S per WHERE per.USER_LOGIN_NAME IN (''' || user_list_multi.USER_OS_NAME || ''') ' AS CHECK_USERS_PER_DOCBASE
  , 'SELECT doc.r_object_id, doc.object_name, doc.title, doc.r_lock_owner, doc.group_name, doc.acl_domain FROM ' || dba_users.USERNAME || '.dm_document_sp  doc INNER JOIN ' || dba_users.USERNAME || '.dm_user_sp dm_user ON dm_user.user_name = doc.r_lock_owner WHERE dm_user.user_os_name IN (''' || user_list_multi.USER_OS_NAME || ''') ' AS DOCUMENTS_CHECKED_OUT
  , 'SELECT per.USER_NAME, UPPER(per.USER_OS_NAME)AS USER_OS_NAME, per.USER_ADDRESS, per.USER_STATE, per.USER_GROUP_NAME, per.HOME_DOCBASE, per.ACL_DOMAIN, per.LAST_LOGIN_UTC_TIME, per.R_MODIFY_DATE FROM ' || dba_users.USERNAME || '.DM_USER_S per WHERE per.LAST_LOGIN_UTC_TIME < (sysdate - interval ''6'' month ) AND USER_OS_NAME != '' '' AND per.USER_STATE = 1 ' AS CHECK_6MTHS_DISABLED
  , 'SELECT per.USER_NAME, UPPER(per.USER_OS_NAME)AS USER_OS_NAME, per.USER_ADDRESS, per.USER_STATE, per.USER_GROUP_NAME, per.HOME_DOCBASE, per.ACL_DOMAIN, per.LAST_LOGIN_UTC_TIME, per.R_MODIFY_DATE FROM ' || dba_users.USERNAME || '.DM_USER_S per WHERE USER_OS_NAME != '' '' AND per.USER_STATE = 1 ' AS CHECK_ALL_DISABLED
  , 'SELECT ''' || dba_users.USERNAME || ''' as DocBase, wrk.object_name, wrk.r_object_id, to_date(to_char(wrk.r_start_date,''MON-YYYY''),''MON-YYYY'') as MonthDate, count(pkg.r_workflow_id) as DocCount FROM ' || dba_users.USERNAME || '.DM_WORKFLOW_S wrk INNER JOIN ' || dba_users.USERNAME || '.DMI_PACKAGE_S pkg ON wrk.r_object_id = pkg.r_workflow_id GROUP BY to_date(to_char(wrk.r_start_date,''MON-YYYY''),''MON-YYYY''), wrk.object_name, wrk.r_object_id, ''' || dba_users.USERNAME || ''' ' as workflow_doc_count
  , 'SELECT ''' || dba_users.USERNAME || ''' as DocBase, loc.R_OBJECT_ID, loc.MOUNT_POINT_NAME, loc.PATH_TYPE, loc.FILE_SYSTEM_PATH, loc.SECURITY_TYPE, loc.NO_VALIDATION FROM ' || dba_users.USERNAME || '.DM_LOCATION_S loc ' AS CHECK_DOCBASE_LOCATIONS
  FROM 
      dba_users
    , user_list_multi
  WHERE 
    1=1
    AND DEFAULT_TABLESPACE NOT IN('SYSAUX', 'SYSTEM', 'USERS', 'AVAIL') --<< REMOVE SYSTEM USERS HERE
    AND dba_users.USERNAME NOT IN('DOC_TEST1', 'DOC_TEST2') --<< NO LONGER USED DOCBASES
)
--SELECT * FROM script_build
, 
max_row_number
AS
(
  SELECT MAX(RowNumber) AS MaxRowNumber FROM script_build
)
--SELECT * FROM max_row_number
, 
script_per_docbase
AS
(
  --SELECT RowNumber, MaxRowNumber, CHECK_DOCBASE_LOCATIONS || CASE WHEN MaxRowNumber = RowNumber THEN '' ELSE 'UNION' END AS "SCRIPT_RESULTS" FROM script_build, max_row_number 
  SELECT RowNumber, MaxRowNumber, CHECK_USERS_PER_DOCBASE || CASE WHEN MaxRowNumber = RowNumber THEN '' ELSE 'UNION' END AS "SCRIPT_RESULTS" FROM script_build, max_row_number 
  --SELECT RowNumber, MaxRowNumber, workflow_doc_count || CASE WHEN MaxRowNumber = RowNumber THEN '' ELSE 'UNION' END AS "SCRIPT_RESULTS" FROM script_build, max_row_number
  --SELECT RowNumber, MaxRowNumber, DOCUMENTS_CHECKED_OUT || CASE WHEN MaxRowNumber = RowNumber THEN '' ELSE 'UNION' END AS "SCRIPT_RESULTS" FROM script_build, max_row_number 
  --SELECT RowNumber, MaxRowNumber, CHECK_6MTHS_DISABLED || CASE WHEN MaxRowNumber = RowNumber THEN '' ELSE 'UNION' END AS "SCRIPT_RESULTS" FROM script_build, max_row_number 
  --SELECT RowNumber, MaxRowNumber, CHECK_ALL_DISABLED || CASE WHEN MaxRowNumber = RowNumber THEN '' ELSE 'UNION' END AS "SCRIPT_RESULTS" FROM script_build, max_row_number 
)
SELECT SCRIPT_RESULTS FROM script_per_docbase ORDER BY RowNumber
/*-------------------------------------------------------------------------------------------------
| -----------  COPY THE ROWS RETURNED AND RUN THEM IN A SEPARATE SQL WINDOW.  ---------------------
*/-------------------------------------------------------------------------------------------------
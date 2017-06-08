/*-------------------------------------------------------------------------------------------------
| Purpose:  To produce a script per docbase to perform various checks.
*/-------------------------------------------------------------------------------------------------

WITH
docbase_list 
AS
(
  SELECT 
      USERNAME
    , DEFAULT_TABLESPACE 
  FROM 
    dba_users 
  WHERE 
    1=1
    AND DEFAULT_TABLESPACE NOT IN('SYSAUX', 'SYSTEM', 'USERS', 'AVAIL') --<< REMOVE SYSTEM USERS HERE
    AND USERNAME NOT IN('DOC_TEST1', 'DOC_TEST2') --<< DOCBASES NOT NEEDED FOR THE LIST
  ORDER BY 1 -- USED TO GET THE DOCBASES IN ABC ORDER
)
,
script_build -- USED TO CREATE A SCRIPT PER DOCBASE
AS
(
  SELECT 
    USERNAME
  , ROWNUM AS RowNumber 
  , 'SELECT USER_NAME, USER_STATE, USER_LOGIN_NAME, ''' || docbase_list.USERNAME || ''' AS DOCBASE_NAME, USER_LOGIN_DOMAIN, USER_ADDRESS, USER_GROUP_NAME, USER_SOURCE, R_IS_GROUP FROM ' || docbase_list.USERNAME || '.DM_USER_S ' AS ACTIVE_USERS_SCRIPT
  FROM 
    docbase_list 
)
, 
max_row_number -- FIND THE LAST ROW TO CREATE THE UNION QUERY
AS
(
  SELECT 
    MAX(RowNumber) AS MaxRowNumber 
  FROM 
    script_build
)
SELECT 
  CASE WHEN RowNumber = 1 THEN 'SELECT UPPER(SYS_CONTEXT (''USERENV'', ''SERVER_HOST'')) AS SERVER_NAME, USER_NAME, USER_STATE, USER_LOGIN_NAME, DOCBASE_NAME, USER_LOGIN_DOMAIN, USER_ADDRESS, USER_GROUP_NAME, USER_SOURCE FROM (' ELSE '' END || ACTIVE_USERS_SCRIPT || CASE WHEN MaxRowNumber = RowNumber THEN ') WHERE (USER_GROUP_NAME NOT IN(''docu'', '' '') AND USER_LOGIN_NAME NOT IN(''ADMIN_USER_NAME1'', ''ADMIN_USER_NAME2'', ''timeout_admin'') AND R_IS_GROUP=''0'')' ELSE 'UNION' END AS "SCRIPT_RESULTS" 
FROM 
    script_build
  , max_row_number;

/*-------------------------------------------------------------------------------------------------
| -----------  COPY THE ROWS RETURNED AND RUN THEM IN A SEPARATE SQL WINDOW.  ---------------------
*/-------------------------------------------------------------------------------------------------

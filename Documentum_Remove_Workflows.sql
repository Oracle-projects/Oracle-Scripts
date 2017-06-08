/*--------------------------------------------------------------------------------------------------------------------------------+
| Purpose: Script for removing Documentum workflows
+--------------------------------------------------------------------------------------------------------------------------------*/

SELECT 
	  r_object_id
	, object_name
	, title
	, owner_name
	, r_object_type
	, r_creation_date
	, r_modify_date
	, a_content_type 
	, r_object_type
FROM 
	dm_document 
WHERE 
	1=1
	AND r_object_id IN(SELECT r_component_id FROM dmi_package WHERE r_workflow_id IN(SELECT r_object_id FROM dm_workflow WHERE r_runtime_state = 4))
	AND r_modify_date < DATE('11/01/2014 00:00:00','MM/DD/YYYY hh:mm:ss') 

SELECT 
	  r_object_id
	, object_name
	, title
	, owner_name
	, r_object_type
	, r_creation_date
	, r_modify_date
	, a_content_type 
	, r_object_type
	, API_SCRIPT1 = 'abort,c,' + r_workflow_id
	, API_SCRIPT2 = 'destroy,c,' + r_workflow_id
FROM 
	dm_document 
WHERE 
	1=1
	AND r_object_id IN(SELECT r_component_id FROM dmi_package WHERE r_workflow_id IN(SELECT r_object_id FROM dm_workflow WHERE r_runtime_state = 4))
	AND r_modify_date < DATE('11/01/2014 00:00:00','MM/DD/YYYY hh:mm:ss') 

/*

--SELECT r_object_id FROM dm_workflow WHERE r_object_id in (SELECT r_workflow_id FROM dmi_package WHERE r_component_id = ‘<document’s r_object_id’)

--to terminate a workflow
--API>abort,c,<workflow id>
--API>destroy,c,<workflow id>

--Values for r_runtime_state are
--DF_WF_STATE_DORMANT =	0
--DF_WF_STATE_FINISHED = 2
--DF_WF_STATE_HALTED = 3
--DF_WF_STATE_RUNNING =	1
--DF_WF_STATE_TERMINATED = 4
--DF_WF_STATE_UNKNOWN =	-1
	
----EXAMPLE EXPRESSIONS
--and r_modify_date < '01-Nov-2014'
--and r_modify_date < DATE('TODAY')	
--and owner_name = 'Adam Clencie'	
--and r_object_type = 'med_prots_reps_doc'

SELECT 
	  w.r_object_id
	, d.r_object_id
	, d.object_name AS doc_name
	, d.document_status AS doc_status
	, w.object_name AS workflow_name
	, w.supervisor_name AS workflow_supervisor 
FROM dm_workflow w, dm_document d 
WHERE d.r_object_id IN (select distinct r_component_id from dmi_package where r_workflow_id = w.r_object_id);

SELECT 
	  w.r_object_id
	, d.r_object_id
	, d.object_name AS doc_name
	, w.object_name AS workflow_name
	, w.supervisor_name AS workflow_supervisor 
FROM 
	  dm_workflow w 
	, dm_document d 
WHERE 
	1=1
	AND d.r_object_id IN (select distinct r_component_id from dmi_package where r_workflow_id = w.r_object_id)
	AND w.supervisor_name = 'Some Name Here';
	
SELECT 
	  w.r_object_id
	, w.object_name AS workflow_name
	, w.supervisor_name AS workflow_supervisor 
	, w.R_START_DATE AS start_date 
FROM 
	  dm_workflow w 
WHERE 
	1=1
	AND w.supervisor_name = 'Some Name Here'
	AND w.R_START_DATE BETWEEN DATE('01/13/2015 00:00:00','MM/DD/YYYY hh:mm:ss') AND DATE('01/13/2015 15:30:00','MM/DD/YYYY hh:mm:ss')
	
*/

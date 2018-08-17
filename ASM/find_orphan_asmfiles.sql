-- Find orphan asm files
DEFINE ASMGROUP="DGDATA"
 
set linesize 200
set pagesize 50000
col reference_index noprint
col type format a15
col files format a80

WITH v_asmgroup AS (SELECT group_number FROM v$asm_diskgroup WHERE name='&ASMGROUP'),
     v_parentindex AS (SELECT parent_index 
                    FROM v$asm_alias 
              WHERE group_number = (SELECT group_number FROM v_asmgroup) 
                AND alias_index=0),
  v_asmfiles AS (SELECT file_number, type 
              FROM v$asm_file 
           WHERE group_number = (SELECT group_number FROM v_asmgroup)),
 v_dbname AS (SELECT '/'||upper(db_unique_name)||'/' dbname from v$database)
SELECT 'rm '|| files files FROM -- this line show the delete command
(
  SELECT '+&ASMGROUP'||files files, type 
  FROM (SELECT upper(sys_connect_by_path(aa.name,'/')) files, aa.reference_index, b.type
        FROM (SELECT file_number,alias_directory,name, reference_index, parent_index 
        FROM v$asm_alias) aa,
             (SELECT parent_index FROM v_parentindex) a,
             (SELECT file_number, type FROM v_asmfiles) b
  WHERE aa.file_number=b.file_number(+)
    AND aa.alias_directory='N'
   -- missing PARAMETERFILE, DATAGUARDCONFIG
   AND b.type in ('DATAFILE','ONLINELOG','CONTROLFILE','TEMPFILE')
  START WITH aa.PARENT_INDEX=a.parent_index
  CONNECT BY PRIOR aa.reference_index=aa.parent_index)
  WHERE substr(files,instr(files,'/',1,1),instr(files,'/',1,2)-instr(files,'/',1,1)+1) = (select dbname FROM v_dbname)
MINUS (
  SELECT upper(name) files, 'DATAFILE' type FROM v$datafile
    UNION ALL 
  SELECT upper(name) files, 'TEMPFILE' type FROM v$tempfile
    UNION ALL
 SELECT upper(name) files, 'CONTROLFILE' type FROM v$controlfile WHERE name like '+&ASMGROUP%'
    UNION ALL
 SELECT upper(member) files, 'ONLINELOG' type FROM v$logfile WHERE member like '+&ASMGROUP%'
)
);
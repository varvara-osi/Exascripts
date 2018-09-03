-- From the following sizing:
-- Peak redo rate according to EM or AWR reports Recommended redo log group size
--   <= 5 MB/sec 4 GB
--   <= 25 MB/sec 16 GB
--   <= 50 MB/sec 32 GB
--   > 50 MB/sec 64 GB

set linesize 300
column REDOLOG_FILE_NAME format a50
SELECT
    a.GROUP#,
    a.THREAD#,
    a.SEQUENCE#,
    a.ARCHIVED,
    a.STATUS,
    b.MEMBER    AS REDOLOG_FILE_NAME,
    (a.BYTES/1024/1024) AS SIZE_MB
FROM v$log a
JOIN v$logfile b ON a.Group#=b.Group#
ORDER BY a.GROUP# ASC;
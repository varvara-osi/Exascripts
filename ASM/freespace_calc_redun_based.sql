select
  2  name,decode(type,'NORMAL',2,'HIGH',3,'EXTERN',1) Redundancy,
  3  (total_mb/decode(type,'NORMAL',2,'HIGH',3,'EXTERN',1)) Total_MB,
  4  (free_mb/decode(type,'NORMAL',2,'HIGH',3,'EXTERN',1)) Free_MB,
  5  ((free_mb/decode(type,'NORMAL',2,'HIGH',3,'EXTERN',1))/(total_mb/decode(type,'NORMAL',2,'HIGH',3,'EXTERN',1)))*100 "%Free"
  6  from v$asm_diskgroup;
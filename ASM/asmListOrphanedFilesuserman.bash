########################################################################
# shell commands to identify orphaned ASM files
########################################################################

Note:
These shell snippets are based upon Martin Nash's blog entry
"Orphaned Files in ASM"
http://oraganism.wordpress.com/2012/09/09/orphaned-files-in-asm/

They are very similar to what is posted there.  I have modified them
to run in both 10g and 11g.  His code uses listagg which is only available
in 11g.  I have also added a step to list the timestamp for each file
so you can confirm they have not been recently used.

Please take the time to review the blog entry for all of the proper
warnings, precautions, and script assumptions.  They all apply to this
code as well.

I recommend you run these commands in steps, reviewing the results
of each step before proceeding to the next one.  To make this clear,
I have bracketed each step with ## begin paste ## and ## end paste ##.
The expectation is you copy everything in between and paste to your
Linux shell.


#-----------------------------------------------------------------------
# Generate list of possible files to orphaned_files_*.log
#-----------------------------------------------------------------------
## begin paste ##
for inst in $(ps -u oracle -o args|grep ^ora_smon|sed s/ora_smon_//g|sort)
do
  ORAENV_ASK=NO
  ORACLE_SID=${inst}
  . oraenv
  ORAENV_ASK=YES
  diskgroups=$(echo "
  set pages 0 feedback off
  select name from v\$asm_diskgroup;
  "|sqlplus -s -L / as sysdba
  )
  echo Checking $diskgroups in instance ${inst}
  for diskgroup in ${diskgroups}
  do
    echo "catalog start with '+${diskgroup}/${inst%[1-8]}';"|rman target / >orphaned_files_${inst%[1-8]}_${diskgroup}.log 2>&1
  done
done
## end paste ##

#-----------------------------------------------------------------------
# Parse orphaned_files_*.log to get list of candidates for removal
#-----------------------------------------------------------------------
## begin paste ##
awk '
{
  if (($1" "$2 == "File Name:") && ($3 !~ /spfile/)) {
    print $3
  }
}' orphaned_files* |\
less -S
## end paste ##

#-----------------------------------------------------------------------
# Do ASM ls command of candidates for removal and make sure timestamp
# is old for every file listed.  If it is recent then you might be
# removing a file you will regret.
#-----------------------------------------------------------------------
## begin paste ##
ORAENV_ASK=NO
ORACLE_SID=$(awk -F: '/ASM/ {print $1'} /etc/oratab|head -n 1)
. oraenv
  ORAENV_ASK=YES
asmVersion=$(asmcmd -V 2>&1)
case "${asmVersion}" in
  "asmcmd version"*)
    lsOptions=" -Llsd --suppressheader "
  ;;
  *)
    lsOptions=" -LlsdH "
  ;;
esac
awk -v lsOptions="${lsOptions}" '
{
  if (($1" "$2 == "File Name:") && ($3 !~ /spfile/)) {
    print "ls " lsOptions $3
  }
}' orphaned_files* |\
asmcmd |\g
tee asmLs.txt |\
less -S
## end paste ##


#-----------------------------------------------------------------------
# Generate removal commands
#-----------------------------------------------------------------------
## begin paste ##
awk '
{
  if (($1" "$2 == "File Name:") && ($3 !~ /spfile/)) {
    print "rm "$3
  }
}' orphaned_files* |\
tee asmRm.txt |\
less -S
## end paste ##


Note: if you are now confident it is safe to delete everything in asmRm.txt,
You can do it by simply piping the file into asmcmd:  cat asmRm.txt|asmcmd
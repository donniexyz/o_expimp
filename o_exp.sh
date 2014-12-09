#!/bin/sh
#
# This scripts export oracle tables using export command: exp
#
# Input:
#    params.dat     oracle parameters is on parameter file
#    EXP.lst        list of tables to export on file
#    $CWDBOWNER     oracle user id
#    $CWDBPASWD     oracle password
#
#
# Output:
#   processed.${stmp}.lst       List of exported tables
#   ${stmp}-DMP/                DMP directory destination
#   ${stmp}-LOG/                Log directory destination
#
#
#
#

echo ""
echo "o_exp"
echo ""
echo "configuration:"
echo "****"
cat < params.dat
echo "****"


echo ""
echo "Preparation.."

stmp=$(date '+%Y%m%d-%H%M%S')
logdir=$(echo "${stmp}-LOG")
dmpdir=$(echo "${stmp}-DMP")
explist=EXP.lst

processed=processed.${stmp}.lst
processing=processing.${stmp}.lst

if [[ ! -f ${explist} ]] 
then
  echo "Input to be exported tables ${explist} is not found."
  echo "***Process terminated"
  exit 1
fi

rm -f ${processing}
rm -f ${processed}
mkdir $logdir
mkdir $dmpdir

echo ""
echo "===================================================="
echo "EXEC STAMP:                          ${stmp}"
echo "Input to be exported tables :        ${explist}"
echo "Output of exported tables :          ${processed}"
echo "DMP destination :                    ${dmpdir}/"
echo "LOG destination :                    ${logdir}/"
echo "===================================================="
echo ""
if [[ ! -s ${explist} ]] 
then
  echo "Input to be exported tables ${explist} is empty."
  echo "Process completed"
  exit
fi

echo "Processing...."
  
while read tblname filedest cond ; do
  
  if [[ -z ${tblname} ]]
  then 
    continue
  fi
  
  echo "-- $tblname $filedest $cond"
  echo $tblname $filedest $cond > ${processing}
  
  rm -f $tblname.dmp 

  if [[ ! -z ${cond} ]]; then QRY=$(echo "QUERY=${cond}") ; else QRY='' ; fi
  
  if [[ -z ${filedest} ]]
  then 
    filedest=${tblname}
  fi
  
  if [[ "${filedest}" = "." ]]
  then 
    filedest=${tblname}
  fi
  
  echo ""
  echo "> exp $CWDBOWNER/$CWDBPASWD TABLES=$tblname $QRY FILE=${dmpdir}/${filedest}.dmp LOG=${logdir}/${tblname}.log PARFILE=params.dat"

  exp $CWDBOWNER/$CWDBPASWD TABLES=$tblname $QRY FILE=${dmpdir}/${filedest}.dmp LOG=${logdir}/${tblname}.log PARFILE=params.dat
  retcode_exp=$?
  
  echo $retcode_exp $tblname ${filedest}.dmp $cond >> ${processed}

  if [[ $retcode_exp != 0 ]]; then
     echo "*** exp fail on :"
     cat < ${processing}
     echo ""
     echo "***Process terminated"
     exit 1
  fi
  
  echo ""
  echo "> zip -m ${dmpdir}/${filedest}.dmp.zip ${dmpdir}/${filedest}.dmp"
  zip -m ${dmpdir}/${filedest}.dmp.zip ${dmpdir}/${filedest}.dmp
  retcode_zip=$?
  
  if [[ $retcode_zip != 0 ]]; then
     echo "*** zip fail on :"
     cat < ${processing}
     echo ""
     echo "***Process terminated"
     exit 1
  fi
  
done  < ${explist}

echo ""
echo "Process completed"

echo ""
echo "===================================================="
echo "EXEC STAMP:                          ${stmp}"
echo "Input to be exported tables :        ${explist}"
echo "Output of exported tables :          ${processed}"
echo "DMP destination :                    ${dmpdir}/"
echo "LOG destination :                    ${logdir}/"
echo "===================================================="
echo ""

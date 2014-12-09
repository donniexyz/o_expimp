#!/bin/sh
#
# This scripts imports oracle dumps using import command: imp
#
# Input:
#    paramsld.dat   oracle parameter file
#    $1             directory of DMP folder (result of o_exp)
#    $CWDBOWNER     oracle user id
#    $CWDBPASWD     oracle password
#
#
# Output:
#   processed.${stmp}.ld        List of imported dump file
#   ${stmp}-LOG/                Log directory destination
#
#
#
#

echo ""
echo "o_imp"
echo ""
echo "configuration:"
echo "****"
cat < paramsld.dat
echo "****"

echo ""
echo "Preparation.."

stmp=$(date '+%Y%m%d-%H%M%S')
logdir=$(echo "${stmp}-LOG")
dmpdir=$1

processed=processed.${stmp}.ld
processing=processing.${stmp}.ld

if [[ -z ${dmpdir} ]] 
then
  echo ""
  echo "ERROR"
  echo "Input directory of the dumps is not set"
  echo "***Process terminated"
  exit 1
fi

rm -f ${processing}
rm -f ${processed}
mkdir $logdir

echo ""
echo "===================================================="
echo "EXEC STAMP:                          ${stmp}"
echo "DMP source loc :                     ${dmpdir}/"
echo "List of imported tables :            ${processed}"
echo "LOG destination :                    ${logdir}/"
echo "===================================================="
echo ""

echo "Processing...."
  
ls -1 ${dmpdir}/ | while read dmpfilename ; do
  echo "  $dmpfilename"
  echo $dmpfilename > ${processing}
  
  dmpfn=${dmpfilename}
  extens=${dmpfilename##*.}

  if [[ "${extens}" = "zip" ]] ; then
     unzip -o -q ${dmpdir}/${dmpfilename} 
     dmpfn=${dmpfilename%.*}
  fi
  
  tblname=${dmpfn%.*}

  echo ""
  echo "> imp $CWDBOWNER/$CWDBPASWD TABLES=$tblname FILE=${dmpdir}/${dmpfn} LOG=${logdir}/${tblname}.log PARFILE=paramsld.dat"

  imp $CWDBOWNER/$CWDBPASWD TABLES=$tblname FILE=${dmpdir}/${dmpfn} LOG=${logdir}/${tblname}.log PARFILE=paramsld.dat
  retcode_imp=$?
  
  echo $retcode_imp $tblname ${dmpfn} >> ${processed}

  if [[ "${extens}" = "zip" ]] ; then
     rm -f ${dmpdir}/${dmpfn}
  fi
  
  if [[ $retcode_imp != 0 ]]; then
     echo "*** imp fail on :"
     cat < ${processing}
     echo ""
     echo "***Process terminated"
     exit 1
  fi
  
done

echo ""
echo "Process completed"

echo ""
echo "===================================================="
echo "EXEC STAMP:                          ${stmp}"
echo "DMP source loc :                     ${dmpdir}/"
echo "List of imported tables :            ${processed}"
echo "LOG destination :                    ${logdir}/"
echo "===================================================="
echo ""


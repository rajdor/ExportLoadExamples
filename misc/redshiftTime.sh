#!/bin/bash

source config.sh
scriptName=`basename "$0"`

banner "Initialize Reshift table for exports and loads using ${RedshifttargetDDL} and ${sourceDataFile}"
echo "config.sh PGHOST          : ${PGHOST}"
echo "config.sh PGPORT          : ${PGPORT}"
echo "config.sh PGDATABASE      : ${PGDATABASE}"
echo "config.sh PGUSER          : ${PGUSER}"
echo "config.sh PGPASSWORD      : ${PGPASSWORD}"
echo "config.sh sourceTablename : ${sourceTablename}"
echo "config.sh sourceDDL       : ${RedshifttargetDDL}"
echo "config.sh sourceDataFile  : ${sourceDataFile}"

echo 
echo "today                     : ${today}"
echo "scriptName                : ${scriptName}"
echo "workingDir                : ${workingDir}"


psql -a -f redshiftTime.sql
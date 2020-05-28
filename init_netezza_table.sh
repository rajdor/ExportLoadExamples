#!/bin/bash

source config.sh

banner "Initialize Netezza table for exports and loads using ${sourceDDL} and ${sourceDataFile}"
echo "config.sh NZ_HOST         : ${NZ_HOST}"
echo "config.sh NZ_PORT         : ${NZ_PORT}"
echo "config.sh NZ_DATABASE     : ${NZ_DATABASE}"
echo "config.sh NZ_USER         : ${NZ_USER}"
echo "config.sh NZ_PASSWORD     : ${NZ_PASSWORD}"
echo "config.sh sourceTablename : ${sourceTablename}"
echo "config.sh sourceDDL       : ${sourceDDL}"
echo "config.sh sourceDataFile  : ${sourceDataFile}"

echo 
echo "today                     : ${today}"
echo "scriptName                : ${scriptName}"
echo "workingDir                : ${workingDir}"

echo "current_time              : ${current_time}"
badfile=${workingDir}${targetTablename}_badrecords_${current_time}.txt
logfile=${workingDir}${targetTablename}_loadlog_${current_time}.txt

echo "badfile                   : ${badfile}"
echo "logfile                   : ${logfile}"


banner "Looking for existing source table"
tables_exist=$(nzsql -t -c "select count(*) from information_schema.tables where table_type = 'TABLE' and upper(table_name) = upper('${sourceTablename}')")
tables_exist="$(echo -e "${tables_exist}" | tr -d '[:space:]')"
echo "  Found ${tables_exist} tables existing"
if [[ ${tables_exist} > 0 ]]; then 
   echo "  Generating Drop statements"
   stmts=$(nzsql -t -c "SELECT 'DROP TABLE ' || table_name || ';' as stmt FROM information_schema.tables where table_type = 'TABLE' and upper(table_name) = upper('${sourceTablename}')")
   echo "Running DROP"
   nzsql -a -c "${stmts}"
fi


banner "Creating table from ${sourceDDL}"
nzsql -a -f ${sourceDDL}


banner "Loading table ${sourceTablename} from ${sourceDataFile}"
nzload -t ${sourceTablename} -df ${sourceDataFile} -delim '|' -bf ${badfile} -lf ${logfile}
if [ -f "${logfile}" ]; then
   cat ${logfile}
fi
if [ -f "${badfile}" ]; then
   head ${badfile}
fi

banner "Counting records on ${sourceTablename}"
nzsql -a -c "SELECT COUNT(*) FROM ${sourceTablename}"


banner "Done"
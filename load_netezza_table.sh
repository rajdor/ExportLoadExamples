#!/bin/bash

source config.sh

targetDataFile=${1}

banner "Netezza Load ${targetTablename} from ${targetDataFile}"
echo "config.sh NZ_HOST         : ${NZ_HOST}"
echo "config.sh NZ_PORT         : ${NZ_PORT}"
echo "config.sh NZ_DATABASE     : ${NZ_DATABASE}"
echo "config.sh NZ_USER         : ${NZ_USER}"
echo "config.sh NZ_PASSWORD     : ${NZ_PASSWORD}"
echo "config.sh targetTablename : ${targetTablename}"
echo "config.sh targetDDL       : ${targetDDL}"
echo "config.sh targetDataFile  : ${targetDataFile}"
echo 
echo "today                     : ${today}"
echo "scriptName                : ${scriptName}"
echo "workingDir                : ${workingDir}"

echo "current_time              : ${current_time}"
badfile=${workingDir}${targetTablename}_badrecords_${current_time}.txt
logfile=${workingDir}${targetTablename}_loadlog_${current_time}.txt

echo "badfile                   : ${badfile}"
echo "logfile                   : ${logfile}"


if [ -z "$targetDataFile" ]
then
      echo "ERROR : \${targetDataFile} is empty; set variable to specify file to load by passing in path & filename of datafile to load"
      exit 8
fi


banner "Looking for existing target table"
tables_exist=$(nzsql -t -c "select count(*) from information_schema.tables where table_type = 'TABLE' and upper(table_name) = upper('${targetTablename}')")
tables_exist="$(echo -e "${tables_exist}" | tr -d '[:space:]')"
echo "  Found ${tables_exist} tables existing"
if [[ ${tables_exist} > 0 ]]; then 
   echo "  Generating Drop statements"
   stmts=$(nzsql -t -c "SELECT 'DROP TABLE ' || table_name || ';' as stmt FROM information_schema.tables where table_type = 'TABLE' and upper(table_name) = upper('${targetTablename}')")
   echo "Running DROP"
   nzsql -a -c "${stmts}"
fi


banner "Creating table from ${targetDDL}"
nzsql -a -f ${targetDDL}


banner "Loading table ${targetTablename} from ${targetDataFile}"
nzload -t ${targetTablename} -df ${targetDataFile} -delim '|' -bf ${badfile} -lf ${logfile}
if [ -f "${logfile}" ]; then
   cat ${logfile}
fi
if [ -f "${badfile}" ]; then
   head ${badfile}
fi


banner "Counting records on ${targetTablename}"
nzsql -a -c "SELECT COUNT(*) FROM ${targetTablename}"


banner "Done"
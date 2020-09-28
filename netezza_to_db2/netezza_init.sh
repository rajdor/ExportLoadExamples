#!/bin/bash

source ../config.sh
source config.sh
scriptName=`basename "$0"`

banner "Initialize Netezza table for exports and loads using ${initDDL}"
echo "../config.sh NZ_HOST          : ${NZ_HOST}"
echo "../config.sh NZ_PORT          : ${NZ_PORT}"
echo "../config.sh NZ_DATABASE      : ${NZ_DATABASE}"
echo "../config.sh NZ_USER          : ${NZ_USER}"
echo "../config.sh NZ_PASSWORD      : ${NZ_PASSWORD}"
echo "config.sh initTablename       : ${initTablename}"
echo "config.sh initDDL             : ${initDDL}"
echo "config.sh initDataInserts     : ${initDataInserts}"
echo "config.sh initDataInsertsCheck: ${initDataInsertsCheck}"
echo "today                         : ${today}"
echo "scriptName                    : ${scriptName}"
echo "workingDir                    : ${workingDir}"
echo "current_time                  : ${current_time}"

badfile=${workingDir}${targetTablename}_badrecords_${current_time}.txt
logfile=${workingDir}${targetTablename}_loadlog_${current_time}.txt
echo "badfile                   : ${badfile}"
echo "logfile                   : ${logfile}"

################################################################################
banner "Looking for existing source table"
tables_exist=$(nzsql -t -c "select count(*) from information_schema.tables where table_type = 'TABLE' and upper(table_name) = upper('${initTablename}')")
tables_exist="$(echo -e "${tables_exist}" | tr -d '[:space:]')"
echo "  Found ${tables_exist} tables existing"
if [[ ${tables_exist} > 0 ]]; then 
    echo "  Generating Drop statements"
    stmts=$(nzsql -t -c "SELECT 'DROP TABLE ' || table_name || ';' as stmt FROM information_schema.tables where table_type = 'TABLE' and upper(table_name) = upper('${initTablename}')")
    echo "Running DROP"
    nzsql -c "${stmts}"
fi

################################################################################
banner "Creating table from ${initDDL}"
nzsql -f ${initDDL}

################################################################################
banner "Running Inserts from ${initDataInserts}"
nzsql -f ${initDataInserts}

################################################################################
banner "Counting records on ${initTablename}"
nzsql -c "SELECT COUNT(*) FROM ${initTablename}"

################################################################################
banner "Running Inserts Check SQL using ${initDataInsertsCheck}"
nzsql -f ${initDataInsertsCheck}

################################################################################
banner "Done"
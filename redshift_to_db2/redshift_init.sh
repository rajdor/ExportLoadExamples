#!/bin/bash

source ../config.sh
source config.sh
scriptName=`basename "$0"`

banner "Initialize Reshift table for exports and loads using ${RedshifttargetDDL} and ${sourceDataFile}"
echo "config.sh PGHOST               : ${PGHOST}"
echo "config.sh PGPORT               : ${PGPORT}"
echo "config.sh PGDATABASE           : ${PGDATABASE}"
echo "config.sh PGUSER               : ${PGUSER}"
echo "config.sh PGPASSWORD           : ${PGPASSWORD}"
echo "config.sh initTablename        : ${initTablename}"
echo "config.sh initDDL              : ${initDDL}"
echo "config.sh initDataInserts      : ${initDataInserts}"
echo "config.sh initDataInsertsCheck : ${initDataInsertsCheck}"

echo 
echo "today                     : ${today}"
echo "scriptName                : ${scriptName}"
echo "workingDir                : ${workingDir}"

fname=$(basename "$sourceDataFile")
s3file=${s3bucket}/${s3path}/${fname}
echo "s3file                    : ${s3file}"



banner "Looking for existing source table"
tables_exist=$(psql -t -c "select count(*) from information_schema.tables where upper(table_catalog) = upper('"${PGDATABASE}"') and upper(table_schema) = 'PUBLIC' and TABLE_TYPE = 'BASE TABLE' and upper(table_name) = upper('${initTablename}')")
tables_exist="$(echo -e "${tables_exist}" | tr -d '[:space:]')"
echo "  Found ${tables_exist} tables existing"
if [[ ${tables_exist} > 0 ]]; then 
   echo "  Generating Drop statements"
   stmts=$(psql -t -c "SELECT 'DROP TABLE ' || table_name || ';' as stmt FROM information_schema.tables where upper(table_catalog) = upper('"${PGDATABASE}"') and upper(table_schema) = 'PUBLIC' and TABLE_TYPE = 'BASE TABLE' and upper(table_name) = upper('${initTablename}')")
   echo "Running DROP"
   psql -c "${stmts}"
fi


banner "Creating table from ${initDDL}"
psql -f ${initDDL}

banner "Running Insert Statements from ${initDataInserts}"
psql -f ${initDataInserts}

banner "Running Insert Checks from ${initDataInsertsCheck}"
psql -f ${initDataInsertsCheck}

banner "Counting records on ${initTablename}"
psql -c "SELECT COUNT(*) FROM ${initTablename}"

banner "Done"
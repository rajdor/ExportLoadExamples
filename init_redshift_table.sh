#!/bin/bash

source config.sh

banner "Initialize Reshift table for exports and loads using ${sourceDDL} and ${sourceDataFile}"
echo "config.sh PGHOST          : ${PGHOST}"
echo "config.sh PGPORT          : ${PGPORT}"
echo "config.sh PGDATABASE      : ${PGDATABASE}"
echo "config.sh PGUSER          : ${PGUSER}"
echo "config.sh PGPASSWORD      : ${PGPASSWORD}"
echo "config.sh sourceTablename : ${sourceTablename}"
echo "config.sh sourceDDL       : ${sourceDDL}"
echo "config.sh sourceDataFile  : ${sourceDataFile}"

echo 
echo "today                     : ${today}"
echo "scriptName                : ${scriptName}"
echo "workingDir                : ${workingDir}"

fname=$(basename "$sourceDataFile")
s3file=${s3bucket}/${s3path}/${fname}
echo "s3file                    : ${s3file}"



banner "Looking for existing source table"
tables_exist=$(psql -t -c "select count(*) from information_schema.tables where upper(table_catalog) = upper('"${PGDATABASE}"') and upper(table_schema) = 'PUBLIC' and TABLE_TYPE = 'BASE TABLE' and upper(table_name) = upper('${sourceTablename}')")
tables_exist="$(echo -e "${tables_exist}" | tr -d '[:space:]')"
echo "  Found ${tables_exist} tables existing"
if [[ ${tables_exist} > 0 ]]; then 
   echo "  Generating Drop statements"
   stmts=$(psql -t -c "SELECT 'DROP TABLE ' || table_name || ';' as stmt FROM information_schema.tables where upper(table_catalog) = upper('"${PGDATABASE}"') and upper(table_schema) = 'PUBLIC' and TABLE_TYPE = 'BASE TABLE' and upper(table_name) = upper('${sourceTablename}')")
   echo "Running DROP"
   psql -a -c "${stmts}"
fi


banner "Creating table from ${sourceDDL}"
psql -a -f ${sourceDDL}

banner "Removing any existing file from ${s3bucket}/${s3path}"
aws s3 rm s3://${s3bucket}/${s3path}/  --recursive

banner "Copying ${sourceDataFile} to S3 ${s3bucket}/${s3path}"
aws s3 cp ${sourceDataFile} s3://${s3file}


banner "Loading table ${sourceTablename} from ${sourceDataFile}"
stmts="copy ${sourceTablename} from 's3://${s3file}'  iam_role '${iamrole}' delimiter '|';"
psql -a -c "${stmts}"


banner "Counting records on ${sourceTablename}"
psql -a -c "SELECT COUNT(*) FROM ${sourceTablename}"


banner "Removing ${s3bucket}/${s3path}"
aws s3 rm s3://${s3bucket}/${s3path}/  --recursive


banner "Done"
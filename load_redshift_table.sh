#!/bin/bash

source config.sh

targetDataFile=${1}

banner "Initialize Reshift table for exports and loads using ${targetDDL} and ${targetDataFile}"
echo "config.sh PGHOST          : ${PGHOST}"
echo "config.sh PGPORT          : ${PGPORT}"
echo "config.sh PGDATABASE      : ${PGDATABASE}"
echo "config.sh PGUSER          : ${PGUSER}"
echo "config.sh PGPASSWORD      : ${PGPASSWORD}"
echo "config.sh targetTablename : ${targetTablename}"
echo "config.sh targetDDL       : ${targetDDL}"
echo "config.sh targetDataFile  : ${targetDataFile}"


echo 
echo "today                     : ${today}"
echo "scriptName                : ${scriptName}"
echo "workingDir                : ${workingDir}"

gzipfile=${targetDataFile}.gz
echo "gzipfile                  : ${gzipfile}"
fname=$(basename "$gzipfile")
s3file=${s3bucket}/${s3path}/${fname}
echo "s3file                    : ${s3file}"

if [ -z "$targetDataFile" ]
then
      echo "ERROR : ${targetDataFile} is empty; set variable to specify file to load by passing in path & filename of datafile to load"
      exit 8
fi

banner "Looking for existing target table"
tables_exist=$(psql -t -c "select count(*) from information_schema.tables where upper(table_catalog) = upper('"${PGDATABASE}"') and upper(table_schema) = 'PUBLIC' and TABLE_TYPE = 'BASE TABLE' and upper(table_name) = upper('${targetTablename}')")
tables_exist="$(echo -e "${tables_exist}" | tr -d '[:space:]')"
echo "  Found ${tables_exist} tables existing"
if [[ ${tables_exist} > 0 ]]; then 
   echo "  Generating Drop statements"
   stmts=$(psql -t -c "SELECT 'DROP TABLE ' || table_name || ';' as stmt FROM information_schema.tables where upper(table_catalog) = upper('"${PGDATABASE}"') and upper(table_schema) = 'PUBLIC' and TABLE_TYPE = 'BASE TABLE' and upper(table_name) = upper('${targetTablename}')")
   echo "Running DROP"
   psql -a -c "${stmts}"
fi


banner "Creating table from ${targetDDL}"
psql -a -f ${targetDDL}

banner "Removing any existing file from ${s3bucket}/${s3path}"
aws s3 rm s3://${s3bucket}/${s3path}/  --recursive


banner "gzipping ${targetDataFile}"
gzip --keep ${targetDataFile}


banner "Copying ${gzipfile} to S3 ${s3bucket}/${s3path}"
aws s3 cp ${gzipfile} s3://${s3file}


banner "removing gzip file ${gzipfile}"
rm ${gzipfile}


banner "Loading table ${targetTablename} from ${gzipfile}"
stmts="copy ${targetTablename} from 's3://${s3file}'  iam_role '${iamrole}' delimiter '|' gzip;"
psql -a -c "${stmts}"


banner "Counting records on ${targetTablename}"
psql -a -c "SELECT COUNT(*) FROM ${targetTablename}"


banner "Removing ${s3bucket}/${s3path}"
aws s3 rm s3://${s3bucket}/${s3path}/  --recursive


banner "Done"
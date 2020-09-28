#!/bin/bash

source ../config.sh
source config.sh
scriptName=`basename "$0"`

sourceDataFile=${1}

banner "Initialize Reshift table for exports and loads using ${RedshifttargetDDL} and ${targetDataFile}"
echo "../config.sh PGHOST           : ${PGHOST}"
echo "../config.sh PGPORT           : ${PGPORT}"
echo "../config.sh PGDATABASE       : ${PGDATABASE}"
echo "../config.sh PGUSER           : ${PGUSER}"
echo "../config.sh PGPASSWORD       : ${PGPASSWORD}"
echo "config.sh targetTablename     : ${targetTablename}"
echo "config.sh targetDDL           : ${targetDDL}"
echo "config.sh sourceDataFile      : ${sourceDataFile}"
echo "config.sh targetDataLoadCheck : ${targetDataLoadCheck}"
echo "today                         : ${today}"
echo "scriptName                    : ${scriptName}"
echo "workingDir                    : ${workingDir}"

################################################################################
fname=$(basename "$sourceDataFile")
s3file=${s3bucket}/${s3path}/${fname}
echo "s3file                    : ${s3file}"

################################################################################
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

################################################################################
banner "Creating table from ${targetDDL}"
psql -f ${targetDDL}

################################################################################
banner "Removing any existing file from ${s3bucket}/${s3path}"
aws s3 rm s3://${s3bucket}/${s3path}/  --recursive

################################################################################
banner "Copying ${fname} to S3 ${s3file}"
aws s3 cp ${sourceDataFile} s3://${s3file}

################################################################################
banner "Loading table ${targetTablename} from ${gzipfile}"
stmts="copy ${targetTablename} from 's3://${s3file}'  iam_role '${iamrole}' FORMAT AS CSV delimiter '|' DATEFORMAT AS 'YYYY-MM-DD' TIMEFORMAT AS 'YYYY-MM-DD HH:MI:SS' ACCEPTINVCHARS gzip;"
psql -a -c "${stmts}"

################################################################################
banner "Counting records on ${targetTablename}"
psql -a -c "SELECT COUNT(*) FROM ${targetTablename}"


################################################################################
banner "Running Check Data"
psql -f ${targetDataLoadCheck}

################################################################################
banner "Done"
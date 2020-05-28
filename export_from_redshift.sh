#!/bin/bash

source config.sh

externalTable='EXT_'${sourceTablename}
exportFileName='TMP_'${sourceTablename}.csv

banner "Redshift Export from ${sourceTablename} to ${workingDir}${exportFileName}"
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
echo "externalTable             : ${externalTable}"
echo "exportFileName            : ${exportFileName}"

fname=$(basename "$sourceDataFile")
s3file=${s3bucket}/${s3path}/${fname}
echo "s3file                    : ${s3file}"

banner "Check for & clear temporary workspaces before starting"
if [[ -d ${workingDir} ]]; then
   echo "Error - unexpectedly found local workspace ${workingDir}"
   echo "Maybe a failed previous run that needs to be cleaned up?"
   if [[ "yes" == $(ask_yes_or_no "Delete existing Working Directory ${workingDir}?") ]]; then
      rm -r ${workingDir}
   fi
fi
mkdir -p ${workingDir}


banner "Looking for existing source table"
tables_exist=$(psql -t -c "select count(*) from information_schema.tables where upper(table_catalog) = upper('"${PGDATABASE}"') and upper(table_schema) = 'PUBLIC' and TABLE_TYPE = 'BASE TABLE' and upper(table_name) = upper('${sourceTablename}')")
tables_exist="$(echo -e "${tables_exist}" | tr -d '[:space:]')"
echo "  Found ${tables_exist} tables existing"
if [[ ${tables_exist} = 0 ]]; then 
   echo "  Table to export not found"
   exit 8
fi
echo "Counting records to export from ${sourceTablename}"
psql -a -c "SELECT COUNT(*) FROM ${sourceTablename}"


banner "Exporting ${sourceTablename} to ${s3file}"
psql -a -c "unload ('select * from ${sourceTablename}') to 's3://${s3file}' delimiter '|' ALLOWOVERWRITE GZIP iam_role '${iamrole}';"


temporaryWorkingDir=${workingDir}/tmp/
banner "Copying s3://${s3file} to local ${temporaryWorkingDir}${exportFileName}"
aws s3 ls s3://${s3file}
aws s3 cp s3://${s3bucket}/${s3path}/ ${temporaryWorkingDir} --recursive


banner "Combining multi-part files to ${temporaryWorkingDir}${exportFileName}"
gunzip ${temporaryWorkingDir}/*.gz
tmpfile=$(mktemp /tmp/abc-script.XXXXXX)
cat $(ls -t ${temporaryWorkingDir}/*) > ${tmpfile}
rm -r ${temporaryWorkingDir}/*
mv ${tmpfile} ${workingDir}${exportFileName}
ls -al  ${workingDir}


banner "Removing ${s3bucket}/${s3path}"
aws s3 rm s3://${s3file} --recursive


banner "Done"
ls -al ${workingDir}${exportFileName}
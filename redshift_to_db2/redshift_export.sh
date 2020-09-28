#!/bin/bash

source ../config.sh
source config.sh
scriptName=`basename "$0"`

banner "Export  from Reshift table"
echo "../config.sh PGHOST       : ${PGHOST}"
echo "../config.sh PGPORT       : ${PGPORT}"
echo "../config.sh PGDATABASE   : ${PGDATABASE}"
echo "../config.sh PGUSER       : ${PGUSER}"
echo "../config.sh PGPASSWORD   : ${PGPASSWORD}"
echo "config.sh sourceTablename : ${sourceTablename}"
echo "config.sh targetFilename  : ${targetFilename}"
echo "today                     : ${today}"
echo "scriptName                : ${scriptName}"
echo "workingDir                : ${workingDir}"

fname=$(basename "$targetFilename")
s3file=${s3bucket}/${s3path}/${fname}
echo "s3file                    : s3://${s3file}"

################################################################################
banner "NOTE : THIS IS INCOMPLETE : MORE WORK ON FILE FORMAT, use generate SQL to replace embdeded 0x00"
echo "PROBABLY LOTS OF OTHER THINGS AS WELL suche as quotes and escapes"
read -p "Continue (y/n)?" CONT
if [ "$CONT" = "y" ]; then
  echo "";
else
  exit;
fi


################################################################################
banner "Looking for existing target table"
tables_exist=$(psql -t -c "select count(*) from information_schema.tables where upper(table_catalog) = upper('"${PGDATABASE}"') and upper(table_schema) = 'PUBLIC' and TABLE_TYPE = 'BASE TABLE' and upper(table_name) = upper('${sourceTablename}')")
tables_exist="$(echo -e "${tables_exist}" | tr -d '[:space:]')"
echo "  Found ${tables_exist} tables existing"
if [[ ${tables_exist} == 0 ]]; then 
   echo "  Unable to continue, source table does not exist"
   exit 
fi

###############################################################################
banner "Removing any existing file from s3://${s3bucket}/${s3path}"
aws s3 rm s3://${s3bucket}/${s3path}/  --recursive

###############################################################################
banner "Unloading ${sourceTablename} to s3://${s3file}"
psql -t -c "unload ('select * from ${sourceTablename}') to 's3://${s3file}' iam_role '${iamrole}' FORMAT AS CSV delimiter '|' NULL AS 'NULL' manifest gzip;"

###############################################################################
banner "Listing S3 files s3://${s3bucket}/${s3path}"
aws s3 ls s3://${s3bucket}/${s3path}/  --recursive

###############################################################################
banner "Copying s3://${s3file} from S3 to "
aws s3 cp --recursive s3://${s3bucket}/${s3path}/ ${workingDir}

################################################################################
banner "Done"
ls -al ${workingDir}
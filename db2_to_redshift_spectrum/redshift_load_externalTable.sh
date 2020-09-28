#!/bin/bash
source ../config.sh
source config.sh
scriptName=`basename "$0"`

fname=${1}

banner "Initialize Reshift table for exports and loads using ${RedshifttargetDDL} and ${targetDataFile}"
echo "../config.sh PGHOST       : ${PGHOST}"
echo "../config.sh PGPORT       : ${PGPORT}"
echo "../config.sh PGDATABASE   : ${PGDATABASE}"
echo "../config.sh PGUSER       : ${PGUSER}"
echo "../config.sh PGPASSWORD   : ${PGPASSWORD}"
echo "config.sh targetTablename : ${targetTablename}"
echo "config.sh targetDDL       : ${targetDDL}"
echo "today                     : ${today}"
echo "scriptName                : ${scriptName}"
echo "workingDir                : ${workingDir}"
echo "redshiftExternalTableDDL  : ${redshiftExternalTableDDL}"

################################################################################
fname=$(basename "$targetDataFile")
s3file=${s3bucket}/${s3path}/${fname}
echo "s3file                    : ${s3file}"

################################################################################
banner "Removing Glue database ${s3bucket}"
aws glue delete-database --catalog-id ${accountNumber} --name ${s3bucket} > /dev/null 2>&1

################################################################################
banner "Cataloging Glue database ${s3bucket}"
aws glue create-database --catalog-id ${accountNumber} --database-input '{"Name": "'${s3bucket}'", "CreateTableDefaultPermissions": [ { "Principal": { "DataLakePrincipalIdentifier": "IAM_ALLOWED_PRINCIPALS" }, "Permissions": [ "ALL" ] } ] }'

################################################################################
banner "Cataloging in Redshift"
psql -a -f ${redshiftExternalTableDDL}

banner "Running Check Data from ${targetDataLoadCheck}"
psql -f ${targetDataLoadCheck}

echo "##################################################################################"
echo "##################################################################################"
echo ""
echo "NOTE :"
echo ""
echo "         Control Characters are replaced with ASCII 26     , as per export SQL"
echo "         Carriage returns   are replaced with ASCII 32     , as per export SQL"
echo "         Line Feeds         are replaced with ASCII 32     , as per export SQL"
echo "         Times              are delimited by period        , as per export SQL"
echo "         Timestamps         are truncated to 3 microseconds, as per export SQL"
echo ""
echo "         Check sql needs to escape \ - some additional work on COL_ID = 401???"
echo ""
echo "         This should be reflected in the Insert Check SQL"
echo ""
echo "##################################################################################"
echo "##################################################################################"

banner "Done"
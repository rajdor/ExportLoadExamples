#!/bin/bash

source ../config.sh
source config.sh
scriptName=`basename "$0"`

sourceDataFile=${1}

if [[ $sourceDataFile =~ \.gz$ ]]; then
    banner "gzip file passed, unzipping ${sourceDataFile}"
    gunzip -kf $sourceDataFile
    sourceDataFile=${sourceDataFile%.*}
    echo "Using ${sourceDataFile}"
fi


banner "Initialize Reshift table for exports and loads using ${RedshifttargetDDL} and ${targetDataFile}"
echo "../config.sh PGHOST           : ${PGHOST}"
echo "../config.sh PGPORT           : ${PGPORT}"
echo "../config.sh PGDATABASE       : ${PGDATABASE}"
echo "../config.sh PGUSER           : ${PGUSER}"
echo "../config.sh PGPASSWORD       : ${PGPASSWORD}"
echo "../config.sh s3bucket         : ${s3bucket}"
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
echo "s3file                        : ${s3file}"

################################################################################
banner "NOTE : THIS IS INCOMPLETE : MORE WORK ON FILE FORMAT, DATA TYPES and LOAD CHECKER REQUIRED"
read -p "Continue (y/n)?" CONT
if [ "$CONT" = "y" ]; then
  echo "";
else
  exit;
fi


################################################################################
banner "Removing any existing file from ${s3bucket}/${s3path}"
aws s3 rm s3://${s3bucket}/${s3path}/  --recursive > /dev/null 2>&1

################################################################################
banner "Making Bucket ${s3bucket}"
aws s3api create-bucket --bucket ${s3bucket} --region ${awsregion}

################################################################################
banner "Copying ${fname} to S3 ${s3file}"
aws s3 cp ${sourceDataFile} s3://${s3file}

################################################################################
banner "Removing Glue database ${s3bucket}"
aws glue delete-database --catalog-id ${accountNumber} --name ${s3bucket} > /dev/null 2>&1

################################################################################
banner "Cataloging Glue database ${s3bucket}"
aws glue create-database --catalog-id ${accountNumber} --database-input '{"Name": "'${s3bucket}'", "CreateTableDefaultPermissions": [ { "Principal": { "DataLakePrincipalIdentifier": "IAM_ALLOWED_PRINCIPALS" }, "Permissions": [ "ALL" ] } ] }'


################################################################################
banner "Cataloging Table ${targetTablename}"
sql=$(<${targetDDL})
queryExecutionID=$(aws athena start-query-execution \
    --query-string "${sql}" \
    --work-group "primary" \
    --result-configuration '{"OutputLocation": "s3://aws-athena-query-results-'${accountNumber}'-us-east-1"}' \
    --query-execution-context Database=${s3bucket} | jq '.QueryExecutionId')

queryExecutionID="${queryExecutionID%\"}"
queryExecutionID="${queryExecutionID#\"}"

################################################################################
banner "Waiting for Query to compelete ${queryExecutionID}"
queryStatus=$(aws athena get-query-execution --query-execution-id ''${queryExecutionID}'' | jq '.QueryExecution.Status.State')
queryStatus="${queryStatus%\"}"
queryStatus="${queryStatus#\"}"
echo "$queryStatus"
while [[ "$queryStatus" != "SUCCEEDED" && "$queryStatus" != "FAILED" ]]
    do
        sleep 5
        queryStatus=$(aws athena get-query-execution --query-execution-id ''${queryExecutionID}'' | jq '.QueryExecution.Status.State')
        queryStatus="${queryStatus%\"}"
        queryStatus="${queryStatus#\"}"
        echo "$queryStatus"
    done

################################################################################
banner "Counting rows ${s3bucket}.${targetTablename}"
sql="SELECT COUNT(*) FROM ${s3bucket}.${targetTablename}"
queryExecutionID=$(aws athena start-query-execution \
    --query-string "${sql}" \
    --work-group "primary" \
    --result-configuration '{"OutputLocation": "s3://aws-athena-query-results-'${accountNumber}'-us-east-1"}' \
    --query-execution-context Database=${s3bucket} | jq '.QueryExecutionId')
returnCode=$?
queryExecutionID="${queryExecutionID%\"}"
queryExecutionID="${queryExecutionID#\"}"

################################################################################
banner "Waiting for Query to compelete ${queryExecutionID}"
queryStatus=""
while [[ "$queryStatus" != "SUCCEEDED" && "$queryStatus" != "FAILED" && ${returnCode} -eq 0 ]]
    do
        sleep 5
        queryStatus=$(aws athena get-query-execution --query-execution-id ''${queryExecutionID}'' | jq '.QueryExecution.Status.State')
        returnCode=$?
        queryStatus="${queryStatus%\"}"
        queryStatus="${queryStatus#\"}"
        echo "$queryStatus"
    done

################################################################################
banner "Getting Query Results ${queryExecutionID}"
queryResults=$(aws athena get-query-results --query-execution-id ''${queryExecutionID}'')
echo ${queryResults} | jq 


################################################################################
banner "Running Load Check ${s3bucket}.${targetTablename} using ${targetDataLoadCheck}"
sql=$(<${targetDataLoadCheck})
queryExecutionID=$(aws athena start-query-execution \
    --query-string "${sql}" \
    --work-group "primary" \
    --result-configuration '{"OutputLocation": "s3://aws-athena-query-results-'${accountNumber}'-us-east-1"}' \
    --query-execution-context Database=${s3bucket} | jq '.QueryExecutionId')
returnCode=$?
echo "return code: " ${returnCode}
queryExecutionID="${queryExecutionID%\"}"
queryExecutionID="${queryExecutionID#\"}"

#if "${queryExecutionID}" == "" then exit, error

################################################################################
banner "Waiting for Query to compelete ${queryExecutionID}"
queryStatus=""
while [[ "$queryStatus" != "SUCCEEDED" && "$queryStatus" != "FAILED" && ${returnCode} -eq 0 ]]
    do
        sleep 5
        queryStatus=$(aws athena get-query-execution --query-execution-id ''${queryExecutionID}'' | jq '.QueryExecution.Status.State')
        returnCode=$?
        queryStatus="${queryStatus%\"}"
        queryStatus="${queryStatus#\"}"
        echo "$queryStatus"
    done

################################################################################
banner "Getting Query Results ${queryExecutionID}"
queryResults=$(aws athena get-query-results --query-execution-id ''${queryExecutionID}'')
echo ${queryResults} | jq 

banner "Done"
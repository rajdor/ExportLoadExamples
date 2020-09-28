#!/bin/bash

source ../config.sh
source config.sh
scriptName=`basename "$0"`

banner "Initialize Db2 Warehouse table for exports and loads using ${initDDL}"
echo "../config DB2_DATABASE        : ${DB2_DATABASE}"
echo "../config DB2_USER            : ${DB2_USER}"
echo "../config DB2_SCHEMA          : ${DB2_SCHEMA}"
echo "../config DB2_PASSWORD        : ${DB2_PASSWORD}"
echo "config    initTablename       : ${initTablename}"
echo "config    initDDL             : ${initDDL}"
echo "config    initDataInserts     : ${initDataInserts}"
echo "config    initDataInsertsCheck: ${initDataInsertsCheck}"
echo "config    initDataFile        : ${initDataFile}"
echo "today                         : ${today}"
echo "scriptName                    : ${scriptName}"
echo "workingDir                    : ${workingDir}"

################################################################################
banner "Connecting to ${DB2_DATABASE}"
db2 CONNECT TO ${DB2_DATABASE} USER ${DB2_USER} USING ${DB2_PASSWORD}
if [ $? -eq 0 ]
then
    echo "OK : connected to ${DB2_DATABASE}" 
else
    echo "ERROR testing connection to ${DB2_DATABASE}" 
    exit 8
fi
db2 "SET SCHEMA ${DB2_SCHEMA}"

################################################################################
banner "Looking for existing source table"
tables_exist=`db2 CONNECT TO ${DB2_DATABASE} USER ${DB2_USER} USING ${DB2_PASSWORD} > /dev/null
              db2 -x "select cast(count(*) as integer) from SYSIBM.SYSTABLES where upper(CREATOR) = upper('${DB2_SCHEMA}') and upper(NAME) = upper('${initTablename}') WITH UR"
              db2 quit > /dev/null
              `
tables_exist="$(echo -e "${tables_exist}" | tr -d '[:space:]')"
echo "  Found ${tables_exist} tables existing"
if [[ ${tables_exist} > 0 ]]; then 
    echo "  Generating Drop statements"
    stmts=`db2 CONNECT TO ${DB2_DATABASE} USER ${DB2_USER} USING ${DB2_PASSWORD} > /dev/null
           db2 -x "SELECT 'DROP TABLE ' || CREATOR || '.' || NAME || ';' as stmt from SYSIBM.SYSTABLES where upper(CREATOR) = upper('${DB2_SCHEMA}') and upper(NAME) = upper('${initTablename}') WITH UR"
           db2 quit > /dev/null
           `
    echo "Running DROP"
    echo ${stmts}
    db2 -tvs "${stmts}"
fi

################################################################################
banner "Creating temp initDDL file using schema : ${DB2_SCHEMA} and ${initDDL}"
value=`cat ${initDDL}`
replaceThis="CREATE TABLE "
withThis="CREATE TABLE ${DB2_SCHEMA}."
value=${value/$replaceThis/$withThis}
tmpfile=$(mktemp ${workingDir}${scriptName}.XXXXXX)
echo "${value}" > "${tmpfile}"

banner "Creating table from ${tmpfile}"
db2 -tsof ${tmpfile}
rm ${tmpfile}

################################################################################
banner "Generating  Inserts SQL using ${DB2_SCHEMA} and ${initDataInserts}"
value=`cat ${initDataInserts}`
replaceThis="INSERT INTO "
withThis="INSERT INTO ${DB2_SCHEMA}."
value=${value/$replaceThis/$withThis}
tmpfile=$(mktemp ${workingDir}${scriptName}.XXXXXX)
echo "${value}" > "${tmpfile}"

outfile=$(mktemp ${workingDir}${scriptName}.XXXXXX)
banner "Running Inserts from ${tmpfile} : output to ${outfile}"
db2 -tsf ${tmpfile} > ${outfile} 2>&1
rm ${tmpfile}

################################################################################
banner "Counting records on ${initTablename}"
db2 -tso "SELECT COUNT(*) FROM ${DB2_SCHEMA}.${initTablename}"

################################################################################
banner "Generating Inserts Check SQL using ${DB2_SCHEMA} and ${initDataInsertsCheck}"
value=`cat ${initDataInsertsCheck}`
replaceThis=${initTablename}
withThis="${DB2_SCHEMA}.${initTablename}"
value=${value/$replaceThis/$withThis}
tmpfile=$(mktemp ${workingDir}${scriptName}.XXXXXX)
echo "${value}" > "${tmpfile}"

banner "Running Inserts Check from Data ${tmpfile}"
db2 -tsof ${tmpfile} 
#rm ${tmpfile}

banner "Done"
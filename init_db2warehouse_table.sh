#!/bin/bash

source config.sh

banner "Initialize Db2 Warehouse table for exports and loads using ${sourceDDL} and ${sourceDataFile}"
echo "config.sh DB2_DATABASE     : ${DB2_DATABASE}"
echo "config.sh DB2_USER         : ${DB2_USER}"
echo "config.sh DB2_SCHEMA       : ${DB2_SCHEMA}"
echo "config.sh DB2_PASSWORD     : ${DB2_PASSWORD}"
echo "config.sh sourceTablename  : ${sourceTablename}"
echo "config.sh sourceDDL        : ${sourceDDL}"
echo "config.sh sourceDataFile   : ${sourceDataFile}"

echo 
echo "today                     : ${today}"
echo "scriptName                : ${scriptName}"
echo "workingDir                : ${workingDir}"

export importmsgs=${workingDir}/db2_load_importmessages_${current_time}.txt


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

banner "Looking for existing source table"
tables_exist=`db2 CONNECT TO ${DB2_DATABASE} USER ${DB2_USER} USING ${DB2_PASSWORD} > /dev/null
db2 -x "select cast(count(*) as integer)                                 from SYSIBM.SYSTABLES where upper(CREATOR) = upper('${DB2_SCHEMA}') and upper(NAME) = upper('${sourceTablename}') WITH UR"
db2 quit > /dev/null
`
tables_exist="$(echo -e "${tables_exist}" | tr -d '[:space:]')"
echo "  Found ${tables_exist} tables existing"
if [[ ${tables_exist} > 0 ]]; then 
   echo "  Generating Drop statements"
   stmts=`db2 CONNECT TO ${DB2_DATABASE} USER ${DB2_USER} USING ${DB2_PASSWORD} > /dev/null
   db2 -x "SELECT 'DROP TABLE ' || CREATOR || '.' || NAME || ';' as stmt from SYSIBM.SYSTABLES where upper(CREATOR) = upper('${DB2_SCHEMA}') and upper(NAME) = upper('${sourceTablename}') WITH UR"
   db2 quit > /dev/null
   `
   echo "Running DROP"
   echo ${stmts}
   db2 -tvso "${stmts}"
fi


banner "Creating table from ${sourceDDL}"
value=`cat ${sourceDDL}`
replaceThis="CREATE TABLE "
withThis="CREATE TABLE ${DB2_SCHEMA}."
value=${value/$replaceThis/$withThis}
db2 -tvso ${value}


banner "Loading table ${DB2_SCHEMA}.${sourceTablename} from ${sourceDataFile}"
loadcmd="load client from ${sourceDataFile} of DEL modified by coldel| nochardel timestampformat=\"YYYY-MM-DD HH:MM:SS\" messages ${importmsgs} REPLACE into ${DB2_SCHEMA}.${sourceTablename} STATISTICS NO NONRECOVERABLE"
echo ${loadcmd}
db2 "${loadcmd}"
if [ $? -ne 0 ]
then
  echo "ERROR : running import" >&2
  head ${importmsgs}
  exit 8
fi
cat ${importmsgs}

banner "Counting records on ${sourceTablename}"
db2 -tvso "SELECT COUNT(*) FROM ${DB2_SCHEMA}.${sourceTablename}"


banner "Done"
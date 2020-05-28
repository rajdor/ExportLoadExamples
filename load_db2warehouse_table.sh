#!/bin/bash

source config.sh

targetDataFile=${1}

banner "Db2 Warehouse Load ${targetTablename} from ${targetDataFile}"
echo "config.sh DB2_DATABASE    : ${DB2_DATABASE}"
echo "config.sh DB2_USER        : ${DB2_USER}"
echo "config.sh DB2_SCHEMA      : ${DB2_SCHEMA}"
echo "config.sh DB2_PASSWORD    : ${DB2_PASSWORD}"
echo "config.sh targetTablename : ${targetTablename}"
echo "config.sh targetDDL       : ${targetDDL}"
echo "config.sh targetDataFile  : ${targetDataFile}"
echo 
echo "today                     : ${today}"
echo "scriptName                : ${scriptName}"
echo "workingDir                : ${workingDir}"

export importmsgs=${workingDir}/db2_load_importmessages_${current_time}.txt

if [ -z "$targetDataFile" ]
then
      echo "ERROR : \${targetDataFile} is empty; set variable to specify file to load by passing in path & filename of datafile to load"
      exit 8
fi

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

banner "Looking for existing target table"
tables_exist=`db2 CONNECT TO ${DB2_DATABASE} USER ${DB2_USER} USING ${DB2_PASSWORD} > /dev/null
db2 -x "select cast(count(*) as integer)                                 from SYSIBM.SYSTABLES where upper(CREATOR) = upper('${DB2_SCHEMA}') and upper(NAME) = upper('${targetTablename}') WITH UR"
db2 quit > /dev/null
`
tables_exist="$(echo -e "${tables_exist}" | tr -d '[:space:]')"
echo "  Found ${tables_exist} tables existing"
if [[ ${tables_exist} > 0 ]]; then 
   echo "  Generating Drop statements"
   stmts=`db2 CONNECT TO ${DB2_DATABASE} USER ${DB2_USER} USING ${DB2_PASSWORD} > /dev/null
   db2 -x "SELECT 'DROP TABLE ' || CREATOR || '.' || NAME || ';' as stmt from SYSIBM.SYSTABLES where upper(CREATOR) = upper('${DB2_SCHEMA}') and upper(NAME) = upper('${targetTablename}') WITH UR"
   db2 quit > /dev/null
   `
   echo "Running DROP"
   echo ${stmts}
   db2 -tvso "${stmts}"
fi


banner "Creating table from ${targetDDL}"
value=`cat ${targetDDL}`
replaceThis="CREATE TABLE "
withThis="CREATE TABLE ${DB2_SCHEMA}."
value=${value/$replaceThis/$withThis}
db2 -tvso "${value}"


banner "Loading table ${DB2_SCHEMA}.${targetTablename} from ${targetDataFile}"
loadcmd="load client from ${targetDataFile} of DEL modified by coldel| nochardel timestampformat=\"YYYY-MM-DD HH:MM:SS\" messages ${importmsgs} REPLACE into ${DB2_SCHEMA}.${targetTablename} STATISTICS NO NONRECOVERABLE"
echo ${loadcmd}
db2 "${loadcmd}"
if [ $? -ne 0 ]
then
  echo "ERROR : running import" >&2
  head ${importmsgs}
  exit 8
fi
cat ${importmsgs}

banner "Counting records on ${targetTablename}"
db2 -tvso "SELECT COUNT(*) FROM ${DB2_SCHEMA}.${targetTablename}"

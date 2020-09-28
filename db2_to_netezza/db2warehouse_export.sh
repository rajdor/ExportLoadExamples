#!/bin/bash

source ../config.sh
source config.sh
scriptName=`basename "$0"`

externalTable='EXT_'${sourceTablename}
exportFileName='TMP_'${sourceTablename}.csv.gz

banner "Db2 Warehouse Export from ${sourceTablename} to ${workingDir}${exportFileName}"
echo "../config.sh DB2_HOST     : ${DB2_HOST}"
echo "../config.sh DB2_PORT     : ${DB2_PORT}"
echo "../config.sh DB2_DATABASE : ${DB2_DATABASE}"
echo "../config.sh DB2_USER     : ${DB2_USER}"
echo "../config.sh DB2_PASSWORD : ${DB2_PASSWORD}"
echo "../config.sh DB2_SCHEMA   : ${DB2_SCHEMA}"
echo "config.sh sourceTablename : ${sourceTablename}"
echo "today                     : ${today}"
echo "scriptName                : ${scriptName}"
echo "workingDir                : ${workingDir}"
echo "externalTable             : ${externalTable}"
echo "exportFileName            : ${exportFileName}"

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
              db2 -x "select cast(count(*) as integer) from SYSIBM.SYSTABLES where upper(CREATOR) = upper('${DB2_SCHEMA}') and upper(NAME) = upper('${sourceTablename}') WITH UR"
              db2 quit > /dev/null
             `
tables_exist="$(echo -e "${tables_exist}" | tr -d '[:space:]')"
echo "  Found ${tables_exist} tables existing"
if [[ ${tables_exist} = 0 ]]; then 
    echo "ERROR : Table to export from does not exist"
    exit 8
fi

################################################################################
banner "Counting records on ${sourceTablename}"
db2 -tso "SELECT COUNT(*) FROM ${sourceTablename}"

################################################################################
banner "Running export from ${DB2_SCHEMA}.${sourceTablename} to ${workingDir}${exportFileName}"
db2 "CREATE EXTERNAL TABLE '${workingDir}${exportFileName}' \
         USING (                                            \
                 RemoteSource 'YES'                         \
                 Encoding 'INTERNAL'                        \
                 EscapeChar '\'                             \
                 CrInString True                            \
                 CtrlChars True                             \
                 Delimiter '|'                              \
                 NullValue 'NULL'                           \
                 QuotedNUll False                           \
                 LFinString True                            \
                 QuotedValue DOUBLE                         \
                 TimeDelim '.'                              \
                 DateDelim '-'                              \
                 DateStyle YMD                              \
                 Compress GZIP                              \
                 LogDir '${workingDir}'                     \
               ) AS SELECT * FROM ${DB2_SCHEMA}.${sourceTablename};"

if [ $? -ne 0 ]
then
    echo "ERROR : running export?" >&2
    ls -al ${workingDir}
    exit 8
fi

################################################################################
banner "Done"
ls -al ${workingDir}${exportFileName}
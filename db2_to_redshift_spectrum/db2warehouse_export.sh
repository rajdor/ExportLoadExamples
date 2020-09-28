#!/bin/bash

source ../config.sh
source config.sh
scriptName=`basename "$0"`

externalTable='EXT_'${sourceTablename}
exportFileName='TMP_'${sourceTablename}.csv
exportGZFileName=${exportFileName}.gz

banner "Db2 Warehouse Export from ${sourceTablename} to ${workingDir}${exportFileName}"
echo "../config.sh DB2_HOST      : ${DB2_HOST}"
echo "../config.sh DB2_PORT      : ${DB2_PORT}"
echo "../config.sh DB2_DATABASE  : ${DB2_DATABASE}"
echo "../config.sh DB2_USER      : ${DB2_USER}"
echo "../config.sh DB2_PASSWORD  : ${DB2_PASSWORD}"
echo "../config.sh DB2_SCHEMA    : ${DB2_SCHEMA}"
echo "config.sh sourceTablename  : ${sourceTablename}"
echo "today                      : ${today}"
echo "scriptName                 : ${scriptName}"
echo "workingDir                 : ${workingDir}"
echo "externalTable              : ${externalTable}"
echo "exportFileName             : ${exportFileName}"
echo "exportGZFileName           : ${exportGZFileName}"

export exportmsgs=${workingDir}/db2_load_export_messages_${current_time}.txt
echo "exportmsgs                 : ${exportmsgs}"

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


#################################################################################
################################################################################
sqlfile=$(mktemp ${workingDir}/${scriptName}.XXXXXX)
banner "Creating export SQL, saving to ${sqlfile}"
banner "NOTE : TIMEZONE IS HARD CODED IN PYTHON SCRIPT"
sql=$(python3 db2_generate_sql.py -j ../db2jcc4.jar -s ${DB2_HOST} -p ${DB2_PORT} -d ${DB2_DATABASE} -u ${DB2_USER} -w ${DB2_PASSWORD} -m ${DB2_SCHEMA} -t ${sourceTablename})
echo "${sql}" > "$sqlfile"

pipeDelim=COLDEL0x7C
commaDelim=COLDEL0x2C
db2 "export to ${workingDir}${exportFileName} of DEL modified by ${pipeDelim} DATESISO  NOCHARDEL TIMESTAMPFORMAT=\"YYYY-MM-DD HH.MM.SS.UUUUUU\" messages ${exportmsgs} ${sql}"
if [ $? -ne 0 ]
then
    echo "ERROR : running export?" >&2
    cat ${exportmsgs} 
    exit 8
fi
cat ${exportmsgs} 
head ${workingDir}${exportFileName}

fname=$(basename "$exportFileName")
s3file=${s3bucket}/${s3path}/${fname}
echo "s3file                    : ${s3file}"

################################################################################
banner "Removing any existing file from ${s3bucket}/${s3path}"
aws s3 rm s3://${s3bucket}/${s3path}/  --recursive

################################################################################
banner "Copying ${gzipfile} to S3 ${s3bucket}/${s3path}"
aws s3 cp ${workingDir}${exportFileName} s3://${s3file}

################################################################################
banner "Done"
ls -al ${workingDir}${exportFileName}
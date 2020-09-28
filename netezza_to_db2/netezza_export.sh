#!/bin/bash

source ../config.sh
source config.sh
scriptName=`basename "$0"`

externalTable='EXT_'${sourceTablename}
exportFileName='TMP_'${sourceTablename}.csv

banner "Netezza Export from ${sourceTablename} to ${workingDir}${exportFileName}"
echo "../config.sh NZ_HOST         : ${NZ_HOST}"
echo "../config.sh NZ_PORT         : ${NZ_PORT}"
echo "../config.sh NZ_DATABASE     : ${NZ_DATABASE}"
echo "../config.sh NZ_USER         : ${NZ_USER}"
echo "../config.sh NZ_PASSWORD     : ${NZ_PASSWORD}"
echo "config.sh sourceTablename : ${sourceTablename}"
echo "config.sh sourceDDL       : ${sourceDDL}"
echo "config.sh sourceDataFile  : ${sourceDataFile}"
echo "today                     : ${today}"
echo "scriptName                : ${scriptName}"
echo "workingDir                : ${workingDir}"
echo "externalTable             : ${externalTable}"
echo "exportFileName            : ${exportFileName}"

################################################################################
banner "Looking for existing source table"
tables_exist=$(nzsql -t -c "select count(*) from information_schema.tables where table_type = 'TABLE' and upper(table_name) = upper('${sourceTablename}')")
tables_exist="$(echo -e "${tables_exist}" | tr -d '[:space:]')"
echo "  Found ${tables_exist} tables existing"
if [[ ${tables_exist} = 0 ]]; then 
    echo "  Table to export not found"
    exit 8
fi
echo "Counting records to export from ${sourceTablename}"
nzsql -c "SELECT COUNT(*) FROM ${sourceTablename}"

################################################################################
echo "Looking for existing external table table"
tables_exist=$(nzsql -t -c "select count(*) from information_schema.tables where table_type = 'EXTERNAL TABLE' and upper(table_name) = upper('${externalTable}')")
tables_exist="$(echo -e "${tables_exist}" | tr -d '[:space:]')"
echo "  Found ${tables_exist} external table existing"
if [[ ${tables_exist} = 1 ]]; then 
    echo "  Dropping exsiting external table ${externalTable}"
    nzsql -a -c "DROP TABLE ${externalTable}"
fi

#banner "Creating export SQL"
#sql=$(python3 netezza_generate_sql.py -j /usr/local/nz/lib/nzjdbc3.jar -s ${NZ_HOST} -p ${NZ_PORT} -d ${NZ_DATABASE} -u ${NZ_USER} -w ${NZ_PASSWORD} -t ${sourceTablename})
#echo ${sql}

banner "Creating external table"
#nzsql -a -c "create external table '${workingDir}${exportFileName}' using ( REMOTESOURCE 'YES' Encoding 'INTERNAL' EscapeChar '\' LFInString True CrInString True CtrlChars True Delimiter '|' NullValue 'NULL') as ${sql};"
nzsql -c "CREATE EXTERNAL TABLE '${workingDir}${exportFileName}' using ( \
                 RemoteSource 'YES'                         \
                 Encoding 'INTERNAL'                        \
                 EscapeChar '\'                             \
                 CrInString True                            \
                 CtrlChars True                             \
                 Delimiter '|'                              \
                 NullValue 'NULL'                           \
                 LFinString True                            \
                 QuotedValue DOUBLE                         \
                 TimeDelim '.'                              \
                 DateDelim '-'                              \
                 DateStyle YMD                              \
) AS SELECT * FROM ${sourceTablename};"

#Hangs without escaping nzsql -a -c "create external table '${workingDir}${exportFileName}' using ( REMOTESOURCE 'YES' Encoding 'INTERNAL' CrInString true CtrlChars true Delimiter '|' NullValue 'NULL') as ${sql};"
 
#banner "Exporting ${sourceTablename} through external table ${externalTable}"
#nzsql -a -c "insert into ${externalTable} select * from ${sourceTablename}"

################################################################################
banner "GZIP file ${workingDir}${exportFileName}"
gzipFileName=${workingDir}${exportFileName}.gz
gzip -f -c ${workingDir}${exportFileName} > ${gzipFileName}

################################################################################
banner "Done"
head ${workingDir}${exportFileName}
ls -al ${workingDir}${exportFileName}
ls -al ${gzipFileName}
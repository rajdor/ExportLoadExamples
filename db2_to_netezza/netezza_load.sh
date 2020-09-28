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

banner "Netezza Load ${targetTablename} from ${sourceDataFile}"
echo "../config.sh NZ_HOST          : ${NZ_HOST}"
echo "../config.sh NZ_PORT          : ${NZ_PORT}"
echo "../config.sh NZ_DATABASE      : ${NZ_DATABASE}"
echo "../config.sh NZ_USER          : ${NZ_USER}"
echo "../config.sh NZ_PASSWORD      : ${NZ_PASSWORD}"
echo "config.sh targetTablename     : ${targetTablename}"
echo "config.sh targetDDL           : ${targetDDL}"
echo "config.sh targetDDL           : ${targetDDL}"
echo "config.sh targetDataLoadCheck : ${targetDataLoadCheck}"
echo "today                         : ${today}"
echo "scriptName                    : ${scriptName}"
echo "workingDir                    : ${workingDir}"
echo "current_time                  : ${current_time}"

badfile=${workingDir}${targetTablename}_badrecords_${current_time}.txt
logfile=${workingDir}${targetTablename}_loadlog_${current_time}.txt
echo "badfile                       : ${badfile}"
echo "logfile                       : ${logfile}"

if [ -z "$sourceDataFile" ]
then
    echo "ERROR : sourceDataFile variable is empty"
    echo "set variable to specify file to load by passing in path & filename of datafile to load"
    exit 8
fi

################################################################################
banner "Looking for existing target table"
tables_exist=$(nzsql -t -c "select count(*) from information_schema.tables where table_type = 'TABLE' and upper(table_name) = upper('${targetTablename}')")
tables_exist="$(echo -e "${tables_exist}" | tr -d '[:space:]')"
echo "  Found ${tables_exist} tables existing"
if [[ ${tables_exist} > 0 ]]; then 
    echo "  Generating Drop statements"
    stmts=$(nzsql -t -c "SELECT 'DROP TABLE ' || table_name || ';' as stmt FROM information_schema.tables where table_type = 'TABLE' and upper(table_name) = upper('${targetTablename}')")
    echo "Running DROP"
    nzsql -c "${stmts}"
fi

################################################################################
banner "Creating table from ${targetDDL}"
nzsql -f ${targetDDL}

################################################################################
banner "Loading table ${targetTablename} from ${sourceDataFile}"
#nzload -t ${targetTablename} -df ${tmpfile} -delim '|' -timeDelim '.' -dateDelim '-' -escapeChar '\\' -dateStyle YMD -LFinString -CRinString -ctrlChars -ignoreZero YES -timeRoundNanos -quotedValue DOUBLE -NullValue 0x00 -bf ${badfile} -lf ${logfile}
nzload -t ${targetTablename} -df ${sourceDataFile} \
            -Encoding 'INTERNAL'                   \
            -EscapeChar '\\'                       \
            -CrInString                            \
            -CtrlChars                             \
            -Delimiter '|'                         \
            -NullValue 'NULL'                      \
            -LFinString                            \
            -QuotedValue DOUBLE                    \
            -TimeDelim '.'                         \
            -DateDelim '-'                         \
            -DateStyle YMD                         \
            -bf ${badfile}                         \
            -lf ${logfile}

if [ -f "${logfile}" ]; then
    cat ${logfile}
fi
if [ -f "${badfile}" ]; then
    head ${badfile}
fi

################################################################################
banner "Counting records on ${targetTablename}"
nzsql -c "SELECT COUNT(*) FROM ${targetTablename}"

################################################################################
banner "Running Check Data"
nzsql -f ${targetDataLoadCheck}

################################################################################
echo "##################################################################################"
echo "##################################################################################"
echo ""
echo "NOTE :"
echo ""
echo "         Original insert of ASCII 0 will have inserted space"
echo ""
echo "         Export will replace ASCII 128 -> ASCII 255 with ASCII 26"
echo ""
echo "         These are reflected in the Insert Check SQL"
echo ""
echo "##################################################################################"
echo "##################################################################################"

banner "Done"
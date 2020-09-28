#!/bin/bash

source ../config.sh
source config.sh
scriptName=`basename "$0"`

sourceDataFile=${1}

banner "Db2 Warehouse Load ${targetTablename} from ${sourceDataFile}"
echo "../config.sh DB2_DATABASE     : ${DB2_DATABASE}"
echo "../config.sh DB2_USER         : ${DB2_USER}"
echo "../config.sh DB2_SCHEMA       : ${DB2_SCHEMA}"
echo "../config.sh DB2_PASSWORD     : ${DB2_PASSWORD}"
echo "config.sh targetTablename     : ${targetTablename}"
echo "config.sh targetDDL           : ${targetDDL}"
echo "config.sh sourceDataFile      : ${sourceDataFile}"
echo "config.sh targetDataLoadCheck : ${targetDataLoadCheck}"
echo "today                         : ${today}"
echo "scriptName                    : ${scriptName}"
echo "workingDir                    : ${workingDir}"

################################################################################
if [ -z "$sourceDataFile" ]
then
    echo "ERROR : \${sourceDataFile} is empty; set variable to specify file to load by passing in path & filename of datafile to load"
    exit 8
fi

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
banner "Looking for existing target table"
tables_exist=`db2 CONNECT TO ${DB2_DATABASE} USER ${DB2_USER} USING ${DB2_PASSWORD} > /dev/null
              db2 -x "select cast(count(*) as integer) from SYSIBM.SYSTABLES where upper(CREATOR) = upper('${DB2_SCHEMA}') and upper(NAME) = upper('${targetTablename}') WITH UR"
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
    db2 -tso "${stmts}"
fi

################################################################################
banner "(Re)creating table from ${targetDDL} using schema ${DB2_SCHEMA}"
value=`cat ${targetDDL}`
replaceThis="CREATE TABLE "
withThis="CREATE TABLE ${DB2_SCHEMA}."
value=${value/$replaceThis/$withThis}
db2 -tso "${value}"

################################################################################
banner "Running Load unsing remote external file ${sourceDataFile} LOGDIR=${workingDir}"
#create external table
#cmd=db2 "INSERT INTO ${DB2_SCHEMA}.${targetTablename}   \
db2 "INSERT INTO ${DB2_SCHEMA}.${targetTablename}   \
         SELECT * FROM EXTERNAL '${sourceDataFile}' \
         USING (                                    \
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
               );"
#echo ${cmd}
if [ $? -ne 0 ]
then
    echo "ERROR : running INSERT FROM EXTERNAL TABLE?" >&2
    ls -al ${workingDir}
#    cat ${tmpfile}
#    temp=$(tail -2 ${tmpfile} | head -1)
#    temp=$(echo ${temp} | xargs)
#    LOGFILE="${temp::-1}"
#    echo "$temp"
#    if test -f "$LOGFILE"; then
#        echo "$FILE exists."
#        cat ${workingDir}S{LOGFILE}
#    fi
    exit 8
fi

################################################################################
banner "Counting records on ${targetTablename}"
db2 -tvso "SELECT COUNT(*) FROM ${DB2_SCHEMA}.${targetTablename}"

################################################################################
banner "Generating Load Check SQL using  ${DB2_SCHEMA} and ${targetDataLoadCheck}"
value=`cat ${targetDataLoadCheck}`
replaceThis=${targetTablename}
withThis="${DB2_SCHEMA}.${targetTablename}"
value=${value/$replaceThis/$withThis}
tmpfile=$(mktemp ${workingDir}${scriptName}.XXXXXX)
echo "${value}" > "${tmpfile}"

banner "Running Check Data from ${tmpfile}"
db2 -tsof ${tmpfile}
rm ${tmpfile}


echo "##################################################################################"
echo "##################################################################################"
echo ""
echo "NOTE :"
echo ""
echo "         Original insert of ASCII 0 may have been inserted as space ASCII 32"
echo ""
echo "         Export may have replaced ASCII 128 -> ASCII 255 with ASCII 26"
echo ""
echo "         This should be reflected in the Insert Check SQL"
echo ""
echo "##################################################################################"
echo "##################################################################################"

banner "Done"
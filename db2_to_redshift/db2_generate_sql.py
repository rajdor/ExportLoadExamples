import jaydebeapi
import optparse
#import csv

'''
python3 db2_generate_sql.py \
     -j ../db2jcc4.jar      \
     -s 192.168.72.143      \
     -p 50000               \
     -d bludb               \
     -u bluadmin            \
     -w bluadmin            \
     -m TEST_DATA           \
     -t TEST_CSV_DATA
'''

def genReplaceCTRL(colName, startAt, endAt):
    sub   = "CHR(26)"
    space = "CHR(32)"
    part1 = "REPLACE("
    outString = colName

    for i in range(startAt,endAt+1):
        if i in (10,13):
            outString = part1 + outString
            outString = outString + ",CHR(" + str(i) + ")," + space + ")"
        else:
            outString = part1 + outString
            outString = outString + ",CHR(" + str(i) + ")," + sub + ")"
    return (outString)

def genReplaceCTRL1(colName):
    s = genReplaceCTRL(colName, 1, 31)
    return s

def genReplaceCTRL2(colName):
    s = genReplaceCTRL(colName, 127, 255)
    return s

PARSER = optparse.OptionParser()
PARSER.add_option('-d', '--database'     , action="store", dest="database", help="database name"         , default="")
PARSER.add_option('-t', '--table'        , action="store", dest="table"   , help="tablename"             , default="")
PARSER.add_option('-m', '--schema'       , action="store", dest="schema"  , help="schema"                , default="")
PARSER.add_option('-s', '--host'         , action="store", dest="host"    , help="host name"             , default="")
PARSER.add_option('-u', '--user'         , action="store", dest="user"    , help="user name"             , default="")
PARSER.add_option('-p', '--port'         , action="store", dest="port"    , help="port"                  , default="")
PARSER.add_option('-w', '--password'     , action="store", dest="password", help="password"              , default="")
PARSER.add_option('-j', '--jarfile'      , action="store", dest="jarfile" , help="full path to jar file" , default="")
OPTIONS, ARGS = PARSER.parse_args()

jdbc_driver_name = "org.netezza.Driver"
jdbc_driver_loc = OPTIONS.jarfile
connection_string='jdbc:db2://' + OPTIONS.host +':'+ str(OPTIONS.port) + '/' + OPTIONS.database
url = '{0}:user={1};password={2}'.format(connection_string, OPTIONS.user, OPTIONS.password)

conn = jaydebeapi.connect("com.ibm.db2.jcc.DB2Driver", connection_string, {'user': OPTIONS.user, 'password': OPTIONS.password}, jars = jdbc_driver_loc)
curs = conn.cursor()
curs.execute("SELECT NAME, COLTYPE, COLNO FROM SYSIBM.SYSCOLUMNS WHERE TBCREATOR = upper('" + OPTIONS.schema + "') AND TBNAME = upper('" + OPTIONS.table + "') ORDER BY COLNO")
columns = curs.fetchall()

## | 124
## " 34
## \ 92

CarriageReturn = "CHR(13)"
Linefeed       = "CHR(10)"
Pipe           = "CHR(" + str(ord("|"))  + ")"
DoubleQuote    = "CHR(" + str(ord("\"")) + ")"
BackSlash      = "CHR(" + str(ord("\\")) + ")"
replaceCRwith  = "CHR(32)"
replaceLFwith  = "CHR(32)"

colDel         = Pipe
escapeChar     = BackSlash
charDel        = DoubleQuote
charDel        = ""

sqltxt = "SELECT"
for i in range (len(columns)):
    sqlcol = ""
    if i > 0:
        sqltxt = sqltxt + "\n,"
    else:
        sqltxt = sqltxt + "\n "
    if "CHAR" in columns[i][1]:
        sqltxt = sqltxt + "CASE WHEN " + columns[i][0] + " IS NULL THEN '' " 
        #special char's, filed is surrounded in quotes
        #replace all linefeeds with space
        #replace all carriage returns with space
        #replace escapechar with double escapchar
        #replace delimter with escape delimiter
        #replace quote with quote and quote
        sqltxt = sqltxt + "\n     WHEN " + columns[i][0] + " LIKE '%|%' OR " + columns[i][0] + " LIKE '%\\%' OR " + columns[i][0] + " LIKE '%\"%' THEN \n"
        sqltxt = sqltxt + "'\"' || " 
        sqlcol = sqlcol + " REPLACE("
        sqlcol = sqlcol + "   REPLACE("
        sqlcol = sqlcol + "         REPLACE("  + columns[i][0]  + "," + Linefeed + "," + replaceLFwith + ")"
        sqlcol = sqlcol + "       ," + CarriageReturn + "," + replaceCRwith + ")"
        sqlcol = sqlcol + " ," + DoubleQuote + "," + DoubleQuote + " || " + DoubleQuote +")"
        sqlcol = genReplaceCTRL2(genReplaceCTRL1(sqlcol))
        sqltxt = sqltxt + sqlcol
        sqltxt = sqltxt + " || '\"' " 
        # no special chars, do not surround in quotes
        # replace all linefeeds with space
        #replace all carriage returns with space

        sqltxt = sqltxt + "\nELSE " 
        sqlcol =         "     REPLACE(REPLACE("  + columns[i][0]  + "," + Linefeed + "," + replaceLFwith + ")," + CarriageReturn + "," + replaceCRwith + ")"
        sqlcol = genReplaceCTRL2(genReplaceCTRL1(sqlcol))
        sqltxt = sqltxt + sqlcol
        sqltxt = sqltxt + " END AS " + columns[i][0]
    else:
        if   "INT"     in columns[i][1] \
          or "NUMERIC" in columns[i][1] \
          or "FLOAT"   in columns[i][1] \
          or "DECIMAL" in columns[i][1] \
          or "REAL"    in columns[i][1] \
          or "FLOAT"   in columns[i][1] \
          or "DOUBLE"  in columns[i][1]:
            sqltxt = sqltxt + "CASE WHEN " + columns[i][0] + " IS NULL THEN '' ELSE CAST(" + columns[i][0] + " AS VARCHAR(128)) END AS " + columns[i][0]
        else: 
            if "CLOB"       in columns[i][1]:
                print ("ERROR UNSUPPORTED DATA TYPE : " + columns[i][1])
                quit(8)
            else:
                if "DATE"      == columns[i][1].strip():
                    sqltxt = sqltxt + "CAST( CASE WHEN " + columns[i][0] + " IS NULL THEN '' ELSE '" + charDel + "' || CAST(" + columns[i][0] + " AS CHAR(10)) || '" + charDel + "' END AS VARCHAR(12)) AS " + columns[i][0]
                else:
                    if "TIMESTMP"  == columns[i][1].strip():
                        sqltxt = sqltxt + "CAST(CASE WHEN " + columns[i][0] + " IS NULL THEN '' ELSE '" + charDel + "' || SUBSTR(CAST(" + columns[i][0] + " AS CHAR(26)),1,10) || ' ' || REPLACE(SUBSTR(CAST(" + columns[i][0] + " AS CHAR(26)),12,8), '.',':') END  AS VARCHAR(29)) AS " + columns[i][0]
                    else:
                        if "TIME"  == columns[i][1].strip():
                            sqltxt = sqltxt + "CAST(CASE WHEN " + columns[i][0] + " IS NULL THEN '' ELSE '" + charDel + "' ||  CAST(" + columns[i][0] + " AS CHAR(8)) || '" + charDel + "' END   AS VARCHAR(10)) AS " + columns[i][0]
                        else:
                            print ("ERROR UNSUPPORTED DATA TYPE : " + columns[i][1])
                            quit(8)
sqltxt = sqltxt + "\n FROM " + OPTIONS.schema + "." + OPTIONS.table + ";"

print (sqltxt)

curs.close()
conn.close()
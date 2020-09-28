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

#print("URL: " + url)
#print("Connection String: " + connection_string)

conn = jaydebeapi.connect("com.ibm.db2.jcc.DB2Driver", connection_string, {'user': OPTIONS.user, 'password': OPTIONS.password}, jars = jdbc_driver_loc)

curs = conn.cursor()

curs.execute("SELECT NAME, COLTYPE, COLNO FROM SYSIBM.SYSCOLUMNS WHERE TBCREATOR = upper('" + OPTIONS.schema + "') AND TBNAME = upper('" + OPTIONS.table + "') ORDER BY COLNO")
columns = curs.fetchall()

sql = "SELECT"
for i in range (len(columns)):
    
    if i > 0:
        sqlcol = "\n,"
    else:
        sqlcol = "\n "
    
    if "CHAR" in columns[i][1]:
#        sqlcol = sqlcol + "CASE WHEN " + columns[i][0] + " IS NULL THEN '' ELSE '\"' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(" + columns[i][0] + ",CHR(34),CHR(34) || CHR(34)),CHR(10),CHR(13)),CHR(01),CHR(63)),CHR(02),CHR(63)),CHR(03),CHR(63)),CHR(04),CHR(63)),CHR(05),CHR(63)),CHR(06),CHR(63)),CHR(07),CHR(63)),CHR(08),CHR(63)),CHR(09),CHR(63)),CHR(10),CHR(63)),CHR(11),CHR(63)),CHR(12),CHR(63)),CHR(13),CHR(63)),CHR(14),CHR(63)),CHR(15),CHR(63)),CHR(16),CHR(63)),CHR(17),CHR(63)),CHR(18),CHR(63)),CHR(19),CHR(63)),CHR(20),CHR(63)),CHR(21),CHR(63)),CHR(22),CHR(63)),CHR(23),CHR(63)),CHR(24),CHR(63)),CHR(25),CHR(63)),CHR(26),CHR(63)),CHR(27),CHR(63)),CHR(28),CHR(63)),CHR(29),CHR(63)),CHR(30),CHR(63)),CHR(31),CHR(63)) || '\"' END AS " + columns[i][0]
           sqlcol = sqlcol + "CASE WHEN " + columns[i][0] + " IS NULL THEN '' ELSE '\"' || " 
           sqlcol = sqlcol + "REPLACE(REPLACE("
           sqlcol = sqlcol + "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("
           sqlcol = sqlcol + "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("
           sqlcol = sqlcol + "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("
           sqlcol = sqlcol + "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("
           sqlcol = sqlcol + "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("
           sqlcol = sqlcol + "REPLACE(REPLACE(REPLACE("  + columns[i][0]  + ",CHR(34),CHR(34) || CHR(34)),CHR(10),CHR(13)),CHR(92),CHR(92) || CHR(92))"
           #sqlcol = sqlcol + "REPLACE(REPLACE("  + columns[i][0]  + ",CHR(34),CHR(34) || CHR(34)),CHR(10),CHR(13))"
           sqlcol = sqlcol + ",CHR(001),CHR(63)),CHR(002),CHR(63)),CHR(003),CHR(63)),CHR(004),CHR(63)),CHR(005),CHR(63)),CHR(006),CHR(63)),CHR(007),CHR(63)),CHR(008),CHR(63)),CHR(009),CHR(63))                  ,CHR(011),CHR(63)),CHR(012),CHR(63))                  ,CHR(014),CHR(63)),CHR(015),CHR(63)),CHR(016),CHR(63))"
           sqlcol = sqlcol + ",CHR(017),CHR(63)),CHR(018),CHR(63)),CHR(019),CHR(63)),CHR(020),CHR(63)),CHR(021),CHR(63)),CHR(022),CHR(63)),CHR(023),CHR(63)),CHR(024),CHR(63)),CHR(025),CHR(63)),CHR(026),CHR(63)),CHR(027),CHR(63)),CHR(028),CHR(63)),CHR(029),CHR(63)),CHR(030),CHR(63)),CHR(031),CHR(63)),CHR(127),CHR(63))"
           sqlcol = sqlcol + ",CHR(128),CHR(63)),CHR(129),CHR(63)),CHR(130),CHR(63)),CHR(131),CHR(63)),CHR(132),CHR(63)),CHR(133),CHR(63)),CHR(134),CHR(63)),CHR(135),CHR(63)),CHR(136),CHR(63)),CHR(137),CHR(63)),CHR(138),CHR(63)),CHR(139),CHR(63)),CHR(140),CHR(63)),CHR(141),CHR(63)),CHR(142),CHR(63)),CHR(143),CHR(63))"
           sqlcol = sqlcol + ",CHR(144),CHR(63)),CHR(145),CHR(63)),CHR(146),CHR(63)),CHR(147),CHR(63)),CHR(148),CHR(63)),CHR(149),CHR(63)),CHR(150),CHR(63)),CHR(151),CHR(63)),CHR(152),CHR(63)),CHR(153),CHR(63)),CHR(154),CHR(63)),CHR(155),CHR(63)),CHR(156),CHR(63)),CHR(157),CHR(63)),CHR(158),CHR(63)),CHR(159),CHR(63))"
           sqlcol = sqlcol + ",CHR(160),CHR(63)),CHR(161),CHR(63)),CHR(162),CHR(63)),CHR(163),CHR(63)),CHR(164),CHR(63)),CHR(165),CHR(63)),CHR(166),CHR(63)),CHR(167),CHR(63)),CHR(168),CHR(63)),CHR(169),CHR(63)),CHR(170),CHR(63)),CHR(171),CHR(63)),CHR(172),CHR(63)),CHR(173),CHR(63)),CHR(174),CHR(63)),CHR(175),CHR(63))"
           sqlcol = sqlcol + ",CHR(176),CHR(63)),CHR(177),CHR(63)),CHR(178),CHR(63)),CHR(179),CHR(63)),CHR(180),CHR(63)),CHR(181),CHR(63)),CHR(182),CHR(63)),CHR(183),CHR(63)),CHR(184),CHR(63)),CHR(185),CHR(63)),CHR(186),CHR(63)),CHR(187),CHR(63)),CHR(188),CHR(63)),CHR(189),CHR(63)),CHR(190),CHR(63)),CHR(191),CHR(63))"
           sqlcol = sqlcol + ",CHR(192),CHR(63)),CHR(193),CHR(63)),CHR(194),CHR(63)),CHR(195),CHR(63)),CHR(196),CHR(63)),CHR(197),CHR(63)),CHR(198),CHR(63)),CHR(199),CHR(63)),CHR(200),CHR(63)),CHR(201),CHR(63)),CHR(202),CHR(63)),CHR(203),CHR(63)),CHR(204),CHR(63)),CHR(205),CHR(63)),CHR(206),CHR(63)),CHR(207),CHR(63))"
           sqlcol = sqlcol + ",CHR(208),CHR(63)),CHR(209),CHR(63)),CHR(210),CHR(63)),CHR(211),CHR(63)),CHR(212),CHR(63)),CHR(213),CHR(63)),CHR(214),CHR(63)),CHR(215),CHR(63)),CHR(216),CHR(63)),CHR(217),CHR(63)),CHR(218),CHR(63)),CHR(219),CHR(63)),CHR(220),CHR(63)),CHR(221),CHR(63)),CHR(222),CHR(63)),CHR(223),CHR(63))"
           sqlcol = sqlcol + ",CHR(224),CHR(63)),CHR(225),CHR(63)),CHR(226),CHR(63)),CHR(227),CHR(63)),CHR(228),CHR(63)),CHR(229),CHR(63)),CHR(230),CHR(63)),CHR(231),CHR(63)),CHR(232),CHR(63)),CHR(233),CHR(63)),CHR(234),CHR(63)),CHR(235),CHR(63)),CHR(236),CHR(63)),CHR(237),CHR(63)),CHR(238),CHR(63)),CHR(239),CHR(63))"
           sqlcol = sqlcol + ",CHR(240),CHR(63)),CHR(241),CHR(63)),CHR(242),CHR(63)),CHR(243),CHR(63)),CHR(244),CHR(63)),CHR(245),CHR(63)),CHR(246),CHR(63)),CHR(247),CHR(63)),CHR(248),CHR(63)),CHR(249),CHR(63)),CHR(250),CHR(63)),CHR(251),CHR(63)),CHR(252),CHR(63)),CHR(253),CHR(63)),CHR(254),CHR(63)),CHR(255),CHR(63))"
           sqlcol = sqlcol + " || '\"' END AS " + columns[i][0]
    else:
        if   "INT"     in columns[i][1] \
          or "NUMERIC" in columns[i][1] \
          or "FLOAT"   in columns[i][1] \
          or "DECIMAL" in columns[i][1] \
          or "REAL"    in columns[i][1] \
          or "FLOAT"   in columns[i][1] \
          or "DOUBLE"  in columns[i][1]:
            sqlcol = sqlcol + "CASE WHEN " + columns[i][0] + " IS NULL THEN '' ELSE CAST(" + columns[i][0] + " AS VARCHAR(128)) END AS " + columns[i][0]
        else: 
            if "CLOB"       in columns[i][1]:
                sqlcol = sqlcol + "CASE WHEN " + columns[i][0] + " IS NULL THEN '' ELSE '\"' || " 
                sqlcol = sqlcol + "REPLACE(REPLACE("
                sqlcol = sqlcol + "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("
                sqlcol = sqlcol + "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("
                sqlcol = sqlcol + "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("
                sqlcol = sqlcol + "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("
                sqlcol = sqlcol + "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("
                sqlcol = sqlcol + "REPLACE(REPLACE(REPLACE(CAST("  + columns[i][0]  + " AS VARCHAR(2048)) ,CHR(34),CHR(34) || CHR(34)),CHR(10),CHR(13)),CHR(92),CHR(92) || CHR(92))"
                #sqlcol = sqlcol + "REPLACE(REPLACE(CAST("  + columns[i][0]  + " AS VARCHAR(2048)) ,CHR(34),CHR(34) || CHR(34)),CHR(10),CHR(13))"
                sqlcol = sqlcol + ",CHR(001),CHR(63)),CHR(002),CHR(63)),CHR(003),CHR(63)),CHR(004),CHR(63)),CHR(005),CHR(63)),CHR(006),CHR(63)),CHR(007),CHR(63)),CHR(008),CHR(63)),CHR(009),CHR(63))                  ,CHR(011),CHR(63)),CHR(012),CHR(63))                  ,CHR(014),CHR(63)),CHR(015),CHR(63)),CHR(016),CHR(63))"
                sqlcol = sqlcol + ",CHR(017),CHR(63)),CHR(018),CHR(63)),CHR(019),CHR(63)),CHR(020),CHR(63)),CHR(021),CHR(63)),CHR(022),CHR(63)),CHR(023),CHR(63)),CHR(024),CHR(63)),CHR(025),CHR(63)),CHR(026),CHR(63)),CHR(027),CHR(63)),CHR(028),CHR(63)),CHR(029),CHR(63)),CHR(030),CHR(63)),CHR(031),CHR(63)),CHR(127),CHR(63))"
                sqlcol = sqlcol + ",CHR(128),CHR(63)),CHR(129),CHR(63)),CHR(130),CHR(63)),CHR(131),CHR(63)),CHR(132),CHR(63)),CHR(133),CHR(63)),CHR(134),CHR(63)),CHR(135),CHR(63)),CHR(136),CHR(63)),CHR(137),CHR(63)),CHR(138),CHR(63)),CHR(139),CHR(63)),CHR(140),CHR(63)),CHR(141),CHR(63)),CHR(142),CHR(63)),CHR(143),CHR(63))"
                sqlcol = sqlcol + ",CHR(144),CHR(63)),CHR(145),CHR(63)),CHR(146),CHR(63)),CHR(147),CHR(63)),CHR(148),CHR(63)),CHR(149),CHR(63)),CHR(150),CHR(63)),CHR(151),CHR(63)),CHR(152),CHR(63)),CHR(153),CHR(63)),CHR(154),CHR(63)),CHR(155),CHR(63)),CHR(156),CHR(63)),CHR(157),CHR(63)),CHR(158),CHR(63)),CHR(159),CHR(63))"
                sqlcol = sqlcol + ",CHR(160),CHR(63)),CHR(161),CHR(63)),CHR(162),CHR(63)),CHR(163),CHR(63)),CHR(164),CHR(63)),CHR(165),CHR(63)),CHR(166),CHR(63)),CHR(167),CHR(63)),CHR(168),CHR(63)),CHR(169),CHR(63)),CHR(170),CHR(63)),CHR(171),CHR(63)),CHR(172),CHR(63)),CHR(173),CHR(63)),CHR(174),CHR(63)),CHR(175),CHR(63))"
                sqlcol = sqlcol + ",CHR(176),CHR(63)),CHR(177),CHR(63)),CHR(178),CHR(63)),CHR(179),CHR(63)),CHR(180),CHR(63)),CHR(181),CHR(63)),CHR(182),CHR(63)),CHR(183),CHR(63)),CHR(184),CHR(63)),CHR(185),CHR(63)),CHR(186),CHR(63)),CHR(187),CHR(63)),CHR(188),CHR(63)),CHR(189),CHR(63)),CHR(190),CHR(63)),CHR(191),CHR(63))"
                sqlcol = sqlcol + ",CHR(192),CHR(63)),CHR(193),CHR(63)),CHR(194),CHR(63)),CHR(195),CHR(63)),CHR(196),CHR(63)),CHR(197),CHR(63)),CHR(198),CHR(63)),CHR(199),CHR(63)),CHR(200),CHR(63)),CHR(201),CHR(63)),CHR(202),CHR(63)),CHR(203),CHR(63)),CHR(204),CHR(63)),CHR(205),CHR(63)),CHR(206),CHR(63)),CHR(207),CHR(63))"
                sqlcol = sqlcol + ",CHR(208),CHR(63)),CHR(209),CHR(63)),CHR(210),CHR(63)),CHR(211),CHR(63)),CHR(212),CHR(63)),CHR(213),CHR(63)),CHR(214),CHR(63)),CHR(215),CHR(63)),CHR(216),CHR(63)),CHR(217),CHR(63)),CHR(218),CHR(63)),CHR(219),CHR(63)),CHR(220),CHR(63)),CHR(221),CHR(63)),CHR(222),CHR(63)),CHR(223),CHR(63))"
                sqlcol = sqlcol + ",CHR(224),CHR(63)),CHR(225),CHR(63)),CHR(226),CHR(63)),CHR(227),CHR(63)),CHR(228),CHR(63)),CHR(229),CHR(63)),CHR(230),CHR(63)),CHR(231),CHR(63)),CHR(232),CHR(63)),CHR(233),CHR(63)),CHR(234),CHR(63)),CHR(235),CHR(63)),CHR(236),CHR(63)),CHR(237),CHR(63)),CHR(238),CHR(63)),CHR(239),CHR(63))"
                sqlcol = sqlcol + ",CHR(240),CHR(63)),CHR(241),CHR(63)),CHR(242),CHR(63)),CHR(243),CHR(63)),CHR(244),CHR(63)),CHR(245),CHR(63)),CHR(246),CHR(63)),CHR(247),CHR(63)),CHR(248),CHR(63)),CHR(249),CHR(63)),CHR(250),CHR(63)),CHR(251),CHR(63)),CHR(252),CHR(63)),CHR(253),CHR(63)),CHR(254),CHR(63)),CHR(255),CHR(63))"
                sqlcol = sqlcol + " || '\"' END AS " + columns[i][0]
            else:
                if "DATE"      == columns[i][1].strip():
                    sqlcol = sqlcol + "CAST( CASE WHEN " + columns[i][0] + " IS NULL THEN '' ELSE '\"' || CAST(" + columns[i][0] + " AS CHAR(10)) || '\"' END AS VARCHAR(12)) AS " + columns[i][0]
                else:
                    if "TIMESTMP"  == columns[i][1].strip():
                        sqlcol = sqlcol + "CAST(CASE WHEN " + columns[i][0] + " IS NULL THEN '' ELSE '\"' || SUBSTR(CAST(" + columns[i][0] + " AS CHAR(26)),1,10) || ' ' || SUBSTR(CAST(" + columns[i][0] + " AS CHAR(26)),12) || '\"' END  AS VARCHAR(28)) AS " + columns[i][0]
                    else:
                        if "TIME"  == columns[i][1].strip():
                            sqlcol = sqlcol + "CAST(CASE WHEN " + columns[i][0] + " IS NULL THEN '' ELSE '\"' ||  CAST(" + columns[i][0] + " AS CHAR(8)) || '\"' END   AS VARCHAR(10)) AS " + columns[i][0]
                        else:
                            print ("ERROR UNSUPPORTED DATA TYPE : " + columns[i][1])
                            quit(8)
    sql = sql + sqlcol
sql = sql + "\n FROM " + OPTIONS.schema + "." + OPTIONS.table + ";"

print (sql)

curs.close()
conn.close()



#Character columns containing NULLS have the string NULL, (Double Quotes are not used)
#Character columns containing that are less than VAR/CHAR(4) are cast to VARCHAR(4)
#Date columns NULLs are converted to CAST TO CHAR(10) and the text NULL is used, (Double Quotes are not used)
#Time columns NULLs are converted to CAST TO CHAR(8) and the text NULL is used, (Double Quotes are not used)
#Timestamp columns NULLs are converted to CAST TO VARCHAR(26) and the text NULL is used, (Double Quotes are not used)
#Date, Time, TImestamp, CHAR, VARCHAR, Unless column containts the raw word NULL, ,column is wrapped in doublequotes
#Numeric columns NULLs are CAST TO VARCHAR(64) and the text NULL is used, (Double Quotes are not used)
#LF are converted to CR
#Character Columns containing \ are escaped using \
#Character Columns containing DoubleQuotes are escaped using \
#Character, Time, Date, Timestamp columns are enclosed in Double Quote
#Ascii 1 through 31 inclusive is changed to Ascii 63
#Ascii 127 through 255 inclusive is changed to Ascii 63


#"REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(" + columns[i][0] + "','\','\\'),CHR(10),CHR(13)),CHR(00),'?'),CHR(01),'?'),CHR(02),'?'),CHR(03),'?'),CHR(04),'?'),CHR(05),'?'),CHR(06),'?'),CHR(07),'?'),CHR(08),'?'),CHR(09),'?'),CHR(10),'?'),CHR(11),'?'),CHR(12),'?'),CHR(13),'?'),CHR(14),'?'),CHR(15),'?'),CHR(16),'?'),CHR(17),'?'),CHR(18),'?'),CHR(19),'?'),CHR(20),'?'),CHR(21),'?'),CHR(22),'?'),CHR(23),'?'),CHR(24),'?'),CHR(25),'?'),CHR(26),'?'),CHR(27),'?'),CHR(28),'?'),CHR(29),'?'),CHR(30),'?'),CHR(31),'?')
#REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(" + columns[i][0] + ",CHR(92),CHR(92)||CHR(92)),CHR(10),CHR(13)),CHR(01),CHR(63)),CHR(02),CHR(63)),CHR(03),CHR(63)),CHR(04),CHR(63)),CHR(05),CHR(63)),CHR(06),CHR(63)),CHR(07),CHR(63)),CHR(08),CHR(63)),CHR(09),CHR(63)),CHR(10),CHR(63)),CHR(11),CHR(63)),CHR(12),CHR(63)),CHR(13),CHR(63)),CHR(14),CHR(63)),CHR(15),CHR(63)),CHR(16),CHR(63)),CHR(17),CHR(63)),CHR(18),CHR(63)),CHR(19),CHR(63)),CHR(20),CHR(63)),CHR(21),CHR(63)),CHR(22),CHR(63)),CHR(23),CHR(63)),CHR(24),CHR(63)),CHR(25),CHR(63)),CHR(26),CHR(63)),CHR(27),CHR(63)),CHR(28),CHR(63)),CHR(29),CHR(63)),CHR(30),CHR(63)),CHR(31),CHR(63))
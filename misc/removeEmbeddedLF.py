import sys
import optparse

#converted from c program as per here https://www.ibm.com/support/pages/loading-file-newline-characters

PARSER = optparse.OptionParser()
PARSER.add_option('-i', '--infile'       , action="store", dest="infile"  , help="Input file name"       , default="")
PARSER.add_option('-o', '--outfile'      , action="store", dest="outfile" , help="Output file name"      , default="")
OPTIONS, ARGS = PARSER.parse_args()

fin = open(OPTIONS.infile, "r", encoding='iso-8859-1')
fout = open(OPTIONS.outfile, "w")

flag = 0
c = fin.read(1)
while c != "":
    #test for "
    if c == "\"":
        if (flag ==0):
            flag = 1
        else:
            flag = 0
    #test for new line
    #if found an if flag is on then output a carriage return instead of newline
    if c == "\n" and flag ==1:
        fout.write("\r")
    else:
        fout.write(c)
    c = fin.read(1)

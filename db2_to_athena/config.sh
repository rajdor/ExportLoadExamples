#!/bin/bash

################################################################################
## Source Table Setup ##########################################################
# variables used for exporting (and initial setup)
################################################################################
# export from this table
export sourceTablename=TEST_CSV_DATA

################################################################################
## Table & Data initialization Setup ###########################################
################################################################################

# Create and insert/load this table - make sure it matches the name of the table in ${initTablename}.ddl
export initTablename=TEST_CSV_DATA
# Create a table using this DDL
export initDDL=${pwd}/${initTablename}.ddl
# Insert records into table using this SQL
export initDataInserts=${pwd}/${sourceTablename}_inserts.sql
# source file containing check sql after inserts
export initDataInsertsCheck=${pwd}/${sourceTablename}_inserts_check.sql
# source file used initial loading from an existing file
export initDataFile=${pwd}/${initTablename}.csv

## Target table setup ###########################################################
# variables used for loading, (Not initialisation):  
################################################################################
#load to this table name - make sure it matches the name of the table in ${targetTablename}.ddl
export targetTablename=testcsvtable
#use this to create the table we are loading 
export targetDDL=${pwd}/${targetTablename}.ddl
# source file used initial loading from an existing file
export targetDataLoadCheck=${pwd}/${targetTablename}_load_check.sql
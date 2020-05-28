#!/bin/bash

export NZ_HOST=192.168.1.179
export NZ_PORT=5480
export NZ_DATABASE=test_data
export NZ_USER=admin
export NZ_PASSWORD=password

export DB2_DATABASE=bludb
export DB2_USER=bluadmin
export DB2_PASSWORD=bluadmin
export DB2_SCHEMA=test_data

export PGHOST=redshift-cluster-1.abcdefghijkl.us-east-1.redshift.amazonaws.com
export PGPORT=5439
export PGDATABASE=dev
export PGUSER=username
export PGPASSWORD=Password-01

s3bucket=mystaging2
s3path=tmp
iamrole=arn:aws:iam::123456789012:role/myRedshiftLoaderRole

###################################################################################
# Functions
function ask_yes_or_no() {
    read -p "$1 ([y]es or [N]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|yes) echo "yes" ;;
        *)     echo "no" ;;
    esac
}

banner()
{
  echo
  echo "+----------------------------------------------------------------------------------+"
  printf "| %-80s |\n" "`date`"
  printf "|`tput bold` %-80s `tput sgr0`|\n" "$@"
  echo "+----------------------------------------------------------------------------------+"
}

###################################################################################
# variables used for file and directory handling
pwd=$(pwd)
current_time=$(date "+%Y%m%d_%H%M%S")
today=$(date +"%F")
export current_time
export today 
export pwd

export workingDir=${pwd}/tmp/${today}/

banner "Making working directory ${workingDir}"
#if [[ -d ${workingDir} ]]; then
#   echo "Error - unexpectedly found local workspace ${workingDir}"
#   echo "Maybe a failed previous run that needs to be cleaned up?"
#   if [[ "yes" == $(ask_yes_or_no "Delete existing Working Directory ${workingDir}?") ]]; then
#      rm -r ${workingDir}
#   fi
#fi
if [[ ! -e ${workingDir} ]]; then
    mkdir -p ${workingDir}
fi 

###################################################################################
# variables used for exporting (and initial setup)
# export from this table
export sourceTablename=CUSTOMER

###################################################################################
# Additional variables for initial setup
export sourceDDL=${pwd}/CUSTOMER.sql
export sourceDataFile=${pwd}/CUSTOMER.csv

###################################################################################
# variables used for loading:

#load to this table name
export targetTablename=STG_CUSTOMER

#use this ddl for the table we are loading
export targetDDL=${pwd}/STG_CUSTOMER.sql

# specify the data filer is supplied on the command line for the load script
export targetDataFile=




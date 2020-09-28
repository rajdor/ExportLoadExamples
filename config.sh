#!/bin/bash
################################################################################
################################################################################
# variables used for file and directory handling
pwd=$(pwd)
current_time=$(date "+%Y%m%d_%H%M%S")
today=$(date +"%F")
export current_time
export today 
export pwd
export workingDir=${pwd}/tmp/${today}/

## Database Server details #####################################################
## Netezza #####################################################################
export NZ_HOST=192.168.1.179
export NZ_PORT=5480
export NZ_DATABASE=test_data
export NZ_USER=admin
export NZ_PASSWORD=password

## Db2 ##########################################################################
export DB2_HOST=192.168.72.143
export DB2_PORT=50000
export DB2_DATABASE=bludb
export DB2_USER=bluadmin
export DB2_PASSWORD=bluadmin
export DB2_SCHEMA=TEST_DATA

## Redshift #####################################################################
export redshiftID=abcdefghijkl
export PGHOST=redshift-cluster-1.${redshiftID}.us-east-1.redshift.amazonaws.com
export PGPORT=5439
export PGDATABASE=dev
export PGUSER=awsuser
export PGPASSWORD=Password-01

export accountNumber=123456789012
export iamrole=arn:aws:iam::${accountNumber}:role/myRedshiftLoaderRole

## S3 ##########################################################################
export awsregion=us-east-1
export s3bucket=mystaging2
export s3path=tmp

################################################################################
################################################################################
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

################################################################################
################################################################################
banner "Making working directory ${workingDir}"
if [[ ! -e ${workingDir} ]]; then
    mkdir -p ${workingDir}
fi 
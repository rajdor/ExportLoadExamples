# Export Load Examples


Export to pipe delimted file and Load examples for Netezza, Redshift, Db2 Warehouse
These can also be combined/chained to move data between each.
Note, the key to using them together is to use a common file format.

Note, 
  Curerntly these are simple examples, thus the 'common' file format is also simple; Pipe delimted, no quotes or escapes
  It is suggested that a common file format be tested against each database, load and unload utility for the following items:
  * Delimiters
  * quoted values
  * Carriage returns
  * Escape characters
  * Nulls
  Additionally, Dates, Times and Timestamps be consistently specified for each load and unload utility.

A few different snippets are used in this project including:
* yes no ask shell script input
* shell script banner
* aws cli s3 copy
* cli database select value to shell script variable
* gzip and unzip for reshdit loads



## Data File
The data file used is 'CUSTOMER.csv'.  This file has been generated and is a mashup of random firstnames, random surnames and random addresses.
Sources used include 
* Names - https://www.census.gov/topics/population/genealogy/data/1990_census/1990_census_namefiles.html
* Address - https://data.gov.au/dataset/ds-dga-19432f89-dc3a-4ef3-b943-5326ef1dbecc/details

## SQL
2 sql files are included to store the loaded CUSTOMER.csv data.  Both have the same columns, but each have different tablenames.
* CUSTOMER.sql - Used for 'initialization'
* STG_CUSTOMER.sql - Used for Loading


## Pre-requisites
1. Ensure you have a working AWS CLI installation
1. Ensure you have working command line clients for Netezza, PostgreSQL, Db2
1. Edit config.sh with your database details
1. If doing Redshift
   1. ensure s3 details and iam details are updated
   1. ensure your S3 bucket is created in the same region as your Redhisft cluster.  i.e. aws s3 mb s3://mystaging2 --region us-east-1
   1. ensure you have assigned the S3 role to allow access to S3.  i.e. myRedshiftLoaderRole/AmazonS3FullAccess 
   1. ensure you have added your clustername and db2 user to the Trust Relationship of your IAM role. i.e. 
     ```{
           "Version":"2012-10-17",
           "Statement":[
              {
                 "Effect":"Allow",
                 "Principal":{
                    "Service":"redshift.amazonaws.com"
                 },
                 "Action":"sts:AssumeRole",
                 "Condition":{
                    "ForAllValues:StringEquals":{
                       "sts:ExternalId":[
                          "arn:aws:redshift:us-east-1:ACCOUNTID:dbuser:redshift-cluster-1/username"
                       ]
                    }
                 }
              }
           ]
        }
     ```

## Basic journey
1. Run the Init script for the database you are testing with
1. Run the Export script for the database you ran the previous script for
1. Take note of the output path and file from the Export script and run a Load script passing the full patha and filename as a parrameter 

### Examples
```
arrod@ubuntu:~/projects-gitea/ExportLoadExamples$ ./init_db2warehouse_table.sh 

+----------------------------------------------------------------------------------+
| Thu 28 May 2020 09:49:40 PM AEST                                                 |
| Making working directory /home/jarrod/projects-gitea/ExportLoadExamples/tmp/2020-05-28/ |
+----------------------------------------------------------------------------------+

+----------------------------------------------------------------------------------+
| Thu 28 May 2020 09:49:40 PM AEST                                                 |
| Initialize Db2 Warehouse table for exports and loads using /home/jarrod/projects-gitea/ExportLoadExamples/CUSTOMER.sql and /home/jarrod/projects-gitea/ExportLoadExamples/CUSTOMER.csv |
+----------------------------------------------------------------------------------+

+----------------------------------------------------------------------------------+
| Thu 28 May 2020 09:49:45 PM AEST                                                 |
| Loading table test_data.CUSTOMER from /home/jarrod/projects-gitea/ExportLoadExamples/CUSTOMER.csv |
+----------------------------------------------------------------------------------+
load client from /home/jarrod/projects-gitea/ExportLoadExamples/CUSTOMER.csv of DEL modified by coldel| nochardel timestampformat="YYYY-MM-DD HH:MM:SS" messages /home/jarrod/projects-gitea/ExportLoadExamples/tmp/2020-05-28//db2_load_importmessages_20200528_214940.txt REPLACE into test_data.CUSTOMER STATISTICS NO NONRECOVERABLE



Number of rows read         = 120000
Number of rows skipped      = 0
Number of rows loaded       = 120000
Number of rows rejected     = 0
Number of rows deleted      = 0
Number of rows committed    = 120000


+----------------------------------------------------------------------------------+
| Thu 28 May 2020 09:49:47 PM AEST                                                 |
| Counting records on CUSTOMER                                                     |
+----------------------------------------------------------------------------------+
SELECT COUNT(*) FROM test_data.CUSTOMER

1                                
---------------------------------
                          120000.

  1 record(s) selected.

+----------------------------------------------------------------------------------+
| Thu 28 May 2020 09:49:47 PM AEST                                                 |
| Done                                                                             |
+----------------------------------------------------------------------------------+

```
```
jarrod@ubuntu:~/projects-gitea/ExportLoadExamples$ ./export_from_db2warehouse.sh 

+----------------------------------------------------------------------------------+
| Thu 28 May 2020 09:51:09 PM AEST                                                 |
| Making working directory /home/jarrod/projects-gitea/ExportLoadExamples/tmp/2020-05-28/ |
+----------------------------------------------------------------------------------+

+----------------------------------------------------------------------------------+
| Thu 28 May 2020 09:51:09 PM AEST                                                 |
| Db2 Warehouse Export from CUSTOMER to /home/jarrod/projects-gitea/ExportLoadExamples/tmp/2020-05-28/TMP_CUSTOMER.csv |
+----------------------------------------------------------------------------------+

SQL3105N  The Export utility has finished exporting "120000" rows.



+----------------------------------------------------------------------------------+
| Thu 28 May 2020 09:51:13 PM AEST                                                 |
| Done                                                                             |
+----------------------------------------------------------------------------------+
```
```
jarrod@ubuntu:~/projects-gitea/ExportLoadExamples$ ./load_netezza_table.sh /home/jarrod/projects-gitea/ExportLoadExamples/tmp/2020-05-28/TMP_CUSTOMER.csv

+----------------------------------------------------------------------------------+
| Thu 28 May 2020 09:52:24 PM AEST                                                 |
| Making working directory /home/jarrod/projects-gitea/ExportLoadExamples/tmp/2020-05-28/ |
+----------------------------------------------------------------------------------+

+----------------------------------------------------------------------------------+
| Thu 28 May 2020 09:52:24 PM AEST                                                 |
| Netezza Load STG_CUSTOMER from /home/jarrod/projects-gitea/ExportLoadExamples/tmp/2020-05-28/TMP_CUSTOMER.csv |
+----------------------------------------------------------------------------------+

Statistics

  number of records read:      120000
  number of bytes read:        14909486
  number of bad records:       0
  -------------------------------------------------
  number of records loaded:    120000

  Parsing Time (sec): 5.0
  Elapsed Time (sec): 5.0

  Rows/Second :       24000.0
  Bytes/Second :      2981897.2

-----------------------------------------------------------------------------
Load completed at: 29-Feb-20 10:50:49 EST 
=============================================================================

+----------------------------------------------------------------------------------+
| Thu 28 May 2020 09:52:29 PM AEST                                                 |
| Counting records on STG_CUSTOMER                                                 |
+----------------------------------------------------------------------------------+
SELECT COUNT(*) FROM STG_CUSTOMER
 COUNT  
--------
 120000
(1 row)


+----------------------------------------------------------------------------------+
| Thu 28 May 2020 09:52:29 PM AEST                                                 |
| Done                                                                             |
+----------------------------------------------------------------------------------+
```





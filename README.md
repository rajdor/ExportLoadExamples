# Export Load Examples

This project has been created to explore export, load options and enablement of usage of data between the following databases and AWS services
  * Db2 Warehouse
  * Netezza
  * Redshift
  * Redshift (Spectrum)
  * Athena

Specifically it deals with file formats (CSV and gzip) covering delimiters, quotes, escape, special characters and the different methods of Exporting, Loading and in some cases cataloging and data movement.

The project has attempted to make a consistent file format for all above use case, preserving special characters and enabling a common file format.
  * Field delimeter               : |    0x7C  ASCII 124
  * Character columns enclosed by : "    0x22  ASCII 034
  * Escape character              : \    0x5C  ASCII 092
  * Record delimeter              : \n   0x0A  ASCII 010
  * Time Format                   : 24.Mi.SS
  * Date Format                   : YYYY-MM-DD
  * Timestamp Format              : YYYY-MM-DD 24.Mi.SS.UUUUUU
  * Null as                       : NULL
  
** This project is incomplete, refer to notes below **
** plus, each generate SQL can be tidied up lots **

# Journeys  
## Db2 to Db2
  * ./db2warehouse_init.sh
  * ./db2warehouse_export.sh
  * ./db2warehouse_load.sh <filename>
  * Uses external tables and gzip to compress exported data.
  * refer to Db2 external table findings
## Db2 to Netezza
  * ./db2warehouse_init.sh
  * ./db2warehouse_export.sh
  * ./netezza_load.sh <filename>
  * Netezza load uncompresses and loads csv file if a gzip file is passed
  * refer to Db2 and Netezza external table findings
## Netezza to Netezza
  * ./netezza_init.sh
  * ./netezza_export.sh
  * ./netezza_load.sh <filename>
  * refer to Netezza external table findings
## Netezza to Db2
  * ./netezza_init.sh
  * ./netezza_export.sh
  * ./db2warehouse_load.sh <filename>
  * refer to Db2 and Netezza external table findings
## Db2 to Redshift
  * ./db2warehouse_init.sh
  * ./db2warehouse_export.sh
  * ./redshift_load.sh <filename>
  * Copy is used to load the file
  * sql is generated to enclose characters in double quotes, escape characters, linefeeds
  * **more work on Redshift copy load options can be done to get NULLs and possibly linefeeds and carriage returns etc working.**
  * refer the Redshift findings below
## Db2 to Redshift Spectrum
  * ./db2warehouse_init.sh
  * ./db2warehouse_export.sh
  * ./redshift_load_externalTable.sh <filename>
  * glue database is created using the s3 bucket name
  ** ensure you update redshiftExternalTable.ddl with your AWS account number
  * sql is generated to enclose characters in double quotes, escape characters, linefeeds
  ** Timestamp requires timezone
  ** Control Characters are replaced with ASCII 26     , as per export SQL
  ** Carriage returns   are replaced with ASCII 32     , as per export SQL
  ** Line Feeds         are replaced with ASCII 32     , as per export SQL
  ** Times              are delimited by period        , as per export SQL
  ** Timestamps         are truncated to 3 microseconds, as per export SQL
  * To do Check sql needs to escape \ - some additional work on COL_ID = 401???
## Db2 to Athena
  * **Incomplete**
  * update the hardcoded values in testcsvtable.ddl
  * db2warehouse_init.sh
  * db2warehouse_export.sh
  * athena_load.sh <filename>
  * sql is generated to enclose characters in double quotes, escape characters, linefeeds
  * To do try gzip, data types, load checker, and then some
## Redshift to Db2
  * **Incomplete**
  * redshift_init.sh
  * redshift_export.sh
  * db2warehouse_load.sh <filename>
  * To do:
  ** Change to generate SQL to replace 0x00 (generate SQL in directory is simply a copy from another directory ready for working on it)
  ** multiple files, manifest usage
  ** and then some
  
#Findings
## Db2 External tables
  * [Db2 11.5](https://www.ibm.com/support/producthub/db2/docs/content/SSEPGG_11.5.0/com.ibm.db2.luw.sql.ref.doc/doc/r_create_ext_table.html)
  * QuotedValue DOUBLE appears to do nothing, no columns are not enclosed in double quotes
  * Nulls for non-string columns are replaced with zero length string; NullValue appears to only impact string columns
  * QuotedNUll False/True appears to do nothing
  * Columns containing the string NULL are escaped as \NULL
  * 0x00 embedded within a string are replaced with space
  * Linefeeds are preserved and escaped with the escape char \
  * Field delimiters are escaped with the escape char \
  * Special characters (above ASCII 031) are exported as ASCII 026 (Substitution character)
  * Loading special characters using external tables
  ** Load will replace ASCII 128  -> ASCII 163 with ASCII 194
  ** Load will replace ASCII 164               with ASCII 226
  ** Load will replace ASCII 192  -> ASCII 255 with ASCII 195
  ** Load will replace ASCII 165* -> ASCII 191 with ASCII 194
  ** Load will replace ASCII 166               with ASCII 197
  ** Load will replace ASCII 168               with ASCII 197
  ** Load will replace ASCII 180               with ASCII 197
  ** Load will replace ASCII 184               with ASCII 197
  ** Load will replace ASCII 188               with ASCII 197
  ** Load will replace ASCII 189               with ASCII 197
  ** Load will replace ASCII 190               with ASCII 197  
## Netezza External tables  
  * QuotedValue DOUBLE appears to do nothing, no columns are not enclosed in double quotes
  * Nulls for non-string columns are replaced with zero length string; NullValue appears to only impact string columns
  * QuotedNUll False/True appears to do nothing
  * Columns containing the string NULL are escaped as \NULL
  * 0x00 embedded within a string are exported as 0x00
  * Linefeeds are preserved and escaped with the escape char \
  * Field delimiters are escaped with the escape char \
  * Special characters (above ASCII 031) are exported correctly
## Redshift
  * [Redshift Copy](https://docs.aws.amazon.com/redshift/latest/dg/r_COPY.html)
  * Embedded linefeeds are not supported
  * Time datatype not supported
  * part second is not supported
  * 0x00 is not supported under any circumstances

## Pre-requisites
1. Ensure you have a working AWS CLI installation
1. Ensure you have working command line clients for Netezza, PostgreSQL, Db2
1. Edit config.sh with your database and AWS details
1. For Redshift:
   1. Ensure s3 details and iam details are updated
   1. Ensure your S3 bucket is created in the same region as your Redhisft cluster.  i.e. aws s3 mb s3://mystaging2 --region us-east-1
   1. Ensure you have assigned the S3 role to allow access to S3.  i.e. myRedshiftLoaderRole/AmazonS3FullAccess 
   1. Ensure you have added your clustername and db2 user to the Trust Relationship of your IAM role. i.e. 
      1.1 IAM -> Roles -> myRedshiftLoaderRole
      1.1 Permissions - attach policy - AmazonS3FullAccess
      1.1 Trust Relationships
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
                             "arn:aws:redshift:us-east-1:ACCOUNTID:dbuser:redshift-cluster-1/awsuser"
                           ]
                        }
                     }
                  }
               ]
            }
         ```
       1.1 Redshift -> Properties -> Attach IAM Roles -> myRedshiftLoaderRole
       1.1 If you are doing this outside of AWS, make your Redshift Publically accessible - this has to be done at cluster create time

## Configuration
There are 2 places where configuration is performed.
1. config.sh in the root directory: used for usernames, servernames, passwords, paths etc..
1. config.sh in each example folder: used for tablenames, filenames etc..

Each example first sources ../config.sh, then config.sh meaning each example directory contains an overriding configuration specific to each example.

## Basic journey
For each of the examples, there are 3 basic steps:
1. Run the Init script for the database you are testing with
1. Run the Export script for the database you ran the previous script for
1. Take note of the output path and file from the Export script and run a Load script passing the full patha and filename as a parameter 

### Examples
```

```





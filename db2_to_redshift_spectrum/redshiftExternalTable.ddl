drop schema if exists spectrum_schema;

create external schema spectrum_schema
  from data catalog
  database 'mystaging2'
  region 'us-east-1'
  iam_role 'arn:aws:iam::<accountNumber>:role/myRedshiftLoaderRole';

drop table if exists spectrum_schema.mytestcsvtable;

CREATE EXTERNAL TABLE
spectrum_schema.mytestcsvtable (
    COL_ID          BIGINT ,
    COL_DESCRIPTION VARCHAR(64),
    COL_TEXT        VARCHAR(64),
    COL_DECIMAL     DECIMAL(16,2),
    COL_FLOAT       FLOAT,
    COL_DATE        DATE,
    COL_TIME        CHAR(8),
    COL_TIMESTAMP   TIMESTAMP
   ) ROW FORMAT SERDE
     'org.apache.hadoop.hive.serde2.OpenCSVSerde'
     WITH SERDEPROPERTIES (
       'separatorChar' = '|',
       'escapeChar' = '\\',
       'quoteChar ' = '"'
     )
   STORED AS TEXTFILE
   LOCATION 's3://mystaging2/tmp/';

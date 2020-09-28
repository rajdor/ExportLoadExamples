CREATE EXTERNAL TABLE mystaging2.testcsvtable (
    col_id          bigint,
    col_description string,
    col_text        string,
    col_decimal     string,
    col_float       float,
    col_date        string,
    col_time        string,
    col_timestamp   string
)
ROW FORMAT SERDE
'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
'separatorChar' = '|',
'escapeChar' = '\\',
'quoteChar ' = '"'
)
STORED AS TEXTFILE
LOCATION 's3://mystaging2/tmp/';
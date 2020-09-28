CREATE TABLE TEST_CSV_DATA (
    COL_ID          BIGINT NOT NULL,
    COL_DESCRIPTION VARCHAR(64),
    COL_TEXT        VARCHAR(64),
    COL_DECIMAL     DECIMAL(16,2),
    COL_FLOAT       DOUBLE,
    COL_DATE        DATE,
    COL_TIME        TIME,
    COL_TIMESTAMP   TIMESTAMP
)
;

--Athena
--CREATE EXTERNAL TABLE mytestcsvtable (
--    col_id          string,
--    col_description string,
--    col_text        string,
--    col_decimal     string,
--    col_float       string,
--    col_date        string,
--    col_time        string,
--    col_timestamp   string
--)
--ROW FORMAT SERDE
--'org.apache.hadoop.hive.serde2.OpenCSVSerde'
--WITH SERDEPROPERTIES (
--'separatorChar' = '|',
--'escapeChar' = '\\',
--'quoteChar ' = '"'
--)
--STORED AS TEXTFILE
--LOCATION 's3://mystaging2/tmp/';
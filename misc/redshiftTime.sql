select version();

-- TimeStamps ------------------------------------------------------------------------
drop table if exists t1;
create table t1 (c1 timestamp);
insert into t1 (select current_timestamp);
insert into t1 values ('2020-03-01 07:30:57.123456');
insert into t1 values ('2020-03-01 07:30:57');

-- Dates -----------------------------------------------------------------------------
drop table if exists t1;
create table t1 (c1 date);
insert into t1 (select current_date);
insert into t1 values ('2020-03-01');


-- Times -----------------------------------------------------------------------------
drop table if exists t1;
create table t1 (c1 time);   -- FAILS????
insert into t1 (select current_time);  
insert into t1 values ('12:00:00'); 


-- CHAR Woraround ???? ----------------------------------------------------------------
drop table if exists t1;
create table t1 (c1 CHAR(8));
insert into t1 (select current_time);   -- FAILS  - expected due to mismatch data type
insert into t1 values ('12:00:00'); -- OK

SELECT CAST( current_time AS CHAR(8)); -- OK - automagic substring
insert into t1 (SELECT CAST( current_time AS CHAR(8))); -- FAILS

SELECT CAST( current_time AS CHAR(18)); -- OK 
insert into t1 (SELECT substr(CAST( current_time AS CHAR(18)),1,8)); -- FAILS




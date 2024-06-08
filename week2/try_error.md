This is my design

1. create file format for parquet
2. create stage of hte parquet file
3. chekc type of parquest
4. create table for parquet
5. copy data of parquet into table
6. create view and stream for trafic change
7. check data by changing data

1. create file format for parquet
```
CREATE OR REPLACE FILE FORMAT week2_parquet TYPE = 'parquet';
```

2. create stage of hte parquet file
```
CREATE OR REPLACE STAGE week2_ext_stage 
  URL = 's3://frostyfridaychallenges/challenge_2/employees.parquet'
  FILE_FORMAT = (FORMAT_NAME = 'week2_parquet');
```

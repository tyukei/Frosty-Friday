This is my first sql code
```
CREATE OR REPLACE SCHEMA ff_schema;
USE SCHEMA ff_schema;
CREATE OR REPLACE STAGE ff_stage
    URL = 's3://frostyfridaychallenges/challenge_1/'
    FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
CREATE OR REPLACE TABLE my_table (
    column1 STRING,
    column2 STRING,
    column3 STRING
);
COPY INTO my_table
FROM @ff_stage
    FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
```

I done till the second last line, But I got error below.
```
Number of columns in file (1) does not match that of the corresponding table (3), use file format option error_on_column_count_mismatch=false to ignore this error
  File 'challenge_1/1.csv', line 3, character 1
  Row 1 starts at line 2, column "MY_TABLE"["COLUMN1":1]
  If you would like to continue loading when an error is encountered, use other values such as 'SKIP_FILE' or 'CONTINUE' for the ON_ERROR option. For more information on loading options, please run 'info loading_data' in a SQL client.
```

This error means just as it's written.
Csv does not match for table, so I have to fit either csv or table.
In this case, csv has only 1 colums, so I fix the number of colums of table on creating table.
I solved like this
```
CREATE OR REPLACE TABLE my_table (
    column1 STRING
);
```
and I got such a result

<img width="613" alt="image" src="https://github.com/tyukei/Frosty-Friday/assets/70129567/f7a7cc47-ecf9-468d-9246-4cf9e3a7fd68">


And also, they have another approch, I followed the instrusction by using CONTINUE 
even if I don't fix any colum number ,I can run this code

```
COPY INTO my_table
FROM @ff_stage
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1 ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE)
ON_ERROR = 'CONTINUE';
```

and I got such a result

<img width="613" alt="image" src="https://github.com/tyukei/Frosty-Friday/assets/70129567/b5f3c91e-30df-4181-99fa-bdd568400597">

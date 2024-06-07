-- スキーマの作成と使用
CREATE OR REPLACE SCHEMA ff_schema;
USE SCHEMA ff_schema;

-- 外部ステージの作成
CREATE OR REPLACE STAGE ff_stage
    URL = 's3://frostyfridaychallenges/challenge_1/'
    FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

-- テーブルの作成
CREATE OR REPLACE TABLE my_table (
    column1 STRING
);

-- データのコピー
COPY INTO my_table
FROM @ff_stage
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1 );
SELECT * FROM my_table;


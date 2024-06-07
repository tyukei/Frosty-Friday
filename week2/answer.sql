-- Parquet形式を読み込むFILE FORMATの作成
CREATE OR REPLACE FILE FORMAT week2_parquet TYPE = 'parquet';

-- STAGEの作成（上記で作成したFILE FORMATを使用）
CREATE OR REPLACE STAGE week2_ext_stage 
  URL = 's3://frostyfridaychallenges/challenge_2/employees.parquet'
  FILE_FORMAT = (FORMAT_NAME = 'week2_parquet');

-- STAGE内を確認
LIST @week2_ext_stage;

-- Parquetファイルからカラム構成を抽出する（INFER_SCHEMAを使用）
SELECT *
FROM TABLE(
    INFER_SCHEMA(
      LOCATION=>'@week2_ext_stage',
      FILE_FORMAT=>'week2_parquet'
    )
);

-- 抽出されたスキーマに基づいてテーブルを作成
CREATE OR REPLACE TABLE week2_table (
    employee_id NUMBER,
    first_name STRING,
    last_name STRING,
    email STRING,
    country STRING,
    dept STRING,
    title STRING,
    job_title STRING
);

-- テーブルの内容を確認
DESC TABLE week2_table;
SELECT * FROM week2_table;

-- Parquetファイルのデータをテーブルにロード（MATCH_BY_COLUMN_NAMEオプションを使用）
COPY INTO week2_table
FROM @week2_ext_stage
FILE_FORMAT = (FORMAT_NAME = 'week2_parquet')
MATCH_BY_COLUMN_NAME = 'CASE_INSENSITIVE';

-- ロードされたテーブルを確認
SELECT * FROM week2_table;

-- 変更管理のために必要な列のみを表示するビューを作成
CREATE OR REPLACE VIEW week2_view AS
SELECT
    employee_id,
    dept,
    job_title
FROM
    week2_table;

-- ビューの内容を確認
SELECT * FROM week2_view;

-- ストリームを作成
CREATE OR REPLACE STREAM week2_stream
    ON VIEW week2_view;

-- ストリームの中身を確認（この時点では空）
SELECT * FROM week2_stream;

-- データの変更を行う（問題に記載のあったUPDATE文を発行）
UPDATE week2_table SET country = 'Japan' WHERE employee_id = 8;
SELECT * FROM week2_stream; -- ストリームには入らない

UPDATE week2_table SET last_name = 'Forester' WHERE employee_id = 22;
SELECT * FROM week2_stream; -- ストリームには入らない

UPDATE week2_table SET dept = 'Marketing' WHERE employee_id = 25;
SELECT * FROM week2_stream; -- ストリームに入る

UPDATE week2_table SET title = 'Ms' WHERE employee_id = 32;
SELECT * FROM week2_stream; -- ストリームには入らない

UPDATE week2_table SET job_title = 'Senior Financial Analyst' WHERE employee_id = 68;
SELECT * FROM week2_stream; -- ストリームに入る

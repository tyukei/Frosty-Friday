/* https://frostyfriday.org/blog/2022/07/15/week-3-basic/
第1週では、S3データの取り込みについて見てきましたが、今回はさらに一歩進めます。今週は、皆さんに取り組んでいただくタスクの短いリストを用意しました。

基本的なことですが、ソリューションを構築し始めると少し悩むかもしれません。

Frosty Friday Inc.、あなたの慈悲深い雇用主は、.csvデータダンプで満たされたS3バケットを持っています。これらのダンプは非常に複雑ではなく、すべて同じスタイルと内容を持っています。これらのファイルはすべて、単一のテーブルに配置する必要があります。

しかし、重要なデータがアップロードされることもあります。これらのファイルは異なる名前の付け方をしており、追跡する必要があります。参照用にメタデータを別のテーブルに保存する必要があります。これらのファイルは、S3バケット内のファイルによって認識できます。このファイル、keywords.csvには、ファイルを重要とするすべてのキーワードが含まれています。

１.全てのCSVデータをSnowflakeにインポートする
２.重要なファイルを特定して追跡する
*/

USE SCHEMA ff_schema;


-- ステージ作成
CREATE STAGE week3_basic
URL = 's3://frostyfridaychallenges/challenge_3/';

-- ステージの中身確認。出力結果が次のFROM文に入る
LIST @week3_basic;



-- キーワードファイルの内容確認
SELECT 
metadata$filename AS file_name,
metadata$file_row_number AS file_row_numer,
$1, $2, $3, $4
FROM @week3_basic/keywords.csv;


--  データファイルの内容確認
SELECT 
metadata$filename AS file_name,
metadata$file_row_number AS number_of_rows,
$1 AS id,
$2 AS first_name,
$3 AS last_name,
$4 AS catch_phrase,
$5 AS timestamp
FROM @week3_basic/week3_data4_extra.csv;

-- ファイルフォーマットの作成
CREATE FILE FORMAT csv_frosty_skip_header
TYPE = 'CSV'
FIELD_DELIMITER = ','
SKIP_HEADER = 1;

-- テーブルの作成
CREATE OR REPLACE TABLE w3_basic_raw (
 file_name VARCHAR,
 number_of_rows VARCHAR,
 id VARCHAR,
 first_name VARCHAR,
 last_name VARCHAR,
 catch_phrase VARCHAR,
 time_stamp VARCHAR  
);

CREATE OR REPLACE TABLE w3_basic_keywords (
file_name VARCHAR,
file_row_number VARCHAR,
keyword VARCHAR,
added_by VARCHAR,
nonsense VARCHAR
);

-- キーワードの取り込み
COPY INTO w3_basic_keywords
FROM
(
  SELECT 
  metadata$filename AS file_name,
  metadata$file_row_number AS file_row_numer,
  t.$1 AS keyword,
  t.$2 AS added_by, 
  t.$3 AS nonsense
  FROM @week3_basic/keywords.csv AS t
)
FILE_FORMAT = 'csv_frosty_skip_header'
PATTERN = 'challenge_3/keywords.csv';

SELECT * FROM w3_basic_keywords;


-- データの取り込み
COPY INTO w3_basic_raw
FROM 
(
  SELECT
  metadata$filename AS file_name,
  metadata$file_row_number AS number_of_rows,
  t.$1 AS id,
  t.$2 AS first_name,
  t.$3 AS last_name,
  t.$4 AS catch_phrase,
  t.$5 AS timestamp
  FROM @week3_basic AS t
)
FILE_FORMAT = 'csv_frosty_skip_header';

SELECT * FROM w3_basic_raw;

-- 重要ファイルの特定
CREATE OR REPLACE VIEW w3_keywordfiles
AS
SELECT
file_name,
COUNT(*) AS number_of_rows
FROM w3_basic_raw
WHERE file_name LIKE ANY (SELECT '%' || $3 || '%' FROM w3_basic_keywords)
GROUP BY file_name;

SELECT * FROM w3_keywordfiles;






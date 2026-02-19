-- セットアップ(ロール、DB、スキーマ)
USE ROLE sysadmin;
CREATE OR REPLACE DATABASE MY_DB;
CREATE OR REPLACE SCHEMA MY_DB.FF;
USE DATABASE MY_DB;
USE SCHEMA FF;

-- ========================================
--　回答1 : 一番初めに思いついたアイディア
-- ========================================
-- テーブル作成
CREATE OR REPLACE TABLE WEEK_87 AS
SELECT 
  'Happy Easter' AS greeting,
  ARRAY_CONSTRUCT('DE', 'FR', 'IT', 'ES', 'PL', 'RO', 'JA', 'KO', 'PT') AS language_codes;

-- テーブルの表示
SELECT *
FROM WEEK_87;

-- 半構造化データ(ARRAY)を展開して、CORTEX.TRANSLATE()で翻訳
SELECT
  f.value::string AS language_code,
  SNOWFLAKE.CORTEX.TRANSLATE(w.greeting, 'en', f.value::string) AS translated_greeting
FROM WEEK_87 w
CROSS JOIN LATERAL FLATTEN(input => w.language_codes) f
ORDER BY language_code;

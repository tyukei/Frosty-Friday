-- https://frostyfriday.org/blog/2024/03/29/week-87-basic/
-- FrostyFriday week 87 回答解説 + 別解４つ　present by chukei

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




-- ========================================
--  目的：　greetingカラムをlanguage_codesカラムの言語コードに翻訳する
--  ポイント１：　半構造化データをどう扱うか
--  ポイント２：　翻訳をどう扱うか
-- ========================================



-- ========================================
-- 入力用テーブルの作成
--    greeting : 翻訳元の英語文
--    language_codes : 翻訳先の言語コード配列

-- ARRAY_CONSTRUCT: https://docs.snowflake.com/ja/sql-reference/functions/array_construct
--   引数に渡した値から ARRAY 型を生成する関数
-- ========================================
CREATE OR REPLACE TABLE WEEK_87 AS
SELECT 
  'Happy Easter' AS greeting,
  ARRAY_CONSTRUCT('DE', 'FR', 'IT', 'ES', 'PL', 'RO', 'JA', 'KO', 'PT') AS language_codes
;

-- テーブルの表示
SELECT *
FROM WEEK_87;

-- ========================================
-- 半構造化データ(ARRAY)の展開
--   FLATTEN はARRAY/JSONなどの半構造化データを「行」に展開する。
--
--   f.* には主に以下のような列が含まれる：
--     SEQ   : FLATTEN が生成する行の連番（補助情報）
--     KEY   : OBJECT のキー（ARRAYのときは常に NULL）
--     PATH  : 入力内での位置を示すパス
--             - ARRAYなら [0], [1] ... のようにインデックス表現
--             - OBJECT なら ["en"] のようにキー表現
--     INDEX : ARRAYのインデックス（OBJECT のときは NULL）
--     VALUE : 展開された要素（ARRAYなら要素、OBJECTなら値）※型は VARIANT
--     THIS  : FLATTEN に渡された入力そのもの（ARRAY/OBJECT 全体）

-- FLATTEN: https://docs.snowflake.com/ja/sql-reference/functions/flatten
--   半構造化データ(ARRAY/JSON)を行に展開する関数
--   名前付き引数の関数のため、INPUTは必要 例)func(one=?,two=?)　※ 一方でfunc(?, ?, ?, ?)は位置引数という
--   FLATTE: FLAT(平にする)
-- LATERAL: https://docs.snowflake.com/ja/sql-reference/constructs/join-lateral
-- 　インラインビューでそのインラインビューの前にあるテーブル式から列を参照する修飾子
--   前にあるテーブル式から列を参照できる修飾子
-- 　LATERAL: LATERAL(横の、外側の)
-- CROSS JOIN: https://docs.snowflake.com/ja/sql-reference/constructs/join#run-a-query-with-a-cross-join
--   全行のあらゆる組み合わせ（デカルト積）で結合
--   例：A(id=1,2,3) と B(code='X','Y') を CROSS JOIN → (1,X),(1,Y),(2,X),(2,Y),(3,X),(3,Y)
-- ========================================
-- ARRAY を FLATTEN して中身を確認
SELECT
  w.greeting,
  f.*
FROM WEEK_87 w
CROSS JOIN LATERAL FLATTEN(INPUT => w.language_codes) f;

-- 脱線(FLATTEN)：JSON(OBJECT)の場合
--   FLATTEN すると、KEY にキー名、VALUE に値が入る（INDEXはNULL）
SELECT PARSE_JSON('{
    "en": "Happy",
    "ja": {"kana":"しあわせ","kanji":"幸"}
    }') AS greetings_json;
    
SELECT
  f.*
FROM (
  SELECT PARSE_JSON('{
    "en": "Happy",
    "ja": {"kana":"しあわせ","kanji":"幸"}
  }') AS greetings_json
)
CROSS JOIN LATERAL FLATTEN(input => greetings_json) f;

-- 脱線(LATERAL) LATERAL無しの場合
--   エラー：右側の FLATTEN が「左側(w)の行」を参照できないため。
SELECT
  w.greeting,
  f.*
FROM WEEK_87 w
CROSS JOIN FLATTEN(INPUT => w.language_codes) f;


-- 必要箇所の取得
SELECT
    w.greeting,
    f.value AS lang_code
FROM WEEK_87 w
CROSS JOIN LATERAL FLATTEN(INPUT => language_codes) f;

--   f.value(VARIANT型)なので ::STRING でキャストする
--   CORTEX.TRANSLATE の引数は STRING
SELECT
    w.greeting,
    f.value::STRING AS lang_code
FROM WEEK_87 w
CROSS JOIN LATERAL FLATTEN(INPUT => language_codes) f;

-- ========================================
-- 翻訳

-- CORTEX.TRANSLATE(旧): https://docs.snowflake.com/ja/sql-reference/functions/translate-snowflake-cortex#arguments
-- AI_TRANSLATE(新): https://docs.snowflake.com/ja/sql-reference/functions/ai_translate
-- 引数はどっちも同じ(<text>, <source_language>, <target_language>)

-- 罠：TRANSLATEは、自然言語の翻訳はしない。文字列中の文字を置換のみ
-- ：https://docs.snowflake.com/ja/sql-reference/functions/translate-snowflake-cortex#arguments
-- ========================================

-- CORTEX.TRANSLATEの場合
SELECT
  f.value::string AS language_code,
  SNOWFLAKE.CORTEX.TRANSLATE(w.greeting, 'en', f.value::string) AS translated_greeting
FROM WEEK_87 w
CROSS JOIN LATERAL FLATTEN(input => w.language_codes) f
ORDER BY language_code;

-- AI_TRANSLATEの場合
SELECT
  f.value::string AS language_code,
  AI_TRANSLATE(w.greeting, 'en', f.value::string) AS translated_greeting
FROM WEEK_87 w
CROSS JOIN LATERAL FLATTEN(input => w.language_codes) f
ORDER BY language_code;

-- 脱線: TRANSLATEの場合
-- 翻訳された単語の内`en`が`言語コード`に置き換わる
-- TRANSLATE(文字列, 置換対象文字列, 置換後文字列)
SELECT
  f.value::string AS language_code,
  TRANSLATE(w.greeting, 'en', f.value::string) AS translated_greeting
FROM WEEK_87 w
CROSS JOIN LATERAL FLATTEN(input => w.language_codes) f
ORDER BY language_code;


-- 脱線:STRINGにキャストしないとどうなるか
-- 実は、暗黙型変換でうまくいくが、明記は推奨
SELECT
  f.value AS language_code,
  SNOWFLAKE.CORTEX.TRANSLATE(w.greeting, 'en', f.value) AS translated_greeting
FROM WEEK_87 w
CROSS JOIN LATERAL FLATTEN(input => w.language_codes) f
ORDER BY language_code;


-- 検証：ちゃんと翻訳できているのか？
-- テーブル作成しデータの保存
CREATE OR REPLACE TABLE WEEK_87_TRANSLATIONS AS
SELECT
  f.value::string AS language_code,
  SNOWFLAKE.CORTEX.TRANSLATE(w.greeting, 'en', f.value::string) AS translated_greeting
FROM WEEK_87 w
CROSS JOIN LATERAL FLATTEN(input => w.language_codes) f
ORDER BY language_code;


-- 作成したテーブルを表示
SELECT *
FROM WEEK_87_TRANSLATIONS
ORDER BY language_code;


--   機械翻訳は基本的に可逆ではないため、逆翻訳しても元の英文と完全一致するとは限らない。
SELECT
  language_code,
  translated_greeting,
  SNOWFLAKE.CORTEX.TRANSLATE(translated_greeting, language_code, 'en') AS back_to_en
FROM WEEK_87_TRANSLATIONS;


-- ========================================
-- 別解
-- 　　テーブルを作らずにシンプルにする　→ サブクエリを使用
-- 　　翻訳の関数って他に何があるか → CORTEX.TRANSLATE, AI_TRANSLATE, CORTEX.COMPLETE, AI_COMPLETE
-- ========================================



-- ========================================
--　回答2: CORTEX.TRANSLATE使用
-- ========================================
WITH src AS (
  SELECT
    'Happy Easter' AS greeting,
    ARRAY_CONSTRUCT('DE', 'FR', 'IT', 'ES', 'PL', 'RO', 'JA', 'KO', 'PT') AS language_codes
)
SELECT
  f.value::string AS language_code,
  SNOWFLAKE.CORTEX.TRANSLATE(src.greeting, 'en', f.value::string) AS translated_greeting
FROM src
CROSS JOIN LATERAL FLATTEN(input => src.language_codes) f
ORDER BY language_code;


-- ========================================
--　回答3：AI_TRANSLATE使用
-- ========================================
WITH src AS (
  SELECT
    'Happy Easter' AS greeting,
    ARRAY_CONSTRUCT('DE', 'FR', 'IT', 'ES', 'PL', 'RO', 'JA', 'KO', 'PT') AS language_codes
)
SELECT
  f.value::string AS language_code,
  AI_TRANSLATE(src.greeting, 'en', f.value::string) AS translated_greeting
FROM src
CROSS JOIN LATERAL FLATTEN(input => src.language_codes) f
ORDER BY language_code;

-- ========================================
--　回答4：CORTEX.COMPLETE使用
-- ========================================
WITH src AS (
  SELECT
    'Happy Easter' AS greeting,
    ARRAY_CONSTRUCT('DE', 'FR', 'IT', 'ES', 'PL', 'RO', 'JA', 'KO', 'PT') AS language_codes
)
SELECT
  f.value::string AS language_code,
  SNOWFLAKE.CORTEX.COMPLETE(
    'llama3.1-70b',
    'Translate the following text into ' || f.value::string ||
    ' and output only the translated text: ' || src.greeting
  ) AS translated_greeting
FROM src
CROSS JOIN LATERAL FLATTEN(input => src.language_codes) f
ORDER BY language_code;

-- ========================================
--　回答5：AI_COMPLETE使用
-- ========================================
WITH src AS (
  SELECT
    'Happy Easter' AS greeting,
    ARRAY_CONSTRUCT('DE', 'FR', 'IT', 'ES', 'PL', 'RO', 'JA', 'KO', 'PT') AS language_codes
)
SELECT
  f.value::string AS language_code,
  AI_COMPLETE(
    'llama3.1-70b',
    'Translate the following text into ' || f.value::string ||
    ' and output only the translated text: ' || src.greeting
  ) AS translated_greeting
FROM src
CROSS JOIN LATERAL FLATTEN(input => src.language_codes) f
ORDER BY language_code;


-- 日本語のプロンプトにすると、出力も日本語になりがち
WITH src AS (
  SELECT
    'Happy Easter' AS greeting,
    ARRAY_CONSTRUCT('DE', 'FR', 'IT', 'ES', 'PL', 'RO', 'JA', 'KO', 'PT') AS language_codes
)
SELECT
  f.value::string AS language_code,
  AI_COMPLETE.COMPLETE(
    'llama3.1-70b',
    '次の英文を' || f.value::string ||
    ' に翻訳し、翻訳結果のみを出力してください: ' || src.greeting
  ) AS translated_greeting
FROM src
CROSS JOIN LATERAL FLATTEN(input => src.language_codes) f
ORDER BY language_code;

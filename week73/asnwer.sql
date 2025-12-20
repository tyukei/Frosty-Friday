-- create dummy table
create or replace table dates_test1 (
  birthday varchar
)AS
SELECT * FROM VALUES
  ('1980-01-05'), --YYYY-MM-DD
  ('07/08/2015'), --MM/DD/YYYY
  ('21/08/2015'), --DD/MM/YYYY
  ('17-DEC-1980'), --DD-MON-YYYY
  ('2451152');   

select * from dates_test1;

-- if value is date type then pass else null
-- https://docs.snowflake.com/ja/sql-reference/functions/try_to_date
create or replace view dates_formatted1 as
select
    birthday as birthday_raw,
    coalesce(
        try_to_date(birthday, 'YYYY-MM-DD'),
        try_to_date(birthday, 'MM/DD/YYYY'),
        try_to_date(birthday, 'DD/MM/YYYY')
    ) as birthday_formatted
from dates_test1;

select * from dates_formatted1;

create or replace view dates_formatted1_2 as
select
    birthday as birthday_raw,
    try_to_date(birthday) as birthday_formatted
from dates_test1;

-- AUTO(デフォルト引数)の場合対応タイプは3つ(YYYY-MM-DD, DD-MON-YYYY, MM/DD/YYYY)
-- https://docs.snowflake.com/ja/sql-reference/date-time-input-output#label-date-time-input-output-supported-formats-for-auto-detection
select * from dates_formatted1_2;






create or replace table dates_test2 (
  birthday  varchar,
  country  varchar  -- 国名
) as
select column1 as birthday, column2 as country
from values
  ('21/02/2008', 'Brazil'),         -- DD/MM/YYYY が一般的な国の例
  ('04/28/2012', 'United States'),  -- MM/DD/YYYY
  ('2019-11-03', 'Japan'),          -- YYYY-MM-DD も普通に来る想定
  ('03.09.2001', 'Germany'),        -- DD.MM.YYYY
  ('2023/10/21', 'China'),          -- YYYY/MM/DD
  ('H12.5.21',   'Japan'),          -- 元号（AIに任せる例）
  ('07/08/2015', 'United State'),        -- 曖昧
  ('07/08/2015', 'France'),        -- 曖昧
  ('20210322',   'South Korea');    -- YYYYMMDD

select * from dates_test2;

create or replace view dates_formatted2 as
select
    *,
    ai_complete(
    'claude-4-sonnet',
    CONCAT('<location>',country,'</location>でよく使われている日付フォーマットで<date>',birthday,'</date>をYYYY-MM-DDに変換してください。出力は変換後の日付のみにしてください')
    ) as birthday_formatted
from dates_test2;

select * from dates_formatted2;

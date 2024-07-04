use role SYSADMIN;
use schema M_KAJIYA_FROSTY_FRIDAY.PUBLIC;

-- 分析対象ファイル
set url = 's3://frostyfridaychallenges/challenge_4';
set file_name = 'Spanish_Monarchs.json';

create temp stage if not exists frosty_friday_stage
    url = $url;

ls @frosty_friday_stage;

-- とりあえずクエリすると、JSONが見える
select top 10
    $1::VARCHAR
from @frosty_friday_stage;

-- ファイルフォーマットを作成
create or replace temporary file format challenge_4_format
    type = json
    strip_outer_array = true; -- 外側の [ ] を削除（いらない）

-- 一旦テーブルにロードしよう
create or replace temp table challenge_4_load as
select
    $1::variant as value
from @frosty_friday_stage
(file_format => 'challenge_4_format');

-- 解析して最終テーブルに格納
create or replace temp table challenge_4_result as
select
    row_number() over (order by Monarchs.value:"Birth"::date) as ID,
    Monarchs.index + 1 as INTER_HOUSE_ID, -- 配列にある要素のインデックス cf. https://docs.snowflake.com/ja/sql-reference/functions/flatten#output
    c.value:Era::string as ERA,
    houses.value:House::string as House,
    Monarchs.value:"Name"::string as NAME,
    case
        when Monarchs.value:"Nickname"[0]::string is not null then Monarchs.value:"Nickname"[0]::string 
        else Monarchs.value:"Nickname"::string 
    end as NICKNAME_1,
    Monarchs.value:"Nickname"[1]::string as NICKNAME_2,
    Monarchs.value:"Nickname"[2]::string as NICKNAME_3,
    Monarchs.value:"Birth"::string as BIRTH,
    Monarchs.value:"Place of Birth"::string as PLACE_OF_BIRTH,
    Monarchs.value:"Start of Reign"::string as START_OF_REIGN,
    case
        when Monarchs.value:"Consort/Queen Consort"[0]::string is not null then Monarchs.value:"Consort/Queen Consort"[0]::string 
        else Monarchs.value:"Consort/Queen Consort"::string 
    end as QUEEN_OR_QUEEN_CONSORT_1,
    Monarchs.value:"Consort/Queen Consort"[1]::string as QUEEN_OR_QUEEN_CONSORT_2,
    Monarchs.value:"Consort/Queen Consort"[2]::string as QUEEN_OR_QUEEN_CONSORT_3,
    Monarchs.value:"End of Reign"::string as END_OF_REIGN,
    Monarchs.value:"Duration"::string as DURATION,
    Monarchs.value:"Death"::string as DEATH,
    SPLIT(Monarchs.value:"Age at Time of Death"::string, ' ')[0]::NUMBER as AGE_AT_TIME_OF_DEATH_YEARS,
    Monarchs.value:"Place of Death"::string as PLACE_OF_DEATH,
    Monarchs.value:"Burial Place"::string as BURIAL_PLACE
from
    challenge_4_load as c,
    lateral flatten (input => c.value:"Houses") houses,
    lateral flatten (input => houses.value:"Monarchs") Monarchs
order by
    ID;

-- 最終結果の表示
select * from challenge_4_result;

-- S3バケット用のステージを作成
create stage ff_week6_stg
url = 's3://frostyfridaychallenges/challenge_6/';

-- ステージの内容をリスト
list @ff_week6_stg;
/* 2つのCSVファイルがリストされました
s3://frostyfridaychallenges/challenge_6/nations_and_regions.csv
s3://frostyfridaychallenges/challenge_6/westminster_constituency_points.csv
*/

-- CSVファイル用のファイルフォーマットを作成
create or replace file format ff_csv_fileformat
type = csv
field_optionally_enclosed_by = '"'
skip_header = 1;

-- nations_and_regions.csvの6列を選択してビューを作成
create or replace view ff_nations_and_regions_v
as
select $1::string as nation_or_region_name
,      $2::string as type
,      $3::int as sequence_num
,      $4::float as longitude
,      $5::float as latitude
,      $6::int as part
from @ff_week6_stg/nations_and_regions.csv
(file_format => 'ff_csv_fileformat');

-- westminster_constituency_points.csvの5列を選択してビューを作成
create or replace view ff_westminster_constituency_points_v
as
select $1::string as constituency
,      $2::int as sequence_num
,      $3::float as longitude
,      $4::float as latitude
,      $5::int as part
from @ff_week6_stg/westminster_constituency_points.csv
(file_format => 'ff_csv_fileformat');

select *
from ff_nations_and_regions_v;

-- 座標ペアとポリゴンを作成して、https://clydedacruz.github.io/openstreetmap-wkt-playground/ で可視化
select nation_or_region_name
, part
, 'POLYGON(('||
  listagg(longitude || ' ' || latitude, ',') within group (order by sequence_num)
  ||'))' as polygon
from ff_nations_and_regions_v
group by nation_or_region_name, part;

select constituency
, part
, 'POLYGON(('||
  listagg(longitude || ' ' || latitude, ',') within group (order by sequence_num)
  ||'))' as polygon
from ff_westminster_constituency_points_v
group by constituency, part;

-- Snowflake Geographyポリゴンをpartレベルで作成
select nation_or_region_name
, part
, to_geography('POLYGON(('||
  listagg(longitude || ' ' || latitude, ',') within group (order by sequence_num)
  ||'))') as polygon
from ff_nations_and_regions_v
group by nation_or_region_name, part;

select constituency
, part
, to_geography('POLYGON(('||
  listagg(longitude || ' ' || latitude, ',') within group (order by sequence_num)
  ||'))') as polygon
from ff_westminster_constituency_points_v
group by constituency, part;

-- 上記のpartレベルのポリゴンを組み合わせて、国/地域および選挙区レベルで集計し、交差数をカウント
with nations_and_regions_parts as
    (select nation_or_region_name
    , type
    , part
    , to_geography('POLYGON(('||
      listagg(longitude || ' ' || latitude, ',') within group (order by sequence_num)
      ||'))') as polygon
    from ff_nations_and_regions_v
    group by nation_or_region_name, type, part
    )
, westminster_constituency_points_parts as
    (select constituency
    , part
    , to_geography('POLYGON(('||
      listagg(longitude || ' ' || latitude, ',') within group (order by sequence_num)
      ||'))') as polygon
    from ff_westminster_constituency_points_v
    group by constituency, part
    )
, nations_and_regions as
    (select nation_or_region_name
    , st_collect(nrp.polygon) as polygon
    from nations_and_regions_parts nrp
    group by nation_or_region_name
    )
, westminster_constituency_points as
    (select constituency
    , st_collect(wcpp.polygon) as polygon
    from westminster_constituency_points_parts wcpp
    group by constituency
    )
, intersections as
    (select nr.nation_or_region_name
          , st_intersects(nr.polygon, wcp.polygon) intersects
     from nations_and_regions nr
     ,    westminster_constituency_points wcp
    )
select i.nation_or_region_name as nation_or_region
,      count(*) as intersecting_constituencies
from   intersections i
where  i.intersects = true
group by i.nation_or_region_name;

-- 環境を設定
create schema challenge_6;
use schema challenge_6;

-- CSVに含まれる列に対して、必要に応じて別のファイルフォーマットを作成
create or replace file format ff6_csv type = csv
skip_header = 0
field_optionally_enclosed_by = '"';

-- ローディングステージを作成
create or replace stage challenge_6_AWS_stage url = 's3://frostyfridaychallenges/challenge_6/' file_format = ff6_csv;

-- ステージ内のファイルをリスト
list @challenge_6_AWS_stage;

-- ファイル内のデータを確認
select
    metadata$filename,
    metadata$file_row_number,
    $1,
    $2,
    $3,
    $4,
    $5,
    $6,
    $7,
    $8
from @challenge_6_AWS_stage
where metadata$filename = 'challenge_6/westminster_constituency_points.csv';

-- データをロードするテーブルを作成
create or replace table ff6_westminster_constituency_points (
    constituency string(100),
    sequence_num int,
    longitude double,
    latitude double,
    part int
);

-- テーブルに値を挿入
insert into ff6_westminster_constituency_points (
    select $1, $2, $3, $4, $5
    from @challenge_6_AWS_stage
    where metadata$filename = 'challenge_6/westminster_constituency_points.csv'
    and METADATA$file_row_number != 1 -- ヘッダ行をスキップ
);

-- ポイントを作成
create or replace temp table westminster_point as (
    select constituency, part, sequence_num,
    listagg(longitude || ' ' || latitude) as str_point
    from ff6_westminster_constituency_points
    group by constituency, part, sequence_num
);

-- ポイントからラインを作成し、ポリゴンを作成
create or replace table westminster_polygon as (
    select constituency, part,
    listagg(str_point, ', ') within group (order by sequence_num) as str_line,
    'LINESTRING(' || str_line || ')' as str_line_2,
    st_makepolygon(to_geography(str_line_2)) as polygon
    from westminster_point
    group by constituency, part
);

-- フィールドpartを使用してポリゴンを集計
create or replace table westminster_combined as (
    select constituency as constituency,
    st_collect(polygon) as polygon
    from westminster_polygon
    group by constituency
);

-- nations and regionsデータについても同様に実行
-- ファイルのデータを確認
select
    metadata$filename,
    metadata$file_row_number,
    $1,
    $2,
    $3,
    $4,
    $5,
    $6,
    $7,
    $8
from @challenge_6_AWS_stage
where metadata$filename = 'challenge_6/nations_and_regions.csv';

-- テーブルを作成
create or replace table ff6_nations_and_regions_points (
    nation_or_region_name string,
    type string,
    sequence_num int,
    longitude double,
    latitude double,
    part int
);

-- テーブルにデータをロード
insert into ff6_nations_and_regions_points (
    select $1, $2, $3, $4, $5, $6
    from @challenge_6_AWS_stage
    where metadata$filename = 'challenge_6/nations_and_regions.csv'
    and METADATA$file_row_number != 1 -- ヘッダ行をスキップ
);

-- ポイントを作成
create or replace temp table nations_and_regions_point as (
    select nation_or_region_name, type, part, sequence_num,
    listagg(longitude || ' ' || latitude) as str_point
    from ff6_nations_and_regions_points
    group by nation_or_region_name, type, part, sequence_num
);

-- ポリゴンを作成
create or replace table nations_and_regions_polygon as (
    select nation_or_region_name, type, part,
    listagg(str_point, ', ') within group (order by sequence_num) as str_line,
    'LINESTRING(' || str_line || ')' as str_line_2,
    st_makepolygon(to_geography(str_line_2)) as polygon
    from nations_and_regions_point
    group by nation_or_region_name, type, part
);

-- ポリゴンを集計
create or replace table nations_and_regions_combined as (
    select nation_or_region_name as name,
    st_collect(polygon) as polygon
    from nations_and_regions_polygon
    group by nation_or_region_name, type
);

-- 交差をフィルタリングするためにクロスジョインを使用
select n.name as NATION_OR_REGION, count(1) as INTERSECTING_CONSITUENCIES
from WESTMINSTER_COMBINED w
cross join nations_and_regions_combined n
where st_intersects(w.polygon, n.polygon)
group by n.name
order by INTERSECTING_CONSITUENCIES desc;

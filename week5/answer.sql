/**
今週は、執筆時点で非常に最新の機能を使用しています。それは、SnowflakeでのPythonです。

まず、単一の列に数字を持つシンプルなテーブルを作成します。サイズや量はお好みで構いません。

その後、非常に基本的な関数を作成します。その数字を3倍にする関数です。

ここでの挑戦は、「非常に難しいPython関数を作成すること」ではなく、その関数をSnowflakeで作成し使用することです。

以下のようなシンプルなSELECTステートメントでコードをテストできます：

SELECT timesthree(start_int)
FROM FF_week_5

**/

REATE OR REPLACE TABLE ff_week_5 (start_int NUMBER);
INSERT INTO ff_week_5 (start_int)
SELECT UNIFORM(0, 1000, RANDOM()) AS start_int
FROM TABLE(GENERATOR(ROWCOUNT => 100));


SELECT * FROM ff_week_5 ORDER BY start_int;


-- python version
CREATE OR REPLACE FUNCTION timesthree(i INT)
RETURNS INT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
HANDLER = 'timesthree_py'
AS
$$
def timesthree_py(i):
    return i * 3
$$
;
SELECT start_int, timesthree(start_int) AS start_int_x3
FROM ff_week_5
ORDER BY start_int;


-- sql version
CREATE OR REPLACE FUNCTION timesthree_by_sql(i INT)
RETURNS INT
LANGUAGE SQL
AS
$$
i * 3
$$
;
SELECT start_int, timesthree_by_sql(start_int) AS start_int_x3
FROM ff_week_5
ORDER BY start_int;


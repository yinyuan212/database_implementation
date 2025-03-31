CREATE PROCEDURE Find_TwoDayPattern
    @StockCode NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    WITH StockData AS (
        SELECT 
            ROW_NUMBER() OVER (PARTITION BY StockCode ORDER BY [Date]) AS rn,
            [Date], [StockCode], [Open], [Close], [High], [Low]
        FROM StockTrading_TA
        WHERE StockCode = @StockCode
    ), TwoDayBase AS (
        SELECT
            s1.StockCode,
            s1.Date AS first_day,
            s2.Date AS second_day,
            s1.[Open] AS o1,
            s1.[Close] AS c1,
            s2.[Open] AS o2,
            s2.[Close] AS c2
        FROM StockData s1
        JOIN StockData s2
            ON s1.rn + 1 = s2.rn
    ), TwoDayLabeled AS (
        SELECT *,
            CASE
                -- 遭遇線：黑→紅，收盤相同（或接近）
                WHEN c1 < o1 AND c2 > o2 AND ABS(c1 - c2) <= 0.5 THEN '遭遇線'

                -- 懷抱線：第一根長實體包住第二根（方向不限）
                WHEN 
                    ABS(c1 - o1) >= 1.5 * ABS(c2 - o2) AND
                    (
                        (o1 < c1 AND o1 <= o2 AND c1 >= c2) OR
                        (o1 > c1 AND o1 >= o2 AND c1 <= c2)
                    )
                THEN '懷抱線'

                -- 吞噬線：第二根長實體包住第一根，方向反轉
                WHEN 
                    ABS(c2 - o2) >= 1.5 * ABS(c1 - o1) AND
                    (
                        (o1 > c1 AND o2 < c2 AND o2 <= o1 AND c2 >= c1) OR  -- 紅K 吞黑K
                        (o1 < c1 AND o2 > c2 AND o2 >= o1 AND c2 <= c1)     -- 黑K 吞紅K
                    )
                THEN '吞噬線'

                -- 插入線：第二根吃掉第一根一半以上，但未完全包住
                WHEN 
                    (
                        (c1 < o1 AND c2 > o2 AND 
                         o2 < c1 AND c2 > ((o1 + c1) / 2) AND NOT (o2 <= o1 AND c2 >= c1)) OR
                        (c1 > o1 AND c2 < o2 AND 
                         o2 > c1 AND c2 < ((o1 + c1) / 2) AND NOT (o2 >= o1 AND c2 <= c1))
                    )
                THEN '插入線'

                ELSE NULL
            END AS type
        FROM TwoDayBase
    )
    SELECT StockCode, first_day, second_day, type
    FROM TwoDayLabeled
    WHERE type IS NOT NULL
    ORDER BY second_day DESC;
END

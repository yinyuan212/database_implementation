CREATE PROCEDURE KD_cross
    @stock_code VARCHAR(10),
    @start_date DATE,
    @end_date DATE
AS
BEGIN
    SET NOCOUNT ON;

    WITH KD_with_lag AS (
        SELECT 
            StockCode,
            [Date],
            K_value,
            D_value,
            LAG(K_value, 1) OVER (PARTITION BY StockCode ORDER BY [Date]) AS K_yesterday,
            LAG(D_value, 1) OVER (PARTITION BY StockCode ORDER BY [Date]) AS D_yesterday
        FROM StockTrading_TA
        WHERE StockCode = @stock_code
    )

    SELECT 
        StockCode AS stock_code,
        [Date] AS [date],
        CASE 
            WHEN K_value > D_value 
                 AND K_yesterday <= D_yesterday 
                 AND K_yesterday < 20 AND D_yesterday < 20
            THEN '黃金交叉'

            WHEN K_value < D_value 
                 AND K_yesterday >= D_yesterday 
                 AND K_yesterday > 80 AND D_yesterday > 80
            THEN '死亡交叉'
        END AS result
    FROM KD_with_lag
    WHERE 
        [Date] BETWEEN @start_date AND @end_date AND
        (
            (K_value > D_value AND K_yesterday <= D_yesterday AND K_yesterday < 20 AND D_yesterday < 20)
            OR
            (K_value < D_value AND K_yesterday >= D_yesterday AND K_yesterday > 80 AND D_yesterday > 80)
        )
    ORDER BY [Date];
END


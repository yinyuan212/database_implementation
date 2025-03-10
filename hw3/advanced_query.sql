-- 查詢指定日期，連續3天上漲的股票
DECLARE @TargetDate DATE = '2023-12-31';

WITH RankedTrades AS 
(
    SELECT 
        stock_code,
        date,
        c,
        LAG(c) OVER (PARTITION BY stock_code ORDER BY date) AS PreviousClosePrice,
        ROW_NUMBER() OVER (PARTITION BY stock_code ORDER BY date DESC) AS TradeRank 
    FROM stock_data 
    WHERE date <= @TargetDate
),
RecentFiveOpenDays AS 
(
    SELECT 
        stock_code,
        date,
        c,
        PreviousClosePrice 
    FROM RankedTrades 
    WHERE TradeRank <= 5
),
DailyPriceChange AS 
(
    SELECT 
        stock_code,
        date AS TradeDate,
        CASE 
            WHEN c > PreviousClosePrice THEN 1 
            ELSE 0 
        END AS IsPriceUp
    FROM RecentFiveOpenDays
    WHERE PreviousClosePrice IS NOT NULL
),
StockPriceTrend AS 
(
    SELECT 
        stock_code,
        SUM(IsPriceUp) AS DaysPriceUp 
    FROM DailyPriceChange 
    GROUP BY stock_code
)

SELECT 
    stock_code,
    DaysPriceUp
FROM StockPriceTrend
WHERE DaysPriceUp > 3;

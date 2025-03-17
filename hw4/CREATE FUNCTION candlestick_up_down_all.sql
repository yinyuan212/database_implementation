CREATE FUNCTION candlestick_up_down_all
(
    @StockCode VARCHAR(10) -- 股票代碼
)
RETURNS TABLE
AS
RETURN
(
    -- 使用 CTE (Common Table Expression) 建立當前與前一日資料
    WITH CurrentAndPrevDay AS (
        SELECT 
            StockCode,
            [Date],
            [Open],
            [Close],
            [High],
            [Low],
            -- 使用 LAG 函數獲取前一日資料
            LAG([Open]) OVER (PARTITION BY StockCode ORDER BY [Date]) AS PrevOpen,
            LAG([Close]) OVER (PARTITION BY StockCode ORDER BY [Date]) AS PrevClose,
            LAG([High]) OVER (PARTITION BY StockCode ORDER BY [Date]) AS PrevHigh,
            LAG([Low]) OVER (PARTITION BY StockCode ORDER BY [Date]) AS PrevLow
        FROM StockTrading_TA
        WHERE StockCode = @StockCode
    )
    -- 主查詢：判斷漲跌型態（含跳空）
	SELECT 
		StockCode,
		[date],
		CASE
			-- 沒有前一天資料
			WHEN PrevOpen IS NULL THEN 99

			-- 跳空上漲：今日最低 > 昨日最高（K線完全不重疊）
			WHEN [Low] > PrevHigh THEN 3

			-- 跳空下跌：今日最高 < 昨日最低
			WHEN [High] < PrevLow THEN -3

			-- 完全上漲：四個條件都要符合
			WHEN [High] > PrevHigh
				 AND [Low] > PrevLow
				 AND [Open] > PrevOpen
				 AND [Close] > PrevClose
			THEN 2

			-- 完全下跌：四個條件都要符合
			WHEN [High] < PrevHigh
				 AND [Low] < PrevLow
				 AND [Open] < PrevOpen
				 AND [Close] < PrevClose
			THEN -2

			-- 一般上漲：收盤價 > 前一日收盤價
			WHEN [Close] > PrevClose THEN 1

			-- 一般下跌：收盤價 < 前一日收盤價
			WHEN [Close] < PrevClose THEN -1

			-- 收盤價相同
			WHEN [Close] = PrevClose THEN 0

			-- 其他情況
			ELSE 99
		END AS up_down  -- 欄位名稱：up_down
	FROM CurrentAndPrevDay


);
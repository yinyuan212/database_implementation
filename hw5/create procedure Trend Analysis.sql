CREATE PROCEDURE [dbo].[Trend_Analysis]
    @Company varchar(10),
    @Day int OUTPUT,
    @Result varchar(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- 宣告變數
    DECLARE @c real
    DECLARE @MA5 real
    DECLARE @MA10 real
    DECLARE @MA20 real
    DECLARE @Trend int
    DECLARE @DailyTrend int

    -- 使用 LOCAL 游標並確保有 MA 值的資料
    DECLARE cur CURSOR LOCAL STATIC FOR
        SELECT [Close], MA5, MA10, MA20
        FROM dbo.StockTrading_TA
        WHERE StockCode = @Company
            AND MA5 IS NOT NULL
            AND MA10 IS NOT NULL
            AND MA20 IS NOT NULL
        ORDER BY [Date] DESC

    OPEN cur
    FETCH NEXT FROM cur INTO @c, @MA5, @MA10, @MA20

    SET @Day = 0

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- 判斷當日趨勢
        IF (@c > @MA5 AND @MA5 > @MA10 AND @MA10 > @MA20)
            SET @DailyTrend = 1
        ELSE IF (@c < @MA5 AND @MA5 < @MA10 AND @MA10 < @MA20)
            SET @DailyTrend = -1
        ELSE
            SET @DailyTrend = 0

        -- 第一天設定趨勢基準
        IF (@Day = 0)
            SET @Trend = @DailyTrend
        ELSE IF (@DailyTrend != @Trend)
            BREAK

        SET @Day = @Day + 1
        FETCH NEXT FROM cur INTO @c, @MA5, @MA10, @MA20
    END

    -- 設定輸出結果
    SET @Result = CASE @Trend
        WHEN 1 THEN 'Up trend'
        WHEN -1 THEN 'Down trend'
        ELSE 'Consolidate'
    END

    CLOSE cur
    DEALLOCATE cur
END

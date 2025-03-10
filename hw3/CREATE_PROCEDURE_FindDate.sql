-- find_date來支持跨年份的搜尋
CREATE PROCEDURE FindDate
    @startDate DATE,
    @days INT,
    @includeToday BIT,
    @direction NVARCHAR(10) -- 'forward' 表示向後, 'backend' 表示向前
AS
BEGIN
    SET NOCOUNT ON;

    -- 確定方向值 (-1 表示向前，1 表示向後)
    DECLARE @step INT = CASE 
                            WHEN @direction = 'forward' THEN -1
                            WHEN @direction = 'backward' THEN 1
                            ELSE 0 -- 無效方向處理
                        END;

    IF @step = 0
    BEGIN
        PRINT 'Invalid direction. Please use ''forward'' or ''backward''.';
        RETURN;
    END;

    -- 根據是否包含當天調整起始偏移量
    DECLARE @offset INT = CASE 
                              WHEN @includeToday = 1 THEN 0 
                              ELSE @step 
                          END;

    -- 初始化變數
    DECLARE @resultDate DATE = @startDate;

    -- 創建臨時表來存儲結果
    CREATE TABLE #Result (
        [date] DATE,
        [day_of_stock] INT
    );

    -- 搜尋目標開市日數
    WHILE @days > 0
    BEGIN
        -- 調整日期
        SET @resultDate = DATEADD(DAY, @offset, @resultDate);

        -- 檢查是否為開市日並插入對應的結果
        IF EXISTS (
            SELECT 1
            FROM calendar
            WHERE date = @resultDate
              AND day_of_stock <> -1 -- 確認是否開市
        )
        BEGIN
            INSERT INTO #Result ([date], [day_of_stock])
            SELECT 
                [date],
                [day_of_stock]
            FROM calendar
            WHERE [date] = @resultDate; -- 假設數據表名為 StockDataTable

            SET @days = @days - 1;
        END
        ELSE
        BEGIN
			CONTINUE
        END;

        -- 更新偏移量為下一天
        SET @offset = @step;
    END;

    -- 返回結果
    SELECT [date], [day_of_stock]
    FROM #Result;

    -- 清理臨時表
    DROP TABLE #Result;
END;
GO


EXEC FindDate 
    @startDate = '2022-01-04', 
    @days = 5, 
    @includeToday = 1, 
    @direction = 'forward';

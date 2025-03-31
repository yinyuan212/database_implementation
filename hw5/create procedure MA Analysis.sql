CREATE PROCEDURE [dbo].[MA_Analysis]
    @MA_First VARCHAR(5),
    @MA_Second VARCHAR(5),
    @Company VARCHAR(10),
    @Result CHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- 宣告變數
    DECLARE @Date DATE;
    DECLARE @C REAL;
    DECLARE @MA_First_Value REAL;
    DECLARE @MA_Second_Value REAL;
    DECLARE @CurrentTrend VARCHAR(10) = NULL;
    DECLARE @DayCount INT = 0;

    -- 建立臨時表
    CREATE TABLE #stock_data (
        date DATE,
        C REAL,
        MA_First_Value REAL,
        MA_Second_Value REAL
    );

    -- 將資料插入臨時表
    INSERT INTO #stock_data (date, C, MA_First_Value, MA_Second_Value)
    SELECT 
        [date], 
        [Close],
        CASE 
            WHEN @MA_First = 'MA5' THEN MA5
            WHEN @MA_First = 'MA10' THEN MA10
            WHEN @MA_First = 'MA20' THEN MA20
            WHEN @MA_First = 'MA60' THEN MA60
            WHEN @MA_First = 'MA120' THEN MA120
            WHEN @MA_First = 'MA240' THEN MA240
            ELSE NULL 
        END,
        CASE 
            WHEN @MA_Second = 'MA5' THEN MA5
            WHEN @MA_Second = 'MA10' THEN MA10
            WHEN @MA_Second = 'MA20' THEN MA20
            WHEN @MA_Second = 'MA60' THEN MA60
            WHEN @MA_Second = 'MA120' THEN MA120
            WHEN @MA_Second = 'MA240' THEN MA240
            ELSE NULL 
        END
    FROM StockTrading_TA
    WHERE StockCode = @Company
    ORDER BY date DESC;

    -- 游標宣告與使用
    DECLARE Cur CURSOR LOCAL FOR
        SELECT date, MA_First_Value, MA_Second_Value
        FROM #stock_data
        ORDER BY date DESC;

    OPEN Cur;
    FETCH NEXT FROM Cur INTO @Date, @MA_First_Value, @MA_Second_Value;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @MA_First_Value IS NOT NULL AND @MA_Second_Value IS NOT NULL
        BEGIN
            IF @MA_First_Value > @MA_Second_Value
            BEGIN
                IF @CurrentTrend IS NULL
                BEGIN
                    SET @CurrentTrend = 'Above';
                    SET @DayCount = 1;
                END
                ELSE IF @CurrentTrend <> 'Above'
                    BREAK;
                ELSE
                    SET @DayCount = @DayCount + 1;
            END
            ELSE IF @MA_First_Value < @MA_Second_Value
            BEGIN
                IF @CurrentTrend IS NULL
                BEGIN
                    SET @CurrentTrend = 'Under';
                    SET @DayCount = 1;
                END
                ELSE IF @CurrentTrend <> 'Under'
                    BREAK;
                ELSE
                    SET @DayCount = @DayCount + 1;
            END
            ELSE
            BEGIN
                -- 平行情況視為趨勢變化（可視需求處理）
                BREAK;
            END
        END

        FETCH NEXT FROM Cur INTO @Date, @MA_First_Value, @MA_Second_Value;
    END

    -- 結果輸出
    IF @CurrentTrend IS NOT NULL
    BEGIN
        SET @Result = @MA_First + ' ' + @CurrentTrend + ' ' + @MA_Second + ' ' + CAST(@DayCount AS VARCHAR) + ' Days';
    END
    ELSE
    BEGIN
        SET @Result = 'No clear trend';
    END

    -- 關閉與釋放游標
    CLOSE Cur;
    DEALLOCATE Cur;

    -- 刪除臨時表
    DROP TABLE #stock_data;
END

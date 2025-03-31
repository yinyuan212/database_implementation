
CREATE PROCEDURE AnalyzeStockDataByPercentage
    @MA1_col NVARCHAR(10),         -- MA_1 欄位名稱
    @MA2_col NVARCHAR(10),         -- MA_2 欄位名稱
    @date_input DATE,              -- 起始日期
    @duration_input INT,          -- 幾個交易日內 (X)
    @percentage_input FLOAT,      -- 百分比閾值 (Y%)
    @compare_type NVARCHAR(10)    -- 'above' or 'below'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @stock_code VARCHAR(10),
            @sqlText NVARCHAR(1000),
            @ParmDefinition NVARCHAR(500),
            @MA1_value REAL, @MA2_value REAL,
            @i INT;

    CREATE TABLE #stock_temp (
        id INT IDENTITY(1,1),
        date DATE NOT NULL,
        stock_code VARCHAR(10) NOT NULL,
        MA_1 REAL NOT NULL,
        MA_2 REAL NOT NULL
    );

    CREATE TABLE #stock (
        stock_code VARCHAR(10)
    );

    CREATE TABLE #FindDateResult (
        [date] DATE,
        [day_of_stock] INT
    );

    -- 取得連續 X 天交易日資料
    INSERT INTO #FindDateResult ([date], [day_of_stock])
    EXEC FindDate @startDate = @date_input,
                  @days = @duration_input,
                  @includeToday = 1,
                  @direction = 'forward';

    -- 游標處理每檔股票
    DECLARE Cur CURSOR LOCAL FOR
        SELECT DISTINCT StockCode FROM StockTrading_TA;
    OPEN Cur;
    FETCH NEXT FROM Cur INTO @stock_code;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        TRUNCATE TABLE #stock_temp;

        SET @sqlText = N'
            SELECT date, StockCode, ' + QUOTENAME(@MA1_col) + ' AS MA_1, ' + QUOTENAME(@MA2_col) + ' AS MA_2
            FROM StockTrading_TA
            WHERE date IN (SELECT date FROM #FindDateResult)
              AND StockCode = @stock_code
            ORDER BY date DESC';

        SET @ParmDefinition = N'@stock_code NVARCHAR(50)';

        INSERT INTO #stock_temp (date, stock_code, MA_1, MA_2)
        EXEC sp_executesql @sqlText, @ParmDefinition,
                           @stock_code = @stock_code;

        -- 逐日檢查是否符合百分比條件
        WHILE EXISTS (SELECT * FROM #stock_temp)
        BEGIN
            SELECT TOP 1 
                @i = id,
                @MA1_value = MA_1,
                @MA2_value = MA_2
            FROM #stock_temp ORDER BY id;

            IF @MA2_value <> 0
            BEGIN
                DECLARE @diff_percent FLOAT = (@MA1_value - @MA2_value) / ABS(@MA2_value) * 100;

                IF (@compare_type = 'above' AND @diff_percent >= @percentage_input)
                   OR (@compare_type = 'below' AND @diff_percent <= -@percentage_input)
                BEGIN
                    INSERT INTO #stock (stock_code) VALUES (@stock_code);
                    BREAK;
                END
            END

            DELETE FROM #stock_temp WHERE id = @i;
        END

        FETCH NEXT FROM Cur INTO @stock_code;
    END

    CLOSE Cur;
    DEALLOCATE Cur;

    SELECT * FROM #stock;

    DROP TABLE #stock_temp;
    DROP TABLE #stock;
    DROP TABLE #FindDateResult;
END

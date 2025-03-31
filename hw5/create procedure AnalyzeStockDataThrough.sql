CREATE PROCEDURE AnalyzeStockDataThrough
    @MA1_col NVARCHAR(10),
    @MA2_col NVARCHAR(10),
    @date_input DATE,
    @duration_input INT,
    @trend_input INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id INT,
            @stock_code VARCHAR(10),
            @sqlText NVARCHAR(1000),
            @ParmDefinition NVARCHAR(500),
            @MA1_value REAL, @MA2_value REAL,
            @MA1_prevalue REAL, @MA2_prevalue REAL,
            @i INT, @date DATE;

    -- 建立臨時表格
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

    -- 游標：逐一處理股票代號
    DECLARE Cur CURSOR LOCAL FOR
        SELECT DISTINCT stock_code FROM stock_data;
    OPEN Cur;
    FETCH NEXT FROM Cur INTO @stock_code;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        TRUNCATE TABLE #stock_temp;

        -- 動態 SQL：拼接欄位名稱
        SET @sqlText = N'
            SELECT date, stock_code, ' + QUOTENAME(@MA1_col) + ' AS MA_1, ' + QUOTENAME(@MA2_col) + ' AS MA_2
            FROM stock_data
            WHERE date IN (
                SELECT date FROM find_date(@date_input, @duration_input, 1, 1)
            )
            AND stock_code = @stock_code
            ORDER BY date DESC';

        SET @ParmDefinition = N'@date_input DATE, @duration_input INT, @stock_code NVARCHAR(50)';

        -- 執行動態 SQL 並寫入臨時表
        INSERT INTO #stock_temp (date, stock_code, MA_1, MA_2)
        EXEC sp_executesql @sqlText, @ParmDefinition,
                           @date_input = @date_input,
                           @duration_input = @duration_input,
                           @stock_code = @stock_code;

        -- 初始化前一日值
        SELECT TOP 1 
            @i = id,
            @MA1_prevalue = MA_1,
            @MA2_prevalue = MA_2
        FROM #stock_temp ORDER BY id;

        -- 循環比對趨勢
        WHILE EXISTS (SELECT * FROM #stock_temp)
        BEGIN
            SELECT TOP 1 
                @i = id,
                @MA1_value = MA_1,
                @MA2_value = MA_2
            FROM #stock_temp ORDER BY id;

            IF (@trend_input = 1 AND @MA1_prevalue < @MA2_prevalue AND @MA1_value > @MA2_value)
                OR (@trend_input = -1 AND @MA1_prevalue > @MA2_prevalue AND @MA1_value < @MA2_value)
            BEGIN
                INSERT INTO #stock (stock_code) VALUES (@stock_code);
                BREAK;
            END

            SET @MA1_prevalue = @MA1_value;
            SET @MA2_prevalue = @MA2_value;
            DELETE FROM #stock_temp WHERE id = @i;
        END

        FETCH NEXT FROM Cur INTO @stock_code;
    END

    CLOSE Cur;
    DEALLOCATE Cur;

    -- 輸出結果
    SELECT * FROM #stock;

    DROP TABLE #stock_temp;
    DROP TABLE #stock;
END

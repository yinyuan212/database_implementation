CREATE PROCEDURE CalculateMAS
    @StockCode VARCHAR(10)
AS
BEGIN
    -- 計算並更新 MA5（5 日移動平均線）
    UPDATE StockTrading_TA
    SET MA5 = (
        SELECT AVG(CAST([Close] AS DECIMAL(10, 2)))
        FROM StockTrading_TA t2
        WHERE t2.[date] <= StockTrading_TA.[date]
            AND t2.[date] > DATEADD(DAY, -5, StockTrading_TA.[date])
            AND t2.StockCode = @StockCode
    ),
    -- 計算並更新 MA10（10 日移動平均線）
    MA10 = (
        SELECT AVG(CAST([Close] AS DECIMAL(10, 2)))
        FROM StockTrading_TA t2
        WHERE t2.[date] <= StockTrading_TA.[date]
            AND t2.[date] > DATEADD(DAY, -10, StockTrading_TA.[date])
            AND t2.StockCode = @StockCode
    ),
    -- 計算並更新 MA20（20 日移動平均線）
    MA20 = (
        SELECT AVG(CAST([Close] AS DECIMAL(10, 2)))
        FROM StockTrading_TA t2
        WHERE t2.[date] <= StockTrading_TA.[date]
            AND t2.[date] > DATEADD(DAY, -20, StockTrading_TA.[date])
            AND t2.StockCode = @StockCode
    ),
    -- 計算並更新 MA60（60 日移動平均線）
    MA60 = (
        SELECT AVG(CAST([Close] AS DECIMAL(10, 2)))
        FROM StockTrading_TA t2
        WHERE t2.[date] <= StockTrading_TA.[date]
            AND t2.[date] > DATEADD(DAY, -60, StockTrading_TA.[date])
            AND t2.StockCode = @StockCode
    ),
    -- 計算並更新 MA120（120 日移動平均線）
    MA120 = (
        SELECT AVG(CAST([Close] AS DECIMAL(10, 2)))
        FROM StockTrading_TA t2
        WHERE t2.[date] <= StockTrading_TA.[date]
            AND t2.[date] > DATEADD(DAY, -120, StockTrading_TA.[date])
            AND t2.StockCode = @StockCode
    ),
    -- 計算並更新 MA240（240 日移動平均線）
    MA240 = (
        SELECT AVG(CAST([Close] AS DECIMAL(10, 2)))
        FROM StockTrading_TA t2
        WHERE t2.[date] <= StockTrading_TA.[date]
            AND t2.[date] > DATEADD(DAY, -240, StockTrading_TA.[date])
            AND t2.StockCode = @StockCode
    )
    WHERE StockCode = @StockCode;
END;
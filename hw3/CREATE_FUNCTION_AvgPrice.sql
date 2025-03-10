-- 查詢指定代號，日期區間內的平均股價
CREATE FUNCTION AvgPrice 
(
    @stockCode VARCHAR(50), 
    @startDate DATE, 
    @endDate DATE
)
RETURNS FLOAT
AS
BEGIN
    DECLARE @averagePrice FLOAT;

    SELECT @averagePrice = AVG(c)
    FROM stock_data
    WHERE stock_code = @stockCode 
      AND date BETWEEN @startDate AND @endDate;

    RETURN @averagePrice;
END;
GO



SELECT dbo.AvgPrice('2330', '2023-01-01', '2023-12-31') AS 'AvgPrice';
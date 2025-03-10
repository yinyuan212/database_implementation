-- 查詢指定代號，日期區間內的資料
CREATE PROCEDURE GetDataByDateRange 
    @stockCode VARCHAR(50), 
    @startDate DATE, 
    @endDate DATE
AS
BEGIN
    SELECT * 
    FROM stock_data 
    WHERE stock_code = @stockCode
      AND date BETWEEN @startDate AND @endDate;
END;


EXEC GetDataByDateRange @stockCode = '2330', @startDate = '2023-10-20', @endDate = '2023-12-30';
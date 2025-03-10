from datetime import datetime, timedelta
import pyodbc
from apscheduler.schedulers.blocking import BlockingScheduler
import requests
# 爬股票歷史資料(台灣50前10大成分股)

# MSSQL 設定
db_settings = {
    "host": "localhost,1433",
    "user": "student",
    "password": "student",
    "database": "stock_database",
    "driver": "ODBC Driver 17 for SQL Server"
}

# 建立排程器
scheduler = BlockingScheduler(timezone='Asia/Taipei')

# 記錄上次插入的股票數據
last_record = {}

def fetch_stock_data(date, stock_code):
    base_url = "https://www.twse.com.tw/exchangeReport/STOCK_DAY?response=json&date={date}&stockNo={stock_code}"
    url = base_url.format(date=date, stock_code=stock_code)

    try:
        response = requests.get(url)
        data = response.json()

        if "data" in data and len(data["data"]) > 0:
            return data["data"]  # 取得股票數據
    except Exception as e:
        print(f"❌ 無法獲取 {stock_code} 的數據: {e}")
    
    return None

def parse_stock_data(stock_data):
    """ 解析 API 數據，並確保所有 `REAL` 類型數據為 float """
    def safe_float(value):
        """ 將字串轉換為浮點數，若為 '-' 則回傳 0.0 """
        try:
            return float(value.replace(',', '').replace('-', '0'))
        except ValueError:
            return 0.0

    def convert_roc_to_gregorian(roc_date):
        """將民國日期轉換為西元日期格式"""
        # 將民國年份轉換為西元年份
        year, month, day = roc_date.split('/')
        year = int(year) + 1911  # 將年份轉換為西元年份

        # 轉換為 datetime 物件
        roc_date_obj = datetime.strptime(f"{year}/{month}/{day}", "%Y/%m/%d")
        formatted_date = roc_date_obj.strftime("%Y-%m-%d")  # 格式化為西元YYYY-MM-dd
        return formatted_date


    parsed_data = []
    for data in stock_data:
        trade_date = convert_roc_to_gregorian(data[0])
        trade_volume = int(data[1].replace(',', ''))  # 成交股數
        trade_value = safe_float(data[2])  # 成交金額
        open_price = safe_float(data[3])  # 開盤價
        high_price = safe_float(data[4])  # 最高價
        low_price = safe_float(data[5])  # 最低價
        close_price = safe_float(data[6])  # 收盤價
        price_change = safe_float(data[7])  # 漲跌價差
        trade_count = int(data[8].replace(',', ''))  # 成交筆數

        parsed_data.append({
            "trade_date": trade_date,
            "trade_volume": trade_volume,
            "trade_value": trade_value,
            "open_price": open_price,
            "high_price": high_price,
            "low_price": low_price,
            "close_price": close_price,
            "price_change": price_change,
            "trade_count": trade_count
        })

    return parsed_data

def daily_crawler(date):
    """ 每次偵測股票變動，只有數據變動時才寫入資料庫 """
    stock_list = [
        {"stock_code": "2330", "stock_name": "台積電"},
        {"stock_code": "2891", "stock_name": "中信金"},
        {"stock_code": "2883", "stock_name": "開發金"},
        {"stock_code": "2884", "stock_name": "玉山金"},
        {"stock_code": "2317", "stock_name": "鴻海"},
        {"stock_code": "2890", "stock_name": "永豐金"},
        {"stock_code": "2886", "stock_name": "兆豐金"},
        {"stock_code": "2887", "stock_name": "台新金"},
        {"stock_code": "2303", "stock_name": "聯電"},
        {"stock_code": "2885", "stock_name": "元大金"},
    ]   

    conn = pyodbc.connect(**db_settings)
    cursor = conn.cursor()

    today = datetime.today().strftime('%Y-%m-%d')

    for stock in stock_list:
        stock_code = stock["stock_code"]
        stock_name = stock["stock_name"]

        # 取得 API 數據
        stock_data = fetch_stock_data(date, stock_code)
        if not stock_data:
            print(f"⚠️ {stock_name}({stock_code}) 無法獲取數據，跳過")
            continue

        # 解析數據
        parsed_data = parse_stock_data(stock_data)

        for data in parsed_data:
            # 構造新數據
            new_record = (
                stock_code, data["trade_date"], "00:00:00", 
                data["trade_volume"], data["trade_value"], data["open_price"], data["high_price"], data["low_price"], data["close_price"], 
                data["price_change"], data["trade_count"]
            )

            print(f"📊 {stock_name}({stock_code}) 新數據: {new_record}")

            # 檢查是否與上次相同
            prev_record = last_record.get(stock_code, None)
            if prev_record and prev_record == new_record:
                print(f"🔄 {stock_name}({stock_code}) 數據未變動，跳過")
                continue  # 如果沒有變化，跳過寫入資料庫

            # 更新記錄
            last_record[stock_code] = new_record

            # **將資料寫入資料庫**
            cursor.execute(
                "INSERT INTO [dbo].[stock_data]" + 
                "([stock_code], [date], [time]," +
                "[tv], [t], [o], [h], [l], [c], [d], [v]," + 
                "[MA5], [MA10], [MA20], [MA60], [MA120], [MA240])" + 
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?," + 
                "NULL, NULL, NULL, NULL, NULL, NULL);",
                new_record
            )
            conn.commit()

    conn.close()

# 呼叫爬蟲
for i in range(2022, 2026):
    for j in range(12, 13):
        if j < 10:
            j = "0" + str(j)

        if i == 2025 and j >= 4:
            break
        print(str(i) + str(j))
        daily_crawler(date=str(i) + str(j) + "01")

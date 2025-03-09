import pyodbc
import requests
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.edge.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException

db_settings = {
    "host": "localhost,1433",
    "user": "student",
    "password": "student",
    "database": "stock_database",
    "driver": "ODBC Driver 17 for SQL Server"
}

# 儲存台灣50前10的陣列
taiwan50 = []

def find_Taiwan50():
    options = Options()
    options.add_argument("--headless")  # 執行時不顯示瀏覽器
    options.add_argument("--disable-notifications")  # 禁止瀏覽器的彈跳通知
    driver = webdriver.Edge(options=options)
    driver.get("https://www.cmoney.tw/etf/tw/0050/fundholding")
    
    try:
        # 等待網頁內容加載完成
        table = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, "table.cm-table__table"))
        )

        # 爬取表格內容
        rows = table.find_elements(By.TAG_NAME, "tr")

        # 取得台灣50前10大成分股的表格
        for row in rows[1:11]:
            cols = row.find_elements(By.TAG_NAME, "td")
            if cols:  # 確保不是標題列
                data = [col.text.strip() for col in cols]
                taiwan50.append(data[0])
                # print(data)
        
    except TimeoutException:
        print("網頁加載超時")
    finally:
        driver.quit()
    
    print("台灣50前10大成分股:", taiwan50)


def find_stock(url, start, end):
    try:
        conn = pyodbc.connect(**db_settings)
        cursor = conn.cursor()

        response = requests.get(url)
        soup = BeautifulSoup(response.text, "html.parser")
        
        # # 找到「股票」的表格
        table = soup.find("table", class_="h4")
        
        # 查找表格中「股票」資訊
        rows = table.find_all("tr")
        
        startIndex = 2
        endIndex = 0
        for row in rows[2:]:
            cols = row.find_all("td")
            if len(cols) > 0:
                if start in cols[0].get_text(strip=True):
                    startIndex = rows.index(row) + 1
                if end in cols[0].get_text(strip=True):
                    endIndex = rows.index(row)
                    break

        print(f"startIndex: {startIndex}, endIndex: {endIndex}")
        print(len(rows))    
        for row in rows[startIndex:endIndex]:
            cols = row.find_all("td")
            if len(cols) > 0:
                if end in cols[0].get_text(strip=True):
                    break

            stock_code = cols[0].get_text(strip=True).replace("\u3000", " ").split()[0]
            stock_name = cols[0].get_text(strip=True).replace("\u3000", " ").split()[1]
            type = cols[3].get_text(strip=True)
            category = cols[4].get_text(strip=True)
            isTaiwan50 = stock_code in taiwan50
            print(f"股票代碼: {stock_code}, 股票名稱: {stock_name}, 類型: {type}, 類別: {category}, 是否為台灣50前10: {isTaiwan50}")
        

            cursor.execute(
                "INSERT INTO stock_list (stock_code, name, type, category, isTaiwan50) VALUES (?, ?, ?, ?, ?)",
                (stock_code, stock_name, type, category, isTaiwan50)
            )
            conn.commit()
    
    except Exception as e:
        # print error message
        print(f"發生錯誤: {e}")
    finally:
        conn.close()
        print("結束")


# 執行爬蟲
find_Taiwan50()
find_stock("https://isin.twse.com.tw/isin/C_public.jsp?strMode=4", "股票", "特別股")
find_stock("https://isin.twse.com.tw/isin/C_public.jsp?strMode=2", "股票", "上市認購(售)權證")

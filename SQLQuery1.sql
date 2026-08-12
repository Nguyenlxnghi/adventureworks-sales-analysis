-- ============================================================
-- BƯỚC ĐẦU TIÊN: chọn đúng database trước khi chạy bất kỳ query nào
-- ============================================================
USE AdventureWorks2022;
GO


-- ============================================================
-- QUERY 1 (Dễ) — Tổng quan toàn bộ Sales
-- Mục tiêu: biết dataset có bao nhiêu đơn, doanh thu bao nhiêu, từ năm nào đến năm nào
-- ============================================================
SELECT
    COUNT(*)                        AS total_orders,
    ROUND(SUM(TotalDue), 0)         AS total_revenue,
    ROUND(AVG(TotalDue), 0)         AS avg_order_value,
    MIN(OrderDate)                  AS first_order_date,
    MAX(OrderDate)                  AS last_order_date
FROM Sales.SalesOrderHeader
WHERE OnlineOrderFlag = 0;  -- chỉ lấy đơn hàng của Sales team (không lấy online)

-- Kết quả mong đợi: ~3,806 orders, revenue ~$52 million, từ 2011 đến 2014


-- ============================================================
-- QUERY 2 (Dễ-Trung) — Doanh thu theo từng năm
-- Mục tiêu: thấy xu hướng tăng trưởng qua các năm
-- ============================================================
SELECT
    YEAR(OrderDate)                 AS order_year,
    COUNT(*)                        AS num_orders,
    ROUND(SUM(TotalDue), 0)         AS total_revenue,
    ROUND(AVG(TotalDue), 0)         AS avg_order_value
FROM Sales.SalesOrderHeader
WHERE OnlineOrderFlag = 0
GROUP BY YEAR(OrderDate)
ORDER BY order_year;

-- Chạy xong: nhìn vào cột total_revenue xem năm nào cao nhất


-- ============================================================
-- QUERY 3 (Trung) — Doanh thu theo Territory (khu vực)
-- Mục tiêu: khu vực nào bán chạy nhất — North America, Europe hay Pacific?
-- ============================================================
SELECT
    st.Name                         AS territory,
    st.[Group]                      AS region_group,
    COUNT(oh.SalesOrderID)          AS num_orders,
    ROUND(SUM(oh.TotalDue), 0)      AS total_revenue,
    ROUND(AVG(oh.TotalDue), 0)      AS avg_order_value
FROM Sales.SalesOrderHeader   oh
JOIN Sales.SalesTerritory     st  ON oh.TerritoryID = st.TerritoryID
WHERE oh.OnlineOrderFlag = 0
GROUP BY st.Name, st.[Group]
ORDER BY total_revenue DESC;

-- Đây là query đầu tiên có JOIN — kết hợp 2 bảng với nhau
-- Kết quả: thấy ngay territory nào dẫn đầu doanh thu


-- ============================================================
-- QUERY 4 (Trung-Khó) — Top sản phẩm theo doanh thu (JOIN 4 bảng)
-- Mục tiêu: category và sản phẩm nào sinh ra nhiều tiền nhất
-- ============================================================
SELECT
    pc.Name                         AS category,
    ps.Name                         AS subcategory,
    SUM(od.OrderQty)                AS units_sold,
    ROUND(SUM(od.LineTotal), 0)     AS total_revenue
FROM Sales.SalesOrderDetail         od
JOIN Sales.SalesOrderHeader         oh  ON od.SalesOrderID       = oh.SalesOrderID
JOIN Production.Product             p   ON od.ProductID          = p.ProductID
JOIN Production.ProductSubcategory  ps  ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory     pc  ON ps.ProductCategoryID  = pc.ProductCategoryID
WHERE oh.OnlineOrderFlag = 0
GROUP BY pc.Name, ps.Name
ORDER BY total_revenue DESC;

-- Query này JOIN 4 bảng — đây là kỹ năng SQL quan trọng nhất trong phỏng vấn!
-- Kết quả: Bikes sẽ chiếm phần lớn doanh thu


-- ============================================================
-- QUERY 5 (Khó) — Sales rep performance vs quota dùng Window Function
-- Mục tiêu: ai vượt quota, ai đang dưới target — dùng RANK()
-- ============================================================
SELECT
    CONCAT(pp.FirstName, ' ', pp.LastName)  AS sales_rep,
    st.Name                                 AS territory,
    ROUND(sp.SalesQuota, 0)                 AS quota,
    ROUND(SUM(oh.TotalDue), 0)              AS actual_sales,
    ROUND(SUM(oh.TotalDue) / sp.SalesQuota * 100, 1) AS quota_pct,
    CASE
        WHEN SUM(oh.TotalDue) >= sp.SalesQuota THEN 'Above quota'
        ELSE 'Below quota'
    END                                     AS performance_status,
    RANK() OVER (ORDER BY SUM(oh.TotalDue) DESC) AS sales_rank
FROM Sales.SalesPerson              sp
JOIN HumanResources.Employee        e   ON sp.BusinessEntityID  = e.BusinessEntityID
JOIN Person.Person                  pp  ON e.BusinessEntityID   = pp.BusinessEntityID
JOIN Sales.SalesTerritory           st  ON sp.TerritoryID       = st.TerritoryID
JOIN Sales.SalesOrderHeader         oh  ON sp.BusinessEntityID  = oh.SalesPersonID
WHERE sp.SalesQuota IS NOT NULL
GROUP BY pp.FirstName, pp.LastName, st.Name, sp.SalesQuota
ORDER BY actual_sales DESC;

-- RANK() là Window Function — kỹ năng nâng cao được hỏi nhiều trong phỏng vấn DA
-- Kết quả: thấy ranking từng sales rep, ai vượt quota, ai không
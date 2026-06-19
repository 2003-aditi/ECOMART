-- Create Sales History Table
CREATE TABLE saleshistory (
    order_id VARCHAR(50) PRIMARY KEY,
    sale_date DATE,
    product_id VARCHAR(50),
    category VARCHAR(50),
    unit_price DECIMAL(10, 2),
    units_sold INT,
    discount_applied DECIMAL(4, 2),
    revenue_generated DECIMAL(10, 2)
);

-- Create Inventory Log Table
CREATE TABLE inventorylog (
    date DATE,
    product_id VARCHAR(50),
    stock_on_hand INT,
    holding_cost_per_unit DECIMAL(10, 2),
    total_daily_holding_cost DECIMAL(10, 2),
    supplier_lead_time_days INT,
    restock_arrived BOOLEAN -- MySQL will automatically convert this to TINYINT(1)
);


WITH DailySales AS (
    -- Find average daily sales per product to estimate lost revenue
    SELECT 
        product_id,
        AVG(units_sold) AS avg_daily_sales,
        MAX(unit_price) AS unit_price
    FROM sales_history
    GROUP BY product_id
),
StockoutDays AS (
    -- Count how many days each product was at 0 stock per month
    SELECT 
        DATE_FORMAT(date, '%Y-%m') AS report_month,
        product_id,
        COUNT(*) AS stockout_days
    FROM inventory_log
    WHERE stock_on_hand = 0
    GROUP BY DATE_FORMAT(date, '%Y-%m'), product_id
)
-- Bring it all together to calculate the financial loss
SELECT 
    s.report_month,
    s.product_id,
    s.stockout_days,
    ROUND((s.stockout_days * d.avg_daily_sales * d.unit_price), 2) AS est_revenue_lost
FROM StockoutDays s
JOIN DailySales d ON s.product_id = d.product_id
ORDER BY s.report_month, est_revenue_lost DESC;


SELECT 
    date,
    product_id,
    supplier_lead_time_days,
    ROUND(AVG(supplier_lead_time_days) OVER (
        PARTITION BY product_id 
        ORDER BY date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS lead_time_7d_moving_avg
FROM inventory_log
ORDER BY product_id, date;
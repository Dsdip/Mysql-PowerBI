create database product_sales;

select * from discount_data;

-- project


WITH CTE AS (
    SELECT 
        pd.Product,
        pd.Category,
        pd.Brand,
        pd.Description,
        pd.Cost_Price,
        pd.Sale_Price,
        pd.`Image url`,
        ps.Date,
        ps.Customer_Type,
        ps.Discount_Band,
        ps.Units_Sold,
        (Sale_Price * Units_Sold) AS Total_Revenue,
        (Cost_Price * Units_Sold) AS Total_Cost,
        DATE_FORMAT(Date, '%M') AS Month,
        DATE_FORMAT(Date, '%Y') AS Year
    FROM product_data AS pd
    JOIN
        product_sales AS ps ON pd.Product_ID = ps.Product_ID
)
SELECT 
    a.*,
    d.Discount_Band,
    d.Discount,
    round(a.Total_Revenue - (a.Total_Revenue * (d.Discount / 100)),2) AS Total_Revenue_After_Discount
FROM CTE AS a
JOIN 
    discount_data AS d ON a.Month = d.Month;


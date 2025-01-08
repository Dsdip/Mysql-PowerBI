use product_sales;

select * from product_sales;
-- 1st
ALTER TABLE product_sales ADD COLUMN Formatted_Date DATE;


SET SQL_SAFE_UPDATES = 0;

SET SQL_SAFE_UPDATES = 1; 

UPDATE product_sales
SET Formatted_Date = STR_TO_DATE(Date, '%m/%d/%Y');



UPDATE product_sales 
SET Formatted_Date = STR_TO_DATE(Date, '%m/%d/%Y')
WHERE Date IS NOT NULL;

SELECT Date, Formatted_Date FROM product_sales;

ALTER TABLE product_sales DROP COLUMN Date;

ALTER TABLE product_sales CHANGE Formatted_Date Date DATE;



ALTER TABLE product_sales RENAME COLUMN Discoun_Band TO Discount_Band;


UPDATE discount_data
SET Discount_Band = UPPER(Discount_Band);

UPDATE discount_data
SET Discount_Band = CONCAT(UPPER(LEFT(Discount_Band, 1)), LOWER(SUBSTRING(Discount_Band, 2)));



SELECT DISTINCT Month FROM discount_data;

SELECT DISTINCT Discount_Band FROM product_sales;






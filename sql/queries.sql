--  creating indexes
CREATE INDEX "sales_product_id" on sales(product_id);
CREATE INDEX sales_stores ON sales(store_id);
CREATE INDEX sale_date ON sales(sale_date);

-- 1. Find the number of stores in each country.
SELECT country, count(*) as 'number_of_stores'
FROM stores
GROUP BY country; 

-- 2. Calculate the total number of units sold by each store.
SELECT B.store_name, sum(A.quantity) as 'units_sold' FROM sales A 
JOIN stores B on A.store_id= B.store_id
GROUP BY A.store_id 
ORDER BY units_sold DESC;

-- 3. Identify how many sales occurred in December 2023.
SELECT COUNT(*) as 'sales_count_2023_Dec' 
FROM sales
WHERE sale_date LIKE '%-12-2023';

-- 4. Determine how many stores have never had a warranty claim filed.
    SELECT COUNT(*) FROM stores WHERE store_id NOT IN (
        -- the stores which filed claim
        SELECT DISTINCT B.store_id
        FROM sales B
        JOIN warranty A 
        ON A.sale_id = B.sale_id
        WHERE B.store_id IS NOT NULL
        );

-- 5. Calculate the percentage of warranty claims marked as "Pending".

    SELECT ROUND(
        (SELECT Count(*)
            FROM warranty
            WHERE repair_status = 'Pending')*100.0/
        (SELECT Count(*)
            FROM warranty
        ),2) 
        as 'pending_percentage';

-- 6. Identify which store had the highest total units sold in the 2024.
    SELECT B.store_name, SUM(A.quantity) AS 'total_units_sold_2024'
    FROM sales A 
    JOIN stores B ON A.store_id = B.store_id  
    WHERE sale_date LIKE '%-2024'
    GROUP BY B.store_id
    ORDER BY SUM(A.quantity) DESC
    LIMIT 1;

-- 7. Count the number of unique products sold in the last year.

    SELECT COUNT(DISTINCT product_id) 
    FROM sales
    WHERE sale_date LIKE '%-2024'; 

-- 8. Find the average price of products in each category.
    SELECT B.category_name, AVG(A.price) AS 'avg_price' 
    FROM products A 
    JOIN category B on A.category_id = B.category_id 
    GROUP BY A.category_id;

-- 9. How many warranty claims were filed in JAN?
    SELECT COUNT(*) FROM warranty
    WHERE claim_date LIKE '2024-01%';

-- 10. For each store, identify the best-selling day based on highest quantity sold.
    WITH daily_totals AS (
        SELECT store_id, sale_date, SUM(quantity) AS total_quantity
        FROM sales
        GROUP BY store_id, sale_date
    )
    SELECT store_id, sale_date, total_quantity
    FROM daily_totals d
    WHERE total_quantity = (
        SELECT MAX(total_quantity)
        FROM daily_totals
        WHERE store_id = d.store_id
        ORDER BY store_id
    );

-- 11. Identify the least selling product in each country for each year based on total units sold.

    WITH product_yearly_sales AS (
        SELECT 
            st.country,
            substr(sa.sale_date, 7, 4) AS year,  -- extract YYYY FROM DD-MM-YYYY
            sa.product_id,
            SUM(sa.quantity) AS total_quantity
        FROM sales sa
        JOIN stores st ON sa.store_id = st.store_id
        GROUP BY st.country, year, sa.product_id
    )
    SELECT p.country, p.year, pr.product_name, p.total_quantity
    FROM product_yearly_sales p
    JOIN products pr ON p.product_id = pr.product_id
    WHERE p.total_quantity = (
        SELECT MIN(total_quantity)
        FROM product_yearly_sales
        WHERE country = p.country
          AND year = p.year
    );

-- 12. Calculate how many warranty claims were filed within 180 days of a product sale.
    SELECT COUNT(*) AS claims_within_180_days
    FROM warranty w
    JOIN sales s 
        ON w.sale_id = s.sale_id
    WHERE 
        JULIANDAY(w.claim_date) -
        JULIANDAY(
            substr(s.sale_date, 7, 4) || '-' || 
            substr(s.sale_date, 4, 2) || '-' || 
            substr(s.sale_date, 1, 2)
        )
        <= 180;

-- 13. Determine how many warranty claims were filed for products launched in the last two years.
    SELECT COUNT(*) AS total_claims
    FROM warranty w
    JOIN sales s ON w.sale_id = s.sale_id
    JOIN products p ON s.product_id = p.product_id
    WHERE CAST(substr(p.launch_date, 7, 4) AS INTEGER) >= strftime('%Y', 'now') - 2;


-- 14. List the months in the last three years WHERE sales exceeded 20,000 units in the USA.
    SELECT 
        substr(s.sale_date, 4, 2) AS month,
        substr(s.sale_date, 7, 4) AS year,
        SUM(s.quantity) AS total_units
    FROM sales s
    JOIN stores st ON s.store_id = st.store_id
    WHERE 
        st.country = 'United States'
        AND CAST(substr(s.sale_date, 7, 4) AS INTEGER) >= 2022
    GROUP BY year, month
    HAVING total_units > 20000
    ORDER BY year, month;

-- select DISTINCT COUNTRY FROM stores;

-- 15. Identify the product category with the most warranty claims filed in the last two years.
    egory_name, count(claim_id)
    y w JOIN sales s on w.sale_id = s.sale_id
    s p on p.product_id = s.product_id
    y c on p.category_id=c.category_id

    (s.sale_date, 7, 4) in ('2024','2023')
    ategory_id
    nt(claim_id) desc
    -- LIMIT 1 ;

-- 16. Determine the percentage chance of receiving warranty claims after each purchase for each country.
    -- using a CTE (temporary table in query)
    WITH total_sales AS (
        SELECT st.country, COUNT(*) AS total_sales
        FROM sales s
        JOIN stores st ON s.store_id = st.store_id
        GROUP BY st.country
    )
    SELECT 
        ts.country,
        COUNT(w.claim_id) AS total_claims,
        ts.total_sales,
        ROUND(COUNT(w.claim_id) * 100.0 / ts.total_sales, 2) AS claim_percentage
    FROM total_sales ts
    LEFT JOIN sales s ON s.store_id IN (
        SELECT store_id FROM stores WHERE country = ts.country
    )
    LEFT JOIN warranty w ON w.sale_id = s.sale_id
    GROUP BY ts.country
    ORDER BY claim_percentage DESC;

-- 17. Analyze the year-by-year growth ratio for each store.
    WITH ranked_sales AS (
        SELECT
            store_id,
            CAST(substr(sale_date, 7, 4) AS INTEGER) AS year,
            SUM(quantity) AS total_sales,
            ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY CAST(substr(sale_date, 7, 4) AS INTEGER)) AS rn
        FROM sales
        GROUP BY store_id, year
    )
    SELECT 
        a.store_id,
        a.year,
        a.total_sales,
        b.total_sales AS prev_year_sales,
        ROUND(((a.total_sales - b.total_sales) * 100.0 / b.total_sales), 2) AS growth_rate_percent
    FROM ranked_sales a
    INNER JOIN ranked_sales b
        ON a.store_id = b.store_id
       AND a.rn = b.rn + 1
    ORDER BY a.year desc, growth_rate_percent desc;

-- 18. Calculate the correlation between product price and warranty claims for products sold in the last five years, segmented by price range.
    SELECT 
        CASE 
            WHEN P.price <500 THEN 'LESS THAN 500'
            WHEN P.price BETWEEN 500 AND 1000 THEN 'BETWEEN 500 - 1000'
            WHEN P.price BETWEEN 1000 AND 1500 THEN 'BETWEEN 1000 - 1500'
            ELSE '>1500'
        END AS 'price_range',
        COUNT(*)
    FROM warranty w 
    JOIN sales s on w.sale_id= s.sale_id 
    JOIN products P on s.product_id= P.product_id
    GROUP BY price_range
    ORDER BY COUNT(*) desc;

-- 19. Identify the top 5 stores with the highest percentage of "Completed" claims relative to total claims filed.
    WITH completed as(
        select s.store_id, COUNT(*) as 'claims_completed'
    FROM warranty w 
    JOIN sales s on s.sale_id = w.sale_id
    WHERE repair_status = 'Completed'
    GROUP BY 1)

    SELECT st.store_name, ROUND(c.claims_completed*100.00/count(*),2) as 'percent_completed_claims_per_store', c.claims_completed 
    FROM warranty w 
    JOIN sales s on s.sale_id=w.sale_id
    JOIN completed c on s.store_id=c.store_id
    JOIN stores st on s.store_id= st.store_id
    GROUP BY 1
    ORDER BY c.claims_completed*100.00/count(*) desc, c.claims_completed DESC
    LIMIT 5;

-- 20. Write a query to calculate the monthly running total of sales for each store over the past four years and compare trends during this period.
    WITH monthly_sales AS (
        SELECT
            store_id,
            substr(sale_date, 4, 2) AS month,
            CAST(substr(sale_date, 7, 4) AS INTEGER) AS year,
            SUM(quantity) AS total_sales
        FROM sales
        WHERE CAST(substr(sale_date, 7, 4) AS INTEGER) >= strftime('%Y', 'now') - 4
        GROUP BY store_id, year, month
    )
    SELECT
        store_id,
        year,
        month,
        total_sales,
        SUM(total_sales) OVER (
            PARTITION BY store_id
            ORDER BY year, month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total
    FROM monthly_sales
    ORDER BY store_id, year, month;

     

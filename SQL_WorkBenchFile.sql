USE amazon;
show tables;

#Check the Columns and its  values in amazon table;
use amazon;
SELECT * FROM amazon;

#Check the Columns and its Datatypes
select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='amazon';
# Convert Datatypes of Date & time Columns
ALTER TABLE amazon MODIFY COLUMN Date DATE;
ALTER TABLE amazon MODIFY COLUMN Time time;

# Date format chaged
SET SQL_SAFE_UPDATES = 0;
update amazon SET Date=date_format(Date,'%Y/%m/%d');

# Create new column for Month, Date, Hour
ALTER TABLE amazon ADD COLUMN timeofday  int;
UPDATE amazon SET timeofday=hour(Time);

ALTER TABLE amazon ADD COLUMN dayname varchar(255);
UPDATE amazon SET dayname=dayname(Date);

ALTER TABLE amazon ADD COLUMN monthname varchar(255);
UPDATE amazon SET monthname=monthname(Date);

ALTER TABLE amazon ADD COLUMN weekdayno int;
UPDATE amazon SET weekdayno=weekday(Date);
SET SQL_SAFE_UPDATES = 1;
select * from amazon;


# Checking for Null Values - No Null values found
SELECT * FROM amazon WHERE `Product line` IS NULL OR `Unit price` IS NULL OR Quantity IS NULL OR `Total` IS NULL 
OR Payment IS NULL OR cogs IS NULL OR `gross margin percentage` IS NULL OR `gross income` IS NULL OR `Rating` IS NULL;



#1.	What is the count of distinct cities in the dataset?
SELECT count(distinct City) as distinct_city_count from amazon ;						

#2.	For each branch, what is the corresponding city?
SELECT distinct(Branch), City from amazon order by Branch;

#3.	What is the count of distinct product lines in the dataset?
SELECT count(distinct `Product line`) as distinct_productline_count from amazon;

#4.	Which payment method occurs most frequently?
WITH paymode as (
	SELECT Payment, count(*) as Paymode_count 
		from amazon group by Payment)
	SELECT Payment FROM paymode 
		Where Paymode_count = (SELECT MAX(Paymode_count) FROM paymode);

# 5.	Which product line has the highest sales?
With Total_Prod_Sales as (
SELECT `Product line`, sum(Total) as Product_Sale 
	FROM amazon group by `Product line`)
SELECT `Product line` FROM Total_Prod_Sales WHERE Product_Sale 
	IN (SELECT MAX(Product_Sale) 
    FROM Total_Prod_Sales);

#6.	How much revenue is generated each month?
SELECT monthname as Month_Name, 
	sum(`gross income`) as Total_Income_Monthly 
	from amazon group by Month_Name;

#7.	In which month did the cost of goods sold reach its peak?

with M_cogs as (
SELECT monthname as Month_Name, sum(cogs) as TotalCost_OfSoldGoods 
	from amazon group by Month_Name)
SELECT Month_Name from M_cogs 
	WHERE TotalCost_OfSoldGoods = (SELECT MAX(TotalCost_OfSoldGoods) FROM M_cogs); 

#8.	Which product line generated the highest revenue?

With Prod_Wise_Rev as (
SELECT `Product line`, sum(`gross income`) as Product_Revenue 
	FROM amazon group by `Product line`)
SELECT `Product line` FROM  Prod_Wise_Rev 
	WHERE Product_Revenue IN (SELECT MAX(Product_Revenue) 
	FROM Prod_Wise_Rev);

#9.	In which city was the highest revenue recorded?

WITH cgr as (SELECT City, sum(`gross income`) as City_Gross_Income 
	from amazon group by City)
SELECT City from cgr 
	where City_Gross_Income IN (SELECT max(City_Gross_Income) from cgr);

#10.	Which product line incurred the highest Value Added Tax?

SELECT `Product line` FROM(
SELECT `Product line`, sum(`Tax 5%`) as Tax 
	FROM amazon group by `Product line` 
	order by Tax desc limit 1) as ht;

#11.For each product line, add a column indicating "Good" if its sales are above average, otherwise "Bad."

SELECT Product_Line,
Case 
When prod_Avg_Sale>All_Avg_Sale THEN "GOOD"
ELSE "BAD" END AS "GOOD/BAD_Rating"
FROM(
SELECT distinct(`Product line`) as Product_Line, 
avg(Total) over(partition by `Product line`) as prod_Avg_Sale,
avg(Total) over() as All_Avg_Sale from amazon 
) as Sale;


#12.Identify the branch that exceeded the average number of products sold.

SELECT Branch 
FROM( 
	SELECT distinct(Branch), 
	avg(Quantity) over(partition by  Branch) as prod_Avg_Sale,
	avg(Quantity) over() as All_Prod_Avg_Sale from amazon
	) as Branch_Sale 
	WHERE prod_Avg_Sale>All_Prod_Avg_Sale;

#13.	Which product line is most frequently associated with each gender?

SELECT Gender, `Product line`, purchase_count
FROM (
    SELECT Gender, `Product line` , COUNT(*) AS purchase_count,
    RANK() OVER (PARTITION BY Gender ORDER BY COUNT(*) DESC) AS prod_rank
    FROM amazon GROUP BY Gender, `Product line`
) AS gender_product_counts
WHERE prod_rank = 1;

#14.	Calculate the average rating for each product line.

SELECT distinct(`Product line`), avg(Rating) over(partition by `Product line`) as Avg_Rating_each_Product 
	from amazon 
		order by Avg_Rating_each_Product desc;

#15.	Count the sales occurrences for each time of day on every weekday.
SELECT dayname, count(*) as sales_occurrences 
	from amazon 
    group by dayname;
SELECT dayname, timeofday, count(*) as sales_occurrences 
	from amazon group by dayname, timeofday 
	order by dayname;

#16.	Identify the customer type contributing the highest revenue.

SELECT `Customer type` FROM(
SELECT `Customer type`, sum(`gross income`) as customer_wise_revenue from amazon group by `Customer type`
order by customer_wise_revenue desc LIMIT 1) as sq1;

# 17.	Determine the city with the highest VAT percentage.
SELECT City, (sum(`Tax 5%`)/sum(Total))*100 as VAT_percentage 
	from amazon group by  City;

with vat as(
SELECT City, (sum(`Tax 5%`)/sum(Total))*100 as VAT_percentage 
	from amazon group by  City)

SELECT City from vat 
	where VAT_percentage IN (SELECT MAX(VAT_percentage) FROM vat);

#18.	Identify the customer type with the highest VAT payments.

with customer_vat as(
SELECT `Customer type`, sum(`Tax 5%`) as customer_VAT_amount 
	from amazon group by  `Customer type`)
SELECT `Customer type` from customer_vat 
	where customer_VAT_amount IN (SELECT MAX(customer_VAT_amount) 
		FROM customer_vat);

#19.	What is the count of distinct customer types in the dataset?
SELECT count(distinct(`Customer type`)) as Distinct_Customer_Types from amazon;

#20.	What is the count of distinct payment methods in the dataset?
SELECT count(distinct(Payment)) as Distinct_Payment_Types from amazon;

#21.	Which customer type occurs most frequently?

SELECT `Customer type` FROM amazon
GROUP BY `Customer type` HAVING COUNT(*) = 
(
    SELECT MAX(type_count) FROM (SELECT COUNT(*) AS type_count FROM amazon
        GROUP BY `Customer type`
    ) AS cust_type_counts
);

#22.	Identify the customer type with the highest purchase frequency.

SELECT distinct(monthname), `Customer type`, weekdayno,  dayname,
count(*) over(partition by monthname, `Customer type` order by weekdayno) as purchase_cnt FROM amazon;

SELECT distinct(monthname), `Customer type`, count(*) as total_orders
FROM amazon group by monthname, `Customer type` order by monthname;

#23.	Determine the predominant gender among customers.

SELECT Gender, count(*) as gend_purchase_freq from amazon group by Gender;
SELECT Gender, sum(Total) as gend_purchase_Value from amazon group by Gender;

#24.	Examine the distribution of genders within each branch.

SELECT Branch, Gender, gender_count, gender_rank
FROM (
    SELECT Branch, Gender, COUNT(*) AS gender_count,
           RANK() OVER (PARTITION BY Branch ORDER BY COUNT(*) DESC) AS gender_rank
    FROM amazon
    GROUP BY Branch, Gender
) AS gender_dist order by gender_rank;

#25.	Identify the time of day when customers provide the most ratings.

SELECT distinct(timeofday),
count(Rating) over(partition by timeofday) as No_of_Ratings from amazon order by No_of_Ratings desc limit 5;

#26.	Determine the time of day with the highest customer ratings for each branch.

SELECT Branch, timeofday, avg_rating
FROM (
    SELECT Branch, timeofday, AVG(Rating) AS avg_rating,
	RANK() OVER (PARTITION BY Branch ORDER BY AVG(Rating) DESC) AS rating_rank
    FROM amazon
    GROUP BY Branch, timeofday
) AS rating_distribution WHERE rating_rank = 1;

#27.	Identify the day of the week with the highest average ratings.

SELECT dayname, avg_rating, rating_rank
FROM (
    SELECT dayname, AVG(Rating) AS avg_rating,
          RANK() OVER (ORDER BY AVG(Rating) DESC) AS rating_rank
    FROM amazon
    GROUP BY dayname
) AS rating_distribution ;


#28.	Determine the day of the week with the highest average ratings for each branch.

SELECT Branch, dayname, avg_rating, rating_rank
FROM (
    SELECT Branch, dayname, AVG(Rating) AS avg_rating,
          DENSE_RANK() OVER (partition by Branch ORDER BY AVG(Rating) DESC) AS rating_rank
    FROM amazon
    GROUP BY Branch, dayname
) AS rating_distribution WHERE rating_rank=1;
















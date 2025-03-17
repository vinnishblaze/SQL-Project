select * from dim_customer;
select * from dim_product;
select * from fact_sales_monthly;

-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
with cte as
(select distinct market, 
sum(case when m.fiscal_year=2020 then sold_quantity*gross_price end) as Sales2020,
sum(case when m.fiscal_year=2021 then sold_quantity*gross_price end) as Sales2021
from dim_customer c join fact_sales_monthly m using (customer_code)
join fact_gross_price p using (product_code)
 where customer='Atliq Exclusive' and region='APAC' group by market order by Sales2021 desc)
select market, ((Sales2021-Sales2020)/Sales2020)*100 as percentage_chg from cte order by percentage_chg desc
;

with cte as
(select distinct market, 
sum(case when fiscal_year=2020 then sold_quantity end) as Sales2020,
sum(case when fiscal_year=2021 then sold_quantity end) as Sales2021
from dim_customer c join fact_gross_price m using (customer_code) where customer='Atliq Exclusive' and region='APAC' group by market order by Sales2021 desc)
select market, ((Sales2021-Sales2020)/Sales2020)*100 as percentage_chg from cte order by percentage_chg desc
;

/* What is the percentage of unique product increase in 2021 vs. 2020? 
The final output contains these fields,unique_products_2020,unique_products_2021,percentage_chg */
with cte as 
(select
count( distinct case when fiscal_year=2020 then product_code end) as unique_products_2020,
count(distinct case when fiscal_year=2021 then product_code end) as unique_products_2021
from fact_sales_monthly)
select unique_products_2020,unique_products_2021,
((unique_products_2021-unique_products_2020)/unique_products_2020)*100 as percentage_chg  from cte 
;


with cte as 
(select division,
count( distinct case when fiscal_year=2020 then product_code end) as unique_products_2020,
count(distinct case when fiscal_year=2021 then product_code end) as unique_products_2021
from fact_sales_monthly s join dim_product p using (product_code) group by division)
select division,unique_products_2020,unique_products_2021,
((unique_products_2021-unique_products_2020)/unique_products_2020)*100 as percentage_chg  from cte 
;


select division,count(product_code) from dim_product where product_code not in 
(select product_code from fact_sales_monthly where fiscal_year = 2021) group by division;



/*Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count*/

select segment,count(*) as product_count from dim_product group by segment order by count(*) desc;

with cte as
(select segment, 
count( distinct case when fiscal_year=2020 then product_code end) as unique_products_2020,
count(distinct case when fiscal_year=2021 then product_code end) as unique_products_2021
from dim_product p join fact_sales_monthly m using (product_code) 
group by segment order by count(distinct product_code) desc)
select segment,unique_products_2020,unique_products_2021,unique_products_2021-unique_products_2020 as diff from cte order by diff desc 
;

/* Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference */

with cte as
(select segment,
count(distinct case when fiscal_year=2020 then product_code end) as product_count_2020,
count(distinct case when fiscal_year=2021 then product_code end) as  product_count_2021
from dim_product p join fact_sales_monthly f using (product_code)  group by segment)
select segment,product_count_2020,product_count_2021,
product_count_2021-product_count_2020 as difference,
((product_count_2021-product_count_2020)/product_count_2020)*100 as "difference%" from cte
order by ((product_count_2021-product_count_2020)/product_count_2020)*100 desc
;

/*Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost */

with cte as (select f.product_code,p.product,f.manufacturing_cost,
rank() over (order by f.manufacturing_cost asc) as low_rnk,
rank() over (order by f.manufacturing_cost desc) as high_rnk
from fact_manufacturing_cost f join dim_product p using (product_code) 
order by f.manufacturing_cost desc) select product_code as "Product Code",product as Product,manufacturing_cost as "Manufacturing Cost" from cte where low_rnk =1 or high_rnk =1;


/*Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage*/

select i.customer_code as "Customer Code",c.customer as Customer,avg(i.pre_invoice_discount_pct)*100 as "Average Discount Percentage"
 from fact_pre_invoice_deductions i 
join dim_customer c using(customer_code) 
where i.fiscal_year=2021 and c.market='India'
 group by i.customer_code,c.customer order by avg(i.pre_invoice_discount_pct)*100 desc limit 5;
 
 /*7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount*/

select month(date) as Month,s.fiscal_year as Year,sum(sold_quantity*gross_price) as gross_sales_amount
from fact_sales_monthly s
join fact_gross_price g using (product_code)
join dim_customer c using (customer_code) where c.customer='Atliq Exclusive' group by s.fiscal_year,Month order by s.fiscal_year,Month asc;

select month(date) as fiscal_m,
sum(case when s.fiscal_year=2020 then sold_quantity*gross_price end) as 2020_sales,
sum(case when s.fiscal_year=2021 then sold_quantity*gross_price end) as 2021_sales
from fact_sales_monthly s
join fact_gross_price g using (product_code)
join dim_customer c using (customer_code) where c.customer='Atliq Exclusive' group by fiscal_m order by fiscal_m asc;

with cte as
(select month(date) as fiscal_m,
sum(case when s.fiscal_year=2020 then sold_quantity*gross_price end) as 2020_sales,
sum(case when s.fiscal_year=2021 then sold_quantity*gross_price end) as 2021_sales
from fact_sales_monthly s
join fact_gross_price g using (product_code)
join dim_customer c using (customer_code) where c.customer='Atliq Exclusive' group by fiscal_m order by fiscal_m asc)
select fiscal_m,2020_sales,2021_sales,((2021_sales-2020_sales)/2020_sales)*100 as diff from cte order by diff desc;

with cte as(
select month(date) as fiscal_m,s.fiscal_year as fiscal_y,sum(sold_quantity*gross_price) as gross_sales_amount
from fact_sales_monthly s
join fact_gross_price g using (product_code)
join dim_customer c using (customer_code) where c.customer='Atliq Exclusive' group by fiscal_y,fiscal_m
), report as (select fiscal_y,fiscal_m,gross_sales_amount,rank() over (partition by fiscal_y order by gross_sales_amount desc) as rnk_desc,
rank() over (partition by fiscal_y order by gross_sales_amount asc) as rnk_asc
 from cte) select fiscal_y,fiscal_m,gross_sales_amount from report where rnk_desc <=3 or rnk_asc <=3 order by fiscal_y,gross_sales_amount desc
; 

/* In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity */

select concat('Q',quarter(date)) as Quarter,sum(sold_quantity) as quantity_sold from fact_sales_monthly
where fiscal_year=2020 group by Quarter order by quantity_sold desc
;


/*Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage */

with sum_d as
(select g.fiscal_year,sum(sold_quantity*gross_price) as sum_sales from fact_sales_monthly s
join fact_gross_price g using(product_code) where g.fiscal_year=2021 group by g.fiscal_year)
select c.channel,sum(sold_quantity*gross_price)/1000000 as gross_sales_mln,(sum(sold_quantity*gross_price)/sum_sales)*100 as "Percentage" from fact_sales_monthly s
join fact_gross_price g using(product_code)
join dim_customer c using (customer_code)
join sum_d t on t.fiscal_year=g.fiscal_year
 where g.fiscal_year=2021 group by c.channel;
 
 select c.channel,sum(sold_quantity*gross_price)/1000000 as gross_sales_mln,(sum(sold_quantity*gross_price)/sum_sales)*100 as "Percentage" from fact_sales_monthly s
join fact_gross_price g using(product_code)
join dim_customer c using (customer_code)
where g.fiscal_year=2021 group by c.channel;


/*Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
product
total_sold_quantity
rank_order */


with cte as(
select p.division,p.product_code,p.product,sum(s.sold_quantity) as total_quantity_sold,
rank() over (partition by p.division order by sum(s.sold_quantity) desc) as rnk
from dim_product p join fact_sales_monthly s using (product_code) 
where fiscal_year=2021
group by division,product_code,product)
select division,product_code,product,total_quantity_sold,rnk as rnk_order from cte where rnk <=3
;

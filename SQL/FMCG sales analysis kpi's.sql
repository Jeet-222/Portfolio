--Product Sales Growth Rate:
--Evaluate the growth of individual products or categories, identifying trends and demand shifts.

WITH kpi AS (
    SELECT
        product,
        SUM(CASE WHEN EXTRACT(YEAR FROM date_of_order) = 2023 THEN sales ELSE 0 END) AS cp_sales,
        SUM(CASE WHEN EXTRACT(YEAR FROM date_of_order) = 2022 THEN sales ELSE 0 END) AS pp_sales
    FROM fmcg
    GROUP BY product
)
SELECT
    product,
	cp_sales,
	pp_sales,
    ((cp_sales - pp_sales) / pp_sales * 100) AS product_sales_growth,
	(case when ((cp_sales - pp_sales) / pp_sales * 100)>0 then 'profit' else 'loss' end)as p_or_l
FROM kpi
order by product_sales_growth desc;



--Category Market Share.
--Determine the dominance of product categories within the overall sales mix, 
--guiding inventory and marketing strategies.

with kpi2 as (SELECT category,
sum(sales) as c_sales,
sum(sum(sales)) over() as total_sales
from fmcg
group by category)
select category,
c_sales/total_sales*100 as cat_mrkt_share 
from kpi2
order by cat_mrkt_share desc;


--Profit Margin per Product
--Assess the profitability of each product, informing pricing and cost management decisions.
select product,
(sum(sales)/sum(total_cost_price))*100 as profit_margin
from fmcg
group by product
order by profit_margin desc;


--Discount Effectiveness
--Measure the impact of discount strategies on sales volumes and profitability for different products.

with kpi4 as(select sum(case when discount>0 then sales else 0 end)as sales_with_dis,
sum(case when discount=0 then sales else 0 end)as sales_without_dis
from fmcg)
SELECT 
(sales_with_dis-sales_without_dis)/sales_without_dis*100 as Discount_Effectiveness
from kpi4;


--Average Sales per Product
--Understand the average revenue contribution of each product, identifying high and low performers.

select product,
sum(sales)as total_sales,
sum(quantity)as total_quantity,
sum(sales)/sum(quantity) as avg_sales
from fmcg
group by product
order by avg_sales desc;


--Customer Reach Index
--Gauge the popularity and reach of each product among the customer base, 
--indicating market penetration and customer preference.
with kpi5 as (select product,
count(order_id) as num_of_prod_order,
sum(count(order_id)) over() as total_orders
from fmcg
group by product)
select product,
round(num_of_prod_order/total_orders*100,2) as most_reached_prod 
from kpi5
order by most_reached_prod desc;



--EDA

--Q1. What is the count of managers at the region, state and city level?
SELECT count(distinct regional_sales_manager) total_region_managers,
count(distinct state_sales_manager) total_state_managers,
count(distinct city_sales_manager )total_city_managers 
from fmcg;


--Q2. How are Regional sales managers performing in sales and profit?
SELECT regional_sales_manager,
region,
(sum(sales)/sum(sum(sales)) over())*100 as total_sales_p,
(sum(profit)/sum(sum(profit)) over())*100 as total_profit_p
from fmcg
group by regional_sales_manager,region
order by total_profit_p desc;


--Q3. Who are top performing state and city sales managers under Rohan Sharma?
with state_m as (												----
select
	regional_sales_manager,
	state_sales_manager,
	sum(sales) as total_sales_s,
	dense_rank() over(order by sum(sales) desc) as s_rank
	from fmcg
	group by state_sales_manager,regional_sales_manager
	having regional_sales_manager = 'Rohan Sharma' limit 1),
city_m as(														----
select 
	city_sales_manager,
	sum(sales) as total_sales_c,
	dense_rank() over(order by sum(sales) desc) c_rank
	from fmcg
	group by city_sales_manager,regional_sales_manager
	having regional_sales_manager = 'Rohan Sharma' limit 1)
select * from state_m as s inner join city_m as c on s.s_rank=c.c_rank; ----



--Q4. What are the sales under Rohan Sharma by store type?
select 
regional_sales_manager,
store_type,
sum(sales) as total_sales,
dense_rank() over(order by sum(sales) desc) as rank_by_sales
from fmcg
group by store_type,regional_sales_manager
having regional_sales_manager='Rohan Sharma';



--Q.5. Who are the top performing sales reps in sales and profit?
SELECT sales_rep,
sum(sales) as total_sales,
dense_rank() over(order by sum(sales) desc) as rank_by_sales,
sum(profit) as total_profit,
dense_rank() over(order by sum(profit)desc) as rank_by_profit
from fmcg
group by sales_rep
order by total_sales desc;



--Q1. What is our overall sales and monthly sales trend in 2023?

--overall sales of 2023
select 
SUM(case when extract(year from date_of_order)=2023 then sales else 0 END) as overall_sales 
from fmcg;

--sales trend of 2023
with 
year_2023 as (select 
	extract(year from date_of_order) AS year_2023,
	to_char(date_of_order,'Mon') as months,
	sum(sales) as overall_sales
	from fmcg
	group by to_char(date_of_order,'Mon'),extract(year from date_of_order),EXTRACT(MONTH FROM date_of_order)
	having extract(year from date_of_order)=2023
	order by EXTRACT(MONTH FROM date_of_order)),
year_2022 as (
select 
extract(year from date_of_order) AS year_2022,
	to_char(date_of_order,'Mon') as months,
	sum(sales) as overall_sales
	from fmcg
	group by to_char(date_of_order,'Mon'),extract(year from date_of_order),EXTRACT(MONTH FROM date_of_order)
	having extract(year from date_of_order)=2022
	order by EXTRACT(MONTH FROM date_of_order))
select 
cy.months as Months_o,
cy.overall_sales as cy_sales,
py.overall_sales as py_sales,
((cy.overall_sales/py.overall_sales)*100)-100 as percent_diff_with_py
from year_2023 cy inner join year_2022 py
on cy.months=py.months;
--each month diffrence comparing to previous month
with cte as(select 
extract(year from date_of_order) AS year_2023,
to_char(date_of_order,'Mon') as months,
sum(sales) as overall_sales,
lag(to_char(date_of_order,'Mon'),1) over(order by EXTRACT(MONTH FROM date_of_order)) as lag_mon,
lag(sum(sales),1) over(order by EXTRACT(MONTH FROM date_of_order)) as lag_sales
from fmcg
group by to_char(date_of_order,'Mon'),extract(year from date_of_order),EXTRACT(MONTH FROM date_of_order)
having extract(year from date_of_order)=2023
order by EXTRACT(MONTH FROM date_of_order))
select months,
overall_sales,
round(case when lag_sales>0 then (overall_sales-lag_sales)/lag_sales*100 else 0 end,2) as dif_cm_vs_py
from cte;




--Q2. How are our categories performing by states in sales?
select 
state,
category,
sum(sales) as total_sales
from fmcg
group by state,category
order by state asc,total_sales desc;


--Q3. What is our overall profit? What is our profit by product and category?

--overall profit
select sum(profit)as overall_profit from fmcg;
--profit by products
select 
distinct product,
sum(profit) over(partition by product) as total_profit
from fmcg
order by total_profit desc;
--profit by category
select 
distinct category,
sum(profit) over(partition by category) as total_profit
from fmcg
order by total_profit desc;



--Q4. How are our sales by population?
--sales by population
select 
population,
sum(sales) as total_sales,
dense_rank() over(order by sum(sales) DESC)as ranks
from fmcg
group by population
order by population desc;



--Q5.what is our profit by different products?
select product,
sum(profit) as total_profit
from fmcg
group by product
order by total_profit desc;





--Q1. What are our overall and yearly sales and profit?
with cte as (select 
cast(extract(year from date_of_order) as varchar) as years, -- years to string
sum(sales) as total_sales,
sum(profit)as total_profit
from fmcg
group by extract(year from date_of_order))
select * from cte
UNION
select 
'Total/Overall' as years,
sum(sales) as overall_sales,
sum(profit) as overall_profit
from fmcg;



--Q2. How are sales and profit in different regions?

SELECT region,
sum(sales)as total_sales,
sum(profit) as total_profit
from fmcg
group by region;


--Q3. What is our sales and profit by state in the south region?
SELECT state,
sum(sales)as total_sales,
sum(profit)as total_profit,
(sum(profit)/sum(sales))*100 as profit_compared_to_sales
from fmcg
group by state,region
having region='South'
order by total_sales desc;


--Q4. Which are our top cities by sales in Karnataka?
select city,
sum(sales) as total_sales
from fmcg
where state='Karnataka'
group by city
order by total_sales desc;



--Q5. Who are our top 5 categories and subcategories in the south region by sales?
with cte1 as(
select category,								--top 5 category
sum(sales) as total_sales,
row_number() over (order by sum(sales) desc) as row_num
from fmcg
group by category,region
having region='South' 
order by total_sales desc limit 5),
cte2 as(
select sub_category,						--top 5 subcategories
sum(sales) as total_sales,
row_number() over (order by sum(sales) desc) as row_num
from fmcg
group by sub_category,region
having region='South' 
order by total_sales desc limit 5)
select
c.category,
c.total_sales,
s.sub_category,
s.total_sales
from cte1 as c full outer join cte2 s
on c.row_num=s.row_num;


--Q6. what are our sales and profit by product in south region?
select product,								
sum(sales) as total_sales,
sum(profit) as total_profit
from fmcg
group by product,region
having region='South' 
order by total_sales desc;



--Q7. What is our sales and Average Discount by subcategory in the south?
select sub_category,								
sum(sales) as total_sales,
round(avg(discount),2) as avg_discount
from fmcg
group by sub_category,region
having region='South' 
order by total_sales desc;




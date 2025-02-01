--first doing the inner join based on lylty_card_num column from both the table
select
	*
from
	cust_behavior as cb
	inner join transactions as t on t.lylty_card_num = cb.lylty_card_num;

--total sales
select
	sum(t.total_sales)
from
	cust_behavior as cb
	inner join transactions as t on t.lylty_card_num = cb.lylty_card_num;

--total customers
select
	count(distinct cb.lylty_card_num) as total_cus
from
	cust_behavior as cb
	inner join transactions as t on t.lylty_card_num = cb.lylty_card_num;

--revenue from top 10 customers
select distinct
	cb.lylty_card_num as customers,
	sum(t.total_sales) as sales
from
	cust_behavior as cb
	inner join transactions as t on t.lylty_card_num = cb.lylty_card_num
group by
	cb.lylty_card_num
order by
	sales desc
limit
	10;

--top 10 selling products with revenue
select distinct
	t.prod_name,
	sum(t.total_sales) as sales
from
	cust_behavior as cb
	inner join transactions as t on t.lylty_card_num = cb.lylty_card_num
group by distinct
	t.prod_name
order by
	sales desc
limit
	10;

--what are the most buyed pack size
select distinct
	t.pack_size,
	count(t.txn_id) as purchase_count,
	sum(t.total_sales) as sales
from
	cust_behavior as cb
	inner join transactions as t on t.lylty_card_num = cb.lylty_card_num
group by
	t.pack_size
order by
	purchase_count desc;

--                                            sales and product performance
--1)which 5 product generates the highest total sales revenue across all transactions?
select distinct
	t.prod_name,
	sum(t.total_sales) as sales
from
	cust_behavior as cb
	inner join transactions as t on t.lylty_card_num = cb.lylty_card_num
group by distinct
	t.prod_name
order by
	sales desc
limit
	5;

--2)what are the top three best-selling product brands by sales quantity?
select distinct
	t.brand,
	sum(t.prod_qty) as quantity,
	sum(t.total_sales)
from
	cust_behavior as cb
	inner join transactions as t on t.lylty_card_num = cb.lylty_card_num
group by
	t.brand
order by
	quantity desc
limit
	3;

--3)which product sizes (pack_size) have the highest sales volume (total sales)?
select distinct
	t.pack_size,
	sum(t.total_sales) as sales
from
	cust_behavior as cb
	inner join transactions as t on t.lylty_card_num = cb.lylty_card_num
group by
	t.pack_size
order by
	sales desc
limit
	1;

--4)what is the average transaction value for each product?
select distinct
	t.prod_name,
	(sum(t.total_sales) / count(t.prod_qty)) as avg_sales
from
	cust_behavior as cb
	inner join transactions as t on t.lylty_card_num = cb.lylty_card_num
group by distinct
	t.prod_name
order by
	avg_sales desc;

--                                       customer insights
--5)which customer segment (customer_segment) contributes the most to total sales?
select
	cb.customer_segment,
	sum(t.total_sales) as total_sales
from
	cust_behavior as cb
	inner join transactions as t on t.lylty_card_num = cb.lylty_card_num
group by
	cb.customer_segment
order by
	total_sales desc;

--6)what is the purchasing behavior of different lifestage groups? (e.g., average spending, most frequently purchased products)
with
	table1 as (
		select
			cb.lifestage,
			t.prod_name,
			(sum(t.total_sales) / count(t.prod_qty)) as avg_spending,
			sum(t.prod_qty) as tot_qty,
			rank() over (
				partition by
					cb.lifestage
				order by
					sum(t.prod_qty) desc
			) as ranks
		from
			cust_behavior as cb
			inner join transactions as t on t.lylty_card_num = cb.lylty_card_num
		group by
			cb.lifestage,
			t.prod_name
	)
select
	lifestage,
	prod_name as most_purchased_prod,
	avg_spending
from
	table1
where
	ranks = 1
order by
	avg_spending desc;

--                                                 seasonal trends
--7)are there any seasonal patterns in product sales based on the date column?
select
	extract(
		year
		from
			t.date
	) as year,
	to_char(t.date, 'month') as months,
	sum(t.total_sales) as sales
from
	cust_behavior as cb
	inner join transactions as t on t.lylty_card_num = cb.lylty_card_num
group by
	months,
	year
order by
	sales desc;

--8) which months see the highest sales for each brand?
with
	brand_detail as (
		select
			t.brand,
			sum(t.total_sales) as sales,
			to_char(t.date, 'month') as months,
			rank() over (
				partition by
					brand
				order by
					sum(t.total_sales) desc
			) as ranks
		from
			cust_behavior as cb
			inner join transactions as t on t.lylty_card_num = cb.lylty_card_num
		group by
			t.brand,
			months
	)
select
	brand,
	months as highest_sales_in_month,
	sales
from
	brand_detail
where
	ranks = 1;

--                                                store analysis
--9)which store (store_nbr) has the highest revenue, and what products drive those sales?
with
	store_revenue as (
		select
			t.store_nbr,
			sum(t.total_sales) as total_revenue
		from
			transactions as t
		group by
			t.store_nbr
		order by
			total_revenue desc
		limit
			1
	),
	top_store_products as (
		select
			t.store_nbr,
			t.prod_name,
			sum(t.total_sales) as revenue
		from
			transactions as t
		where
			t.store_nbr = (
				select
					store_nbr
				from
					store_revenue
			) -- filter by the top-ranked store
		group by
			t.store_nbr,
			t.prod_name
		order by
			revenue desc
	)
select
	*
from
	top_store_products;

--10)is there a correlation between the number of transactions at a store and the total sales generated?
select
	store_nbr,
	count(txn_id) as transaction_count,
	sum(total_sales) as sales
from
	transactions
group by
	store_nbr
order by
	sales desc;

--there is a positive co relation between transaction and total sales
--                                      product and price optimization
--11) are larger pack sizes more popular than smaller pack sizes for a given brand?
with
	table1 as (
		select
			brand,
			pack_size,
			sum(prod_qty) as purchased_time,
			rank() over (
				partition by
					brand
				order by
					sum(prod_qty) desc
			) as ranks
		from
			transactions
		group by
			brand,
			pack_size
		order by
			purchased_time desc
	)
select
	brand,
	pack_size,
	purchased_time,
	ranks
from
	table1
where
	ranks = 1;

--12)which products have the highest sales revenue despite having lower sales quantities (indicating a high price point)?
select
	prod_name,
	sum(prod_qty) as quantity,
	sum(total_sales) as sales,
	(sum(total_sales) / sum(prod_qty)) as average
from
	transactions
group by
	prod_name
order by
	average desc;

--13)what is the average price per unit of products for each brand, and how does it impact sales?
with
	table1 as (
		select
			t.brand,
			t.prod_name,
			sum(t.total_sales) as sales,
			sum(t.prod_qty) as quantity,
			(sum(t.total_sales) / nullif(sum(t.prod_qty), 0)) as avg_sales -- avoid division by zero
		from
			transactions as t
		group by
			t.brand,
			t.prod_name
	),
	table2 as (
		select
			t1.brand,
			t1.prod_name,
			t1.avg_sales,
			(
				t1.sales / sum(t1.sales) over (
					partition by
						t1.brand
				) * 100
			) as percent_in_total -- percentage within each brand
		from
			table1 as t1
	)
select
	t2.brand,
	t2.prod_name,
	t2.avg_sales,
	t2.percent_in_total
from
	table2 t2
where
	t2.percent_in_total > 50
order by
	t2.brand asc,
	t2.percent_in_total desc;





--14) compare each product with the total sales of its brand?
select
	prod_name,
	sum(total_sales) as sales,
	round(
		(
			sum(sum(total_sales)) over (
				partition by
					prod_name
			) / sum(sum(total_sales)) over (
				partition by
					brand
			) * 100
		),
		2
	) as of_total_brand
from
	transactions
group by
	prod_name,
	brand
order by
	sales desc;

--                                      profitability and market basket
--15)what is the proportion of high-selling products (revenue) within each brand compared to the total sales?
with t1 as (
select brand,
prod_name,
sum(total_sales) sales, 
rank() over(partition by brand order by sum(total_sales) desc) as best_prod,
sum(sum(total_sales)) over(partition by brand) as total_sales from transactions
group by brand,prod_name)
select brand,prod_name,sales,((sales/total_sales)*100)as percent_of_total ,total_sales 
from t1 where best_prod=1
order by percent_of_total desc;

--16)what are the most common products bought together (market basket analysis)?
with productpairs as (
    select 
        t1.prod_name as product_a,
        t2.prod_name as product_b,
        count(*) as pair_count
    from 
        transactions as t1
    inner join 
        transactions as t2
    on 
        t1.txn_id = t2.txn_id -- match products in the same transaction
        and t1.prod_name < t2.prod_name -- avoid duplicate pairs and self-joins
    group by 
        t1.prod_name, t2.prod_name
    order by 
        pair_count desc
)
select 
    product_a, 
    product_b, 
    pair_count
from 
    productpairs
limit 10; -- limit to top 10 pairs



--                                      customer retention and loyalty
--17)what is the frequency of purchases for customers in each lifestage and customer segment?
select
	cb.lifestage,
	cb.customer_segment,
	count(t.txn_id) as purchase_time
from
	cust_behavior as cb
	inner join transactions as t on t.lylty_card_num = cb.lylty_card_num
group by cb.lifestage,cb.customer_segment;











									---------advanced---------
--									Customer Behavior Analysis
--1)What percentage of total sales revenue is contributed by the top 10% of customers (by spending)?






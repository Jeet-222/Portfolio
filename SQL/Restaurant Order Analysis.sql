select * from menu_items;
select * from order_details;
select * from menu_items inner join order_details on
menu_items.menu_item_id=order_details.item_id;



-- View the menu_items table and write a query to find the number of items on the menu
select count(distinct(item_name)) from menu_items;



-- What are the least and most expensive items on the menu? 
SELECT 
    (SELECT item_name FROM menu_items ORDER BY price DESC LIMIT 1) AS most_expensive_item,
    (SELECT MAX(price) FROM menu_items) AS most_expensive_price,
    (SELECT item_name FROM menu_items ORDER BY price ASC LIMIT 1) AS least_expensive_item,
    (SELECT MIN(price) FROM menu_items) AS least_expensive_price;



-- How many Italian dishes are on the menu? What are the least and most expensive Italian dishes on the menu? 
select count(distinct(item_name)) from menu_items where category = 'Italian';



-- How many dishes are in each category? What is the average dish price within each category?
select category,count(item_name) as total_dishes,avg(price)
from menu_items group by category;



-- View the order_details table. What is the date range of the table?
select * from order_details;
select max(order_date),min(order_date) from order_details;



-- How many orders were made within this date range? How many items were ordered within this date range?
select count(distinct(order_id)) as total_orders,count(distinct(order_details_id)) total_items_ordered from order_details;



-- Which orders had the most number of items?
select order_id,count(item_id) as total_number_dishes
from order_details group by order_id
order by total_number_dishes desc;


-- How many orders had more than 12 items?
with cte as (select order_id,count(item_id) as total_number_dishes
from order_details group by order_id)
select count(order_id) from cte where total_number_dishes>=12;



-- Combine the menu_items and order_details tables into a single table
select * from menu_items inner join order_details on
menu_items.menu_item_id=order_details.item_id;



-- What were the least and most ordered items? What categories were they in?
select item_name,count(order_id) as total_orders from menu_items inner join order_details on
menu_items.menu_item_id=order_details.item_id
group by item_name
order by total_orders desc;


-- What were the top 5 orders that spent the most money?
select order_id, sum(price) as total_price from menu_items inner join order_details on
menu_items.menu_item_id=order_details.item_id
group by order_id
order by total_price desc limit 5;


-- View the details of the highest spend order. Which specific items were purchased?
select order_id,item_name, sum(price) as total_price from menu_items inner join order_details on
menu_items.menu_item_id=order_details.item_id
where order_id=
(
select order_id from menu_items inner join order_details on
menu_items.menu_item_id=order_details.item_id
group by order_id
order by sum(price) desc limit 1
)
group by order_id,item_name;



-- BONUS: View the details of the top 5 highest spend orders
SELECT od.order_id, mi.item_name, mi.category, mi.price, od.order_date, od.order_time
FROM order_details od
INNER JOIN menu_items mi ON od.item_id = mi.menu_item_id
INNER JOIN (
    SELECT order_id, SUM(price) AS total_price
    FROM order_details od
    INNER JOIN menu_items mi ON od.item_id = mi.menu_item_id
    GROUP BY order_id
    ORDER BY total_price DESC
    LIMIT 5
) top_orders ON od.order_id = top_orders.order_id
ORDER BY od.order_id, mi.price DESC;





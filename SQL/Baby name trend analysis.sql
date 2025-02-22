--Find the overall most popular girl and boy names and show how they have changed in popularity rankings over the years
select name,
sum(births) as born
from names
where gender='M'
group by name
order by born desc limit 1; --"Michael"

select name,
sum(births) as born
from names
where gender='F'
group by name
order by born desc limit 1; --"Jessica"


with cte1 as(select * from 
(SELECT year, name, sum(births) as borns,
dense_rank() over(partition by year order by sum(births) desc)as popularity
from names
group by year,name) where name='Michael'),
cte2 as(select * from 
(SELECT year, name, sum(births) as borns,
dense_rank() over(partition by year order by sum(births) desc)as popularity
from names
group by year,name) where name='Jessica')
select * from cte1 a full join cte2 b on a.year=b.year;



--Find the names with the biggest jumps in popularity from the first year of the data set to the last year
with minyear as(
	with all_details as (
		select year,name,sum(births)as born from names 
		group by year,name)
	select *,row_number() over(partition by year order by born desc) as ranks
	from all_details where year=1980),
maxyear as(
	with all_details as (
		select year,name,sum(births)as born from names 
		group by year,name)
	select *,row_number() over(partition by year order by born desc) as ranks
	from all_details where year=2009)
select *,(b.ranks-a.ranks)as jump from minyear a inner join maxyear b on a.name=b.name
order by jump asc;




--For each year, return the 3 most popular girl names and 3 most popular boy names

select year,name,gender,born,ranks from 
(select year,name,gender,sum(births)as born,
dense_rank() over(partition by year,gender order by sum(births)desc) as ranks
from names
group by year,name,gender)
where ranks<4
order by year asc;




--For each decade, return the 3 most popular girl names and 3 most popular boy names
select * from
	(select decade,name,gender,born,dense_rank() over(partition by decade,gender order by born desc) as ranks from
		(select (case when year between 1980 and 1989 then 1
				  when year between 1990 and 1999 then 2
				  when year between 2000 and 2009 then 3 end) as decade,
				  name,gender,sum(births) as born
		from names
		group by decade,name,gender)
	)
where ranks<4;




--Return the number of babies born in each of the six regions (NOTE: The state of MI should be in the Midwest region)

SELECT 
	case 
		when r.region='New_England' then 'New England' 
		else COALESCE(r.region, 'Midwest') 
		end as regions,
    SUM(n.births) 
FROM regions r 
RIGHT JOIN names n ON r.state = n.country 
GROUP BY regions;

--2nd way
SELECT 
    CASE 
        WHEN r.region IS NULL THEN 'Midwest' 
		when r.region='New_England' then 'New England'
        ELSE r.region 
    END AS region, 
    SUM(n.births) 
FROM regions r 
RIGHT JOIN names n ON r.state = n.country 
GROUP BY CASE 
        WHEN r.region IS NULL THEN 'Midwest' 
		when r.region='New_England' then 'New England'
        ELSE r.region 
    END;





--Return the 3 most popular girl names and 3 most popular boy names within each region
select * from 
	(select regions,
		name,
		gender,
		sum(births) as born,
		dense_rank() over(partition by regions,gender order by sum(births)desc)as ranks
		from
			(select 
				n.name,
				n.gender,
				n.births,
				case 
					when r.region='New_England' then 'New England' 
					else COALESCE(r.region, 'Midwest') 
				end as regions
				from names n left join regions r on n.country=r.state)
		group by regions,name,gender) 
where ranks<4;






--Find the 10 most popular androgynous names (names given to both females and males)

WITH 
male as(
	select name,gender,sum(births)as pop from names 
	group by name,gender
	having gender='M'),
female as(
	select name,gender,sum(births)as pop from names 
	group by name,gender
	having gender='F')
select m.name,(m.pop+f.pop)as popularity 
from male m inner join female f on m.name=f.name
order by popularity desc limit 10;





/*Find the length of the shortest and longest names, and identify the most popular 
short names (those with the fewest characters) and long names (those with the most characters)*/
select name,sum(births) as born,
dense_rank() over (order by sum(births)desc)
from names
where length(name)=(select min(length(name)) from names)
group by name;

select name,sum(births) as born,
dense_rank() over (order by sum(births)desc)
from names
where length(name)=(select max(length(name)) from names)
group by name;





--The founder of Maven Analytics is named Chris. Find the state with the highest percent of babies named "Chris"

WITH 
    all_names AS (
        SELECT country, SUM(births) AS pop 
        FROM names 
        GROUP BY country
    ),
    c_names AS (
        SELECT country, SUM(births) AS born 
        FROM names 
        WHERE name = 'Chris'
        GROUP BY country
    ),
    cte AS (
        SELECT 
            cn.country, 
            cn.born, 
            an.pop
        FROM c_names cn 
        INNER JOIN all_names an ON cn.country = an.country
    )
SELECT 
    country, 
    (born * 100.0 / pop) AS percent_of_total 
FROM cte
ORDER BY percent_of_total DESC;





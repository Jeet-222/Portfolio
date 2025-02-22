--find the overall most popular girl and boy names and show how they have changed in popularity rankings over the years
select 
	name,
	sum(births) as born
from names
where gender='m'
group by name
order by born desc limit 1; --"michael"

select 
	name,
	sum(births) as born
from names
where gender='f'
group by name
order by born desc limit 1; --"jessica"


with cte1 as(
	select * from 
		(select year, name, sum(births) as borns,
		dense_rank() over(partition by year order by sum(births) desc)as popularity
		from names
		group by year,name) 
	where name='michael'
	),
cte2 as(
	select * from 
		(select year, name, sum(births) as borns,
		dense_rank() over(partition by year order by sum(births) desc)as popularity
		from names
		group by year,name) 
	where name='jessica'
	)
select * from cte1 a full join cte2 b on a.year=b.year;



--find the names with the biggest jumps in popularity from the first year of the data set to the last year
with minyear as(
	with all_details as (
		select 
			year,name,sum(births)as born from names 
		group by year,name
		)
	select *,row_number() over(partition by year order by born desc) as ranks
	from all_details 
	where year=1980
	),
maxyear as(
	with all_details as (
		select 
			year,name,sum(births)as born from names 
		group by year,name
		)
	select *,row_number() over(partition by year order by born desc) as ranks
	from all_details 
	where year=2009
	)
select 
	*,
	(b.ranks-a.ranks)as jump 
from minyear a inner join maxyear b 
on a.name=b.name
order by jump asc;




--for each year, return the 3 most popular girl names and 3 most popular boy names

select year,name,gender,born,ranks 
from 
	(select 
		year,
		name,
		gender,
		sum(births)as born,
		dense_rank() over(partition by year,gender order by sum(births)desc) as ranks
	from names
	group by year,name,gender
	)
where ranks<4
order by year asc;




--for each decade, return the 3 most popular girl names and 3 most popular boy names
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




--return the number of babies born in each of the six regions (note: the state of mi should be in the midwest region)

select 
	case 
		when r.region='new_england' then 'new england' 
		else coalesce(r.region, 'midwest') 
		end as regions,
    sum(n.births) 
from regions r 
right join names n on r.state = n.country 
group by regions;

--2nd way
select 
    case 
        when r.region is null then 'midwest' 
		when r.region='new_england' then 'new england'
        else r.region 
    end as region, 
    sum(n.births) 
from regions r 
right join names n on r.state = n.country 
group by case 
        when r.region is null then 'midwest' 
		when r.region='new_england' then 'new england'
        else r.region 
    end;





--return the 3 most popular girl names and 3 most popular boy names within each region
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
					when r.region='new_england' then 'new england' 
					else coalesce(r.region, 'midwest') 
				end as regions
				from names n left join regions r on n.country=r.state)
		group by regions,name,gender) 
where ranks<4;






--find the 10 most popular androgynous names (names given to both females and males)

with 
male as(
	select name,gender,sum(births)as pop from names 
	group by name,gender
	having gender='m'),
female as(
	select name,gender,sum(births)as pop from names 
	group by name,gender
	having gender='f')
select m.name,(m.pop+f.pop)as popularity 
from male m inner join female f on m.name=f.name
order by popularity desc limit 10;





/*find the length of the shortest and longest names, and identify the most popular 
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





--the founder of maven analytics is named chris. find the state with the highest percent of babies named "chris"

with 
    all_names as (
        select country, sum(births) as pop 
        from names 
        group by country
    ),
    c_names as (
        select country, sum(births) as born 
        from names 
        where name = 'chris'
        group by country
    ),
    cte as (
        select 
            cn.country, 
            cn.born, 
            an.pop
        from c_names cn 
        inner join all_names an on cn.country = an.country
    )
select 
    country, 
    (born * 100.0 / pop) as percent_of_total 
from cte
order by percent_of_total desc;





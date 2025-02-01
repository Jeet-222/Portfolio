--copy a TABLE
Create table retail_copy as
select * from retail;


--delete null VALUES from the DATA
SELECT *
FROM retail_copy
WHERE description
IS NULL;

delete from retail_copy
where retail_copy.description is null;


--choose the specific values from columns
SELECT * from pop where country IN('India','China')


--choose data with condition in a range in between
SELECT * from pop where year between 2010 and 2023;


--order by ascending or descending
SELECT DISTINCT(country) from pop order by country ASC;


--choose from rows where name ends with letter 'a'
SELECT * FROM pop where country like '%a';


--choose from rows where name starts with letter 'A'
SELECT * FROM pop where country like 'A%';


--choose from rows where 'nd' is present in any part of the specific value of row
SELECT * from pop where country like '%nd%'


--choose from rows where the 2nd letter is 'a'
SELECT * FROM pop where country like '_a%';


--choose from rows where the 5th letter is 'a'
SELECT * FROM pop where country like '____a%';


--choose from rows where the first letter is 'a' but case insensitive
SELECT * FROM pop where country ilike 'a%';






--count/sum/avg
select count(DISTINCT(country)) from pop;

SELECT sum(population) from pop where year=2023;

select avg(population) from pop where year = 2023;





--Group by with conditions
SELECT country from pop group by country;
--this one with conditions and we can use a lot more conditions here
select country, avg(population) from pop where year between 2020 and 2023 
group by country order by country asc;




										--string functions--

--concat function(suppose i want to merge two columns names like afganistan
--with its country code, ex- 'Afganistan-AFG')
SELECT CONCAT(country,'-',code) as ccd from pop;
select concat_ws('-',country,code) as ccd from pop;
select concat_ws('-',country,code) as ccd,year,population from pop;

--concat with conditions--
select concat_ws('-',country, code) as ccc,year,population from pop
where population>=100000000 and
year between 2020 and 2023 and country ilike '%a%';



--substring function (suppose i want the country code first 3 letters of each country,EX- 'India-Ind'), we can use comdition with it also
select substr(country,1,3)as country_new_code from pop;



--replace function-- replace(column,from_str,to_str)
select replace(code,'AFG','afg') from pop;



--reverse function--
select reverse(code)from pop;



--length function--
SELECT country,length(country) as size from pop;

SELECT DISTINCT(country),length(country) as size from pop
order by country ASC;

select distinct(country) from pop where length(country)>=10 order by country asc;



--upper/lower(case) function
select upper(country) from pop;

select lower(code) from pop;



--left/right(characters) FUNCTION
SELECT left(country,5) from pop;

select right(country,5) from pop;



--trim function for removing spaces
--we can use columns too but i dont have columns in like this here.--
select trim('   hello,  ');



--position function
select position('jeet' in 'hello jeet');

select position('In' in country) from pop where country='India';



								--Alter Table--
--making changes in table and structure of the table	(data type paltanor jonno)
alter table pop 
add column avg_population int;

alter table pop 
drop column avg_population;

--rename a column or u can do the same with table name also
alter table pop
rename column index_column to index_id;
--table rename
alter table popu
rename to pop;
--or
rename table pop to popu;


--if i want to change the data type
alter table pop
alter column code
set data type varchar(200);
--here i put default value if nothing exists on the row
alter table pop
alter column code
set default 'unknown';

select * from students;

--check function(it basically cheks if it meets your criteria,it is also a constraint)
alter table students
add column mobile TEXT check (length(mobile)=10);

alter table students
add column marks INT check (marks<=100);

--now if i have to remove the constrain then (table_column_check)
ALTER TABLE students
drop CONSTRAINT students_marks_check;

--now if have to add constraint as a comment when the input is wrong or didnt meet the check function
alter table students
add constraint marks_greater_than 100
check (marks<=100);

INSERT into students(marks)
values (110);



---case function--
SELECT country,year,population,
CASE 
	when population>=1000000000 then 'extreme high'
	when population>200000000 and population<1000000000 then 'medium'
	when population>10000000 and population<200000000 then 'low'
	ELSE 'extreme low'
end as pop_category
from pop;

--using group by with case(you can use any other too)
SELECT
CASE 
	when population>=1000000000 then 'extreme high'
	when population>200000000 and population<1000000000 then 'medium'
	when population>10000000 and population<200000000 then 'low'
	ELSE 'extreme low'
end as pop_cat,
count(distinct(country)) as ccount
from pop 
group by pop_cat 
order by ccount desc;


--now suppose i want to add a column using CASE
alter table pop
add column pop_category TEXT;

update pop
SET pop_category = case
	when population>=1000000000 then 'extreme high'
	when population>200000000 and population<1000000000 then 'medium'
	when population>10000000 and population<200000000 then 'low'
	ELSE 'extreme low'
END



select * from pop;






--suppose i want make changes in my database rows and make it permanent and reflect it on data

--CREATING A NEW COLUMN
ALTER TABLE pop
ADD COLUMN index_column INT;

--PUTTING VALUES IN IT THAT WILL UPDATED PERMANENTLY
WITH CTE AS (
    SELECT ROW_NUMBER() OVER (ORDER BY country ASC, year ASC) AS index, ctid
    FROM pop
)
UPDATE pop
SET index_column = CTE.index
FROM CTE
WHERE pop.ctid = CTE.ctid;


select * from pop;

--HERE I HAVE CHANGED THE POSITION OF THE LAST COLUMN(index_column) to first column of my table

--first altering the table and giving it a new name
ALTER TABLE pop RENAME TO pop_backup;

--as i have given it a diffrent name now i can create a table with the same name and putting same columns as i want them to be
CREATE TABLE pop (
    index_column INT,
    country TEXT,
    code TEXT,
    year INT,
    population BIGINT
    -- Add other columns as needed
);

--here lastly i am inserting the data of the alter table that i have renamed in the first
INSERT INTO pop (index_column, country, code, year, population)
SELECT index_column, country, code, year, population
FROM pop_backup;
drop table pop_backup;
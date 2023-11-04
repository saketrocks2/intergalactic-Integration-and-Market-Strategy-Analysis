select * from aliens
limit 10;
-- types of alien gender
select  gender,count(*) from aliens group by 1;
select * from details limit 10;
select * from location limit 10;
-- occupation statewise
with x as(select state,occupation,count(*) as total_count,row_number()over(partition by state order by count(*) desc) as r
 from location group by 1,2)
 select * from x where r=1;
-- What is the population of aliens per state and what is the average age?   Order from highest to lowest population.
select state,count(*),avg(year(now())-a.birth_year) 
from aliens a join location l on a.id=l.loc_id group by 1 order by count(*) desc;
-- What is the top favorite food of every species including ties?
with x as (select type,favorite_food,count(*),rank()over(partition by a.type order by count(*) desc) as r from aliens a join details d on 
a.id=d.detail_id group by 1,2)
select * from x where r=1;
-- Which are the top 10 cities where aliens are located and is the population majority hostile or friendly?
with x as (select `current_location`,count(*),sum(if(aggressive="TRUE",1,0)) as hostile, sum(if(aggressive="false",1,0)) as friendly 
from location l join details d on d.detail_id=l.loc_id group by 1)
select `current_location`,count(*),hostile,friendly,case when hostile<friendly then'friendly' else 'hostile' end as 'category' from x
group by 1 limit 10;
-- -- Find the Alien Species With the Highest Percentage of Hostile Individuals in Each State     
with x as (select state,type,sum(if(aggressive='true',1,0)) /count(*) *100 as p,
rank()over(partition by state order by (sum(if(aggressive='true',1,0)) /count(*) *100) desc) as r
from location l join aliens a on a.id=l.loc_id join details d on d.detail_id=a.id 
 group by 1,2)
select * from x where r=1 ;













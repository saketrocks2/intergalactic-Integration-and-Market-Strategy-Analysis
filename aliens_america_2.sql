/* 
 * Aliens in America
 * Case Study Questions by saket kumar saket847@gmail.com
 *   

For this project, you play a role as a newly hired Data Analyst for a pharmaceutical company.

It's the year 2022 and aliens are well known to be living amongst us.

Unfortunately, some of the aliens are a bit... too alien... and would like to fit into society a bit more.

So it's up to you to find the best state(s) we should market our new prescription.

It would be helpful to know...

If these aliens are hostile
Their diet
Their age
It's up to you to clean up the data and report back.

*/



-- How many countrys are present in out dataset?

SELECT COUNT(DISTINCT country) AS country_count
FROM location;


-- Are all states represented in the dataset?

SELECT 
	count(DISTINCT state) AS number_of_states
FROM location;

              
-- All 50 states are represented and the District of Columbia           

-- What is the population of aliens per state and what is the average age?   Order from highest to lowest population.
-- Include the percentage of hostile vs. friendly aliens per state.  Limit the first 10 for brevity.
SELECT distinct birth_year from aliens;
SELECT
    l.state,
    COUNT(*) AS alien_population,
    ROUND(year(CURRENT_TIMESTAMP)-AVG(a.birth_year), 2) AS avg_alien_age,
    ROUND((SUM(CASE WHEN d.aggressive = 'TRUE' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS hostile_percentage,
    ROUND((SUM(CASE WHEN d.aggressive = 'FALSE' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS friendly_percentage
FROM aliens a
JOIN location l ON a.id = l.loc_id
JOIN details d ON a.id = d.detail_id
GROUP BY l.state
ORDER BY alien_population DESC
LIMIT 10;

-- What are the yougest and oldest alien ages in the U.S.?

SELECT
    MIN(YEAR(NOW()) - a.birth_year) AS youngest_age,
    MAX(YEAR(NOW()) - a.birth_year) AS oldest_age
FROM aliens a
JOIN location l ON a.id = l.loc_id
WHERE l.country = 'United States';





-- The U.S. Bureau of Economic Analysis developed an eight-region map of the US seen below.  What regions have the highest population of aliens and what
-- is the overall population percentage per region?

WITH RegionAlienPopulation AS (
    SELECT
        CASE
            WHEN l.state IN ('Maine', 'New Hampshire', 'Massachusetts', 'Connecticut', 'Vermont', 'Rhode Island') THEN 'New England'
            WHEN l.state IN ('Alabama', 'Arkansas', 'Florida', 'Georgia', 'Kentucky', 'Louisiana', 'Mississippi', 'North Carolina', 'South Carolina', 'Tennessee', 'Virginia', 'West Virginia') THEN 'Southeast'
            WHEN l.state IN ('Wisconsin', 'Ohio', 'Indiana', 'Illinois', 'Michigan') THEN 'Great Lakes'
            WHEN l.state IN ('New Mexico', 'Arizona', 'Texas', 'Oklahoma') THEN 'Southwest'
            WHEN l.state IN ('North Dakota', 'South Dakota', 'Kansas', 'Iowa', 'Nebraska', 'Missouri', 'Minnesota') THEN 'Plains'
            WHEN l.state IN ('Colorado', 'Utah', 'Idaho', 'Montana', 'Wyoming') THEN 'Rocky Mountain'
            WHEN l.state IN ('New York', 'New Jersey', 'Pennsylvania', 'Delaware', 'Maryland', 'District of Columbia') THEN 'Mideast'
            WHEN l.state IN ('California', 'Alaska', 'Nevada', 'Oregon', 'Washington', 'Hawaii') THEN 'Far West'
            ELSE 'Other'
        END AS region,
        COUNT(*) AS alien_population
    FROM location l
    JOIN aliens a ON l.loc_id = a.id
    WHERE l.country = 'United States'
    GROUP BY region
)
SELECT region, alien_population,
       ROUND((alien_population / SUM(alien_population) OVER ()) * 100, 2) AS region_population_percentage
FROM RegionAlienPopulation
ORDER BY alien_population DESC;



-- What is the top favorite food of every species including ties?

WITH TopFavoriteFoods AS (
    SELECT
        a.type AS species,
        d.favorite_food AS favorite_food,
        COUNT(*) AS food_count,
        RANK() OVER (PARTITION BY a.type ORDER BY COUNT(*) DESC) AS food_rank
    FROM
        aliens a
    JOIN
        details d ON a.id = d.detail_id
    GROUP BY
        a.type, d.favorite_food
)
SELECT species, favorite_food, food_count
FROM TopFavoriteFoods
WHERE food_rank = 1;






-- Which are the top 10 cities where aliens are located and is the population majority hostile or friendly?

WITH CityAlienPopulation AS (
    SELECT
        l.current_location AS city,
        SUM(CASE WHEN d.aggressive = 'true' THEN 1 ELSE 0 END) AS hostile_population,
        SUM(CASE WHEN d.aggressive = 'false' THEN 1 ELSE 0 END) AS friendly_population
    FROM location l
    JOIN aliens a ON l.loc_id = a.id
    JOIN details d ON a.id = d.detail_id
    GROUP BY l.current_location
)
SELECT
    city,
    hostile_population,
    friendly_population,
    CASE
        WHEN hostile_population > friendly_population THEN 'Hostile'
        WHEN friendly_population > hostile_population THEN 'Friendly'
        ELSE 'Equal'
    END AS population_majority
FROM CityAlienPopulation
ORDER BY (hostile_population + friendly_population) DESC
LIMIT 10;

-- what are the top 10 most common occupations among aliens
SELECT
    ltrim(rtrim(lower(l.occupation))) AS occupation,
    COUNT(*) AS occupation_count
FROM
    location l
JOIN
    aliens a ON l.loc_id = a.id
WHERE
    l.occupation IS NOT NULL
GROUP BY
    ltrim(rtrim(lower(l.occupation)))
ORDER BY
    COUNT(*) DESC
LIMIT 10;
-- Calculate the Cumulative Percentage of Alien Populations by Species

WITH SpeciesPopulation AS (
    SELECT
        a.type AS species,
        COUNT(*) AS population
    FROM
        aliens a
    GROUP BY
        a.type
),
CumulativeSpeciesPopulation AS (
    SELECT
        species,
        population,
        SUM(population) OVER (ORDER BY population DESC) AS cumulative_population,
        (SUM(population) OVER (ORDER BY population DESC) * 100.0 / SUM(population) OVER ()) AS cumulative_percentage
    FROM SpeciesPopulation
)
SELECT species, population, cumulative_population, ROUND(cumulative_percentage, 2) AS cumulative_percentage
FROM CumulativeSpeciesPopulation;




-- top 5 rank of hostile on basis of species
WITH SpeciesHostilePercentage AS (
    SELECT
        a.type AS species,
        (SUM(CASE WHEN d.aggressive = 'true' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS hostile_percentage
    FROM
        aliens a
    JOIN
        details d ON a.id = d.detail_id
    GROUP BY
        a.type
)
SELECT
    species,
    hostile_percentage,
    RANK() OVER (ORDER BY hostile_percentage DESC) AS species_rank
FROM SpeciesHostilePercentage;


-- -- Find the Alien Species With the Highest Percentage of Hostile Individuals in Each State     


WITH SpeciesHostilePercentage AS (
    SELECT
        l.state,
        a.type AS species,
        (SUM(CASE WHEN d.aggressive = 'true' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS hostile_percentage,
        RANK() OVER (PARTITION BY l.state ORDER BY (SUM(CASE WHEN d.aggressive = 'true' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) DESC) AS species_rank
    FROM
        location l
    JOIN
        aliens a ON l.loc_id = a.id
    JOIN
        details d ON a.id = d.detail_id
    GROUP BY
        l.state, a.type
)
SELECT
    state,
    species,
    hostile_percentage
FROM SpeciesHostilePercentage
WHERE species_rank = 1;

-- occupation statewise
with x as(select state,occupation,count(*) as total_count,row_number()over(partition by state order by count(*) desc) as r
 from location group by 1,2)
 select * from x where r=1;
 
 -- 


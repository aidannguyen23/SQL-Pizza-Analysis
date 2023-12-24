-- Entire Dataset 
SELECT * FROM pizza_data;

-- What are the least and most expensive cities for pizza? 
WITH city_cte AS (
	SELECT 
		DISTINCT id,
		city,
		(priceRangeMin+priceRangeMax) / 2 AS average_restaurant_price
	FROM pizza_data
	WHERE priceRangeMax != 0
), city_rank_cte AS (
	SELECT city, 
		AVG(average_restaurant_price) as average_city_price,
		DENSE_RANK() OVER(ORDER BY average_city_price DESC) as expensive_price_rank,
		DENSE_RANK() OVER(ORDER BY average_city_price ASC) as cheaper_price_rank
	FROM city_cte
    GROUP BY city
	)

SELECT city, average_city_price
FROM city_rank_cte
WHERE (expensive_price_rank <= 2 OR cheaper_price_rank = 1)
GROUP BY city
ORDER BY average_city_price DESC;

-- What is the median price of a cheese pizza across the U.S.?
ALTER TABLE pizza_data
CHANGE COLUMN `menus.name` `menus_name` VARCHAR(255), -- Changed menus.name to menusName because mySQL can't handle columns with '.'
CHANGE COLUMN `menus.amountMin` `menus_amountMin` VARCHAR(255), 
CHANGE COLUMN `menus.amountMax` `menus_amountMax` VARCHAR(255),
CHANGE COLUMN `menus.dateSeen` `menus_dateSeen` VARCHAR(255);

WITH item_cte AS 
(
    SELECT name, menus_name AS item_name, menus_amountMax AS item_price
    FROM pizza_data
    WHERE menus_name LIKE 'Large Cheese Pizza'
)

SELECT item_name, item_price as median_item_price
FROM (
    SELECT item_name, item_price,
        ROW_NUMBER() OVER (ORDER BY CAST(item_price AS DECIMAL(10, 2))) AS rownumber,
        COUNT(*) OVER () AS total_count
    FROM item_cte
) AS subquery
WHERE rownumber IN ((total_count + 1) / 2, (total_count + 2) / 2); -- select median

-- What are the top five most common types of dishes among the restaurants listed?
WITH dish_ranking_cte AS (
	SELECT menus_name AS dish_name, COUNT(*) as frequency,
		RANK() OVER(ORDER BY COUNT(*) DESC) AS frequency_rank
	FROM pizza_data
	GROUP BY menus_name
	ORDER BY frequency DESC
)

SELECT dish_name, frequency
FROM dish_ranking_cte
WHERE frequency_rank <= 5;

-- How have average pizza menu prices changed over the years for restaurants in New York?
    SELECT
        EXTRACT(YEAR FROM menus_dateSeen) as year,
        ROUND(AVG((menus_amountMax + menus_amountMin) / 2), 2) as average_menu_price
	FROM pizza_data
    WHERE city = 'New York'
	AND menus_amountMax != 0 and menus_amountMin != 0
    GROUP BY year;
    
-- Which city has the highest number of bars selling pizza?
WITH bars_cte AS (
	SELECT city, COUNT(categories) as frequency_of_bars,
		DENSE_RANK() OVER(ORDER BY frequency_of_bars DESC) as bars_rank
	FROM pizza_data
	WHERE categories LIKE "%Bar%"
	GROUP BY city
	ORDER BY frequency_of_bars DESC
)

SELECT city, frequency_of_bars
FROM bars_cte
WHERE bars_rank <= 5;


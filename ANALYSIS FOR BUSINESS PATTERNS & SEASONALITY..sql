# ANALYSIS FOR BUSINESS PATTERNS & SEASONALITY.

# Request-1 - Understanding Seasonality.
/*
NEW MESSAGE January 02, 2013
From: Cindy Sharp (CEO)
Subject: Understanding Seasonality
Good morning,
2012 was a great year for us. As we continue to grow, we should take a look at 2012's monthly and weekly volume patterns, to see if we can find any seasonal trends we should plan for in 2013.
If you can pull session volume and order volume, that would be excellent.
Thanks, -Cindy
*/

# MONTHLY TREND....
SELECT YEAR(W.created_at) AS YEAR,MONTH(W.created_at)  AS MONTH,
COUNT(DISTINCT W.website_session_id) AS SESSIONS,
COUNT(DISTINCT O.order_id) AS ORDERS
FROM website_sessions W
LEFT JOIN orders O USING(website_session_id)
WHERE YEAR(W.created_at)  = "2012"
GROUP BY 1,2;

# WEEKLY TREND....
SELECT MIN(DATE(W.created_at)) AS WEEK_START_DATE,
COUNT(DISTINCT W.website_session_id) AS SESSIONS,
COUNT(DISTINCT O.order_id) AS ORDERS
FROM website_sessions W
LEFT JOIN orders O USING(website_session_id)
WHERE YEAR(W.created_at)  = "2012"
GROUP BY WEEK(W.created_at);

# Request-2 - Data for Customer Service.
/*
NEW MESSAGE January 05, 2013
From: Cindy Sharp (CEO)
Subject: Data for Customer Service
Good morning,
We're considering adding live chat support to the website to improve our customer experience.
Could you analyze the average website session volume, by hour of day and by day week, so that we can staff appropriately?
Let's avoid the holiday time period and use a date range of Sep 15 - Nov 15, 2012.
Thanks, Cindy
*/
SELECT HOUR(created_at) AS HOUR,
		COUNT(DISTINCT IF(WEEKDAY(created_at) = 0,website_session_id,NULL )) AS "MON",
		COUNT(DISTINCT IF(WEEKDAY(created_at) = 1,website_session_id,NULL )) AS "TUE",
		COUNT(DISTINCT IF(WEEKDAY(created_at) = 2,website_session_id,NULL )) AS "WED",
		COUNT(DISTINCT IF(WEEKDAY(created_at) = 3,website_session_id,NULL )) AS "THU",
		COUNT(DISTINCT IF(WEEKDAY(created_at) = 4,website_session_id,NULL )) AS "FRI",
		COUNT(DISTINCT IF(WEEKDAY(created_at) = 5,website_session_id,NULL )) AS "SAT",
		COUNT(DISTINCT IF(WEEKDAY(created_at) = 6,website_session_id,NULL )) AS "SUN"
FROM website_sessions
WHERE (DATE(created_at) BETWEEN "2012-09-15" AND "2012-11-15")
GROUP BY 1
ORDER BY 1;

-- **********************************************************************************************
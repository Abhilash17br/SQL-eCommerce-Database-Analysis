# USER ANALYSIS.

# CONCEPT: ANALYZE REPEAT BEHAVIOR

-- Analyzing repeat visits helps you understand user behavior and identify some of your most valuable customers.

# Request 1: - IDENTIFYING REPEAT VISITORS
/*
NEW MESSAGE
November 01, 2014
From: Tom Parmesan (Marketing Director)
Subject: Repeat Visitors
Hey there,
We've been thinking about customer value based solely on
their first session conversion and revenue. But if customers
have repeat sessions, they may be more valuable than we
thought. If that's the case, we might be able to spend a bit
more to acquire them.
Could you please pull data on how many of our website
visitors come back for another session? 2014 to date is good.
Thanks, Tom
*/
WITH CTE2 AS(
			WITH CTE AS(
						SELECT user_id,
							   website_session_id,
							   is_repeat_session,
							   ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY website_session_id) - 1  AS RN
						FROM website_sessions
						WHERE DATE(created_at) BETWEEN "2014-01-01" AND  "2014-11-01")
			SELECT user_id,MAX(RN) AS REPEAT_SESSIONS  FROM CTE GROUP BY 1)
SELECT REPEAT_SESSIONS, COUNT(DISTINCT user_id) AS USERS FROM CTE2 GROUP BY REPEAT_SESSIONS;

# Request 2: - ANALYZING THE TIME TO REPEAT.
/*
NEW MESSAGE
November 03, 2014
From: Tom Parmesan (Marketing Director)
Subject: Deeper Dive on Repeat
Ok, so the repeat session data was really interesting to see.
Now you've got me curious to better understand the behavior
of these repeat customers.
Could you help me understand the minimum, maximum, and
average time between the first and second session for
customers who do come back? Again, analyzing 2014 to date
is probably the right time period.
Thanks, Tom
*/
CREATE TEMPORARY TABLE A21
WITH CTE AS (
SELECT *,ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY website_session_id) - 1  AS RN
FROM website_sessions
WHERE DATE(created_at) BETWEEN "2014-01-01" AND  "2014-11-03")
SELECT user_id,created_at AS SESOND_SESSION FROM CTE WHERE RN =1;

SELECT * FROM A21;

CREATE TEMPORARY TABLE A22
SELECT user_id,created_at AS FIRST_SESSION 
FROM website_sessions 
WHERE is_repeat_session = 0 AND user_id IN(SELECT user_id FROM A21) AND (DATE(created_at) BETWEEN "2014-01-01" AND  "2014-11-03") ; 

WITH CTE AS(
			SELECT * 
			FROM A22
			INNER JOIN A21 USING(user_id))
SELECT AVG(DATEDIFF(SESOND_SESSION,FIRST_SESSION)) AS AVERAGE_DAYS_FIRST_TO_SECOND,
		MIN(DATEDIFF(SESOND_SESSION,FIRST_SESSION)) AS MIN_DAYS_FIRST_TO_SECOND,
        MAX(DATEDIFF(SESOND_SESSION,FIRST_SESSION)) AS MAX_DAYS_FIRST_TO_SECOND
FROM CTE;

# Request 3: - ANALYZING REPEAT CHANNEL BEHAVIOUR.
/*
NEW MESSAGE
November 05, 2014
From: Tom Parmesan (Marketing Director)
Subject: Repeat Channel Mix
Hi there,
Let's do a bit more digging into our repeat customers.
Can you help me understand the channels they come back
through? Curious if it's all direct type-in, or if we're paying for
these customers with paid search ads multiple times.
Comparing new vs. repeat sessions by channel would be
really valuable, if you're able to pull it! 2014 to date is great
Thanks, Tom
*/
WITH CTE AS(
			SELECT website_session_id,is_repeat_session,
			CASE
				WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN 'ORGANIC_SEARCH'
                WHEN utm_campaign = 'brand' THEN 'PAID_BRAND'
				WHEN utm_source IS NULL AND http_referer IS NULL THEN 'DIRECT_TYPE_IN'
				WHEN utm_campaign = 'nonbrand' THEN 'PAID_NONBRAND'
				WHEN utm_source = 'socialbook' THEN 'PAID_SOCIAL'
				ELSE "NONE"
				END AS CHANNEL_GROUP
			FROM website_sessions
			WHERE created_at > "2014-01-01" AND  created_at <= "2014-11-05")
SELECT CHANNEL_GROUP,
		COUNT(DISTINCT IF(is_repeat_session = 0,website_session_id,NULL)) AS NEW_SESSIONS,
		COUNT(DISTINCT IF(is_repeat_session = 1,website_session_id,NULL)) AS REPEAT_SESSIONS
FROM CTE
GROUP BY CHANNEL_GROUP;       

# Request 4: - ANALYZING NEW AND REPEAT CONVERSION RATES.
/*
NEW MESSAGE
November 08, 2014
From: Morgan Rockwell (Website Manager)
Subject: Top Website Pages
Hi there!
Sounds like you and Tom have learned a lot about our repeat
customers. Can I trouble you for one more thing?
rd love to do a comparison of conversion rates and revenue per
session for repeat sessions vs new sessions.
Let's continue using data from 2014, year to date.
Thank you!
-Morgan
*/

WITH CTE AS (
			SELECT W.website_session_id,W.is_repeat_session,O.order_id,O.price_usd
			FROM website_sessions W
			LEFT JOIN orders O USING(website_session_id)
            WHERE W.created_at > "2014-01-01" AND  W.created_at <= "2014-11-08")
SELECT is_repeat_session, 
	   COUNT(DISTINCT website_session_id) AS SESSSIONS,
       COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id) AS CONV_RATE,
       SUM(price_usd)/COUNT(DISTINCT website_session_id) AS REVENUE_PER_SESSION
FROM CTE
GROUP BY is_repeat_session;

-- *********************************************************************************************
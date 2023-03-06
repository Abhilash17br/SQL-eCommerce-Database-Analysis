# ANALYZING TRAFFIC SOURCES.

-- ******************************************************************************************
# CONCEPT 1 - Sessions Count, Conversion Rate.
-- Find the session to order conversion rate for all the possible utm_content.
SELECT W.utm_content, COUNT(DISTINCT W.website_session_id) AS SESSIONS ,
COUNT( DISTINCT O.order_id) AS ORDERS,
(COUNT( DISTINCT O.order_id)/COUNT(DISTINCT W.website_session_id))*100 AS CONVERSION_RATE_PCT
FROM WEBSITE_SESSIONS W
LEFT JOIN ORDERS O ON O.website_session_id = W.website_session_id
GROUP BY 1
ORDER BY 4 DESC;

# Request-1 - Site traffic breakdown
/*
NEW MESSAGE - April 12, 2012
From: Cindy Sharp (CEO)
Subject: Site traffic breakdown
Good morning,
We've been live for almost a month now and we're starting to generate sales. 
Can you help me understand where the bulk of our website sessions are coming from,
through yesterday?
I'd like to see a breakdown by UTM source, campaign and referring domain if possible. Thanks!
OUTPUT COLUMNS -- utm_source,utm_campaign,http_referer,SESSIONS
*/
SELECT utm_source,utm_campaign,http_referer,
	   COUNT(DISTINCT website_session_id) AS SESSIONS
FROM website_sessions
WHERE created_at < '2012-04-12'
GROUP BY 1,2,3
ORDER BY 4 DESC;

# Request-2 - Gsearch conversion rate
/*
1 NEW MESSAGE April 14, 2012
From: Tom Parmesan (Marketing Director)
Subject: Gsearch conversion rate
Hi there,
Sounds like gsearch nonbrand is our major traffic source, but we need to understand if those sessions are driving sales.
Could you please calculate the conversion rate (CVR) from session to order?
Based on what we're paying for clicks, we'll need a CVR of at least 4% to make the numbers work.
If we're much lower, we'll need to reduce bids. If we're higher, we can increase bids to drive more volume.
OUTPUT COLUMNS -- SESSIONS,ORDERS,CVR
*/
SELECT 
	COUNT(DISTINCT W.website_session_id) AS SESSIONS,
    COUNT(DISTINCT O.order_id) AS ORDERS,
    (COUNT(DISTINCT O.order_id)/COUNT(DISTINCT W.website_session_id))*100 AS CVR
FROM website_sessions W
LEFT JOIN orders O  ON O.website_session_id = W.website_session_id
WHERE W.created_at < '2012-04-14' AND 
	  utm_source  = 'gsearch' AND 
	  utm_campaign = 'nonbrand';
-- ---------------------------------------------------------------------------------------------
# CONCEPT 2 - Bid Optimization and Trend Analysis.
-- Trend of Sessions Count..
SELECT YEAR(created_at),WEEK(created_at),
MIN(DATE(created_at)) AS WEEK_START,
COUNT(DISTINCT website_session_id) AS SESSIONS
FROM website_sessions
WHERE website_session_id BETWEEN 100000 AND 115000
GROUP BY 1, 2;


# Request-3 - Gsearch volume trends
/*
1 NEW MESSAGE May 10, 2012
From: Tom Parmesan (Marketing Director) 
Subject: Gsearch volume trends
Hi there,
Based on your conversion rate analysis, we bid down gsearch nonbrand on 2012-04-15.
Can you pull gsearch nonbrand trended session volume, by week,
to see if the bid changes have caused volume to drop at all?
Thanks, Tom
*/
SELECT MIN(DATE(created_at)) AS WEEK_START,
	   WEEK(created_at), 
       COUNT(website_session_id) AS SESSIONS
FROM website_sessions
WHERE created_at < "2012-05-10" AND utm_source  = 'gsearch' AND utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at);

# Request-4 - Gsearch device-level performance
/*
1 NEW MESSAGE May 11, 2012
From: Tom Parmesan (Marketing Director) 
Subject: Gsearch device-level performance
Hi there,
I was trying to use our site on my mobile device the other day, and the experience was not great.
Could you pull conversion rates from session to order, by device type?
If desktop performance is better than on mobile we may be able to bid up for desktop specifically to get more volume?
Thanks, Tom
*/
SELECT device_type,
       COUNT(DISTINCT W.website_session_id) AS SESSIONS,
	   COUNT(DISTINCT O.order_id) AS ORDERS,
	   ROUND(COUNT(DISTINCT O.order_id)/COUNT(DISTINCT W.website_session_id),2)*100 AS SESSIONS_TO_ORDER_CONV_RATE
FROM website_sessions W
LEFT JOIN ORDERS O ON O.website_session_id  = W.website_session_id
WHERE W.created_at < "2012-05-11" AND utm_source  = 'gsearch' AND utm_campaign = 'nonbrand'
GROUP BY 1;

# Request-5 - Gsearch device-level trends
/*
1 NEW MESSAGE June 09, 2012
From: Tom Parmesan (Marketing Director)
Subject: Gsearch device-level trends
Hi there,
After your device-level analysis of conversion rates, we realized desktop was doing well, 
so we bid our gsearch nonbrand desktop campaigns up on 2012-05-19.
Could you pull weekly trends for both desktop and mobile so we can see the impact on volume?
You can use 2012-04-15 until the bid change as a baseline.
Thanks, Tom
*/ 
SELECT MIN(DATE(created_at)),
COUNT(IF(device_type = 'mobile',website_session_id,NULL)) AS MOBILE_SESSIONS,
COUNT(IF(device_type = 'desktop',website_session_id,NULL)) AS DESKTOP_SESSIONS
FROM website_sessions
WHERE created_at > "2012-04-15" AND created_at < "2012-06-09" AND 
	utm_source  = 'gsearch' AND 
	utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at); 

-- this shows the Sessions from mobile for gsearch nonbrand are decreasing and increasing for device,
-- due to bid optimization.

-- *********************************************************************************************

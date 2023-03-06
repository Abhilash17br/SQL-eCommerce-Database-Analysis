# ANALYSIS FOR CHANNEL MANAGEMENT.


# CONCEPT 1 - -- ANALYZING BY UTM_CONTENT.
-- To get Overall Conversion Rates.
SELECT utm_content,
COUNT( DISTINCT website_session_id) AS SESSIONS,
COUNT(DISTINCT order_id) AS ORDERS,
COUNT(DISTINCT order_id)/COUNT( DISTINCT website_session_id) AS CONVERSION_RATE
FROM website_sessions
LEFT JOIN orders USING(website_session_id)
GROUP BY 1
ORDER BY 2 DESC;

# Request-1 - Expanded Channel Portfolio.
/*
NEW MESSAGE November 29, 2012
From: Tom Parmesan (Marketing Director) 
Subject: Expanded Channel Portfolio
Hi there,
With gsearch doing well and the site performing better, we launched a second paid search channel, bsearch, around August 22.
Can you pull weekly trended session volume since then and compare to gsearch nonbrand so
I can get a sense for how important this will be for the business?
Thanks, Tom
*/
SELECT MIN(DATE(created_at)) AS WEEK_START_DATE, WEEK(created_at) AS WEEK ,
COUNT( DISTINCT IF(utm_source = 'gsearch',website_session_id,NULL)) AS GSEARCH_SESSIONS,
COUNT( DISTINCT IF(utm_source = 'bsearch',website_session_id,NULL)) AS BSEARCH_SESSIONS
FROM website_sessions 
WHERE (DATE(created_at) BETWEEN  "2012-08-22" AND  "2012-11-29") AND utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at)
ORDER BY 1 ;

# Request-2 - Comparing Our Channels.
/*
NEW MESSAGE November 30, 2012
From: Tom Parmesan (Marketing Director) 
Subject: Comparing Our Channels
Hi there,
I'd like to learn more about the bsearch nonbrand campaign.
Could you please pull the percentage of traffic coming on Mobile, and compare that to gsearch?
Feel free to dig around and share anything else you find interesting.
Aggregate data since August 22nd is great, no need to show trending at this point.
Thanks, Tom
*/
WITH CTE AS (
		SELECT utm_source, 
        COUNT(DISTINCT website_session_id) AS SESSIONS,
		COUNT( DISTINCT IF(device_type = 'mobile',website_session_id,NULL)) AS MOBILE_SESSIONS
		FROM website_sessions 
		WHERE (DATE(created_at) BETWEEN  "2012-08-22" AND  "2012-11-30") AND utm_campaign = 'nonbrand'
		GROUP BY utm_source)
SELECT *,MOBILE_SESSIONS/SESSIONS AS PCT FROM CTE
GROUP BY utm_source;

# Request-3 - Multi-Channel Bidding.
/*
NEW MESSAGE December 01, 2012
From: Tom Parmesan (Marketing Director)
Subject: Multi-Channel Bidding
Hi there,
I'm wondering if bsearch nonbrand should have the same bids as gsearch.
Could you pull nonbrand conversion rates from session to order for gsearch and bsearch, and slice the data by device type?
Please analyze data from August 22 to September 18;
we ran a special pre-holiday campaign for gsearch starting on September 19th, so the data after that isn't fair game.
Thanks, Tom
*/
SELECT device_type,utm_source,
		COUNT( DISTINCT website_session_id) AS SESSIONS,
		COUNT(DISTINCT order_id) AS ORDERS,
        COUNT(DISTINCT order_id)/COUNT( DISTINCT website_session_id) AS CONVERSION_RATE
FROM website_sessions W
LEFT JOIN orders USING(website_session_id)
WHERE (DATE(W.created_at) BETWEEN "2012-08-22" AND "2012-09-18") AND utm_campaign = 'nonbrand'
GROUP BY 1,2;

# Request-4 - Impact of Bid Changes.
/*
NEW MESSAGE December 22, 2012
From: Tom Parmesan (Marketing Director) 
Subject: Impact of Bid Changes.
Hi there,
Based on your last analysis, we bid down bsearch nonbrand on December 2nd.
Can you pull weekly session volume for gsearch and bsearch nonbrand, broken down by device, since November 4th?
If you can include a comparison metric to show bsearch as a percent of gsearch for each device, that would be great too.
Thanks, Tom
*/
WITH CTE AS(
SELECT MIN(DATE(created_at)),
		COUNT( DISTINCT IF(device_type = 'desktop' AND utm_source = 'bsearch',website_session_id,NULL)) AS BS_DSK_SESSIONS,
        COUNT( DISTINCT IF(device_type = 'desktop' AND utm_source = 'gsearch',website_session_id,NULL)) AS GS_DSK_SESSIONS,
        COUNT( DISTINCT IF(device_type = 'mobile' AND utm_source = 'bsearch',website_session_id,NULL)) AS BS_MOB_SESSIONS,
        COUNT( DISTINCT IF(device_type = 'mobile' AND utm_source = 'gsearch',website_session_id,NULL)) AS GS_MOB_SESSIONS
FROM website_sessions
WHERE (DATE(created_at) BETWEEN "2012-11-04" AND "2012-12-22") AND utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at))
SELECT *,BS_DSK_SESSIONS/GS_DSK_SESSIONS AS DESKTOP_B_TO_G_PCT,BS_MOB_SESSIONS/GS_MOB_SESSIONS AS MOBILE_B_TO_G_PCT
FROM CTE;

# CONCEPT 2 ANALYZING DIRECT TRAFFIC.

# WHEN UTM PARAMETERS ARE EMPTY, THEN ITS - DIRECT TRAFFIC, IF NOT THEN ITS PAID TRAFFIC.
# AMONGS DIRECT TRAFFIC, IF HTTP_REFERS IS NULL - THE ITS DIRECT TRAFFICE, ELSE ITS ORGANIC 

-- ANALYZING DIRECT_TRAFFIC BY SESSIONS.
WITH CTE AS(
SELECT *,CASE 
			WHEN http_referer IS NULL THEN "DIRECT_TYPE_IN"
			WHEN http_referer = 'https://www.gsearch.com' THEN "G_SEARCH_ORGANIC"
			WHEN http_referer = 'https://www.Bsearch.com' THEN "B_SEARCH_ORGANIC"
			ELSE "OTHERS"
		END AS TRAFFIC_TYPE
FROM website_sessions
WHERE utm_source IS NULL)
SELECT TRAFFIC_TYPE,COUNT(DISTINCT website_session_id) AS SESSION_COUNT
FROM CTE 
GROUP BY TRAFFIC_TYPE;

-- PAID AND NON PAID SEARCH TRAFFIC SESSIONS
WITH CTE AS(
SELECT *,CASE 
			WHEN http_referer IS NULL THEN "DIRECT_TYPE_IN"
			WHEN http_referer = 'https://www.gsearch.com' AND utm_source IS NULL THEN "G_SEARCH_ORGANIC"
			WHEN http_referer = 'https://www.Bsearch.com' AND utm_source IS NULL THEN "B_SEARCH_ORGANIC"
			ELSE "PAID_TRAFFIC"
		END AS TRAFFIC_TYPE
FROM website_sessions )
SELECT TRAFFIC_TYPE,COUNT(DISTINCT website_session_id) AS SESSION_COUNT
FROM CTE 
GROUP BY TRAFFIC_TYPE;

# Request-5 - Site traffic breakdown.
/*
NEW MESSAGE December 23, 2012
From: Cindy Sharp (CEO)
Subject: Site traffic breakdown
Good morning,
A potential investor is asking if we're building any momentum with our brand or if we'll need to keep relying on paid traffic.
Could you pull organic search, direct type in,
and paid brand search sessions by month, and show those sessions as a % of paid search nonbrand?
-Cindy
*/

WITH CTE AS(
SELECT YEAR(created_at) AS YEAR, MONTH(created_at) AS MONTH,
		COUNT(DISTINCT IF(utm_campaign = 'nonbrand',website_session_id,NULL)) AS "NON_BRAND",
		COUNT(DISTINCT IF(utm_campaign = 'brand',website_session_id,NULL)) AS "BRAND",
		COUNT(DISTINCT IF(http_referer IS NULL,website_session_id,NULL)) AS "DIRECT_TYPE_IN",
		COUNT(DISTINCT IF(http_referer IS NOT NULL AND utm_source IS NULL,website_session_id,NULL)) AS "ORGANIC_TRAFFIC"
FROM website_sessions
WHERE created_at < "2012-12-23"
GROUP BY 1,2)
SELECT *,BRAND/NON_BRAND AS B_NB_PCT,
         DIRECT_TYPE_IN/NON_BRAND AS D_NB_PCT,
         ORGANIC_TRAFFIC/NON_BRAND AS O_NB_PCT
FROM CTE;

-- *********************************************************************************************

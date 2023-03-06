# Analyzing Top Website Performance.

-- To Get Number of Visits to Each Page.
select pageview_url,count(DISTINCT website_pageview_id) AS PVS
from website_pageviews
where website_pageview_id < 1000
GROUP BY  pageview_url
ORDER  BY 2 DESC;

-- TO FIND THE TOP ENTRY PAGE..
WITH CTE AS 
			(SELECT website_session_id,website_pageview_id,pageview_url,
			row_number() over(partition by website_session_id order by website_pageview_id) as rn
			from website_pageviews
			GROUP BY website_session_id,website_pageview_id,pageview_url),
	CTE2 AS (SELECT website_session_id,pageview_url AS landing_page FROM CTE 
			WHERE RN  =1)
SELECT landing_page, COUNT(DISTINCT website_session_id) 
FROM CTE2
GROUP BY landing_page;


# Request-1 - Top Website Pages.
/*
1 NEW MESSAGE June 09, 2012
From: Morgan Rockwell (Website Manager)
Subject: Top Website Pages
Hi there!
I'm Morgan, the new Website Manager.
Could you help me get my head around the site by pulling the most-viewed website pages,
ranked by session volume?
Thanks!
-Morgan
*/
SELECT DISTINCT pageview_url,COUNT(pageview_url)  AS SESSIONS_COUNT
FROM website_pageviews
WHERE DATE(created_at) < "2012-06-09"
GROUP BY pageview_url;

# Request-2 - Top Entry Pages.
/*
NEW MESSAGE
June 12, 2012
From: Morgan Rockwell (Website Manager)
Subject: Top Entry Pages
Hi there!
Would you be able to pull a list of the top entry pages?
I want to confirm where our users are hitting the site.
If you could pull all entry pages and rank them on entry volume, that would be great.
Thanks!
-Morgan
*/
WITH CTE AS 
		(SELECT website_session_id,website_pageview_id,pageview_url,
		ROW_NUMBER() OVER(PARTITION BY website_session_id ORDER BY  website_pageview_id) AS RN
		FROM website_pageviews
		WHERE DATE(created_at) < "2012-06-12"
		GROUP BY website_session_id,website_pageview_id,pageview_url)
SELECT pageview_url AS LANDING_PAGE, COUNT(DISTINCT website_session_id) AS VOLUME
FROM CTE 
WHERE RN = 1
ORDER BY 2;

# CONCEPT 1 - ANALYZING BOUNCE RATES AND LANDING PAGE TESTS.
-- landing page Performance and Testing.
-- CALCULATE BOUNCE RATES, CONVERSION RATES.
 
-- IF RN == 1 - LANDING PAGES.
-- IF RN>1 FOR ANY CUSTOMERS THEN THEY HAVE MOVED ON FROM HOME PAGE TO OTHER PAGES.
-- CONVERSION RATE  = WHEN FOR AN WEBSITE_SESION,IF USER MOVES FROM LANDING_PAGE TO NEXT_PAGE -- CONVERTED,
-- NUMBER OF SESSIONS WHERE AN USER IS AT LANDING PAGE FOR AN PARTICULAR URL. - SESSION_COUNT
-- NUMBER OF SESSIONS WHERE AN USER IS AT NEXT_PAGE FOR AN PARTICULAR URL - CONVERSION_COUNT.
-- CONVERSION_COUNT/SESSIONS_COUNT -- CONVERSION_RATE
-- (1-CONVERSSION_RATE) = BOUNCE_RATE..

# CREATING VIEW WITH -- ROW_NUMBER TO IDENTIFY LANDING PAGES AND NEXT_PAGES..
CREATE VIEW MASTER_TABLE AS 
SELECT website_session_id,website_pageview_id,pageview_url,
ROW_NUMBER() OVER(PARTITION BY website_session_id ORDER BY website_pageview_id) AS RN
FROM website_pageviews
GROUP BY 1,2,3
ORDER BY 1;

SELECT * FROM MASTER_TABLE;

SELECT * FROM MASTER_TABLE WHERE RN = 1; # ALL DETAILS WHEN WEBSESSIONS AT LANDING PAGES

SELECT website_session_id FROM MASTER_TABLE WHERE RN = 1;

# DETAILS OF ALL THOSE, WHO WERE IN LANDING PAGE AND HAVE MOVED TO NEXT PAGE...
SELECT * 
FROM MASTER_TABLE 
WHERE RN = 2 AND website_session_id IN(SELECT website_session_id FROM MASTER_TABLE WHERE RN = 1);

# COMBINING BOTH TO GET AN MATRIX OF ALL.
WITH CTE1 AS (SELECT * FROM MASTER_TABLE WHERE RN = 1),
	 CTE2 AS (SELECT * 
				FROM MASTER_TABLE 
				WHERE RN = 2 AND website_session_id IN(SELECT website_session_id FROM MASTER_TABLE WHERE RN = 1))
SELECT C1.website_session_id, C1.website_pageview_id AS C1PAGE_VIEW,C1.pageview_url AS LANDING_PAGE,C1.RN AS C1RN,
C2.website_pageview_id AS C2PAGE_VIEW,C2.pageview_url AS NEXT_PAGE,C2.RN AS C2RN
FROM CTE1 C1
LEFT JOIN CTE2 C2 USING(website_session_id);

# CREATING AN TEMP TABLE FOR THE SAME.
CREATE TEMPORARY TABLE TABLE1
WITH CTE1 AS (SELECT * FROM MASTER_TABLE WHERE RN = 1),
	 CTE2 AS (SELECT * 
				FROM MASTER_TABLE 
				WHERE RN = 2 AND website_session_id IN(SELECT website_session_id FROM MASTER_TABLE WHERE RN = 1))
SELECT C1.website_session_id, C1.website_pageview_id AS C1PAGE_VIEW,C1.pageview_url AS LANDING_PAGE,C1.RN AS C1RN,
C2.website_pageview_id AS C2PAGE_VIEW,C2.pageview_url AS NEXT_PAGE,C2.RN AS C2RN
FROM CTE1 C1
LEFT JOIN CTE2 C2 USING(website_session_id);

SELECT * FROM TABLE1;

SELECT DISTINCT LANDING_PAGE,
COUNT(LANDING_PAGE) AS SESSIONS_COUNT,
COUNT(NEXT_PAGE) AS CONVERSION_COUNT,
(1 - (COUNT(NEXT_PAGE)/COUNT(LANDING_PAGE)))*100 AS BOUNCE_RATE
FROM TABLE1
GROUP BY 1;

# Request-3 - Bounce Rate Analysis.
/*
NEW MESSAGE June 14, 2012
From: Morgan Rockwell (Website Manager) 
Subject: Bounce Rate Analysis
Hi there!
The other day you showed us that all of our traffic is landing on the homepage right now. 
We should check how that landing page is performing.
Can you pull bounce rates for traffic landing on the homepage? 
I would like to see three numbers...Sessions, Bounced Sessions,
and % of Sessions which Bounced (aka "Bounce Rate").
Thanks!
-Morgan
*/ -- OUTPUT -- SESSIONS,BOUNCED_SESSIONS,BOUNCE_RATE.

CREATE VIEW  T1 AS 
SELECT website_session_id,website_pageview_id,pageview_url,
ROW_NUMBER() OVER(PARTITION BY website_session_id ORDER BY website_pageview_id) AS RN
FROM website_pageviews
WHERE created_at < "2012-06-14"
GROUP BY 1,2,3;

SELECT * FROM T1;

CREATE TEMPORARY TABLE T2
WITH CTE1 AS (SELECT * FROM T1 WHERE RN = 1),
	 CTE2 AS (SELECT * 
				FROM T1
				WHERE RN = 2 AND website_session_id IN(SELECT website_session_id FROM T1 WHERE RN = 1))
SELECT C1.website_session_id, C1.website_pageview_id AS C1PAGE_VIEW,C1.pageview_url AS LANDING_PAGE,C1.RN AS C1RN,
C2.website_pageview_id AS C2PAGE_VIEW,C2.pageview_url AS NEXT_PAGE,C2.RN AS C2RN
FROM CTE1 C1
LEFT JOIN CTE2 C2 USING(website_session_id);

SELECT * FROM T2;

SELECT DISTINCT LANDING_PAGE,
COUNT(LANDING_PAGE) AS SESSIONS_COUNT,
COUNT(LANDING_PAGE) - COUNT(NEXT_PAGE) AS BOUNCED_COUNT,
ROUND((1 - (COUNT(NEXT_PAGE)/COUNT(LANDING_PAGE)))*100,2) AS BOUNCE_RATE
FROM T2
GROUP BY 1;

# Request-4 - Help Analyzing LANDING PAGE Test.(A/B Split Testing).
/*
NEW MESSAGE July 28, 2012
From: Morgan Rockwell (Website Manager)
Subject: Help Analyzing LP Test
Hi there!
Based on your bounce rate analysis, we ran a new custom landing page (/lander-1) in a 50/50 test against the homepage (/home) for our gsearch nonbrand traffic.
Can you pull bounce rates for the two groups so we can evaluate the new page? Make sure to just look at the time period where /lander-1 was getting traffic, so that it is a fair comparison.
Thanks, Morgan
*/
# TO GET THE DATE WHEN LANDER-1 WAS LAUNCHED, SO WE CAN COMPARE HOME-PAGE VS LANDER-1 FOR BOUNCED_RATE..
SELECT MIN(DATE(created_at))
FROM website_pageviews WHERE pageview_url = '/lander-1'
ORDER BY created_at;

# GETTING ALL WEBSITE SESSIONS FOR GSEARCH , NONBRAND TRAFFIC...
SELECT website_session_id FROM website_sessions
WHERE utm_source = 'gsearch' AND utm_campaign = 'nonbrand';

-- QUERY TIME..
CREATE VIEW  T3 AS 
SELECT website_session_id,website_pageview_id,pageview_url,
ROW_NUMBER() OVER(PARTITION BY website_session_id ORDER BY website_pageview_id) AS RN
FROM website_pageviews
WHERE (created_at > (SELECT MIN(DATE(created_at)) FROM website_pageviews WHERE pageview_url = '/lander-1' ORDER BY created_at)  AND created_at < "2012-07-28" )
AND
(website_session_id IN (SELECT website_session_id FROM website_sessions WHERE utm_source = 'gsearch' AND utm_campaign = 'nonbrand'));

SELECT * FROM T3;

CREATE TEMPORARY TABLE T4
WITH CTE1 AS (SELECT * FROM T3 WHERE RN = 1),
	 CTE2 AS (SELECT * 
				FROM T3
				WHERE RN = 2 AND website_session_id IN(SELECT website_session_id FROM T3 WHERE RN = 1))
SELECT C1.website_session_id, C1.website_pageview_id AS C1PAGE_VIEW,C1.pageview_url AS LANDING_PAGE,C1.RN AS C1RN,
C2.website_pageview_id AS C2PAGE_VIEW,C2.pageview_url AS NEXT_PAGE,C2.RN AS C2RN
FROM CTE1 C1
LEFT JOIN CTE2 C2 USING(website_session_id);

SELECT * FROM T4;

SELECT DISTINCT LANDING_PAGE,
COUNT(LANDING_PAGE) AS SESSIONS_COUNT,
COUNT(LANDING_PAGE) - COUNT(NEXT_PAGE) AS BOUNCED_COUNT,
ROUND((1 - (COUNT(NEXT_PAGE)/COUNT(LANDING_PAGE)))*100,2) AS BOUNCE_RATE
FROM T4
GROUP BY 1;

# Request-5 - Landing Page Trend Analysis.
/*
NEW MESSAGE August 31, 2012
From: Morgan Rockwell (Website Manager) 
Subject: Landing Page Trend Analysis
Hi there,
Could you pull the volume of paid search nonbrand traffic landing on /home and /lander-1, trended weekly since June 1st?
I want to confirm the traffic is all routed correctly.
Could you also pull our overall paid search bounce rate trended weekly?
I want to make sure the lander change has improved the overall picture.
Thanks!
*/ -- OUT-PUT -- WEEK_START_DATE,BOUNCE_RATE,HOME_SESSIONS,_LANDER_SESSIONS.

# 1.TREND ANALYSIS FOR HOME, LANDER-1 - WEEKLY TREND..
SELECT MIN(DATE(created_at)) AS WEEK_START_DATE,
COUNT(IF(pageview_url = '/home',1,NULL)) AS HOME_SESSIONS,
COUNT(IF(pageview_url = '/lander-1',1,NULL)) AS LANDER_SESSIONS
FROM website_pageviews
WHERE (created_at BETWEEN  "2012-06-01" AND "2012-08-31") AND 
website_session_id IN ( SELECT website_session_id FROM website_sessions WHERE utm_source = 'gsearch' AND utm_campaign = 'nonbrand')
GROUP BY WEEK(created_at);

CREATE TEMPORARY TABLE T8
SELECT MIN(DATE(created_at)) AS WEEK_START_DATE,
COUNT(IF(pageview_url = '/home',1,NULL)) AS HOME_SESSIONS,
COUNT(IF(pageview_url = '/lander-1',1,NULL)) AS LANDER_SESSIONS
FROM website_pageviews
WHERE (created_at BETWEEN  "2012-06-01" AND "2012-08-31") AND 
website_session_id IN ( SELECT website_session_id FROM website_sessions WHERE utm_source = 'gsearch' AND utm_campaign = 'nonbrand')
GROUP BY WEEK(created_at);

# 2. BOUNCE RATES FOR LANDER-1..
CREATE VIEW T5 AS
SELECT *,
ROW_NUMBER() OVER(PARTITION BY website_session_id ORDER BY website_pageview_id) AS RN
FROM website_pageviews
WHERE (created_at BETWEEN  "2012-06-01" AND "2012-08-31") AND 
website_session_id IN ( SELECT website_session_id FROM website_sessions WHERE utm_source = 'gsearch' AND utm_campaign = 'nonbrand');

SELECT * FROM T5;

CREATE TEMPORARY TABLE T6
WITH CTE1 AS (SELECT * FROM T5 WHERE RN = 1),
	 CTE2 AS (SELECT * 
				FROM T5
				WHERE RN = 2 AND website_session_id IN(SELECT website_session_id FROM T5 WHERE RN = 1))
SELECT C1.created_at,C1.pageview_url AS LANDING_PAGE,C2.pageview_url AS NEXT_PAGE
FROM CTE1 C1
LEFT JOIN CTE2 C2 USING(website_session_id);

SELECT * FROM T6;

CREATE TEMPORARY TABLE T9
SELECT MIN(DATE(created_at)) AS WEEK_START_DATE,
ROUND((1 - (COUNT(NEXT_PAGE)/COUNT(LANDING_PAGE)))*100,2) AS BOUNCE_RATE
FROM T6
GROUP BY WEEK(created_at);

# COMBINING BOTH ...FOR REQUIRED OUTPUT
SELECT *
FROM T9
INNER JOIN T8 USING ( WEEK_START_DATE);

# CONCEPT 2 - ANALYZING AND TESTING CONVERSION FUNNELS..
-- CONVERSION FUNNELS..
-- IT TELLS US THE CONVERSION RATES, FROM EACH PAGE TO NEXT PAGE..
-- i,e.. - how many moved from landing page to - producrt page., product page to order page conversion rate, till last..

CREATE VIEW NEW_VIEW  AS
SELECT *,ROW_NUMBER() OVER(PARTITION BY website_session_id ORDER BY website_pageview_id) AS RN 
FROM website_pageviews;

SELECT * FROM NEW_VIEW;

# HERE WE HAVE OBTAINED- WHICH SESSION_ID HAS REACHED WHICH PAGE BY 
CREATE TEMPORARY TABLE NEW_TEMP
SELECT website_session_id,pageview_url,
COUNT(IF(RN =1, 1,NULL)) AS LANDING_COUNT,
COUNT(IF(RN =2, 1,NULL)) AS PRODUCT_COUNT,
COUNT(IF(RN =3, 1,NULL)) AS INDV_PRODUCT_COUNT,
COUNT(IF(RN =4, 1,NULL)) AS CART_COUNT,
COUNT(IF(RN =5, 1,NULL)) AS SHIPPING_COUNT,
COUNT(IF(RN =6, 1,NULL)) AS BILLING_COUNT,
COUNT(IF(RN =7, 1,NULL)) AS COMPLETED_COUNT
FROM NEW_VIEW
GROUP BY website_session_id;

# SO TO GET TOTAL CONVERSION RATE - WE HAVE TO DO FEW AGGREGATIONS ON THE SAME.
SELECT * FROM NEW_TEMP;

# THIS GIVES COUNT.
SELECT SUM(LANDING_COUNT) AS SESSIONS_COUNT,
SUM(PRODUCT_COUNT) AS PROD_PAGE_COUNT,
SUM(INDV_PRODUCT_COUNT) AS INDV_PRODUCT_COUNT,
SUM(CART_COUNT) AS CART_COUNT,
SUM(SHIPPING_COUNT) AS SHIPPING_COUNT,
SUM(BILLING_COUNT) AS BILLING_COUNT,
SUM(COMPLETED_COUNT) AS COMPLETED_COUNT
FROM NEW_TEMP;
 
# THIS GIVES % AT EACH STAGES..
 WITH CTE AS (
SELECT SUM(LANDING_COUNT) AS SESSIONS_COUNT,
		SUM(PRODUCT_COUNT) AS PROD_PAGE_COUNT,
		SUM(INDV_PRODUCT_COUNT) AS INDV_PRODUCT_COUNT,
		SUM(CART_COUNT) AS CART_COUNT,
		SUM(SHIPPING_COUNT) AS SHIPPING_COUNT,
		SUM(BILLING_COUNT) AS BILLING_COUNT,
		SUM(COMPLETED_COUNT) AS COMPLETED_COUNT
FROM NEW_TEMP)
SELECT SESSIONS_COUNT,
		(PROD_PAGE_COUNT/SESSIONS_COUNT)  AS LANDING_CLICK_THRU_RATE,
		(INDV_PRODUCT_COUNT/PROD_PAGE_COUNT)  AS PRODUCT_CLICK_THRU_RATE,
		(CART_COUNT/INDV_PRODUCT_COUNT)  AS PRODUCT_SELECTION_CLICK_THRU_RATE,
		(SHIPPING_COUNT/CART_COUNT)  AS CART_CLICK_THRU_RATE,
		(BILLING_COUNT/SHIPPING_COUNT)  AS SHIPPING_CLICK_THRU_RATE,
		(COMPLETED_COUNT/BILLING_COUNT)  AS BILLING_COUNT_THRU_RATE
FROM CTE;

# Request-6 - Help Analyzing Conversion Funnels.
/*
NEW MESSAGE September 05, 2012
From: Morgan Rockwell (Website Manager) 
Subject: Help Analyzing Conversion Funnels
Hi there!
I'd like to understand where we lose our gsearch visitors between the new /lander-1 page and placing an order.
Can you build us a full conversion funnel, analyzing how many customers make it to each step?
Start with /lander-1 and build the funnel all the way to our thank you page. Please use data since August 5th.
Thanks!
-Morgan
*/

CREATE VIEW ASSIGN6 AS
SELECT website_session_id,website_pageview_id,pageview_url,
ROW_NUMBER() OVER(PARTITION BY website_session_id ORDER BY website_pageview_id) AS RN 
FROM website_pageviews
WHERE (created_at  BETWEEN "2012-08-05" AND "2012-09-05") AND
(website_session_id IN (SELECT website_session_id FROM website_sessions WHERE utm_source = 'gsearch'));

# TO GET COUNT..
CREATE TEMPORARY TABLE ASSIGN6_COUNT
SELECT 
COUNT(IF(RN =1, 1,NULL)) AS SESSIONS_COUNT,
COUNT(IF(RN =2, 1,NULL)) AS PROD_PAGE_COUNT,
COUNT(IF(RN =3, 1,NULL)) AS INDV_PRODUCT_COUNT,
COUNT(IF(RN =4, 1,NULL)) AS CART_COUNT,
COUNT(IF(RN =5, 1,NULL)) AS SHIPPING_COUNT,
COUNT(IF(RN =6, 1,NULL)) AS BILLING_COUNT,
COUNT(IF(RN =7, 1,NULL)) AS COMPLETED_COUNT
FROM ASSIGN6 WHERE pageview_url != '/home';

SELECT * FROM ASSIGN6_COUNT;

# TO GET PERCENT....
SELECT SESSIONS_COUNT,
		(PROD_PAGE_COUNT/SESSIONS_COUNT)  AS LANDING_CLICK_THRU_RATE,
		(INDV_PRODUCT_COUNT/PROD_PAGE_COUNT)  AS PRODUCT_CLICK_THRU_RATE,
		(CART_COUNT/INDV_PRODUCT_COUNT)  AS PRODUCT_SELECTION_CLICK_THRU_RATE,
		(SHIPPING_COUNT/CART_COUNT)  AS CART_CLICK_THRU_RATE,
		(BILLING_COUNT/SHIPPING_COUNT)  AS SHIPPING_CLICK_THRU_RATE,
		(COMPLETED_COUNT/BILLING_COUNT)  AS BILLING_COUNT_THRU_RATE
FROM ASSIGN6_COUNT;

# Request-7 - Conversion Funnel Test Results.(A/B Testing)
/* NEW MESSAGE
November 10, 2012
From: Morgan Rockwell (Website Manager)
Subject: Conversion Funnel Test Results
Hello!
We tested an updated billing page based on your funnel analysis.
Can you take a look and see whether /billing-2 is doing any better than the original /billing page?
We're wondering what % of sessions on those pages end up placing an order.
FYI - we ran this test for all traffic, not just for our search visitors.
Thanks!
-Morgan
*/

# WE WILL BE DOING AN A/B TEST FOR BILLING PAGE AND BILLING- PAGE 2.
# WE START FROM DATE WHEN BILLING PAGE 2 WAS CREATE  AND LIMIT TILL "2012-11-10" i,e THE DATE OF EMAIL recived..

select MIN(DATE(created_at)) from website_pageviews where pageview_url = '/billing-2';

CREATE VIEW ASSIGN7 AS
SELECT website_session_id,website_pageview_id,pageview_url,
ROW_NUMBER() OVER(PARTITION BY website_session_id ORDER BY website_pageview_id) AS RN 
FROM website_pageviews
WHERE (created_at  BETWEEN (select MIN(DATE(created_at)) from website_pageviews where pageview_url = '/billing-2') AND "2012-11-10");

SELECT * FROM ASSIGN7 WHERE RN >= 6;  # PAGES WHERE BILING OTHER PROCESS TOOK PLACE..

# TO GET BILLING PAGE AND NEXT PAGE..
CREATE TEMPORARY TABLE ASSIGN7_COUNT
WITH CTE1 AS (SELECT website_session_id,pageview_url AS LANGING_PAGE FROM ASSIGN7 WHERE RN = 6),
	 CTE2 AS (SELECT website_session_id,pageview_url AS NEXT_PAGE FROM ASSIGN7 WHERE RN = 7)
SELECT * 
FROM CTE1
LEFT JOIN CTE2 USING(website_session_id);

SELECT * FROM ASSIGN7_COUNT;

SELECT LANGING_PAGE AS BILLING_VERSION,
COUNT(DISTINCT website_session_id) AS SESSIONS,
COUNT(NEXT_PAGE) AS ORDERS_COMPLETED,
(COUNT(NEXT_PAGE)/COUNT(DISTINCT website_session_id)) AS CONVERSION_RATIO
FROM ASSIGN7_COUNT 
GROUP BY LANGING_PAGE;

-- **********************************************************************************************





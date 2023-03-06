# PRODUCT ANALYSIS

-- CONCEPT 1: PRODUCT SALES ANALYSIS

-- orders -- number of orders. -(count(order_id))
-- revenue -- money the business brings in from orders. -sum(price_usd)
-- margin -- revenue after cogs..i,e revenue-cogs --row level, i,e sum(price_usd-cogs)
-- AOV - Average revenue generated per order. -avg(price_usd)

# TO GET SAMPLE OF ORDERS VOLUME, REVENUE, MARGIN, AVG_ORDER_VALUE -- IN AN SAMPLE SPACE..
SELECT COUNT(order_id) AS ORDERS,
	   SUM(price_usd) AS REVENUE,
       SUM(price_usd-cogs_usd) AS MARGIN,
       AVG(price_usd) AS AVERAGE_ORDER_VALUE
FROM orders
WHERE ORDER_ID BETWEEN 100 AND 200; -- ARBITARY SAMPLE SPACE..

# TO GET ORDERS VOLUME, REVENUE, MARGIN, AVG_ORDER_VALUE - IN AN SAMPLE SPACE..FOR THE INDIVIDUAL PRODUCTS
SELECT primary_product_id,COUNT(order_id) AS ORDERS,
	   SUM(price_usd) AS REVENUE,
       SUM(price_usd-cogs_usd) AS MARGIN,
       AVG(price_usd) AS AVERAGE_ORDER_VALUE
FROM orders
WHERE ORDER_ID BETWEEN 10000 AND 11000      -- ARBITARY SAMPLE SPACE..
GROUP BY 1;

# Request 1: Sales Trends.
/*
NEW MESSAGE
January 04, 2013
From: Cindy Sharp (CEO)
Subject: Sales Trends
Good morning
We're about to launch a new product, and l'd like to do a
deep dive on our current flagship product.
Can you please pull monthly trends to date for number of
sales, total revenue, and total margin generated for the
business?
Cindy
*/
SELECT YEAR(created_at),MONTH(created_at),
       COUNT(order_id) AS NUMBER_OF_SALES,
	   SUM(price_usd) AS TOTAL_REVENUE,
       SUM(price_usd-cogs_usd) AS TOTAL_MARGIN
FROM orders
WHERE DATE(created_at) < "2013-01-04"
GROUP BY 1,2;

# Request 2: Impact of New Product Launch.
/*
NEW MESSAGE
April 05, 2013
From: Cindy Sharp (CEO)
Subject: Impact of New Product Launch
Good morning,
We launched our second product back on January 6th, Can
you pull together some trended analysis?
r'd like to see monthly order volume, overall conversion
rates, revenue per session, and a breakdown of sales by
product, all for the time period since April 1, 2012.
Thanks,
-Cindy
*/
SELECT YEAR(W.created_at) AS YR,
	   MONTH(W.created_at) AS MO,
       COUNT(DISTINCT W.website_session_id) AS SESSIONS,
	   COUNT(DISTINCT O.order_id) AS ORDERS,
       COUNT(DISTINCT O.order_id)/COUNT(DISTINCT W.website_session_id) AS CVR,
       SUM(O.price_usd)/COUNT(DISTINCT W.website_session_id) AS REVENUE_PER_SESSION,
       COUNT(DISTINCT IF(O.primary_product_id = 1,O.order_id,NULL)) AS PRODUCT_ONE_ORDERS,
       COUNT(DISTINCT IF(O.primary_product_id = 2,O.order_id,NULL)) AS PRODUCT_TWO_ORDERS
FROM website_sessions W
LEFT JOIN  orders O ON O.website_session_id = W.website_session_id
WHERE W.created_at > "2012-04-01" AND W.created_at < "2013-04-01"
GROUP BY 1,2;

-- CONCEPT 2: PRODUCT LEVEL WEBSITE ANALYSIS
-- Understanding how well each product converts customers.
WITH CTE AS(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY website_session_id ORDER BY website_pageview_id) AS RN 
FROM website_pageviews
WHERE created_at BETWEEN "2013-02-01" AND "2013-03-01")
SELECT pageview_url,COUNT(website_pageview_id) FROM CTE WHERE RN =3 GROUP BY 1 ;

# GETTING SESSIONS,ORDERS, CVR TO INDIVIDUAL PRODUCTS..
WITH CTE AS(
			SELECT W.*,O.order_id,
			ROW_NUMBER() OVER(PARTITION BY W.website_session_id ORDER BY W.website_pageview_id) AS RN 
			FROM website_pageviews W
			LEFT JOIN orders O USING(website_session_id)
			WHERE W.created_at BETWEEN "2013-02-01" AND "2013-03-01")
SELECT pageview_url,
	   COUNT(website_session_id) AS SESSIONS, 
       COUNT(order_id) AS ORDERS ,
       COUNT(order_id)/COUNT(website_session_id) AS VIEWD_PRD_TO_ORDER
FROM CTE 
WHERE RN =3 
GROUP BY 1 ;

-- Request 3: Help with User Pathing
/*
NEW MESSAGE
April 06, 2013
From: Morgan Rockwell (Website Manager)
Subject: Help w/ User Pathing
Hi there!
Now that we have a new product, ľ'm thinking about our
user path and conversion funnel. Let's look at sessions which
hit the /products page and see where they went next.
Could you please pull clickthrough rates from /products
since the new product launch on January 6th 2013, by
product, and compare to the 3 months leading up to launch
as a baseline?
Thanks, Morgan
*/
-- launch date --> "2013-01-06"
-- CONVERSION FUNNEL ANALYSIS.

SELECT * FROM website_pageviews;

# DATE RANGE 3 MONTHS BEFORE THE LAUNCH DATE..

SELECT DATE_ADD("2013-01-06",INTERVAL -3 MONTH);

CREATE VIEW PLT1 AS
SELECT *,
ROW_NUMBER() OVER(PARTITION BY website_session_id ORDER BY website_pageview_id) AS RN 
FROM website_pageviews
WHERE (DATE(created_at) > '2012-10-06' AND DATE(created_at) < "2013-01-06");

SELECT * FROM PLT1; # PLT1 HAS DETAILS WHERE PRODUCT PAGE WILL LOOK LIKE THE LANDING PAGE WHEN DATA EXTRACTED FRO THE GIVEN DATE RANGE.
# PLT1 HAS DETAILS WHERE PRODUCT PAGE WILL LOOK LIKE THE LANDING PAGE WHEN DATA EXTRACTED FRO THE GIVEN DATE RANGE.

SELECT * FROM PLT1 WHERE pageview_url = '/products';

-- THIS  BELOW VIEW HAS ALL THE DETAILS FOR WEBSITE SESSIONS IN THE GIVEN DATE RANGE.
CREATE VIEW PLAS3T1 AS 
SELECT *,
ROW_NUMBER() OVER(PARTITION BY website_session_id ORDER BY website_pageview_id) AS RN 
FROM website_pageviews WHERE website_session_id IN ( SELECT website_session_id FROM PLT1);

SELECT * FROM PLAS3T1 WHERE pageview_url = '/products';

SELECT * FROM PLAS3T1 WHERE RN =2; # PRODUCTS PAGE
SELECT website_session_id FROM PLAS3T1 WHERE RN =2;
SELECT * FROM PLAS3T1 WHERE RN =3; # PRODUCTS NEXT PAGE.
SELECT * FROM PLAS3T1 WHERE RN =3 AND website_session_id IN (SELECT website_session_id FROM PLAS3T1 WHERE RN =2);

CREATE TEMPORARY TABLE PLAS3TT1
WITH CTE1 AS (SELECT * FROM PLAS3T1 WHERE RN =2),
	 CTE2 AS (SELECT * FROM PLAS3T1 WHERE RN =3 AND website_session_id IN (SELECT website_session_id FROM PLAS3T1 WHERE RN =2))
SELECT CTE1.website_session_id,
	   CTE1.website_pageview_id,
       CTE1.created_at,
       CTE1.pageview_url AS PRODUCT_PAGE,
       CTE2.pageview_url AS SELECTED_PRODUCT_PAGE,
       CTE1.RN AS RN1,
       CTE2.RN AS RN2
 FROM CTE1 LEFT JOIN CTE2 USING(website_session_id);

SELECT DISTINCT SELECTED_PRODUCT_PAGE FROM  PLAS3TT1;

CREATE TEMPORARY TABLE PRE_PRODUCT_2
WITH CTE AS (
SELECT "PRE_PRODUCT_2" AS TIME_PEROID,
COUNT(website_session_id) AS SESSIONS,
	   COUNT(SELECTED_PRODUCT_PAGE) AS W_NEXT_PAGE,
       COUNT(DISTINCT IF(SELECTED_PRODUCT_PAGE = '/the-original-mr-fuzzy',website_session_id, NULL)) AS TO_MRFUZZY,
       COUNT(DISTINCT IF(SELECTED_PRODUCT_PAGE = '/the-forever-love-bear',website_session_id, NULL)) AS TO_LOVEBEAR
FROM PLAS3TT1)
SELECT TIME_PEROID,
	   SESSIONS,
       W_NEXT_PAGE,
       W_NEXT_PAGE/SESSIONS AS PCT_W_NECXT_PG,
       TO_MRFUZZY,
	   TO_MRFUZZY/SESSIONS AS PCT_TO_MRFUZZY,
       TO_LOVEBEAR,
       TO_LOVEBEAR/SESSIONS AS PCT_TO_LOVEBEAR
FROM CTE;

SELECT * FROM  PRE_PRODUCT_2;

# DATE RANGE 3 MONTHS AFTER THE LAUNCH DATE..

SELECT DATE_ADD("2013-01-06",INTERVAL 3 MONTH);

CREATE VIEW PLT2 AS
SELECT *
FROM website_pageviews
WHERE (DATE(created_at) BETWEEN '2013-01-06' AND '2013-04-06');

SELECT * FROM PLT2; # PLT1 HAS DETAILS WHERE PRODUCT PAGE WILL LOOK LIKE THE LANDING PAGE WHEN DATA EXTRACTED FRO THE GIVEN DATE RANGE.
# PLT1 HAS DETAILS WHERE PRODUCT PAGE WILL LOOK LIKE THE LANDING PAGE WHEN DATA EXTRACTED FRO THE GIVEN DATE RANGE.

-- THIS  BELOW VIEW HAS ALL THE DETAILS FOR WEBSITE SESSIONS IN THE GIVEN DATE RANGE.
CREATE VIEW PLAS3T2 AS 
SELECT *,
ROW_NUMBER() OVER(PARTITION BY website_session_id ORDER BY website_pageview_id) AS RN 
FROM website_pageviews WHERE website_session_id IN (SELECT website_session_id FROM PLT2);

SELECT * FROM PLAS3T2;

CREATE TEMPORARY TABLE PLAS3TT2
WITH CTE1 AS (SELECT * FROM PLAS3T2 WHERE RN =2),
	 CTE2 AS (SELECT * FROM PLAS3T2 WHERE RN =3 AND website_session_id IN(SELECT website_session_id FROM PLAS3T2 WHERE RN =2))
SELECT CTE1.website_session_id,
	   CTE1.website_pageview_id,
       CTE1.created_at,
       CTE1.pageview_url AS PRODUCT_PAGE,
       CTE2.pageview_url AS SELECTED_PRODUCT_PAGE,
       CTE1.RN AS RN1,
       CTE2.RN AS RN2
 FROM CTE1 LEFT JOIN CTE2 USING(website_session_id);
 
SELECT * FROM PLAS3TT2;
SELECT DISTINCT SELECTED_PRODUCT_PAGE FROM PLAS3TT2;

CREATE TEMPORARY TABLE POST_PRODUCT_2
WITH CTE AS (
SELECT "POST_PRODUCT_2" AS TIME_PEROID,
	   COUNT(website_session_id) AS SESSIONS,
	   COUNT(SELECTED_PRODUCT_PAGE) AS W_NEXT_PAGE,
       COUNT(DISTINCT IF(SELECTED_PRODUCT_PAGE = '/the-original-mr-fuzzy',website_session_id, NULL)) AS TO_MRFUZZY,
       COUNT(DISTINCT IF(SELECTED_PRODUCT_PAGE = '/the-forever-love-bear',website_session_id, NULL)) AS TO_LOVEBEAR
FROM PLAS3TT2)
SELECT TIME_PEROID,
	   SESSIONS,
       W_NEXT_PAGE,
       W_NEXT_PAGE/SESSIONS AS PCT_W_NECXT_PG,
       TO_MRFUZZY,
	   TO_MRFUZZY/SESSIONS AS PCT_TO_MRFUZZY,
       TO_LOVEBEAR,
       TO_LOVEBEAR/SESSIONS AS PCT_TO_LOVEBEAR
FROM CTE;

# FINAL RESULTS...
SELECT * FROM PRE_PRODUCT_2
UNION
SELECT * FROM POST_PRODUCT_2;

# ASSIGNMENT 4:(PRODUCT LEVEL CONVERSION FUNNEL).
/*
NEW MESSAGE
April 10, 2014
From: Morgan Rockwell (Website Manager)
Subject: Product Conversion Funnels
Hi there!
Id like to look at our two products since January 6th and
analyze the conversion funnels from each product page to
conversion.
It would be great if you could produce a comparison between
the two conversion funnels, for all website traffic.
Thanks!
-Morgan
*/

-- CONVERSION FUNNEL FOR EACH PRODUCT..

CREATE VIEW V1 AS
SELECT *,
ROW_NUMBER() OVER(PARTITION BY website_session_id ORDER BY website_pageview_id) AS RN 
FROM website_pageviews
WHERE (DATE(created_at) BETWEEN '2013-01-06' AND '2013-04-10');

CREATE VIEW PLAS4 AS 
WITH CTE AS(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY website_session_id ORDER BY website_pageview_id) AS RN 
FROM website_pageviews WHERE website_session_id IN (SELECT website_session_id FROM V1) AND (DATE(created_at) < '2013-04-10'))
SELECT * FROM CTE WHERE RN >= 3;

CREATE TEMPORARY TABLE T1
WITH CTE AS (
SELECT website_session_id,
	   pageview_url,
       COUNT(IF(RN =3, 1,NULL)) AS SESSIONS,
       COUNT(IF(RN =4, 1,NULL)) AS TO_CART,
       COUNT(IF(RN =5, 1,NULL)) AS TO_SHIPPING,
	   COUNT(IF(RN =6, 1,NULL)) AS TO_BILLING,
	   COUNT(IF(RN =7, 1,NULL)) AS TO_COMPLETE
FROM PLAS4
GROUP BY website_session_id)
SELECT pageview_url,
	   SUM(SESSIONS) AS SESSIONS,
       SUM(TO_CART) AS TO_CART,
       SUM(TO_SHIPPING) AS TO_SHIPPING,
       SUM(TO_BILLING) AS TO_BILLING,
       SUM(TO_COMPLETE) AS TO_COMPLETE
FROM CTE
GROUP BY pageview_url;
	
SELECT * FROM T1;


# TO GET PERCENTAGE..

SELECT  pageview_url,
	   TO_CART/SESSIONS AS PRODUCT_PG_CLICK_RT,
	   TO_SHIPPING/TO_CART AS CART_CLICK_RT,
       TO_BILLING/TO_SHIPPING AS SHIPPING_CLICK_RT,
       TO_COMPLETE/TO_BILLING AS BILLING_CLICK_RT
FROM T1;


# BUSINESS CONCEPT - CROSS-SELLING PRODUCTS
/*
Cross-sell analysis is about understanding which products users are most likely to purchase together, 
and offering smart product recommendations.

COMMON USE CASES:
Understanding which products are often purchased together.
Testing and optimizing the way you cross-sell products on your website.
Understanding the conversion rate impact and the overall revenue impact of trying to cross- sell additional products.
*/

-- CROSS PRODUCTS ARE THE PRODUCTS SOLD WOTH MAIN PRODUCTS, AND THESE ARE NOT THE PRIMARY OBJECT THAT THE USER INTENDED TO BUY..

SELECT * FROM orders WHERE order_id BETWEEN 10000 AND 11000;

-- THESE ARE CROSS SELLING PRODUCTS..(SAME QUERY)
WITH CTE AS(
SELECT O.order_id,O.primary_product_id,O.items_purchased,OI.order_item_id,OI.product_id,OI.is_primary_item
FROM orders O 
LEFT JOIN order_items OI USING(order_id)
WHERE O.order_id BETWEEN 10000 AND 11000 AND O.items_purchased > 1)
SELECT * FROM CTE WHERE primary_product_id!=product_id;

-- THESE ARE CROSS SELLING PRODUCTS..(SAME QUERY ABOVE)--- THESE PRODUCTS ARE SOLD WITH 
SELECT O.order_id,O.primary_product_id,O.items_purchased,OI.order_item_id,OI.product_id,OI.is_primary_item
FROM orders O 
LEFT JOIN order_items OI ON OI.order_id = O.order_id AND OI.is_primary_item = 0
WHERE O.order_id BETWEEN 10000 AND 11000 ;

# NOTE IMP..
-- IMPORTANT JOINS CONCEPT, WHEN JOINING IF THERE IS AN FILTER CONDITION ON BOTH TABLES, i,e AN WHERE CLAUSE TO BOTH THE TABLES,
-- THEN, YOU WONT GET THE DESIREDE RESULTS.
-- SO WHEN IN THIS CASE, YOU HAVE TO SPECIFY THE WHERE CONDITION OF THE JOINING TABLE IN THE ON CONDITION ON THE JOIN, JUST AS ABOVE,
-- YOU CANNOT HAVE THE BOTH FILTER CONDITIONS FOR BOTH TABLES IN ONE PLACE..

-- FROM ABOVE, --  WE GET ALL ORDER)ID, THEIR PRIMARY PRODUCT, THEIR CROSS PRODUCT IF ANY OR ELSE NULL.
SELECT O.order_id,
	   O.primary_product_id AS PRIMARY_PRODUCT,
	   OI.product_id AS CROSS_SELLING_PRODUCT
FROM orders O 
LEFT JOIN order_items OI ON OI.order_id = O.order_id AND OI.is_primary_item = 0
WHERE O.order_id BETWEEN 10000 AND 11000 ;

-- WE GET THE THE DETAILS WHERE WHICH GETS SOLD WITH WHICH BETTER
SELECT 
	   O.primary_product_id AS PRIMARY_PRODUCT,
	   OI.product_id AS CROSS_SELLING_PRODUCT,
       COUNT(DISTINCT O.order_id) AS ORDERS
FROM orders O 
LEFT JOIN order_items OI ON OI.order_id = O.order_id AND OI.is_primary_item = 0
WHERE O.order_id BETWEEN 10000 AND 11000
GROUP BY 1,2;

-- PIVOT COUNT METHOD -- WE COULD SEE THE SAME RESULTS HERE..
SELECT 
	   O.primary_product_id AS PRIMARY_PRODUCT,
       COUNT(DISTINCT O.order_id) AS ORDERS,
       COUNT(DISTINCT IF(OI.product_id = 1,O.order_id,NULL))AS '1',
       COUNT(DISTINCT IF(OI.product_id = 2,O.order_id,NULL))AS '2',
       COUNT(DISTINCT IF(OI.product_id = 3,O.order_id,NULL))AS '3'
FROM orders O 
LEFT JOIN order_items OI ON OI.order_id = O.order_id AND OI.is_primary_item = 0
WHERE O.order_id BETWEEN 10000 AND 11000
GROUP BY 1;

-- TO GET CROSS_SELL RATES..

WITH CTE AS (
			SELECT 
				   O.primary_product_id AS PRIMARY_PRODUCT,
				   COUNT(DISTINCT O.order_id) AS ORDERS,
				   COUNT(DISTINCT IF(OI.product_id = 1,O.order_id,NULL))AS 'PRD_1',
				   COUNT(DISTINCT IF(OI.product_id = 2,O.order_id,NULL))AS 'PRD_2',
				   COUNT(DISTINCT IF(OI.product_id = 3,O.order_id,NULL))AS 'PRD_3'
			FROM orders O 
			LEFT JOIN order_items OI ON OI.order_id = O.order_id AND OI.is_primary_item = 0
			WHERE O.order_id BETWEEN 10000 AND 11000
			GROUP BY 1)
SELECT *,
	   ROUND(PRD_1/ORDERS,4) AS '1_PCT',
       ROUND(PRD_2/ORDERS,4) AS '2_PCT',
       ROUND(PRD_3/ORDERS,4) AS '3_PCT'
FROM CTE;

# OR ...

SELECT 
	   O.primary_product_id AS PRIMARY_PRODUCT,
       COUNT(DISTINCT O.order_id) AS ORDERS,
       COUNT(DISTINCT IF(OI.product_id = 1,O.order_id,NULL)) AS '1',
       COUNT(DISTINCT IF(OI.product_id = 2,O.order_id,NULL)) AS '2',
       COUNT(DISTINCT IF(OI.product_id = 3,O.order_id,NULL)) AS '3',
       COUNT(DISTINCT IF(OI.product_id = 1,O.order_id,NULL))/COUNT(DISTINCT O.order_id) AS '1_PCT',
       COUNT(DISTINCT IF(OI.product_id = 2,O.order_id,NULL))/COUNT(DISTINCT O.order_id) AS '2_PCT',
       COUNT(DISTINCT IF(OI.product_id = 3,O.order_id,NULL))/COUNT(DISTINCT O.order_id) AS '3_PCT'
FROM orders O 
LEFT JOIN order_items OI ON OI.order_id = O.order_id AND OI.is_primary_item = 0
WHERE O.order_id BETWEEN 10000 AND 11000
GROUP BY 1;

# ASSIGNMENT 5:(CROSS-SELL ANALYSIS).
/*
NEW MESSAGE
November 22, 2013
From: Cindy Sharp (CEO)
Subject: Cross-Selling Performance
Good morning,
On September 25th we started giving customers the option
to add a 2nd product while on the /cart page. Morgan says
this has been positive, but l'd like your take on it.
Could you please compare the month before vs the month
after the change? I'd like to see CTR from the /cart page,
Avg Products per Order, AOV, and overall revenue per
Jcart page view.
Thanks, Cindy
*/
# APPROACH - 1..

-- 1.PRE_CROSS_SELL - SESSIONS, CLICK THROUGHS, CVR.

CREATE VIEW ASSIGN5 AS
SELECT *,
ROW_NUMBER() OVER(PARTITION BY website_session_id ORDER BY website_pageview_id) AS RN
FROM website_pageviews WHERE website_session_id IN(
SELECT website_session_id FROM website_pageviews WHERE DATE(created_at) > "2013-08-25" AND  DATE(created_at) < "2013-09-25")
AND DATE(created_at) < "2013-09-25";

CREATE TEMPORARY TABLE PRE_CROSS_SELL_1
WITH CTE3 AS(
	WITH CTE1 AS (SELECT * FROM ASSIGN5 WHERE RN =4),
		 CTE2 AS (SELECT * FROM  ASSIGN5 WHERE RN = 5 AND website_session_id IN(SELECT website_session_id FROM ASSIGN5 WHERE RN =4))
	SELECT CTE1.website_session_id,
		   CTE1.pageview_url AS CART_PG,
		   CTE2.pageview_url AS NEXT_PG
	FROM CTE1
	LEFT JOIN CTE2 ON CTE2.website_session_id = CTE1.website_session_id)
SELECT "PRE_CROSS_SELL" AS TIME_PEROID,
       COUNT(CART_PG) AS SESSIONS,
       COUNT(NEXT_PG) AS CLICK_THROUGH,
       COUNT(NEXT_PG)/COUNT(CART_PG) AS CART_CTR
FROM CTE3;
       
SELECT * FROM PRE_CROSS_SELL_1;

-- 2.PRE_CROSS_SELL - PRODUCTS_PDR_ORDER,_AOV,REVENUE PER SESSION.

SELECT *
FROM orders WHERE DATE(created_at) > "2013-08-25" AND  DATE(created_at) < "2013-09-25";

CREATE TEMPORARY TABLE PRE_CROSS_SELL_2
SELECT "PRE_CROSS_SELL" AS TIME_PEROID,
       SUM(price_usd) AS REVENUE,
       SUM(items_purchased)/COUNT(order_id) AS PRODUCTS_PER_ORDER,
	   SUM(price_usd)/COUNT(order_id) AS AVG_ORDER_VALUE  
FROM orders
WHERE DATE(created_at) > "2013-08-25" AND  DATE(created_at) < "2013-09-25";

SELECT * FROM PRE_CROSS_SELL_2;

CREATE TEMPORARY TABLE PRE_CROSS_SELL
SELECT TIME_PEROID,
       SESSIONS,
       CLICK_THROUGH,
       CART_CTR,
       PRODUCTS_PER_ORDER,
       AVG_ORDER_VALUE,
       REVENUE/SESSIONS AS REVENUE_PER_CART_SESSIONS
FROM PRE_CROSS_SELL_1 
LEFT JOIN PRE_CROSS_SELL_2 USING(TIME_PEROID);

SELECT * FROM PRE_CROSS_SELL;

-- 3.POST_CROSS_SELL - SESSIONS, CLICK THROUGHS, CVR.

CREATE VIEW ASSIGN5_2 AS
SELECT *,
ROW_NUMBER() OVER(PARTITION BY website_session_id ORDER BY website_pageview_id) AS RN
FROM website_pageviews WHERE website_session_id IN(
SELECT website_session_id FROM website_pageviews WHERE (DATE(created_at) BETWEEN "2013-09-25" AND   "2013-10-25"))
AND DATE(created_at) <= "2013-10-25";

SELECT * FROM ASSIGN5_2;

CREATE TEMPORARY TABLE POST_CROSS_SELL_1
WITH CTE3 AS(
	WITH CTE1 AS (SELECT * FROM ASSIGN5_2 WHERE RN =4),
		 CTE2 AS (SELECT * FROM  ASSIGN5_2 WHERE RN = 5 AND website_session_id IN(SELECT website_session_id FROM ASSIGN5_2 WHERE RN =4))
	SELECT CTE1.website_session_id,
		   CTE1.pageview_url AS CART_PG,
		   CTE2.pageview_url AS NEXT_PG
	FROM CTE1
	LEFT JOIN CTE2 ON CTE2.website_session_id = CTE1.website_session_id)
SELECT "POST_CROSS_SELL" AS TIME_PEROID,
       COUNT(CART_PG) AS SESSIONS,
       COUNT(NEXT_PG) AS CLICK_THROUGH,
       COUNT(NEXT_PG)/COUNT(CART_PG) AS CART_CTR
FROM CTE3;
       
SELECT * FROM PRE_CROSS_SELL_1;

-- 2.POST_CROSS_SELL - PRODUCTS_PDR_ORDER,_AOV,REVENUE PER SESSION.

SELECT *
FROM orders WHERE (DATE(created_at) BETWEEN "2013-09-25" AND  "2013-10-25");

CREATE TEMPORARY TABLE POST_CROSS_SELL_2
SELECT "POST_CROSS_SELL" AS TIME_PEROID,
       SUM(price_usd) AS REVENUE,
       SUM(items_purchased)/COUNT(order_id) AS PRODUCTS_PER_ORDER,
	   SUM(price_usd)/COUNT(order_id) AS AVG_ORDER_VALUE  
FROM orders
WHERE (DATE(created_at) BETWEEN "2013-09-25" AND  "2013-10-25");

SELECT * FROM POST_CROSS_SELL_2;

CREATE TEMPORARY TABLE POST_CROSS_SELL
SELECT TIME_PEROID,
       SESSIONS,
       CLICK_THROUGH,
       CART_CTR,
       PRODUCTS_PER_ORDER,
       AVG_ORDER_VALUE,
       REVENUE/SESSIONS AS REVENUE_PER_CART_SESSIONS
FROM POST_CROSS_SELL_1 
LEFT JOIN POST_CROSS_SELL_2 USING(TIME_PEROID);

SELECT * FROM POST_CROSS_SELL;

# FINAL QUERY.

SELECT * FROM PRE_CROSS_SELL
UNION 
SELECT * FROM POST_CROSS_SELL;

-- ***************************************

# APPROACH - 2..

CREATE VIEW A1 AS 
WITH CTE AS(
SELECT W.website_session_id,
	   W.pageview_url,
	   ROW_NUMBER() OVER(PARTITION BY W.website_session_id ORDER BY W.website_pageview_id) AS RN,
       O.order_id,
       O.items_purchased,
       O.price_usd,
       CASE
			WHEN DATE(W.created_at) < "2013-09-25" THEN "PRE_CROSS_SELL"
            WHEN DATE(W.created_at) >= "2013-09-25" THEN "POST_CROSS_SELL"
            ELSE "NOTHING"
            END AS TIME_PEROID
FROM website_pageviews W
LEFT JOIN orders O ON O.website_session_id = W.website_session_id
WHERE DATE(W.created_at) BETWEEN "2013-08-25" AND  "2013-10-25")
SELECT * FROM CTE WHERE RN IN(4,5);

SELECT * FROM A1;

CREATE TEMPORARY TABLE A2 
SELECT *,COUNT(DISTINCT IF(pageview_url ='/shipping',1,NULL)) AS NEXT_PAGE
FROM A1
GROUP BY website_session_id,order_id;

SELECT * FROM A2;

SELECT TIME_PEROID,
		COUNT(DISTINCT website_session_id) AS SESSIONS,
        SUM(NEXT_PAGE) AS CLICK_THROUGHS,
        SUM(NEXT_PAGE)/COUNT(DISTINCT website_session_id) AS CART_CTR,
        SUM(items_purchased)/COUNT(order_id) AS PRODUCTS_PER_ORDER,
        SUM(price_usd)/COUNT(order_id) AS AVG_ORDER_VALUE,
        SUM(price_usd)/COUNT(DISTINCT website_session_id) AS REVENUE_PER_CART_SESSIONS
FROM A2
GROUP BY TIME_PEROID;

-- ********************************************************************************************************************************

# ASSIGNMENT 6:(PRODUCT PORTFOLIO EXPANSION).
/*
NEW MESSAGE
January 12, 2014
From: Cindy Sharp (CEO)
Subject: Recent Product Launch
Good morning,
On December 12th 2013, we launched a third product
targeting the birthday gift market (Birthday Bear).
Could you please run a pre-post analysis comparing the
month before vs. the month after, in terms of session-to
order conversion rate, AOV, products per order, and
revenue per session?
Thank you
Cindy
*/
-- GIVEN NEW PRODUCT ADDED ON -"2013-12-12"

CREATE TEMPORARY TABLE A3
SELECT W.website_session_id,
		O.order_id,
        O.items_purchased,
        O.price_usd,
		CASE
			WHEN DATE(W.created_at) < "2013-12-12" THEN "PRE_BIRTH_YEAR"
			WHEN DATE(W.created_at) >= "2013-12-12" THEN "POST_BIRTH_YEAR"
			ELSE "NOTHING"
			END AS TIME_PEROID
FROM website_sessions W
LEFT JOIN orders O ON O.website_session_id = W.website_session_id
WHERE DATE(W.created_at) BETWEEN "2013-11-12" AND "2014-01-12";

SELECT * FROM A3;

WITH CTE AS(
SELECT   TIME_PEROID,
	     COUNT( DISTINCT website_session_id) AS SESSONS,
		 COUNT( DISTINCT order_id) AS ORDERS,
         COUNT( DISTINCT order_id)/COUNT( DISTINCT website_session_id) AS CONV_RATE,
         SUM(price_usd)/COUNT(order_id) AS AVG_ORDER_VALUE,
         SUM(items_purchased)/COUNT(order_id) AS PRODUCTS_PER_ORDER,
         SUM(price_usd)/COUNT( DISTINCT website_session_id) AS REVENUE_PER_SESSION
 FROM A3
 GROUP BY TIME_PEROID)
SELECT TIME_PEROID,
	   CONV_RATE,
       AVG_ORDER_VALUE,
       PRODUCTS_PER_ORDER,
       REVENUE_PER_SESSION
FROM CTE;

# BUSINESS CONCEPT : PRODUCT REFUND ANALYSIS.
/*
Analyzing product refund rates is about controlling for quality andunderstanding where you might have problems to address.

COMMON USE CASES:
Monit oring products from diferent suppliers.
Understanding refund rates for products at different price points.
Taking product refund rates and the associated costs into account when assessing the overal performance of your business.
*/

SELECT * FROM order_item_refunds;
SELECT * FROM order_items;

SELECT OI.order_id,OI.created_at AS ORDER_DATE,OI.order_item_id,OI.price_usd,
	   OIR.order_item_refund_id,OIR.created_at AS REFUND_DATE,OIR.order_item_id,OIR.refund_amount_usd
FROM order_items OI
LEFT JOIN order_item_refunds OIR ON  OIR.order_item_id = OI.order_item_id;

# ASSIGNMENT 7:(ANALYZING PRODUCT REFUND RATE - QUALITY ISSUE AND REFUND).
/*
NEW MESSAGE
October 15, 2014
From: Cindy Sharp (CEO)
Subject: Quality Issues & Refunds
Good morning,
Our Mr. Fuzzy supplier had some quality issues which
weren't corected until September 2013. Then they had a
major problem where the bears' arms were falling off in
Aug/Sep 2014. As a result, we replaced them with a new
supplier on September 16, 2014.
Can you please pull monthly product refund rates, by
product, and confirm our quality issues are now fixed?
-Cindy
*/

WITH CTE AS(
SELECT OI.created_at,OI.order_item_id,OI.product_id,
	   OIR.order_item_refund_id
FROM order_items OI
LEFT JOIN order_item_refunds OIR ON  OIR.order_item_id = OI.order_item_id
WHERE DATE(OI.created_at) < "2014-10-15")
SELECT YEAR(created_at) AS YR, MONTH(created_at) AS MON,
	   COUNT(DISTINCT IF(product_id =1,order_item_id, NULL)) AS P1_ORDERS,
       COUNT(DISTINCT IF(product_id =1,order_item_refund_id, NULL)) AS P1_REFUND,
       COUNT(DISTINCT IF(product_id =1,order_item_refund_id, NULL))/COUNT(DISTINCT IF(product_id =1,order_item_id, NULL)) AS P1_REFUND_RT,
	   COUNT(DISTINCT IF(product_id =2,order_item_id, NULL)) AS P2_ORDERS,
       COUNT(DISTINCT IF(product_id =2,order_item_refund_id, NULL)) AS P2_REFUND,
       COUNT(DISTINCT IF(product_id =2,order_item_refund_id, NULL))/COUNT(DISTINCT IF(product_id =2,order_item_id, NULL)) AS P2_REFUND_RT,
	   COUNT(DISTINCT IF(product_id =3,order_item_id, NULL)) AS P3_ORDERS,
       COUNT(DISTINCT IF(product_id =3,order_item_refund_id, NULL)) AS P3_REFUND,
       COUNT(DISTINCT IF(product_id =3,order_item_refund_id, NULL))/COUNT(DISTINCT IF(product_id =3,order_item_id, NULL)) AS P3_REFUND_RT,
       COUNT(DISTINCT IF(product_id =4,order_item_id, NULL)) AS P4_ORDERS,
       COUNT(DISTINCT IF(product_id =4,order_item_refund_id, NULL)) AS P4_REFUND,
       COUNT(DISTINCT IF(product_id =4,order_item_refund_id, NULL))/COUNT(DISTINCT IF(product_id =4,order_item_id, NULL)) AS P4_REFUND_RT
FROM CTE
GROUP BY 1,2;
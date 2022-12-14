USE FAANG;

#Number of the days between each user's first and last post.
SELECT user_id, MAX(DAY(post_date)) - MIN(DAY(post_date)) 
AS days_between
FROM facebook_post
WHERE YEAR(post_date) = 2021
GROUP BY user_id
HAVING COUNT(post_id)>1;

#CTR % per app in 2022.
SELECT app_id, ROUND(100 * SUM(CASE WHEN event_type = 'click'
THEN 1 ELSE 0 END) / SUM(CASE WHEN event_type = 'impression'
THEN 1 ELSE 0 END), 2) AS CTR
FROM facebook_event
WHERE timestamp >= '2022-01-01' 
   AND timestamp < '2023-01-01'
GROUP BY app_id
ORDER BY CTR;

#Cumulative purchases for each product type.
SELECT order_date, product_type, 
   SUM(quantity) OVER(
   PARTITION BY product_type ORDER BY order_date) 
   AS cumulative_purchased
FROM amazon_product
ORDER BY order_date;


#Average stars for each product every month.
SELECT 
  month,
  product_id,
  ROUND(AVG(stars), 2) AS avg_stars
FROM (
  SELECT 
    MONTH(submit_date) AS month,
    product_id,
    stars
  FROM amazon_reviews) AS rev_star
GROUP BY month, product_id
ORDER BY month, product_id;


#Histogram of tweets per user in 2022.
SELECT tweets_number AS tweet_bucket, 
   COUNT(user_id) AS users_num
FROM (
SELECT user_id, COUNT(tweet_id) AS tweets_number
FROM twitter_history
WHERE tweet_date BETWEEN '2022-01-01'
   AND '2022-12-31'
GROUP BY user_id) AS total_tweets
GROUP BY tweets_number;   

#Rank users according to their session durations for each
-- session type, between 2022-01-01 and 2022-02-01.
SELECT 
   user_id, session_type, 
   RANK() OVER (
   PARTITION BY session_type 
   ORDER BY total_duration DESC) AS ranking
FROM (
   SELECT 
   user_id, session_type, 
   SUM(duration) AS total_duration
   FROM twitter_session
    WHERE start_date >= '2022-01-01' 
     AND start_date <= '2022-02-01'
   GROUP BY user_id, session_type) AS user_duration 
ORDER BY session_type, ranking;


#The number of the companies that have posted duplicate job listings.
WITH jobs_grouped 
AS(
SELECT 
   company_id, title, description, COUNT(job_id) AS job_count
   FROM linkedIn_dupe
   GROUP BY company_id, title, description)
SELECT
   COUNT(DISTINCT company_id) AS
   duplicate_companies
FROM jobs_grouped
WHERE job_count > 1; 



#Candidates who possess all the required skills 
-- (Python, Tableau, PostgreSQL) for a job.
SELECT candidate_id 
FROM linkedIN_cadidates
WHERE skill IN('Python', 'Tableau', 'PostgreSQL')
GROUP BY candidate_id
HAVING COUNT(skill) = 3
ORDER BY candidate_id ASC;


#Find the confirmation rate of people who confirmed their 
-- signups with text messages.
SELECT ROUND(CAST(SUM(signup) AS DECIMAL(6,2)) / 
    COUNT(user_id),2) AS confirm_rate
FROM (
   SELECT user_id,
	CASE WHEN tt.email_id IS NOT NULL THEN 1
    ELSE 0
    END AS signup
   FROM tiktok_mail tm 
LEFT JOIN tiktok_text tt   
ON tm.email_id = tt.email_id
 AND signup_action = 'Confirmed'
)
AS rate;

#Users who did not confirm on the first day of signup, 
-- but confirmed on the second day.
SELECT DISTINCT user_id
FROM (
  SELECT tm2.user_id,
    tm2.signup_date,
    tt2.action_date
  FROM tiktok_mail2 tm2
  JOIN tiktok_text2 tt2
    ON tm2.email_id = tt2.email_id
    WHERE tt2.signup_action = 'Confirmed'
) AS second_day
WHERE action_date = signup_date + INTERVAL 1 DAY;    

#Return on ad spend (ROAS).
SELECT 
   advertiser_id, 
   ROUND(SUM(revenue) / CAST(SUM(spend) AS DECIMAL), 2) 
   AS ROAS
FROM google_ad
GROUP BY advertiser_id
ORDER BY advertiser_id;


#Total bench time in days during 2021 for each employee.
WITH consulting_days AS(
SELECT 
   gs.employee_id, SUM(gc.end_date - gc.start_date) 
   AS non_bench_days,
   COUNT(gs.employee_id) AS inclusive_days
FROM google_staff gs
JOIN google_consulting gc
ON gs.job_id = gc.job_id
WHERE gs.is_consultant = 'true'
GROUP BY gs.employee_id
)
SELECT employee_id, 365 - SUM(non_bench_days) - 
   SUM(inclusive_days) AS bench_days
FROM consulting_days
GROUP BY employee_id;   

# This table helps answer - who are the users, how do they move through the funnel, and what characteristics are associated with higher or lower conversion and value?

### Sanity Check ###

# Check for duplicates / confirm row and users line up
SELECT
  COUNT(*),
  COUNT(DISTINCT USER_ID_INT) AS COUNT_USERS
 FROM `monarch-money-481323.marketing_data.fct_users`  ;
 # No duplicate users. Rows and users are both 100,000

# Do acquisitions make sense?
SELECT
  COUNT(*) AS users,
  SUM(STARTED_TRIAL) AS trials,
  SUM(SUBSCRIBED) AS paid
 FROM `monarch-money-481323.marketing_data.fct_users` ;
# Results: Users: 100,000 Trials: 45,436 Paid: 31,489

# Are there users marked as subscribed who never started a trial?
SELECT 
  COUNT(*) AS PAID_WITHOUT_TRIAL,
FROM `monarch-money-481323.marketing_data.fct_users` 
WHERE SUBSCRIBED = 1 AND STARTED_TRIAL = 0;
# 987 users subscribed without starting a trial

# Check legitamcy of users who subscribed without starting a trial
SELECT 
  COUNT(*) AS TOTAL_PAID_USERS,
  COUNTIF(SUBSCRIBED = 1 AND STARTED_TRIAL = 0) AS PAID_WITHOUT_TRIAL,
  SAFE_DIVIDE(
    COUNTIF(SUBSCRIBED = 1 AND STARTED_TRIAL = 0),
    COUNTIF(SUBSCRIBED = 1) 
  ) AS PCT_PAID_WITHOUT_TRIAL
FROM  `monarch-money-481323.marketing_data.fct_users`;
# Roughly 3% of total users subscribed without starting a trial first (Chose to skip trial). This is low enough to be legitimate.

# Check if these users have subscription time stamps
SELECT 
  COUNT(*) AS SUBS_BEFORE_TRIAL
FROM  `monarch-money-481323.marketing_data.fct_users`
WHERE SUBSCRIBED = 1 AND STARTED_TRIAL = 1 AND SUBSCRIPTION_STARTED_AT < FREE_TRIAL_STARTED_AT;
# There are only 3 subscriptions that started before a trial. Small enough to not be super concerning. User could have paid immediately upon signup, trial event may have been created
# later due to a delay, user never had a trial and may have been created due to a misfire

# Are there negative or extremely large conversion times?
SELECT
  INTERNAL_ATTRIBUTION_CHANNEL,
  AVG(
  DATE_DIFF(
    DATE(FREE_TRIAL_STARTED_AT),
    DATE(REGISTERED_AT),
    DAY)
  ) AS DAYS_TO_TRIAL,
  AVG(
    DATE_DIFF(
    DATE(SUBSCRIPTION_STARTED_AT),
    DATE(FREE_TRIAL_STARTED_AT),
    DAY)
  ) AS DAYS_TRIAL_TO_PAID,
FROM  `monarch-money-481323.marketing_data.fct_users`
WHERE SUBSCRIBED = 1
GROUP BY 1;
# Nearly everything fits within the 1 week window, with the exception of Guest Pass Referrals, which have a 29 day trial to paid, but this could be due to their unique trial period.

# Are there subscriptions with zero or negative LTV?
SELECT
  COUNT(*) AS PAID_USERS,
  COUNTIF(LIFETIME_VALUE <= 0) AS ZERO_OR_NEG_LTV
FROM  `monarch-money-481323.marketing_data.fct_users`
WHERE SUBSCRIBED = 1;
# No

------------------------------------------------------------

### Baseline funnel ###
SELECT
  COUNT(*) AS SIGNUPS,
  SUM(STARTED_TRIAL) AS TRIAL_STARTS,
  SUM(CASE WHEN IS_VERIFIED THEN 1 ELSE 0 END) AS VERIFIED,
  SUM(SUBSCRIBED) AS PAID,
  SAFE_DIVIDE(SUM(STARTED_TRIAL), COUNT(*)) AS SIGNUP_TO_TRIAL,
  SAFE_DIVIDE(SUM(SUBSCRIBED), COUNT(*)) AS SIGNUP_TO_PAID,
  SAFE_DIVIDE(SUM(SUBSCRIBED), SUM(STARTED_TRIAL)) AS TRIAL_TO_PAID
FROM  `monarch-money-481323.marketing_data.fct_users`;
# SIGNUPS: 100,000 TRIAL_STARTS: 45,436 VERIFIED: 85,871 PAID: 31,489 SIGNUP_TO_TRIAL: 45% SIGNUP_TO_PAID: 31% TRIAL_TO_PAID: 69%

# Which users are the best quality?
SELECT
  INTERNAL_ATTRIBUTION_CHANNEL AS CHANNEL,
  SUM(STARTED_TRIAL) AS TRIALS,
  SUM(SUBSCRIBED) AS PAID,
  SAFE_DIVIDE(SUM(SUBSCRIBED), COUNT(*)) AS SIGNUP_TO_PAID_RATE,
  AVG(
    TIMESTAMP_DIFF(
    SUBSCRIPTION_STARTED_AT,
    REGISTERED_AT,
    HOUR)/24.0
  ) AS AVG_DAYS_SIGNUP_TO_PAID,
  AVG(
    TIMESTAMP_DIFF(
    SUBSCRIPTION_STARTED_AT,
    FREE_TRIAL_STARTED_AT,
    HOUR)/24.0
  ) AS AVG_DAYS_TRIAL_TO_PAID,
  AVG(LIFETIME_VALUE) AS AVG_LTV
FROM  `monarch-money-481323.marketing_data.fct_users`
GROUP BY 1
ORDER BY SIGNUP_TO_PAID_RATE DESC;
# Which channel converts best? Most trials come from Google Ads (16,079) with 56% moving from signup to paid subscriptions,
# Which channel produce paid users the fastest? Bing is the fastest at 7-8days, but they're roughly the same (8 days) with Facebook being the slowest at 10 days. Google Ads 8days
# Which channel generates the most LTV? Guest Pass Referral ($177), Podcast Ads ($173), Bing Ads ($170)

-----------------------------------------------------

### Signup Platform and Authentication Friction ###

# Platform Analysis
SELECT 
  SIGNUP_CLIENT_PLATFORM,
  COUNT(*) AS SIGNUPS,
  SAFE_DIVIDE(SUM(SUBSCRIBED), COUNT(*)) AS SIGNUP_TO_PAID
FROM  `monarch-money-481323.marketing_data.fct_users`
GROUP BY 1;
# Most signups come from website (24,093) while the others are similar Android (20,822), IOS (21,056), and Mobile_Web (21,556)

# Auth Provider Analysis
SELECT
  EXTERNAL_AUTH_PROVIDER,
  COUNT(*) AS SIGNUPS,
  SAFE_DIVIDE(SUM(STARTED_TRIAL), COUNT(*)) AS SIGNUP_TO_TRIAL,
  SAFE_DIVIDE(SUM(SUBSCRIBED), COUNT(*)) AS SIGNUP_TO_PAID
FROM  `monarch-money-481323.marketing_data.fct_users`
GROUP BY 1;
# While most users authenticate with Google, those who use Apple have a slightly higher signup rate (51% vs 47%). Conversions to subs are roughly the same (33% vs 31%)

# Conversion Velocity
SELECT
  INTERNAL_ATTRIBUTION_CHANNEL,
  AVG(
  DATE_DIFF(
    DATE(FREE_TRIAL_STARTED_AT),
    DATE(REGISTERED_AT),
    DAY)
  ) AS DAYS_TO_TRIAL,
  AVG(
    DATE_DIFF(
    DATE(SUBSCRIPTION_STARTED_AT),
    DATE(FREE_TRIAL_STARTED_AT),
    DAY)
  ) AS DAYS_TRIAL_TO_PAID
FROM  `monarch-money-481323.marketing_data.fct_users`
WHERE SUBSCRIBED = 1
GROUP BY 1;
# Users are starting trials very quickly after signup, thus onboarding friction is low
# CTA to start trial is effective
# Users seem to be subscribing after the free trial period. Guest referrals are subscribing at 29 days. This could be from a longer trial period or less-pressure to subscribe
# Users who come from search ads seem to have high intent, signing up <1hr from viewing the ad and convert at the end of their free trial
# Affiliate and Facebook signup quickly after ads but convert to paid subscribers slower (10-11 days) suggesting they might be more price sensitive or comparison-driven
# Affiliate and Facebook might benefit from a better in-trial nudge or pricing/value reinforcement mid-trial
# Guest Pass referral has the fastest trial start but longest time to paid. Might benefit from shorten trials, added urgency or reminders
# *** As a follow-up, I'd look at whether trial length or in-trial engagement differs across cohorts, especially guest pass referrals.

-------------------------------------------------------

### Pricing & Discount Impact ###

# Do discounted users convert more?
SELECT
  (CASE WHEN PLAN_PRICE_PAID < PLAN_BASE_PRICE THEN "DISCOUNTED" ELSE 'FULL_PRICE' END) AS PRICING_GROUP,
  COUNTIF(STARTED_TRIAL = 1) AS TRIAL_USERS,
  COUNTIF(STARTED_TRIAL = 1 AND SUBSCRIBED = 1) AS TRIAL_TO_PAID,
  SAFE_DIVIDE(
    COUNTIF(STARTED_TRIAL = 1 AND SUBSCRIBED = 1), COUNTIF(STARTED_TRIAL = 1)) AS SIGNUP_TO_PAID_RATE
FROM  `monarch-money-481323.marketing_data.fct_users`
GROUP BY 1;
# Discounted users have a 100% subscription rate... seems off. 

# Quick check: Are there any discounted users who are not subscribed?
SELECT 
  COUNT(*) AS DISCOUNTED_NOT_PAID
FROM  `monarch-money-481323.marketing_data.fct_users`
WHERE STARTED_TRIAL = 1 
  AND (PLAN_PRICE_PAID < PLAN_BASE_PRICE)
  AND SUBSCRIBED = 0; 
# No

# Discounting can't be used as a driver of conversion with this dataset, because pricing info is only available after conversion.

# Do discounted subscribers have a lower or higher LTV?
SELECT 
  CASE WHEN PLAN_PRICE_PAID < PLAN_BASE_PRICE THEN 'DISCOUNTED' ELSE 'FULL_PRICE' END AS PRICING_GROUP,
  COUNT(*) AS PAID_USERS,
  AVG(PLAN_PRICE_PAID) AS AVG_PRICE_PAID,
  AVG(LIFETIME_VALUE) AS AVG_LTV,
  SAFE_DIVIDE(AVG(LIFETIME_VALUE), AVG(PLAN_PRICE_PAID)) AS LTV_PER_DOLLAR
FROM  `monarch-money-481323.marketing_data.fct_users`
WHERE SUBSCRIBED = 1
GROUP BY 1;
# Discounted users have lower absolute LTV ($11 lower less)
# Discounted users are far more efficient on a per-dollar basis (52% higher return per dollar paid)
# *** Discounted users generate slightly less total value, but they are significantly more cost-efficient 
# *** Discounting makes sense when acquisition costs are high, want to improve short-term roas, targeting price-sensitive cohorts
# *** Blanket discounting may cap long-term upside, discounts should be targeted not universal.

# Signup to Paid Conversion By Platform Bar Chart
SELECT
  SIGNUP_CLIENT_PLATFORM AS PLATFORM,
  COUNT(*) AS SIGNUPS,
  COUNTIF(SUBSCRIBED = 1) AS PAID_USERS,
  SAFE_DIVIDE(COUNTIF(SUBSCRIBED = 1), COUNT(*)) AS SIGNUP_TO_PAID_RATE
FROM  `monarch-money-481323.marketing_data.fct_users`
WHERE SIGNUP_CLIENT_PLATFORM IS NOT NULL AND SIGNUP_CLIENT_PLATFORM != 'UNKNOWN'
GROUP BY 1
HAVING COUNT(*) >= 500
ORDER BY SIGNUP_TO_PAID_RATE DESC;
# Signup platforms have a major impact on conversion efficiency, with web signups converting more than six times better than Android signups.


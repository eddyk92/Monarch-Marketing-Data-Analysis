# This table helps answer - How efficient is each acquisition channel over time when evaluated on a signup cohort basis?

### Sanity Check ###

# One row per signup_date x channel?
SELECT 
  COUNT(*) AS TOTAL_ROWS, 
  COUNT(DISTINCT CONCAT(DATE, '-', CHANNEL)) AS DISTINCT_GRAIN
 FROM `monarch-money-481323.marketing_data.fct_channel_signup_cohort_day`;
 # YES

# Do signups roll up to fct_user?
SELECT
  SUM(SIGNUPS)
FROM `monarch-money-481323.marketing_data.fct_channel_signup_cohort_day`;

 SELECT
  COUNT(*)
 FROM `monarch-money-481323.marketing_data.fct_users` ;
 # Both tables are aligned

# Do counts make sense?
SELECT 
  SUM(SIGNUPS),
  SUM(TRIAL_STARTS),
  SUM(PAID_SUBSCRIBERS)
FROM `monarch-money-481323.marketing_data.fct_channel_signup_cohort_day`;

# Is spend aligned?
SELECT
  COUNT(*) AS TOTAL_ROWS,
  COUNTIF(SPEND IS NULL) AS NULL_SPEND_ROWS
FROM `monarch-money-481323.marketing_data.fct_channel_signup_cohort_day`;
# There are 270 null spend rows. This is expected for organic channels

# Check math
SELECT
  MIN(CAC_PER_PAID_SUBSCRIBER) AS MIN_PAID_SUB,
  MAX(CAC_PER_PAID_SUBSCRIBER) AS MAX_PAID_SUB
FROM `monarch-money-481323.marketing_data.fct_channel_signup_cohort_day`;
# No negatives or extremely high values

 --------------------------------------------------------

### Establish channel volume mix ###

# Which channels drive scale vs efficiency?
SELECT
  CHANNEL,
  SUM(SIGNUPS) AS TOTAL_SIGNUPS,
  SUM(PAID_SUBSCRIBERS) AS TOTAL_PAID,
  SAFE_DIVIDE(SUM(PAID_SUBSCRIBERS), SUM(SIGNUPS)) AS SIGNUP_TO_PAID_RATE
FROM `monarch-money-481323.marketing_data.fct_channel_signup_cohort_day`
GROUP BY 1
ORDER BY TOTAL_SIGNUPS DESC;
# Other: likely includes mixed or unattributed traffic. High volume, low quality
# Google UAC: Mass reach, low intent. Good for top-of-funnel growth, but likely expensive unless supports LTV
# Guest Pass Referrals: Extremely high intent (warm referrals), but we already saw they're slow to convert
# Google Ads: Best balance of scale and quality. Strong candidate for continued/ increased investment
# Impact Affiliates: Mid-scale, high-quality. Likely efficient if CAC is reasonable
# Bing Ads: High impact but limit scale. Good efficiency, but likely has low ad spend
# Apple Search Ads: Users discover in-app but may have low intent, needs more context from CAC/LTV
# Facebook Ads: decent quality, but likely sensitive to creative/targeting. Optimization opportunity rather than immediate scaling
# Partnerships: Extremely low quality, this is either a data issue or should be paused. 
# Podcast Ads: Very low volume too low to generalize. 

---------------------------------------------------------

### CAC Analysis ###

# How expensive is each stage of the funnel by channel?
SELECT
  CHANNEL,
  AVG(CAC_PER_SIGNUP) AS AVG_CAC_SIGNUP,
  AVG(CAC_PER_TRIAL_START) AS AVG_CAC_TRIAL,
  AVG(CAC_PER_PAID_SUBSCRIBER) AS AVG_CAC_PAID
FROM `monarch-money-481323.marketing_data.fct_channel_signup_cohort_day`
GROUP BY 1
ORDER BY AVG_CAC_PAID;
# Impact Affiliates: Minimal drop-off at every stage, very efficient traffic, shows strong intent
# Apple Search: Users signup cheaply, meaningful drop-off before trial, still resonable paid CAC
# Google & Bing Ads: High intent, but expensive clicks, reasonable funnel efficiency, costs scale linearly
# Google UAC: Good signup volume, significant drop-off post-signup, very expensive revenue acquisition. Might be better as awareness/early funnel
# Facebook Ads: Expenisve traffic, heavy drop-off at every stage, poor efficiency compare to others. Great for optimization or budget constraint
# Podcast Ads: Very high acquisition cost, small sample size, might be more of a branding ad than performance

-----------------------------------------------

### Value Generation (LTV/ROAS)

# Which channels generate the most value?
SELECT
  CHANNEL,
  SUM(TOTAL_LTV) AS TOTAL_LTV,
  SAFE_DIVIDE(SUM(TOTAL_LTV), SUM(SPEND)) AS ROAS_LTV
FROM `monarch-money-481323.marketing_data.fct_channel_signup_cohort_day`
GROUP BY 1
ORDER BY ROAS_LTV DESC;
# Impact Affiliates: Best performer - extremely high efficiency with very low CAC and strong conversion and value
# Google Ads: Highest absolute value - drives the most revenue at acceptable efficiency, strong balance of scale and value
# Bing Ads and Apple Search Ads: High efficiency, low scale - high-intent traffic but smaller volume with good efficiency
# Podcast Ads: Roughly breaks-even on LTV, likely focused on branding/ awareness
# Google UAC: Underperforming - high volume, low downstream value, poor funnel efficiency 
# Facebook Ads: Worst paid performer - value doesnt justify spend, simialr with pervious CAC analysis
# Organic/ Referral/ Partnership: Extreamly valuable, worth growing 

----------------------------------------------------

### LTV:CAC Efficiency ###

# Where do we get the most value per dollar spent?
SELECT
  CHANNEL,
  AVG(LTV_TO_CAC_RATIO) AS AVG_LTV_CAC
FROM `monarch-money-481323.marketing_data.fct_channel_signup_cohort_day`
GROUP BY 1
ORDER BY AVG_LTV_CAC DESC;
# Impact Affiliates: Clear winner - For every $1 spent, you generate ~$13 in lifetime value
# Podcast Ads: Strong efficiency - worth keeping as a controlled, experimental channel
# Bing Ads: Good effiency channel although low volume
# Apple Search Ads: Reasonable efficiency - predictable, strong balance of scale and value
# Google UAC: OK effiency - needs optimization or reframing as upper-funnel. moderate LTV
# Facebook Ads: Poor funnel effiency - For every $1 spent, you get ~$0.47 back in lifetime value. Strong candidate for optimization
# Organic/ Referral/Partnerships: Extreamly valuable, best ROI, should be grown via product and lifecycle efforts

--------------------------------------

### Time Trends ### 

# Are channels improving or degrading over time?
SELECT 
  DATE,
  CHANNEL,
  CAC_PER_PAID_SUBSCRIBER,
  ROAS_LTV
FROM `monarch-money-481323.marketing_data.fct_channel_signup_cohort_day`
ORDER BY DATE;
# CAC_PER_PAID_SUBSCRIBER over time: CAC across channels do not show a sustained improvement trend, indicating that efficiency issues are structural rather than temporary.
# ROAS_LTV over time: Early volatility, then sustained deterioration. ROAS across channels decay as time goes on.
# ROAS based on LTV shows early volatility followed by a steady decline and stablization at low levels, indicating dimishing returns and limited long-term upside.

----------------------------------------------------------

### Outliers & Anomalies ###

# Value-Negative Spend: How often is each channel losing money
SELECT
  CHANNEL,
  COUNT(*) AS COHORT_DAYS,
  COUNTIF(LTV_TO_CAC_RATIO < 1) AS VALUE_NEGATIVE_DAYS,
  SAFE_DIVIDE(
    COUNTIF(LTV_TO_CAC_RATIO < 1),
    COUNT(*)
  ) AS PCT_VALUE_NEGATIVE_DAYS
FROM `monarch-money-481323.marketing_data.fct_channel_signup_cohort_day`
WHERE SIGNUPS > 50 AND SPEND > 100
GROUP BY 1
ORDER BY PCT_VALUE_NEGATIVE_DAYS DESC;
# Facebook Ads: 100% of cohort days lose money
# Google UAC: 81% of days lose money - has some good days but tends to be inefficient
# Apple Search Ads: 1.3% of days lose money - strong and reliable acquistion channel
# Google Ads: Has never lost money - high intent and predictable performance
# Impact Affiliates: Similar to Google Ads


# Identify Extreme CAC Spikes where CAC per subscriber is >2x overall average
WITH BASE_METRICS AS (
  SELECT
    *,
    AVG(CAC_PER_PAID_SUBSCRIBER) OVER() AS AVG_CAC
  FROM `monarch-money-481323.marketing_data.fct_channel_signup_cohort_day`
  WHERE SIGNUPS > 50 AND SPEND > 100
)

SELECT
  CHANNEL,
  COUNT(*) AS COHORT_DAYS,
  COUNTIF(CAC_PER_PAID_SUBSCRIBER > 2 * AVG_CAC) AS HIGH_CAC_DAYS
FROM BASE_METRICS
GROUP BY 1
ORDER BY HIGH_CAC_DAYS DESC;
# Google UAC: 46% of cohort day have extreme CAC - acquisition efficiency is volatile, budget changes, bidding, or targeting likely cause large swings
# Facebook Ads: 88% of cohort days have extreme CAC - consistently unstable and expensive
# Apple Search Ads: 0/79 days - predictable performance
# Google Ads: 0/90 days - reliable channel, predictable performance
# Impact Affiliates: 0/83 days 

# Presistent Underperformance by Channel

# Which channels most often underperform?
SELECT 
  CHANNEL,
  COUNT(*) AS TOTAL_DAYS,
  COUNTIF(LTV_TO_CAC_RATIO < 1) AS BAD_DAYS,
  SAFE_DIVIDE(
    COUNTIF(LTV_TO_CAC_RATIO <1),
    COUNT(*)
  ) AS PCT_BAD_DAYS
FROM `monarch-money-481323.marketing_data.fct_channel_signup_cohort_day`
GROUP BY 1
HAVING PCT_BAD_DAYS >0.25
ORDER BY PCT_BAD_DAYS DESC;
# Persistent underperformance is highly concentrated in Facebook Ads and Google UAC, while other channels are consistently value-positive.

# LTV To CAC Ratio x Channel Bar Chart
SELECT
  CHANNEL,
  SUM(TOTAL_LTV) / NULLIF(SUM(SPEND), 0) AS LTV_TO_CAC_RATIO
FROM `monarch-money-481323.marketing_data.fct_channel_signup_cohort_day`
WHERE SPEND > 0
GROUP BY 1
ORDER BY LTV_TO_CAC_RATIO;



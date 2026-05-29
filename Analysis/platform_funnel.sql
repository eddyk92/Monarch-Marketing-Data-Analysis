# This table helps answer - Where does the funnel break - overall and by key segments?

# Global Funnel
SELECT 
  SIGNUPS,
  VERIFIED_USERS,
  TRIAL_STARTS,
  PAID_SUBSCRIBERS,
  SIGNUP_TO_VERIFIED_RATE,
  SIGNUP_TO_TRIAL_RATE,
  TRIAL_TO_PAID_RATE,
  SIGNUP_TO_PAID_RATE
FROM `monarch-money-481323.marketing_data.fct_funnel_summary`
WHERE BEAKDOWN_TYPE = 'OVERALL';
# Largest dropoff is Signup to Trial (45%)

# Identify where the funnel breaks
SELECT
  'SIGNUP_TO_VERIFIED' AS STEP,
  1 - SIGNUP_TO_VERIFIED_RATE AS DROPOFF,
FROM `monarch-money-481323.marketing_data.fct_funnel_summary`
WHERE BEAKDOWN_TYPE = 'OVERALL'

UNION ALL
SELECT
  'SIGNUP_TO_TRIAL',
  1 - SIGNUP_TO_TRIAL_RATE
FROM `monarch-money-481323.marketing_data.fct_funnel_summary`
WHERE BEAKDOWN_TYPE = 'OVERALL'

UNION ALL
SELECT
  'TRIAL_TO_PAID',
  1 - TRIAL_TO_PAID_RATE
FROM `monarch-money-481323.marketing_data.fct_funnel_summary`
WHERE BEAKDOWN_TYPE = 'OVERALL';
# Going from signup to trial sees the highest friction at 54%

# Segment the funnel by Signup platform
SELECT
  BREAKDOWN_VALUE AS SIGNUP_PLATFORM,
  SIGNUPS,
  SIGNUP_TO_TRIAL_RATE,
  TRIAL_TO_PAID_RATE,
  SIGNUP_TO_PAID_RATE
FROM `monarch-money-481323.marketing_data.fct_funnel_summary`
WHERE BEAKDOWN_TYPE = 'SIGNUP_PLATFORM'
ORDER BY SIGNUPS DESC;
# Channels heavy in web traffic(search, affiliates) have high efficiency
# Channels heavy in app traffic (Facebook, UAC) have low early-funnel conversion
# Facebook underperformance is partly explained by platform mix, not just spend
# *** Improve Android onboarding and trail activation, Consider platform-aware acquisition strategy, Optimize Facebook.UAC landing flows for trial starts

# Quality Filter - Ignoring small-sample noise, whcih signup platforms consistently produce high-quality users?
SELECT 
  BREAKDOWN_VALUE,
  SIGNUP_TO_PAID_RATE,
FROM `monarch-money-481323.marketing_data.fct_funnel_summary`
WHERE BEAKDOWN_TYPE = 'SIGNUP_PLATFORM' AND SIGNUPS >= 500
ORDER BY SIGNUP_TO_PAID_RATE DESC;
# When filtering to high-volume cohorts, signup platform quailty is very consistent. Web signups convert over 6x better than Android signups, with mobile web and iOS falling in between.
# This reinforces that platform experience plays a major role in downstream conversions.



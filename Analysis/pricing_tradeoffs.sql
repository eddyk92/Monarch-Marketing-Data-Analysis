# This table will help to answer. - How price, discounts, and plans affect value - and where discounting helps vs hurts?

# Sanity Checks
SELECT
  COUNT(*) AS TOTAL_ROWS,
  COUNT(DISTINCT USER_ID_INT) AS USERS
FROM `monarch-money-481323.marketing_data.fct_pricing`;

# Confirm Discount Math
SELECT
  MIN(DISCOUNT_PERCENT) AS MIN_DISCOUNT,
  MAX(DISCOUNT_PERCENT) AS MAX_DISCOUNT
FROM `monarch-money-481323.marketing_data.fct_pricing`;

# Full price vs discounted
SELECT 
  CASE WHEN DISCOUNT_AMT > 0 THEN 'DISCOUNTED' ELSE 'FULL-PRICE' END AS PRICING_GROUP,
  COUNT(*) AS PAID_USERS,
  AVG(PLAN_PRICE_PAID) AS AVG_PRICE_PAID,
  AVG(LIFETIME_VALUE) AS AVG_LTV,
  SAFE_DIVIDE(AVG(LIFETIME_VALUE), AVG(PLAN_PRICE_PAID)) AS LTV_PER_DOLLAR
FROM `monarch-money-481323.marketing_data.fct_pricing`
GROUP BY 1;
# Discounted users have a lower avg ltv but a larger ltv per dollar ($2.95 compared to $1.94) 
# This supports targeted discounting rather than blanket discounting

# Disocunt Depth

# At what discount level does value degrade?
SELECT
  DISCOUNT_BUCKET,
  COUNT(*) AS USERS,
  AVG(PLAN_PRICE_PAID) AS AVG_PRICE_PAID,
  AVG(LIFETIME_VALUE) AS AVG_LTV,
  SAFE_DIVIDE(AVG(LIFETIME_VALUE), AVG(PLAN_PRICE_PAID)) AS LTV_PER_DOLLAR
FROM `monarch-money-481323.marketing_data.fct_pricing`
GROUP BY 1
ORDER BY DISCOUNT_BUCKET;
# 50% discounts increase efficiency with much more value per dollar charged, but reduce absolute value
# Discounting improves efficiency, but deeper discounts cap upside. The optimal strategy is targeted discounting, not blanket discounting.
# 30% discount cohort is relatively small, it would benifit from furhter validation with more volume.
# *** Use 50% discounts for low-intent channels, app-based signups, re-engagement flows
# *** Use 30% discounts for higher-intent cohorts/ channels closer to purchase
# *** Use no-discounts for high-intent web traffic and search-driven acquisition


# Plan period tradeoff
# Do yearly plans outperfom monthly plans - and how does discounting interact? 
SELECT 
  PLAN_PERIOD,
  COUNT(*) AS USERS,
  AVG(PLAN_PRICE_PAID) AS AVG_PRICE_PAID,
  AVG(LIFETIME_VALUE) AS AVG_LTV,
  SAFE_DIVIDE(AVG(LIFETIME_VALUE), AVG(PLAN_PRICE_PAID)) AS LTV_PER_DOLLAR
FROM `monarch-money-481323.marketing_data.fct_pricing`
GROUP BY 1;
# Yearly subscribers generate more lifetime value per user, even though monthly plans appear more “efficient” due to lower upfront price.
# LTV-per-dollar overstates efficiency for montly plans because it uses the intial charge as the denominator 
# *** Consider up-grade nudges from monthly users

# Channel by pricing 
# Where do discounts actually make sense?
SELECT
  INTERNAL_ATTRIBUTION_CHANNEL,
  COUNT(*) AS PAID_USERS,
  AVG(DISCOUNT_PERCENT) AS AVG_DISCOUNT,
  AVG(LIFETIME_VALUE) AS AVG_LTV
FROM `monarch-money-481323.marketing_data.fct_pricing`
GROUP BY 1
ORDER BY AVG_DISCOUNT DESC;
# High-intent channels can sustain moderate discounts without destroying LTV
# Facebook's underperformance is not driven by discount depth. It's driven by acquisition quality and funnel inefficiency, which aligns 
# with the ealier CAC and funnel findings
# Discounting strategy varies by channel, but differences in long-term value are driven more by acquisition quality and platform behavior than by discount depth alone.
# *** Avoid trying to 'fix' weak channels through pricing alone

# Platform by pricing
# Should pricing strategy vary by platform?
SELECT
  SIGNUP_CLIENT_PLATFORM,
  COUNT(*) AS USERS,
  AVG(PLAN_PRICE_PAID) AS AVG_PRICE_PAIDM,
  AVG(LIFETIME_VALUE) AS AVG_LTV
FROM `monarch-money-481323.marketing_data.fct_pricing`
GROUP BY 1
ORDER BY USERS DESC;
# All platforms receive similar discount depths
# Platform differences in performance are not driven by discounts, so pricing is not compensating for weaker app funnel performance
# Despite the consistent discount depth across web and app experiences, LTV varies signifcantly, which suggests platform performance 
# differences are driven by funnel behavior and user intent rather than pricing strategy.
# *** Focus on improving app onboarding and activation by optimizing experience, not incentives.

# Bar Chart for Discount Depth vs Value
SELECT
  discount_bucket,
  COUNT(*) AS users,
  AVG(plan_price_paid) AS avg_price_paid,
  AVG(lifetime_value) AS avg_ltv,
  SAFE_DIVIDE(AVG(lifetime_value), AVG(plan_price_paid)) AS ltv_per_dollar
FROM `monarch-money-481323.marketing_data.fct_pricing`
GROUP BY discount_bucket
ORDER BY
  CASE
    WHEN discount_bucket = 'NO-DISCOUNT' THEN 3
    WHEN discount_bucket = '30%' THEN 1
    WHEN discount_bucket = '50%' THEN 2
    ELSE 99
  END;
# Deeper discounts improve efficiency (LTV per dollar) but reduce absolute lifetime value, suggesting discounting should be targeted rather than universally applied.


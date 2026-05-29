## Monarch Money: Take Home

# Marketing Acquisition Analysis for Monarch Money

## Overview

This project analyzes marketing and user acquisition data to uncover trends and insights that optimize acquisition strategy. The analysis focuses on channel efficiency, funnel performance, signup platform behavior, pricing effectiveness, and identifying anomalies affecting CAC, ROAS, and lifetime value.

## Objectives

The primary goals of this analysis are to:

- Evaluate acquisition performance across marketing channels
- Understand conversion behavior through the signup, trial, and subscription funnel
- Identify how signup platform impacts user quality and conversion
- Assess the effectiveness of pricing and discounting strategies
- Surface anomalies and structural inefficiencies affecting CAC and ROAS
- Provide actionable recommendations to improve acquisition efficiency

## Data Sources

The analysis is based on five input datasets:

- **Users:** User-level signup data
- **Attribution:** Internal attribution channel and user-selected attribution
- **Trial:** Free trial start and end timestamps
- **Subscription:** Subscription start, plan period, pricing, and modeled lifetime value
- **Ad Spend:** Daily spend by marketing channel

## Data Modeling

The analysis uses fact tables built with dbt-style modeling principles:

- **fct_user:** User-level acquisition funnel from signup through trial and subscription
- **fct_channel_signup_cohort_day:** Daily channel performance (CAC, ROAS, LTV)
- **fct_pricing_analysis:** Paid user pricing, discounting, and value metrics
- **fct_funnel_summary:** Aggregated funnel metrics by channel and platform

All SQL is included in the `sql/` directory.

## Key Analyses

### Channel Performance
- Volume vs efficiency tradeoffs
- CAC per paid subscriber
- ROAS based on lifetime value
- Identification of value-negative channels

### Funnel Analysis
- Signup to trial conversion
- Trial to paid conversion
- Conversion velocity and early funnel drop-offs

### Signup Platform Insights
- Conversion differences across web, mobile web, iOS, and Android
- Impact of platform mix on channel performance
- Platform-driven inefficiencies

### Pricing and Discounting
- Full price vs discounted user value
- Discount depth tradeoffs
- Monthly vs yearly plan performance
- Pricing behavior by channel and platform

### Anomalies and Validation
- Persistent value-negative spend
- Extreme CAC spikes
- Attribution and data quality checks

## Tools and Technologies

- **BigQuery** for data storage and SQL execution
- **SQL** for modeling and analysis

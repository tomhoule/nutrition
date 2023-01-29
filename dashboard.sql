WITH rows AS (
    SELECT ts AS "when", weight_grams::float / 1000 AS weight, created_at
    FROM weight
    ORDER BY created_at DESC, ts ASC
    LIMIT 18
)
SELECT "when", weight FROM rows ORDER BY created_at ASC;

WITH
weight_windows AS (
    SELECT
        *,
        avg(weight_grams) OVER week AS naive_avg_weight,
        avg(epoch(ts)) OVER week AS avg_ts,
        regr_slope(weight_grams, epoch(ts)) OVER week AS raw_slope,
        regr_slope(weight_grams, epoch(ts) / (3600 * 24 * 7)) OVER week AS rate,
        count(*) OVER week AS measurements_count,
    FROM weight
    WINDOW week AS (
        ORDER BY ts
        RANGE BETWEEN INTERVAL 3 DAYS PRECEDING
                  AND INTERVAL 3 DAYS FOLLOWING
    )
    ORDER BY ts
),
daily_weight_windows AS (
    SELECT
        first(ts) AS ts,
        first(naive_avg_weight) AS naive_avg_weight,
        first(measurements_count) AS measurements_count,
        first(raw_slope) AS raw_slope,
        first(rate) AS rate,
        first(avg_ts) AS avg_ts,
    FROM weight_windows
    GROUP BY ts::DATE
    ORDER BY ts
)
SELECT
    ts::DATE AS date,
    printf('%.2f', naive_avg_weight / 1000) AS naive_avg_weight,
    -- See the regression intercept formula at
    -- https://duckdb.org/docs/sql/aggregates#statistical-aggregates
    printf('%.2f', (naive_avg_weight - raw_slope * (avg_ts - epoch(ts))) / 1000) AS regression_intercept,
    printf('%+.2f', coalesce(rate / 1000, 0)) AS weekly_rate,
FROM daily_weight_windows
WHERE ts > now() - INTERVAL 2 MONTHS
  AND ts < now() - INTERVAL 3 DAYS
  AND measurements_count > 4
ORDER BY ts

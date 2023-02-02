WITH
weight_windows AS (
    SELECT
        *,
        avg(weight_grams) OVER week AS naive_avg_weight,
        regr_slope(weight_grams, epoch(ts)) OVER week AS slope,
        count(*) OVER week AS measurements_count,
        last(ts) OVER week AS last_ts,
        avg(epoch(ts)) OVER week AS avg_ts,
    FROM weight
    WINDOW week AS (
        ORDER BY ts
        RANGE BETWEEN INTERVAL 9 DAYS PRECEDING
                  AND CURRENT ROW
    )
    ORDER BY ts
),
daily_weight_windows AS (
    SELECT
        first(ts) AS ts,
        first(naive_avg_weight) AS naive_avg_weight,
        first(measurements_count) AS measurements_count,
        first(slope) AS slope,
        first(last_ts) AS last_ts,
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
    printf('%.2f', (naive_avg_weight - (slope * (avg_ts - epoch(last_ts)))) / 1000) AS approx_weight,
    printf('%+.2f', coalesce(slope * 3600 * 24 * 7 / 1000, 0)) AS weekly_rate,
FROM daily_weight_windows
WHERE ts > now() - INTERVAL 2 MONTHS
  AND measurements_count > 4
ORDER BY ts

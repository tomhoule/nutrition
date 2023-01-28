WITH rows AS (
    SELECT ts AS "when", weight_grams::float / 1000 AS weight, created_at
    FROM weight
    ORDER BY created_at DESC, ts ASC
    LIMIT 18
)
SELECT "when", weight FROM rows ORDER BY created_at ASC;

WITH
    bucketed_weight AS (
        SELECT
            *,
            date_part('day', age(ts)) / 3 AS bucket, -- 2-day buckets
            avg(weight_grams) OVER week AS naive_avg_weight,
            avg(epoch(ts)) OVER week AS avg_ts,
            regr_slope(weight_grams, epoch(ts)) OVER week AS raw_slope,
            regr_slope(weight_grams, epoch(ts) / (3600 * 24 * 7)) OVER week AS rate,
        FROM weight
        WINDOW week AS (
            ORDER BY ts
            RANGE BETWEEN INTERVAL 3 DAYS PRECEDING
                      AND INTERVAL 3 DAYS FOLLOWING
        )
        ORDER BY ts
    )
SELECT
    first(ts)::date AS date,
    printf('%.2f', first(naive_avg_weight) / 1000) AS naive_avg_weight,
    -- See the regression intercept formula at
    -- https://duckdb.org/docs/sql/aggregates#statistical-aggregates
    printf('%.2f', (first(naive_avg_weight) - first(raw_slope) * (first(avg_ts) - first(epoch(ts)))) / 1000) AS regression_intercept,
    printf('%+.2f', coalesce(first(rate) / 1000, 0)) AS weekly_rate,
FROM bucketed_weight
GROUP BY bucket
ORDER BY bucket DESC

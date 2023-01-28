WITH rows AS (
    SELECT ts AS "when", weight_grams::float / 1000 AS weight, created_at
    FROM weight
    ORDER BY created_at DESC, ts ASC
    LIMIT 18
)
SELECT "when", weight FROM rows ORDER BY created_at ASC;

WITH windowed_weight AS (
  SELECT
    *,
    first_value(ts) OVER bucket AS first_ts,
    last_value(ts) OVER bucket AS last_ts,
    (epoch(first_ts) + epoch(last_ts)) / 2 AS mid_bucket,
    regr_slope(weight_grams, epoch(ts) / (3600 * 24 * 7)) OVER rate_range AS rate,
  FROM weight
  WINDOW
    bucket AS (PARTITION BY date_diff('weeks', now()::timestamp, ts)),
    rate_range AS (
      ORDER BY ts
      RANGE BETWEEN INTERVAL 8 DAYS PRECEDING
                AND INTERVAL 2 DAYS FOLLOWING
    )
  ORDER BY ts ASC
)
SELECT
    to_timestamp(mid_bucket)::date AS date,
    printf(
      '%.2f',
      regr_intercept(weight_grams, epoch(ts) - mid_bucket) / 1000
    ) AS avg_weight,
    printf('%+.2f', last(rate) / 1000) AS rate,
FROM windowed_weight
GROUP BY mid_bucket
HAVING avg_weight IS NOT NULL;

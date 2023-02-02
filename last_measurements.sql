WITH rows AS (
    SELECT ts AS "when", weight_grams::float / 1000 AS weight, created_at
    FROM weight
    ORDER BY created_at DESC, ts ASC
    LIMIT 18
)
SELECT "when", weight FROM rows ORDER BY created_at ASC;


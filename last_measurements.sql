WITH rows AS (
    SELECT date, weight_grams::float / 1000 AS weight, created_at
    FROM weight
    ORDER BY created_at DESC
    LIMIT 18
)
SELECT date, weight FROM rows ORDER BY created_at ASC;


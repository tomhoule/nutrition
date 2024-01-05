WITH
daily_weight AS (
    SELECT date, avg(weight_grams) AS daily_avg_weight,
    FROM weight
    GROUP BY date
),
with_recent_weight AS (
    SELECT
        *,
        avg(daily_avg_weight)
            OVER (
                ORDER BY date
                RANGE BETWEEN INTERVAL 9 DAYS PRECEDING
                          AND CURRENT ROW
            )
            AS recent_avg_weight,
        avg(daily_avg_weight)
            OVER (
                ORDER BY date
                RANGE BETWEEN INTERVAL 20 DAYS PRECEDING
                          AND INTERVAL 10 DAYS PRECEDING
            )
            AS previous_avg_weight,
    FROM daily_weight
)
SELECT
    date,
    printf('%.2f', daily_avg_weight / 1000) AS daily_avg_weight,
    printf('%.2f', recent_avg_weight / 1000) AS recent_avg_weight,
    printf('%+.2f', ((recent_avg_weight - previous_avg_weight) * 7 / 10) / 1000) AS estimated_weekly_slope,
FROM with_recent_weight
WHERE date > today() - INTERVAL 35 DAYS
ORDER BY date ASC

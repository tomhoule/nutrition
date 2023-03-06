WITH
daily_weight AS (
    SELECT first(ts::DATE) AS date, avg(weight_grams) AS daily_avg_weight,
    FROM weight
    GROUP BY ts::DATE
),
with_recent_weight AS (
    SELECT
        *,
        avg(daily_avg_weight)
            OVER (
                ORDER BY date
                RANGE BETWEEN INTERVAL 6 DAYS PRECEDING
                          AND CURRENT ROW
            )
            AS recent_avg_weight,
        avg(daily_avg_weight)
            OVER (
                ORDER BY date
                RANGE BETWEEN INTERVAL 11 DAYS PRECEDING
                          AND INTERVAL 6 DAYS PRECEDING
            )
            AS last_week_weight,
    FROM daily_weight
)
SELECT
    date,
    printf('%.2f', daily_avg_weight / 1000) AS daily_avg_weight,
    printf('%.2f', recent_avg_weight / 1000) AS recent_avg_weight,
    printf('%+.2f', (recent_avg_weight - last_week_weight) / 1000) AS estimated_weekly_slope,
FROM with_recent_weight
WHERE date > today() - INTERVAL 35 DAYS
ORDER BY date ASC

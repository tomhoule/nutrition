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
                RANGE BETWEEN INTERVAL 13 DAYS PRECEDING
                          AND CURRENT ROW
            )
            AS recent_avg_weight,
    FROM daily_weight
),
with_slope AS (
    SELECT
        *,
        recent_avg_weight - lag(recent_avg_weight)
            OVER (ORDER BY date)
            AS estimated_weekly_slope,
    FROM with_recent_weight
)
SELECT
    date,
    printf('%.2f', daily_avg_weight / 1000) AS daily_avg_weight,
    printf('%.2f', recent_avg_weight / 1000) AS recent_avg_weight,
    printf('%+.2f', (estimated_weekly_slope * 7) / 1000) AS estimated_weekly_slope,
FROM with_slope
WHERE date > today() - INTERVAL 35 DAYS
ORDER BY date ASC

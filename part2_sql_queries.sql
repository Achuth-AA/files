-- Part 2 
-- Query 1: Total active patients in the last 90 days
-- Active = any engagement or appointment in that period
-- Using '2025-09-01' as the current date for this query

WITH active_from_appointments AS (
    SELECT DISTINCT patient_id
    FROM appointments
    WHERE scheduled_date >= DATE_SUB('2025-09-01', INTERVAL 90 DAY)
),
active_from_engagement AS (
    SELECT DISTINCT patient_id
    FROM engagement
    WHERE date >= DATE_SUB('2025-09-01', INTERVAL 90 DAY)
),
all_active_patients AS (
    SELECT patient_id FROM active_from_appointments
    UNION
    SELECT patient_id FROM active_from_engagement
)
SELECT COUNT(DISTINCT patient_id) AS total_active_patients_last_90_days
FROM all_active_patients;


-- Query 2: Appointment no-show rate by provider type
-- No-show rate = (Count of attended_flag = 'N') / (Total appointments) * 100

SELECT 
    provider_type,
    COUNT(*) AS total_appointments,
    SUM(CASE WHEN attended_flag = 'N' THEN 1 ELSE 0 END) AS no_shows,
    ROUND(
        (SUM(CASE WHEN attended_flag = 'N' THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 
        2
    ) AS no_show_rate_percentage
FROM appointments
GROUP BY provider_type
ORDER BY no_show_rate_percentage DESC;


-- Query 3: Average engagement (actions per user) for patients with ≥1 appointment in the last 30 days
-- Using '2025-09-01' as the current date

WITH patients_with_recent_appointments AS (
    SELECT DISTINCT patient_id
    FROM appointments
    WHERE scheduled_date >= DATE_SUB('2025-09-01', INTERVAL 30 DAY)
),
engagement_stats AS (
    SELECT 
        e.patient_id,
        SUM(e.action_count) AS total_actions
    FROM engagement e
    INNER JOIN patients_with_recent_appointments p
        ON e.patient_id = p.patient_id
    GROUP BY e.patient_id
)
SELECT 
    ROUND(AVG(total_actions), 2) AS avg_actions_per_user,
    COUNT(DISTINCT patient_id) AS number_of_patients
FROM engagement_stats;


-- Bonus Query 4: Top 10 patients with the longest average gap between signup date and first appointment

WITH first_appointments AS (
    SELECT 
        a.patient_id,
        p.signup_date,
        MIN(a.scheduled_date) AS first_appointment_date,
        DATEDIFF(MIN(a.scheduled_date), p.signup_date) AS days_to_first_appointment
    FROM appointments a
    INNER JOIN patients p ON a.patient_id = p.patient_id
    GROUP BY a.patient_id, p.signup_date
)
SELECT 
    patient_id,
    signup_date,
    first_appointment_date,
    days_to_first_appointment
FROM first_appointments
ORDER BY days_to_first_appointment DESC
LIMIT 10;



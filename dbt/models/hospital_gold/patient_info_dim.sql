-- This model creates a comprehensive 'Patient 360' view by joining all relevant
-- silver tables. It includes logic to format salary and fix swapped email/phone data.

-- Step 1: Create CTEs for each silver table, cleaning data where necessary.

WITH patients AS (
    SELECT *
    FROM {{ ref('patients') }}
    QUALIFY ROW_NUMBER() OVER(PARTITION BY patient_id ORDER BY admission_date DESC) = 1
),

doctors AS (
    -- In this CTE, we add logic to fix the swapped email and phone numbers.
    SELECT
        doctor_id,
        doctor_name,
        salary,
        specialization,
        department,
        availability,
        joining_date,
        qualification,
        experience_years,
        image_url,
        -- Check which column actually contains the email. If the 'email' column
        -- doesn't have an '@', then it's actually the phone number.
        CASE
            WHEN email LIKE '%@%' THEN email
            WHEN phone LIKE '%@%' THEN phone
            ELSE NULL
        END AS corrected_email,
        -- If the 'phone' column has an '@', then it's actually the email.
        CASE
            WHEN phone LIKE '%@%' THEN email
            WHEN email LIKE '%@%' THEN phone
            ELSE phone
        END AS corrected_phone
    FROM {{ ref('doctors') }}
    QUALIFY ROW_NUMBER() OVER(PARTITION BY doctor_id ORDER BY joining_date DESC) = 1
),

departments AS (
    SELECT *
    FROM {{ ref('departments') }}
    QUALIFY ROW_NUMBER() OVER(PARTITION BY department_id ORDER BY department_id) = 1
),

rooms AS (
    SELECT *
    FROM {{ ref('rooms') }}
    QUALIFY ROW_NUMBER() OVER(PARTITION BY room_id ORDER BY room_id) = 1
),

latest_appointment AS (
    SELECT *
    FROM {{ ref('appointments') }}
    QUALIFY ROW_NUMBER() OVER(PARTITION BY patient_id ORDER BY appointment_date DESC, appointment_time DESC) = 1
),

latest_bed_assignment AS (
    SELECT *
    FROM {{ ref('beds') }}
    WHERE patient_id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER(PARTITION BY patient_id ORDER BY occupied_from DESC) = 1
),

latest_surgery AS (
    SELECT *
    FROM {{ ref('surgery') }}
    QUALIFY ROW_NUMBER() OVER(PARTITION BY patient_id ORDER BY surgery_date DESC, surgery_time DESC) = 1
),

latest_satisfaction AS (
    SELECT *
    FROM {{ ref('satisfaction_score') }}
    QUALIFY ROW_NUMBER() OVER(PARTITION BY patient_id ORDER BY survey_date DESC) = 1
),

-- Step 2: Join all the CTEs together.

final_join AS (
    SELECT
        p.*,
        d.doctor_name,
        d.salary AS doctor_salary,
        d.specialization AS doctor_specialization,
        d.department AS doctor_department,
        d.availability AS doctor_availability,
        d.joining_date AS doctor_joining_date,
        d.qualification AS doctor_qualification,
        d.experience_years AS doctor_experience_years,
        d.corrected_email AS doctor_email, -- Using the corrected email
        d.corrected_phone AS doctor_phone, -- Using the corrected phone
        d.image_url AS doctor_img,
        dept.name AS department_name,
        dept.total_staff AS department_total_staff,
        bed.bed_id AS beds_bed_id,
        bed.occupied_from AS beds_occupied_from,
        bed.occupied_till AS beds_occupied_till,
        bed.status AS beds_status,
        room.room_id AS room_room_id,
        room.floor AS room_floor,
        room.room_type AS room_room_type,
        room.capacity AS room_capacity,
        room.daily_charge AS room_daily_charge,
        room.avg_monthly_maintenance_cost AS room_avgmontlymaintenancecost,
        room.status AS room_status,
        surg.appointment_id AS surgery_appointment_id,
        surg.surgery_date AS surgery_appointment_date,
        surg.surgery_time AS surgery_appointment_time,
        surg.status AS surgery_status,
        surg.reason AS surgery_reason,
        surg.notes AS surgery_notes,
        sat.satisfaction_id AS satisfaction_satisfaction_id,
        sat.rating AS satisfaction_rating,
        sat.feedback AS satisfaction_feedback,
        la.doctor_id AS doctor_doctor_id
    FROM patients p
    LEFT JOIN latest_appointment la ON p.patient_id = la.patient_id
    LEFT JOIN doctors d ON la.doctor_id = d.doctor_id
    LEFT JOIN departments dept ON d.department = dept.name
    LEFT JOIN latest_bed_assignment bed ON p.patient_id = bed.patient_id
    LEFT JOIN rooms room ON bed.room_id = room.room_id
    LEFT JOIN latest_surgery surg ON p.patient_id = surg.patient_id
    LEFT JOIN latest_satisfaction sat ON p.patient_id = sat.patient_id
)

-- Step 3: Select and alias all columns to exactly match your desired output.

SELECT
    -- Patient Info
    patient_id AS "PATIENT_ID",
    patient_name AS "PATIENT_NAME",
    gender AS "PATIENT_GENDER",
    age AS "PATIENT_AGE",
    weight AS "PATIENT_WEIGHT",
    blood_group AS "PATIENT_BLOOD_GROUP",
    email AS "PATIENT_EMAIL",
    admission_date AS "PATIENT_ADMISSION_DATE",
    discharge_date AS "PATIENT_DISCHARGE_DATE",
    address AS "PATIENT_ADDRESS",
    admission_status AS "PATIENT_STATUS",
    admission_status AS "PATIENT_ADMISSION_STATUS",
    image_url AS "PATIENT_IMG",

    -- Doctor Info
    doctor_doctor_id AS "DOCTOR_DOCTOR_ID",
    doctor_name AS "DOCTOR_NAME",
    -- THIS IS THE FIX for salary format
    '$' || TO_VARCHAR(doctor_salary, '999,999,999') AS "DOCTOR_SALARY",
    doctor_specialization AS "DOCTOR_SPECIALIZATION",
    doctor_department AS "DOCTOR_DEPARTMENT",
    doctor_availability AS "DOCTOR_AVAILABILITY",
    doctor_joining_date AS "DOCTOR_JOINING_DATE",
    doctor_qualification AS "DOCTOR_QUALIFICATION",
    doctor_experience_years AS "DOCTOR_EXPERIENCE_YEARS",
    doctor_email AS "DOCTOR_EMAIL",
    doctor_phone AS "DOCTOR_PHONE",
    doctor_img AS "DOCTOR_IMG",

    -- Bed & Room Info
    beds_bed_id AS "BEDS_BED_ID",
    beds_occupied_from AS "BEDS_OCCUPIED_FROM",
    beds_occupied_till AS "BEDS_OCCUPIED_TILL",
    beds_status AS "BEDS_STATUS",
    room_room_id AS "ROOM_ROOM_ID",
    room_floor AS "ROOM_FLOOR",
    room_room_type AS "ROOM_ROOM_TYPE",
    room_capacity AS "ROOM_CAPACITY",
    room_daily_charge AS "ROOM_DAILY_CHARGE",
    room_avgmontlymaintenancecost AS "ROOM_AVGMONTLYMAINTENANCECOST",
    room_status AS "ROOM_STATUS",

    -- Department Info
    department_name AS "DEPARTMENT_NAME",
    department_total_staff AS "DEPARTMENT_TOTAL_STAFF",

    -- Satisfaction Info
    satisfaction_satisfaction_id AS "SATISFACTION_SATISFACTION_ID",
    satisfaction_rating AS "SATISFACTION_RATING",
    satisfaction_feedback AS "SATISFACTION_FEEDBACK",

    -- Surgery Info
    surgery_appointment_id AS "SURGERY_APPOINTMENT_ID",
    DAYNAME(surgery_appointment_date) || ', ' || TO_VARCHAR(surgery_appointment_date, 'MMMM DD, YYYY') AS "SURGERY_APPOINTMENT_DATE",
    TO_VARCHAR(surgery_appointment_time, 'HH12:MI AM') AS "SURGERY_APPOINTMENT_TIME",
    surgery_status AS "SURGERY_STATUS",
    surgery_reason AS "SURGERY_REASON",
    surgery_notes AS "SURGERY_NOTES",

    -- Calculated Fields
    CASE WHEN surgery_appointment_id IS NOT NULL THEN 'Yes' ELSE 'No' END AS "Had Surgery",
    CASE WHEN beds_bed_id IS NOT NULL THEN 'Yes' ELSE 'No' END AS "Had Room"

FROM final_join

-- ============================================================================
-- PNC - VITALS (program_id = 35, encounter type 'Vitals')
-- One row per encounter, raw values (latest value of each concept within the encounter), coded values decoded to concept names.
-- A reading that was not taken keeps its stored text (e.g. 'Machine not available').
-- record_type: baby = under 5 years, woman = 5+, unknown = no birthdate. Join to the pivot on person_id + visit_date.
-- ============================================================================
WITH enc_obs AS (
    SELECT o.obs_id, o.person_id, o.location_id, o.encounter_id, o.concept_id, o.obs_datetime,
        o.value_coded, o.value_numeric, o.value_text, o.value_datetime,
        ROW_NUMBER() OVER (PARTITION BY o.encounter_id, o.concept_id ORDER BY o.obs_datetime DESC, o.obs_id DESC) AS rn
    FROM obs o
    INNER JOIN encounter e ON e.encounter_id = o.encounter_id AND e.program_id = 35 AND e.voided = 0
    INNER JOIN encounter_type et ON et.encounter_type_id = e.encounter_type AND et.name = 'Vitals'
    WHERE o.voided = 0 AND o.concept_id IN (53312, 53316, 53319, 53322, 53325, 53328, 53333, 53478, 57157, 58873)
),

coded_names AS (
    SELECT concept_id, name
    FROM (
        SELECT cn.concept_id, cn.name,
            ROW_NUMBER() OVER (PARTITION BY cn.concept_id
                ORDER BY (cn.locale = 'en') DESC, (cn.concept_name_type = 'FULLY_SPECIFIED') DESC, cn.concept_name_id) AS r
        FROM concept_name cn
        WHERE cn.voided = 0 AND cn.concept_id IN (SELECT DISTINCT value_coded FROM enc_obs WHERE value_coded IS NOT NULL)
    ) x
    WHERE r = 1
)

SELECT
    o.person_id,
    o.location_id,
    o.encounter_id,
    DATE(MIN(o.obs_datetime)) AS visit_date,
    MIN(o.obs_datetime) AS encounter_time,
    CASE WHEN p.birthdate IS NULL THEN 'unknown'
             WHEN TIMESTAMPDIFF(YEAR, p.birthdate, DATE(MIN(o.obs_datetime))) < 5 THEN 'baby' ELSE 'woman' END AS record_type,
    MAX(CASE WHEN o.concept_id = 53312 AND o.rn = 1 THEN o.value_numeric END) AS systolic_blood_pressure,
    MAX(CASE WHEN o.concept_id = 53316 AND o.rn = 1 THEN o.value_numeric END) AS diastolic_blood_pressure,
    MAX(CASE WHEN o.concept_id = 53319 AND o.rn = 1 THEN COALESCE(n.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS pulse,
    MAX(CASE WHEN o.concept_id = 53322 AND o.rn = 1 THEN COALESCE(n.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS temperature_c,
    MAX(CASE WHEN o.concept_id = 53325 AND o.rn = 1 THEN COALESCE(n.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS weight_kg,
    MAX(CASE WHEN o.concept_id = 53328 AND o.rn = 1 THEN o.value_numeric END) AS height,
    MAX(CASE WHEN o.concept_id = 53333 AND o.rn = 1 THEN COALESCE(n.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS sao2,
    MAX(CASE WHEN o.concept_id = 53478 AND o.rn = 1 THEN COALESCE(n.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS respiratory_rate,
    MAX(CASE WHEN o.concept_id = 57157 AND o.rn = 1 THEN o.value_text END) AS blood_pressure,
    MAX(CASE WHEN o.concept_id = 58873 AND o.rn = 1 THEN o.value_numeric END) AS weight_grams
FROM enc_obs o
INNER JOIN person p ON p.person_id = o.person_id
LEFT JOIN coded_names n ON n.concept_id = o.value_coded
GROUP BY o.person_id, o.location_id, o.encounter_id, p.birthdate
ORDER BY o.person_id, encounter_time;

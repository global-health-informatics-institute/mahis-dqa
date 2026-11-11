-- ============================================================================
-- LABOUR AND DELIVERY - VITALS (program_id = 36, encounter type 'Vitals')
-- One row per Vitals encounter, raw values (latest value of each concept within the encounter).
-- A reading that was not taken keeps its stored text, e.g. 'Machine not available'.
-- record_type: baby = under 5 years, woman = 5+, unknown = no birthdate (the program also holds newborns' own records).
-- Join to the pivot on person_id + visit_date.
-- ============================================================================
WITH vit_obs AS (
    SELECT o.obs_id, o.person_id, o.location_id, o.encounter_id, o.concept_id, o.obs_datetime,
        o.value_numeric, o.value_text, o.value_datetime,
        ROW_NUMBER() OVER (PARTITION BY o.encounter_id, o.concept_id ORDER BY o.obs_datetime DESC, o.obs_id DESC) AS rn
    FROM obs o
    INNER JOIN encounter e ON e.encounter_id = o.encounter_id AND e.program_id = 36 AND e.voided = 0
    INNER JOIN encounter_type et ON et.encounter_type_id = e.encounter_type AND et.name = 'Vitals'
    WHERE o.voided = 0 AND o.concept_id IN (53312, 53316, 53319, 53321, 53322, 53325, 53328, 53333, 53478, 53479, 58873)
)

SELECT
    o.person_id,
    o.location_id,
    o.encounter_id,
    DATE(MIN(o.obs_datetime)) AS visit_date,
    MIN(o.obs_datetime) AS vitals_time,
    CASE WHEN pe.birthdate IS NULL THEN 'unknown'
         WHEN TIMESTAMPDIFF(YEAR, pe.birthdate, DATE(MIN(o.obs_datetime))) < 5 THEN 'baby' ELSE 'woman' END AS record_type,
    MAX(CASE WHEN o.concept_id = 53312 AND o.rn = 1 THEN o.value_numeric END) AS systolic_blood_pressure,
    MAX(CASE WHEN o.concept_id = 53316 AND o.rn = 1 THEN o.value_numeric END) AS diastolic_blood_pressure,
    MAX(CASE WHEN o.concept_id = 53319 AND o.rn = 1 THEN COALESCE(CAST(o.value_numeric AS char), o.value_text, CAST(o.value_datetime AS char)) END) AS pulse,
    MAX(CASE WHEN o.concept_id = 53321 AND o.rn = 1 THEN o.value_numeric END) AS heart_rate,
    MAX(CASE WHEN o.concept_id = 53322 AND o.rn = 1 THEN COALESCE(CAST(o.value_numeric AS char), o.value_text, CAST(o.value_datetime AS char)) END) AS temperature_c,
    MAX(CASE WHEN o.concept_id = 53325 AND o.rn = 1 THEN o.value_numeric END) AS weight_kg,
    MAX(CASE WHEN o.concept_id = 53328 AND o.rn = 1 THEN COALESCE(CAST(o.value_numeric AS char), o.value_text, CAST(o.value_datetime AS char)) END) AS height,
    MAX(CASE WHEN o.concept_id = 53333 AND o.rn = 1 THEN COALESCE(CAST(o.value_numeric AS char), o.value_text, CAST(o.value_datetime AS char)) END) AS sao2,
    MAX(CASE WHEN o.concept_id = 53478 AND o.rn = 1 THEN COALESCE(CAST(o.value_numeric AS char), o.value_text, CAST(o.value_datetime AS char)) END) AS respiratory_rate,
    MAX(CASE WHEN o.concept_id = 53479 AND o.rn = 1 THEN o.value_numeric END) AS respiration_rate,
    MAX(CASE WHEN o.concept_id = 58873 AND o.rn = 1 THEN o.value_numeric END) AS weight_grams
FROM vit_obs o
INNER JOIN person pe ON pe.person_id = o.person_id
GROUP BY o.person_id, o.location_id, o.encounter_id, pe.birthdate
ORDER BY o.person_id, vitals_time;

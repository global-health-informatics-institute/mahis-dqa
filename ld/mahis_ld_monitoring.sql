-- ============================================================================
-- LABOUR AND DELIVERY - LABOUR MONITORING (program_id = 36, encounter type 'Continous monitoring')
-- One row per monitoring encounter (one assessment round during labour), raw values, coded values decoded to concept names.
-- Join to the pivot on person_id + visit_date (several rounds per day are possible); number_of_monitoring_rounds is in the pivot.
-- ============================================================================
WITH mon_obs AS (
    SELECT o.obs_id, o.person_id, o.location_id, o.encounter_id, o.concept_id, o.obs_datetime,
        o.value_coded, o.value_numeric, o.value_text, o.value_datetime
    FROM obs o
    INNER JOIN encounter e ON e.encounter_id = o.encounter_id AND e.program_id = 36 AND e.voided = 0
    INNER JOIN encounter_type et ON et.encounter_type_id = e.encounter_type AND et.name = 'Continous monitoring'
    WHERE o.voided = 0 AND o.concept_id IN (23761, 48007, 48013, 48015, 48320, 48395, 55854, 55855, 55857, 55860, 55861, 55991, 58622, 58661, 58676, 58821, 58822, 59264, 59266, 59434, 59435)
),

coded_names AS (
    SELECT concept_id, name
    FROM (
        SELECT cn.concept_id, cn.name,
            ROW_NUMBER() OVER (PARTITION BY cn.concept_id
                ORDER BY (cn.locale = 'en') DESC, (cn.concept_name_type = 'FULLY_SPECIFIED') DESC, cn.concept_name_id) AS r
        FROM concept_name cn
        WHERE cn.voided = 0 AND cn.concept_id IN (SELECT DISTINCT value_coded FROM mon_obs WHERE value_coded IS NOT NULL)
    ) x
    WHERE r = 1
)

SELECT
    o.person_id,
    o.location_id,
    o.encounter_id,
    DATE(MIN(o.obs_datetime)) AS visit_date,
    MIN(o.obs_datetime) AS monitoring_start_time,
    MAX(o.obs_datetime) AS monitoring_end_time,
    MAX(CASE WHEN o.concept_id = 23761 THEN o.value_text END) AS umbilical_cord,
    MAX(CASE WHEN o.concept_id = 48007 THEN o.value_text END) AS severity_of_contractions,
    MAX(CASE WHEN o.concept_id = 48013 THEN o.value_numeric END) AS amount_of_urine,
    MAX(CASE WHEN o.concept_id = 48015 THEN o.value_text END) AS color_of_urine,
    MAX(CASE WHEN o.concept_id = 48320 THEN o.value_text END) AS obstetric_complications,
    MAX(CASE WHEN o.concept_id = 48395 THEN o.value_text END) AS odour_of_urine,
    MAX(CASE WHEN o.concept_id = 55854 THEN o.value_numeric END) AS contractions,
    MAX(CASE WHEN o.concept_id = 55855 THEN o.value_numeric END) AS fetal_heart_rate,
    MAX(CASE WHEN o.concept_id = 55857 THEN o.value_text END) AS descent,
    MAX(CASE WHEN o.concept_id = 55860 THEN o.value_numeric END) AS cervical_dilation,
    MAX(CASE WHEN o.concept_id = 55861 THEN n.name END) AS caput,
    MAX(CASE WHEN o.concept_id = 55991 THEN n.name END) AS moulding,
    MAX(CASE WHEN o.concept_id = 58622 THEN o.value_text END) AS contractions_remarks,
    MAX(CASE WHEN o.concept_id = 58661 THEN o.value_text END) AS fetal_station,
    MAX(CASE WHEN o.concept_id = 58676 THEN n.name END) AS holder_membranes,
    MAX(CASE WHEN o.concept_id = 58821 THEN n.name END) AS state_of_liquor,
    MAX(CASE WHEN o.concept_id = 58822 THEN n.name END) AS state_of_membranes,
    MAX(CASE WHEN o.concept_id = 59264 THEN n.name END) AS non_pharmacological_pain_management,
    MAX(CASE WHEN o.concept_id = 59266 THEN n.name END) AS pharmacological_pain_management,
    MAX(CASE WHEN o.concept_id = 59434 THEN n.name END) AS are_contractions_available,
    MAX(CASE WHEN o.concept_id = 59435 THEN n.name END) AS are_the_contractions_coordinated
FROM mon_obs o
LEFT JOIN coded_names n ON n.concept_id = o.value_coded
GROUP BY o.person_id, o.location_id, o.encounter_id
ORDER BY o.person_id, monitoring_start_time;

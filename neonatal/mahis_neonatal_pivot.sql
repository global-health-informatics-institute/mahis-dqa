-- ============================================================================
-- MAHIS PIVOT QUERY - MULTI-LEVEL OBS HIERARCHY WITH ROOT-LEVEL UNION
--
-- Purpose: Handle nested obs records + root-level obs separately
-- - Recursive CTE: Flattens multi-level hierarchies (parent concept_id + child values)
-- - Root UNION: Captures root-level obs (obs_group_id IS NULL) separately
-- - Combined into latest_obs for comprehensive pivot
--
-- Process:
-- 1. Recursively flatten multi-level obs hierarchy into denormalized records
-- 2. UNION with root-level obs queried directly from obs table
-- 3. Join concept_name to decode value_coded into readable values
-- 4. Pivot concepts into columns using MAX(CASE WHEN...)
-- 5. Group by location, person, visit_date to get one row per encounter
-- ============================================================================

with obbs as 
(
WITH RECURSIVE mahis_persons AS (
    -- Persons with a MAHIS (program 39) encounter; all their obs from any program are brought in
    SELECT DISTINCT o.person_id
    FROM obs o
    INNER JOIN encounter e ON e.encounter_id = o.encounter_id AND e.program_id = 39
    WHERE e.voided = 0 AND o.voided = 0
),

obs_hierarchy AS (
    -- LEVEL 0: Root-level observations (obs_group_id IS NULL)
    SELECT
        o.obs_id,
        o.obs_group_id,
        o.encounter_id,
        o.location_id,
        o.person_id,
        o.concept_id,
        o.concept_id AS own_concept_id,
        o.value_numeric,
        o.value_text,
        o.value_coded,
        o.value_datetime,
        o.obs_datetime,
        DATE(o.obs_datetime) as visit_date,
        0 as hierarchy_level,
        o.obs_id as root_obs_id,
        CAST(o.obs_id AS char(255)) as path
    FROM obs o
    INNER JOIN mahis_persons mp ON mp.person_id = o.person_id
    LEFT JOIN encounter e ON e.encounter_id = o.encounter_id
    WHERE (e.encounter_id IS NULL OR e.voided = 0)
        AND o.voided = 0
        AND o.obs_group_id IS NULL

    UNION ALL

    -- LEVELS 1+: Child observations (obs_group_id references parent obs_id)
    SELECT
        o.obs_id,
        o.obs_group_id,
        o.encounter_id,
        oh.location_id,
        oh.person_id,
        oh.concept_id,
        o.concept_id,
        o.value_numeric,
        o.value_text,
        o.value_coded,
        o.value_datetime,
        o.obs_datetime,
        oh.visit_date,
        oh.hierarchy_level + 1,
        oh.root_obs_id,
        CONCAT(oh.path, ',', o.obs_id)
    FROM obs o
    INNER JOIN obs_hierarchy oh ON o.obs_group_id = oh.obs_id
    WHERE o.voided = 0
        AND oh.hierarchy_level < 5  -- Limit recursion depth (adjust as needed)
),

all_obs_data AS (
    -- Multi-level records from recursive CTE (child records with parent concept_id)
    SELECT
        location_id,
        person_id,
        visit_date,
        -- Lab test status (59662) is a child of Test type (57640) but keeps its own concept_id
        CASE WHEN own_concept_id = 59662 THEN 59662 ELSE concept_id END AS concept_id,
        obs_id,
        value_numeric,
        value_text,
        value_coded,
        value_datetime,
        obs_datetime,
        -- Lab test key = test type (value_coded of the Test type obs) so each test gets its own row
        CASE WHEN own_concept_id = 59662
             THEN COALESCE((SELECT t.value_coded FROM obs t WHERE t.obs_id = obs_hierarchy.root_obs_id AND t.concept_id = 57640), 0)
             ELSE 0 END AS lab_test_key
    FROM obs_hierarchy
    WHERE hierarchy_level > 0  -- Only child records (parent concept_id + child values)

    UNION ALL

    -- Root-level obs directly from obs table (own concept_id + values)
    SELECT
        o.location_id,
        o.person_id,
        DATE(o.obs_datetime) as visit_date,
        o.concept_id,
        o.obs_id,
        o.value_numeric,
        o.value_text,
        o.value_coded,
        o.value_datetime,
        o.obs_datetime,
        -- Order status precedes its Test type obs; requester/reason/comment follow it (same encounter)
        CASE
            WHEN o.concept_id = 57640 THEN COALESCE(o.value_coded, 0)
            WHEN o.concept_id = 47384 THEN COALESCE((
                SELECT t.value_coded FROM obs t
                WHERE t.person_id = o.person_id AND t.encounter_id = o.encounter_id
                    AND t.concept_id = 57640 AND t.voided = 0 AND t.obs_id > o.obs_id
                ORDER BY t.obs_id ASC LIMIT 1), 0)
            WHEN o.concept_id IN (54609, 51076, 50510) THEN COALESCE((
                SELECT t.value_coded FROM obs t
                WHERE t.person_id = o.person_id AND t.encounter_id = o.encounter_id
                    AND t.concept_id = 57640 AND t.voided = 0 AND t.obs_id < o.obs_id
                ORDER BY t.obs_id DESC LIMIT 1), 0)
            ELSE 0
        END AS lab_test_key
    FROM obs o
    INNER JOIN mahis_persons mp ON mp.person_id = o.person_id
    LEFT JOIN encounter e ON e.encounter_id = o.encounter_id
    WHERE (e.encounter_id IS NULL OR e.voided = 0)
        AND o.voided = 0
        AND o.obs_group_id IS NULL
),

latest_obs AS (
    -- Get the latest (most recent) occurrence of each concept per visit
    SELECT
        location_id,
        person_id,
        visit_date,
        concept_id,
        obs_id,
        value_numeric,
        value_text,
        value_coded,
        value_datetime,
        lab_test_key,
        ROW_NUMBER() OVER (
            PARTITION BY location_id, person_id, visit_date, lab_test_key, concept_id
            ORDER BY obs_datetime DESC, obs_id DESC
        ) AS rn
    FROM all_obs_data
    WHERE concept_id IN (
        272, 13322, 22348, 23765, 36847, 37198, 37284, 37357, 37769, 37967,
        38025, 38115, 38417, 38565, 46900, 47384, 47538, 47659, 48015, 48300,
        48303, 48502, 48803, 49510, 49512, 49514, 49516, 49522, 49524, 49528,
        49695, 49708, 49716, 49852, 49889, 49933, 50109, 50115, 50117, 50119,
        50121, 50123, 50125, 50127, 50129, 50141, 50144, 50146, 50148, 50150,
        50154, 50156, 50164, 50181, 50183, 50187, 50189, 50202, 50209, 50211,
        50213, 50217, 50219, 50244, 50246, 50251, 50253, 50255, 50259, 50261,
        50263, 50265, 50266, 50268, 50270, 50272, 50274, 50276, 50278, 50280,
        50282, 50312, 50330, 50361, 50363, 50385, 50387, 50389, 50391, 50395,
        50397, 50399, 50401, 50402, 50404, 50406, 50408, 50410, 50412, 50414,
        50417, 50419, 50421, 50423, 50425, 50435, 50439, 50441, 50510, 50568,
        50718, 51076, 51293, 51936, 53262, 53319, 53322, 53325, 53478, 53551,
        54106, 54609, 54757, 54758, 54759, 55169, 55288, 55366, 55369, 55517,
        55706, 56097, 56596, 56699, 57640, 57645, 57653, 58971, 58976, 59210,
        59211, 59213, 59214, 59215, 59216, 59217, 59221, 59224, 59225, 59248,
        59392, 59394, 59403, 59404, 59662, 157910, 157911, 157912, 157914, 157915,
        157916, 157919, 157923, 157924,
        37678, 48282, 48284, 49070, 49085, 49509, 50107, 50340, 50345, 50383, 50393, 52925, 56620, 58873, 59219, 157913, 159054, 159055, 159056, 159059, 159061, 159062,
        55541, 53328, 48285, 59098, 56806
    )
)

-- PIVOT: Convert concepts into columns
-- cn.name = decoded value_coded (concept name), value_text = free text, value_numeric = numeric
SELECT
    lo.location_id,
    lo.person_id,
    lo.visit_date,
--     NULLIF(lo.lab_test_key, 0) AS lab_test_key,
--     MAX(CASE WHEN lo.concept_id = 272 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS pyogenic_abscess_skin,
    MAX(CASE WHEN lo.concept_id = 13322 THEN cn.name END) AS abdominal_distension,
    MAX(CASE WHEN lo.concept_id = 22348 THEN cn.name END) AS palate,
    MAX(CASE WHEN lo.concept_id = 23765 THEN cn.name END) AS head,
    MAX(CASE WHEN lo.concept_id = 36847 THEN lo.value_numeric END) AS blood_sugar,
    MAX(CASE WHEN lo.concept_id = 37198 THEN cn.name END) AS teo,
    MAX(CASE WHEN lo.concept_id = 37284 THEN cn.name END) AS skin_rash,
    MAX(CASE WHEN lo.concept_id = 37357 THEN cn.name END) AS splenomegaly,
    MAX(CASE WHEN lo.concept_id = 37769 THEN lo.value_text END) AS mode_of_transport,
--     MAX(CASE WHEN lo.concept_id = 37967 THEN cn.name END) AS no_response,
--     MAX(CASE WHEN lo.concept_id = 38025 THEN cn.name END) AS normal,
    MAX(CASE WHEN lo.concept_id = 38115 THEN lo.value_text END) AS treatment,
    MAX(CASE WHEN lo.concept_id = 38417 THEN cn.name END) AS activity,
    MAX(CASE WHEN lo.concept_id = 38565 THEN lo.value_datetime END) AS drug_end_date,
    MAX(CASE WHEN lo.concept_id = 46900 THEN cn.name END) AS colour,
    MAX(CASE WHEN lo.concept_id = 47384 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS lab_order_status,
    MAX(CASE WHEN lo.concept_id = 47538 THEN cn.name END) AS capillary_refill_time,
--     MAX(CASE WHEN lo.concept_id = 47659 THEN cn.name END) AS absent,
    MAX(CASE WHEN lo.concept_id = 48015 THEN COALESCE(cn.name, lo.value_text) END) AS color_of_urine,
    MAX(CASE WHEN lo.concept_id = 48300 THEN cn.name END) AS vitamin_k_given,
    MAX(CASE WHEN lo.concept_id = 48303 THEN COALESCE(cn.name, lo.value_text) END) AS mode_of_delivery,
    MAX(CASE WHEN lo.concept_id = 48502 THEN lo.value_numeric END) AS current_weight,
--     MAX(CASE WHEN lo.concept_id = 48803 THEN cn.name END) AS capillary_refill_less_3_seconds,
    MAX(CASE WHEN lo.concept_id = 49510 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS baby_breathing_status,
    MAX(CASE WHEN lo.concept_id = 49512 THEN lo.value_numeric END) AS oxygen_saturation_on_oxygen,
    MAX(CASE WHEN lo.concept_id = 49514 THEN cn.name END) AS can_measure_oxygen_saturation,
    MAX(CASE WHEN lo.concept_id = 49516 THEN cn.name END) AS oxygen_available_at_facility,
    MAX(CASE WHEN lo.concept_id = 49522 THEN cn.name END) AS can_measure_temperature,
    MAX(CASE WHEN lo.concept_id = 49524 THEN lo.value_text END) AS blood_sugar_unit,
    MAX(CASE WHEN lo.concept_id = 49528 THEN lo.value_text END) AS referral_facility,
--     MAX(CASE WHEN lo.concept_id = 49695 THEN cn.name END) AS anus_patent_normal,
    MAX(CASE WHEN lo.concept_id = 49708 THEN lo.value_text END) AS musculoskeletal_deformities,
--     MAX(CASE WHEN lo.concept_id = 49716 THEN cn.name END) AS palpable,
    MAX(CASE WHEN lo.concept_id = 49852 THEN COALESCE(lo.value_numeric, lo.value_text) END) AS oxygen_saturation,
    MAX(CASE WHEN lo.concept_id = 49889 THEN cn.name END) AS normal_heart_sounds,
    MAX(CASE WHEN lo.concept_id = 49933 THEN cn.name END) AS offensive_liquor,
    MAX(CASE WHEN lo.concept_id = 50109 THEN lo.value_numeric END) AS gestation_in_weeks,
    MAX(CASE WHEN lo.concept_id = 50115 THEN cn.name END) AS baby_given_nvp,
    MAX(CASE WHEN lo.concept_id = 50117 THEN cn.name END) AS baby_tested_hepatitis,
    MAX(CASE WHEN lo.concept_id = 50119 THEN cn.name END) AS birth_asphyxia_suspected,
    MAX(CASE WHEN lo.concept_id = 50121 THEN cn.name END) AS do_hiv_retest,
    MAX(CASE WHEN lo.concept_id = 50123 THEN cn.name END) AS is_baby_vomiting,
    MAX(CASE WHEN lo.concept_id = 50125 THEN cn.name END) AS baby_passing_urine,
    MAX(CASE WHEN lo.concept_id = 50127 THEN cn.name END) AS mother_treated_vdrl,
    MAX(CASE WHEN lo.concept_id = 50129 THEN cn.name END) AS stethoscope_available,
    MAX(CASE WHEN lo.concept_id = 50141 THEN cn.name END) AS abdomen_color_change,
    MAX(CASE WHEN lo.concept_id = 50144 THEN cn.name END) AS abdomen_distended_veins,
    MAX(CASE WHEN lo.concept_id = 50146 THEN cn.name END) AS abdomen_shiny,
    MAX(CASE WHEN lo.concept_id = 50148 THEN cn.name END) AS abdomen_soft_normal,
    MAX(CASE WHEN lo.concept_id = 50150 THEN cn.name END) AS abdomen_tender,
    MAX(CASE WHEN lo.concept_id = 50154 THEN cn.name END) AS blood_in_stools,
    MAX(CASE WHEN lo.concept_id = 50156 THEN cn.name END) AS chest_clear,
    MAX(CASE WHEN lo.concept_id = 50164 THEN cn.name END) AS spinal_bifida,
    MAX(CASE WHEN lo.concept_id = 50181 THEN cn.name END) AS chlorohexidine_cord_care,
    MAX(CASE WHEN lo.concept_id = 50183 THEN lo.value_text END) AS mother_name,
    MAX(CASE WHEN lo.concept_id = 50187 THEN lo.value_text END) AS birth_facility_name,
    MAX(CASE WHEN lo.concept_id = 50189 THEN lo.value_text END) AS referring_facility_name,
    MAX(CASE WHEN lo.concept_id = 50202 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS skin_findings,
    MAX(CASE WHEN lo.concept_id = 50209 THEN cn.name END) AS palpable_kidneys,
    MAX(CASE WHEN lo.concept_id = 50211 THEN cn.name END) AS mucus_in_stools,
    MAX(CASE WHEN lo.concept_id = 50213 THEN cn.name END) AS color_of_stools,
    MAX(CASE WHEN lo.concept_id = 50217 THEN cn.name END) AS consistency_of_stools,
    MAX(CASE WHEN lo.concept_id = 50219 THEN cn.name END) AS passage_of_meconium,
    MAX(CASE WHEN lo.concept_id = 50244 THEN cn.name END) AS extra_digits,
    MAX(CASE WHEN lo.concept_id = 50246 THEN cn.name END) AS talipes,
    MAX(CASE WHEN lo.concept_id = 50251 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS duration_of_feeding,
    MAX(CASE WHEN lo.concept_id = 50253 THEN cn.name END) AS effort_during_feeding,
    MAX(CASE WHEN lo.concept_id = 50255 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS frequency_of_feeding,
    MAX(CASE WHEN lo.concept_id = 50259 THEN cn.name END) AS suck_reflex,
    MAX(CASE WHEN lo.concept_id = 50261 THEN cn.name END) AS grasp_reflex,
    MAX(CASE WHEN lo.concept_id = 50263 THEN cn.name END) AS moro_reflex,
    MAX(CASE WHEN lo.concept_id = 50265 THEN cn.name END) AS tone_assessment,
    MAX(CASE WHEN lo.concept_id = 50266 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS thompson_consciousness_score,
    MAX(CASE WHEN lo.concept_id = 50268 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS thompson_fits_score,
    MAX(CASE WHEN lo.concept_id = 50270 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS thompson_fontanelle_score,
    MAX(CASE WHEN lo.concept_id = 50272 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS thompson_grasp_score,
    MAX(CASE WHEN lo.concept_id = 50274 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS thompson_moro_score,
    MAX(CASE WHEN lo.concept_id = 50276 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS thompson_posture_score,
    MAX(CASE WHEN lo.concept_id = 50278 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS thompson_respiration_score,
    MAX(CASE WHEN lo.concept_id = 50280 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS thompson_suck_score,
    MAX(CASE WHEN lo.concept_id = 50282 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS thompson_tone_score,
    -- MAX(CASE WHEN lo.concept_id = 50312 THEN cn.name END) AS hyperthermia,
    MAX(CASE WHEN lo.concept_id = 50330 THEN cn.name END) AS thermal_care,
    MAX(CASE WHEN lo.concept_id = 50361 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS admitted_from,
    MAX(CASE WHEN lo.concept_id = 50363 THEN cn.name END) AS mother_status,
    MAX(CASE WHEN lo.concept_id = 50385 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS multiple_birth,
    MAX(CASE WHEN lo.concept_id = 50387 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS type_of_birth,
    MAX(CASE WHEN lo.concept_id = 50389 THEN cn.name END) AS cried_after_birth,
    MAX(CASE WHEN lo.concept_id = 50391 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS resuscitation_method,
    MAX(CASE WHEN lo.concept_id = 50395 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS gestation_method_assessment,
    MAX(CASE WHEN lo.concept_id = 50397 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS ultrasound_scanning,
    MAX(CASE WHEN lo.concept_id = 50399 THEN lo.value_datetime END) AS onset_of_labor,
    MAX(CASE WHEN lo.concept_id = 50401 THEN cn.name END) AS rupture_of_membranes,
    MAX(CASE WHEN lo.concept_id = 50402 THEN cn.name END) AS meconium_present,
    MAX(CASE WHEN lo.concept_id = 50404 THEN cn.name END) AS maternal_analgesia,
    MAX(CASE WHEN lo.concept_id = 50406 THEN cn.name END) AS anesthesia_used,
    MAX(CASE WHEN lo.concept_id = 50408 THEN lo.value_datetime END) AS last_hiv_test_date,
    MAX(CASE WHEN lo.concept_id = 50410 THEN cn.name END) AS mother_vdrl_result,
    MAX(CASE WHEN lo.concept_id = 50412 THEN cn.name END) AS three_doses_completed,
    MAX(CASE WHEN lo.concept_id = 50414 THEN cn.name END) AS mother_hepatitis_result,
    MAX(CASE WHEN lo.concept_id = 50417 THEN cn.name END) AS fontanelle,
    MAX(CASE WHEN lo.concept_id = 50419 THEN cn.name END) AS femoral_pulses,
    MAX(CASE WHEN lo.concept_id = 50421 THEN cn.name END) AS anus_assessment,
    MAX(CASE WHEN lo.concept_id = 50423 THEN cn.name END) AS genitalia,
    MAX(CASE WHEN lo.concept_id = 50425 THEN cn.name END) AS congenital_abnormality,
--     MAX(CASE WHEN lo.concept_id = 50435 THEN cn.name END) AS yellow_skin,
--     MAX(CASE WHEN lo.concept_id = 50439 THEN cn.name END) AS normal_male,
--     MAX(CASE WHEN lo.concept_id = 50441 THEN cn.name END) AS normal_female,
    MAX(CASE WHEN lo.concept_id = 50510 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS comment_to_fulfiller,
    -- MAX(CASE WHEN lo.concept_id = 50568 THEN cn.name END) AS flat,
    MAX(CASE WHEN lo.concept_id = 50718 THEN lo.value_text END) AS workstation_location,
    MAX(CASE WHEN lo.concept_id = 51076 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS reason_for_test,
    MAX(CASE WHEN lo.concept_id = 51293 THEN lo.value_text END) AS clinician_notes,
    MAX(CASE WHEN lo.concept_id = 51936 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS place_of_birth,
    MAX(CASE WHEN lo.concept_id = 53262 THEN cn.name END) AS hepatomegaly,
    MAX(CASE WHEN lo.concept_id = 53319 THEN lo.value_numeric END) AS pulse,
    MAX(CASE WHEN lo.concept_id = 53322 THEN lo.value_numeric END) AS temperature,
    MAX(CASE WHEN lo.concept_id = 53325 THEN lo.value_numeric END) AS weight,
    MAX(CASE WHEN lo.concept_id = 53478 THEN lo.value_numeric END) AS respiratory_rate,
    MAX(CASE WHEN lo.concept_id = 53551 THEN lo.value_numeric END) AS head_circumference,
    MAX(CASE WHEN lo.concept_id = 54106 THEN lo.value_numeric END) AS birth_weight,
    MAX(CASE WHEN lo.concept_id = 54609 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS person_making_request,
    MAX(CASE WHEN lo.concept_id = 54757 THEN cn.name END) AS referred,
    MAX(CASE WHEN lo.concept_id = 54758 THEN cn.name END) AS primary_diagnosis,
    MAX(CASE WHEN lo.concept_id = 54759 THEN cn.name END) AS secondary_diagnosis,
--     MAX(CASE WHEN lo.concept_id = 55169 THEN cn.name END) AS alert,
    MAX(CASE WHEN lo.concept_id = 55288 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS tetanus_diphtheria,
    MAX(CASE WHEN lo.concept_id = 55366 THEN cn.name END) AS nasal_flaring,
    MAX(CASE WHEN lo.concept_id = 55369 THEN cn.name END) AS central_cyanosis,
    MAX(CASE WHEN lo.concept_id = 55517 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS referred_from,
    MAX(CASE WHEN lo.concept_id = 55706 THEN cn.name END) AS respiratory_distress,
    MAX(CASE WHEN lo.concept_id = 56097 THEN cn.name END) AS mother_hiv_status,
    MAX(CASE WHEN lo.concept_id = 56596 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS presenting_complaint,
    MAX(CASE WHEN lo.concept_id = 56699 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS avpu,
    MAX(CASE WHEN lo.concept_id = 57640 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS test_type,
    -- MAX(CASE WHEN lo.concept_id = 57645 THEN cn.name END) AS pink_skin,
    MAX(CASE WHEN lo.concept_id = 57653 THEN cn.name END) AS hiv_unknown,
    MAX(CASE WHEN lo.concept_id = 58971 THEN cn.name END) AS readmission,
    MAX(CASE WHEN lo.concept_id = 58976 THEN cn.name END) AS hiv_low_risk,
    MAX(CASE WHEN lo.concept_id = 59210 THEN cn.name END) AS type_of_feed,
    MAX(CASE WHEN lo.concept_id = 59211 THEN cn.name END) AS mode_of_feeding,
    MAX(CASE WHEN lo.concept_id = 59213 THEN cn.name END) AS weight_trend_since_birth,
    MAX(CASE WHEN lo.concept_id = 59214 THEN cn.name END) AS baby_oral_thrush,
    MAX(CASE WHEN lo.concept_id = 59215 THEN cn.name END) AS baby_oral_sores,
    MAX(CASE WHEN lo.concept_id = 59216 THEN cn.name END) AS baby_tongue_tie,
    MAX(CASE WHEN lo.concept_id = 59217 THEN cn.name END) AS umbilical_condition,
    MAX(CASE WHEN lo.concept_id = 59221 THEN cn.name END) AS umbilicus_healthy,
    MAX(CASE WHEN lo.concept_id = 59224 THEN lo.value_text END) AS mother_identifier,
    MAX(CASE WHEN lo.concept_id = 59225 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS known_medical_condition,
    MAX(CASE WHEN lo.concept_id = 59248 THEN cn.name END) AS clinical_review_outcome,
    MAX(CASE WHEN lo.concept_id = 59392 THEN cn.name END) AS baby_catheterized,
    MAX(CASE WHEN lo.concept_id = 59394 THEN cn.name END) AS baby_feeding,
    MAX(CASE WHEN lo.concept_id = 59403 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS duration_rupture_membranes,
    MAX(CASE WHEN lo.concept_id = 59404 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS analgesia_drug,
    MAX(CASE WHEN lo.concept_id = 59662 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS lab_test_status,
    MAX(CASE WHEN lo.concept_id = 157910 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS tactile_trunk_temperature,
    MAX(CASE WHEN lo.concept_id = 157911 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS airway_status,
    MAX(CASE WHEN lo.concept_id = 157912 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS warm_peripherals,
    MAX(CASE WHEN lo.concept_id = 157914 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS pulse_volume,
    MAX(CASE WHEN lo.concept_id = 157915 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS convulsions_or_twitching,
    MAX(CASE WHEN lo.concept_id = 157916 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS signs_of_dehydration,
    MAX(CASE WHEN lo.concept_id = 157919 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS breathing_triage,
    MAX(CASE WHEN lo.concept_id = 157923 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS baby_dehydrated,
    MAX(CASE WHEN lo.concept_id = 157924 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS oxygen_unavailable_reason,
    MAX(CASE WHEN lo.concept_id = 37678 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS fast_breathing,
    MAX(CASE WHEN lo.concept_id = 48282 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS apgar_score_1_min,
    MAX(CASE WHEN lo.concept_id = 48284 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS apgar_score_5_min,
    MAX(CASE WHEN lo.concept_id = 49070 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS protected_at_birth,
    MAX(CASE WHEN lo.concept_id = 49085 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS tdv_doses_received,
    MAX(CASE WHEN lo.concept_id = 49509 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS baby_crying,
    MAX(CASE WHEN lo.concept_id = 50107 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS apgar_score_10_min,
    MAX(CASE WHEN lo.concept_id = 50340 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS oxygen_therapy,
    MAX(CASE WHEN lo.concept_id = 50345 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS feeding_support,
    MAX(CASE WHEN lo.concept_id = 50383 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS multiple_birth_type,
    MAX(CASE WHEN lo.concept_id = 50393 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS steroids_given,
    MAX(CASE WHEN lo.concept_id = 52925 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS hiv_status,
    MAX(CASE WHEN lo.concept_id = 56620 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS severe_respiratory_distress,
    MAX(CASE WHEN lo.concept_id = 58873 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS weight_grams,
    MAX(CASE WHEN lo.concept_id = 59219 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS crt_3_or_more_seconds,
    MAX(CASE WHEN lo.concept_id = 157913 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS central_capillary_refill_time,
    MAX(CASE WHEN lo.concept_id = 159054 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS baby_symptomatic_low_blood_sugar,
    MAX(CASE WHEN lo.concept_id = 159055 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS femoral_pulse_palpable,
    MAX(CASE WHEN lo.concept_id = 159056 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS crt_less_than_3_seconds,
    MAX(CASE WHEN lo.concept_id = 159059 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS triage_priority,
    MAX(CASE WHEN lo.concept_id = 159061 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS frequency_of_stooling,
    MAX(CASE WHEN lo.concept_id = 159062 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS wet_nappies_per_day,
    MAX(CASE WHEN lo.concept_id = 55541 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS time_of_delivery,
    MAX(CASE WHEN lo.concept_id = 53328 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS height_cm,
    MAX(CASE WHEN lo.concept_id = 48285 THEN COALESCE(lo.value_numeric, lo.value_text, cn.name) END) AS circumference_cm,
    MAX(CASE WHEN lo.concept_id = 59098 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS cried_at_birth,
    MAX(CASE WHEN lo.concept_id = 56806 THEN COALESCE(cn.name, lo.value_text, CAST(lo.value_numeric AS char)) END) AS newborn_complications
FROM latest_obs lo
LEFT JOIN concept_name cn ON cn.concept_id = lo.value_coded AND cn.voided = 0
WHERE lo.rn = 1
GROUP BY lo.location_id, lo.person_id, lo.visit_date -- , lo.lab_test_key
-- ORDER BY lo.location_id, lo.person_id, lo.visit_date, lo.lab_test_key;
)
, peops as 
(
WITH mahis_persons AS (SELECT DISTINCT o.person_id FROM obs o INNER JOIN encounter e ON e.encounter_id = o.encounter_id AND e.program_id = 39 WHERE e.voided = 0 AND o.voided = 0),
first_visit AS (
    SELECT patient_id, MIN(DATE(encounter_datetime)) AS first_mahis_visit
    FROM encounter WHERE program_id = 39 AND voided = 0 GROUP BY patient_id
)
SELECT
    p.person_id,
    p.gender,
    p.birthdate,
    p.birthdate_estimated,
    fv.first_mahis_visit,
    DATEDIFF(fv.first_mahis_visit, p.birthdate) AS age_days_at_first_mahis_visit,
    p.dead,
    p.death_date,
    p.cause_of_death
FROM person p
INNER JOIN mahis_persons mp ON mp.person_id = p.person_id
LEFT JOIN first_visit fv ON fv.patient_id = p.person_id
WHERE p.voided = 0
ORDER BY p.person_id
),
other_progs as (
WITH mahis_persons AS (
    SELECT DISTINCT o.person_id
    FROM obs o
    INNER JOIN encounter e ON e.encounter_id = o.encounter_id AND e.program_id = 39
    WHERE e.voided = 0 AND o.voided = 0
)
SELECT distinct
    o.person_id person_id_,
    DATE(o.obs_datetime) AS visit_date_,
--     e.program_id,
    MAX(CASE WHEN o.concept_id = 47384 THEN COALESCE(vn.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS lab_order_status,
    MAX(CASE WHEN o.concept_id = 48284 THEN COALESCE(vn.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS apgar_score_at_5_minutes,
    MAX(CASE WHEN o.concept_id = 48285 THEN COALESCE(vn.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS circumference,
    MAX(CASE WHEN o.concept_id = 48303 THEN COALESCE(vn.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS mode_of_delivery,
    MAX(CASE WHEN o.concept_id = 49070 THEN COALESCE(vn.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS protected_at_birth,
    MAX(CASE WHEN o.concept_id = 49085 THEN COALESCE(vn.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS how_many_doses_of_tdv_did_the_mother_receive,
    MAX(CASE WHEN o.concept_id = 50510 THEN COALESCE(vn.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS comment_to_fulfiller,
    MAX(CASE WHEN o.concept_id = 51076 THEN COALESCE(vn.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS reason_for_test,
    MAX(CASE WHEN o.concept_id = 52925 THEN COALESCE(vn.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS hiv_status,
    MAX(CASE WHEN o.concept_id = 53328 THEN COALESCE(vn.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS height,
    MAX(CASE WHEN o.concept_id = 54609 THEN COALESCE(vn.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS person_making_request,
    MAX(CASE WHEN o.concept_id = 55541 THEN COALESCE(vn.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS time_of_delivery,
    MAX(CASE WHEN o.concept_id = 56806 THEN COALESCE(vn.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS newborn_baby_complications,
    MAX(CASE WHEN o.concept_id = 57640 THEN COALESCE(vn.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS test_type,
    MAX(CASE WHEN o.concept_id = 58873 THEN COALESCE(vn.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS weight_grams,
    MAX(CASE WHEN o.concept_id = 59098 THEN COALESCE(vn.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS did_the_baby_cry_at_birth,
    MAX(CASE WHEN o.concept_id = 59662 THEN COALESCE(vn.name, o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) END) AS lab_test_status
FROM obs o
INNER JOIN mahis_persons mp ON mp.person_id = o.person_id
LEFT JOIN encounter e ON e.encounter_id = o.encounter_id
LEFT JOIN concept_name vn ON vn.concept_id = o.value_coded AND vn.voided = 0 AND vn.locale = 'en' AND vn.concept_name_type = 'FULLY_SPECIFIED'
WHERE o.voided = 0
    AND (e.program_id IS NULL OR e.program_id <> 39)
GROUP BY o.person_id, DATE(o.obs_datetime) -- , e.program_id
)
SELECT o.*,    p.gender,
    p.birthdate,
    p.birthdate_estimated,
    p.first_mahis_visit,
    p.age_days_at_first_mahis_visit,
    p.dead,
    p.death_date,
    p.cause_of_death
    -- op.*
from obbs o inner join peops p on o.person_id = p.person_id
-- left join other_progs op on op.person_id_ = o.person_id and o.visit_date = op.visit_date_





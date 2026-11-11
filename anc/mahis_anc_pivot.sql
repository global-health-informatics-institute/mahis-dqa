-- ============================================================================
-- MAHIS ANC PIVOT (ANC PROGRAM, program_id = 12) - one row per person / visit_date
--
-- * Obs come from non-voided encounters of program 12 only (add other programs later if needed)
-- * Child obs keep their OWN concept_id (ANC groups hold real fields, unlike the neonatal answer-as-child pattern)
-- * Previous pregnancy history (group 59249) repeats once per past pregnancy: its children are NOT pivoted as ordinary columns;
--   they appear as the prev_preg_* columns at the end (all pregnancies of the visit joined with '; ' in pregnancy-number order,
--   '-' = not recorded) and as one row per pregnancy in mahis_anc_previous_pregnancies.sql
-- * Multi-select concepts (counselling, medications, ...) are joined with '; '; every other concept keeps its latest value of the day
-- * Coded values decoded to concept names; patient columns added at the end
-- ============================================================================
SET SESSION group_concat_max_len = 1000000;

WITH anc_obs AS (
    SELECT
        o.obs_id, o.person_id, o.location_id, o.concept_id, o.obs_group_id,
        DATE(o.obs_datetime) AS visit_date, o.obs_datetime,
        o.value_coded, o.value_numeric, o.value_text, o.value_datetime
    FROM obs o
    INNER JOIN encounter e ON e.encounter_id = o.encounter_id AND e.program_id = 12 AND e.voided = 0
    LEFT JOIN obs p ON p.obs_id = o.obs_group_id
    WHERE o.voided = 0
        AND (p.obs_id IS NULL OR p.concept_id <> 59249)
        AND o.concept_id IN (
        152, 9763, 29690, 32906, 36870, 36907, 36975, 37381, 37950, 38034,
        38248, 38565, 38611, 38899, 39039, 39510, 47297, 47321, 47384, 47421,
        47456, 47458, 47640, 47724, 47763, 47767, 47772, 47792, 47799, 47800,
        47801, 47802, 47818, 47820, 47858, 47859, 47860, 47862, 47863, 47865,
        47867, 47875, 47905, 47909, 47914, 47915, 47918, 47928, 47930, 47963,
        47979, 47980, 47987, 47988, 48027, 48095, 48113, 48115, 48116, 48119,
        48147, 48199, 48218, 48240, 48266, 48303, 48616, 48636, 48637, 48639,
        48867, 48877, 49126, 49153, 49161, 49341, 49407, 49409, 49413, 49422,
        49459, 49520, 50109, 50247, 50369, 50510, 50560, 50562, 50567, 50569,
        50571, 50586, 50588, 50590, 50592, 50598, 50600, 50611, 50618, 50619,
        50620, 50622, 50625, 50628, 50632, 51076, 51290, 51678, 52051, 52499,
        52777, 52925, 53312, 53316, 53319, 53322, 53325, 53328, 53333, 53337,
        53478, 53510, 53712, 53813, 53818, 53819, 54120, 54410, 54609, 54670,
        55214, 55307, 55373, 55488, 55520, 55537, 55544, 55855, 55875, 56025,
        56399, 56437, 57132, 57157, 57460, 57640, 58426, 58427, 58437, 58438,
        58447, 58448, 58467, 58468, 58469, 58478, 58482, 58483, 58487, 58489,
        58490, 58507, 58509, 58510, 58512, 58514, 58519, 58521, 58528, 58533,
        58534, 58542, 58545, 58551, 58556, 58558, 58561, 58562, 58567, 58570,
        58672, 58755, 58928, 58929, 58930, 58931, 58932, 58933, 58935, 58936,
        58937, 58938, 58939, 58940, 58944, 58946, 58950, 59096, 59103, 59117,
        59141, 59142, 59143, 59180, 59182, 59249, 59291, 59326, 59327, 59328,
        59347, 59348, 59349, 59350, 59351, 59352, 59353, 59354, 59355, 59362,
        59363, 59364, 59381, 59382, 59384, 59385, 59386, 59417, 59427, 59453,
        59468, 59487, 59488, 59489, 59492, 59662, 158992
        )
),

coded_names AS (
    -- one readable name per coded value (English, fully specified first)
    SELECT concept_id, name
    FROM (
        SELECT cn.concept_id, cn.name,
            ROW_NUMBER() OVER (PARTITION BY cn.concept_id
                ORDER BY (cn.locale = 'en') DESC, (cn.concept_name_type = 'FULLY_SPECIFIED') DESC, cn.concept_name_id) AS r
        FROM concept_name cn
        WHERE cn.voided = 0 AND cn.concept_id IN (SELECT DISTINCT value_coded FROM anc_obs WHERE value_coded IS NOT NULL)
    ) x
    WHERE r = 1
),

decoded AS (
    SELECT
        a.*,
        COALESCE(cn.name, a.value_text, CAST(a.value_numeric AS char), CAST(a.value_datetime AS char)) AS val,
        ROW_NUMBER() OVER (
            PARTITION BY a.location_id, a.person_id, a.visit_date, a.concept_id
            ORDER BY a.obs_datetime DESC, a.obs_id DESC
        ) AS rn
    FROM anc_obs a
    LEFT JOIN coded_names cn ON cn.concept_id = a.value_coded
),

anc_pivot AS (
    SELECT
        o.location_id,
        o.person_id,
        o.visit_date,
    MAX(CASE WHEN o.concept_id = 152 AND o.rn = 1 THEN val END) AS sexually_transmitted_infection,
    MAX(CASE WHEN o.concept_id = 9763 AND o.rn = 1 THEN o.value_text END) AS dysmenorrhoea,
    MAX(CASE WHEN o.concept_id = 29690 AND o.rn = 1 THEN o.value_text END) AS folic_acid,
    MAX(CASE WHEN o.concept_id = 32906 AND o.rn = 1 THEN o.value_text END) AS albendazole,
    MAX(CASE WHEN o.concept_id = 36870 AND o.rn = 1 THEN val END) AS hepatitis_b,
    MAX(CASE WHEN o.concept_id = 36907 AND o.rn = 1 THEN o.value_text END) AS sp,
    MAX(CASE WHEN o.concept_id = 36975 AND o.rn = 1 THEN val END) AS condoms,
    MAX(CASE WHEN o.concept_id = 37381 AND o.rn = 1 THEN val END) AS gait,
    MAX(CASE WHEN o.concept_id = 37950 AND o.rn = 1 THEN o.value_numeric END) AS parity,
    MAX(CASE WHEN o.concept_id = 38034 AND o.rn = 1 THEN val END) AS respiratory_exam_findings,
    MAX(CASE WHEN o.concept_id = 38248 AND o.rn = 1 THEN o.value_numeric END) AS muac,
    MAX(CASE WHEN o.concept_id = 38565 AND o.rn = 1 THEN val END) AS drug_end_date,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 38611 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS contraceptive_use,
    MAX(CASE WHEN o.concept_id = 38899 AND o.rn = 1 THEN o.value_numeric END) AS gravida,
    MAX(CASE WHEN o.concept_id = 39039 AND o.rn = 1 THEN o.value_text END) AS hiv_test_date,
    MAX(CASE WHEN o.concept_id = 39510 AND o.rn = 1 THEN val END) AS side_effects,
    MAX(CASE WHEN o.concept_id = 47297 AND o.rn = 1 THEN val END) AS ipv_status,
    MAX(CASE WHEN o.concept_id = 47321 AND o.rn = 1 THEN o.value_text END) AS random_blood_sugar,
    MAX(CASE WHEN o.concept_id = 47384 AND o.rn = 1 THEN o.value_text END) AS lab_order_status,
    MAX(CASE WHEN o.concept_id = 47421 AND o.rn = 1 THEN val END) AS tb_screening_result,
    MAX(CASE WHEN o.concept_id = 47456 AND o.rn = 1 THEN o.value_text END) AS past_surgeries,
    MAX(CASE WHEN o.concept_id = 47458 AND o.rn = 1 THEN val END) AS genital_examination_normal,
    MAX(CASE WHEN o.concept_id = 47640 AND o.rn = 1 THEN val END) AS symmetrical,
    MAX(CASE WHEN o.concept_id = 47724 AND o.rn = 1 THEN val END) AS vulva_inspection_abnormalities,
    MAX(CASE WHEN o.concept_id = 47763 AND o.rn = 1 THEN o.value_text END) AS gestation_age_to_be_used,
    MAX(CASE WHEN o.concept_id = 47767 AND o.rn = 1 THEN o.value_text END) AS the_woman_received_tetanus_doses_for_immunization,
    MAX(CASE WHEN o.concept_id = 47772 AND o.rn = 1 THEN o.value_text END) AS reason_tetanus_toxoid_tt_was_not_conducted,
    MAX(CASE WHEN o.concept_id = 47792 AND o.rn = 1 THEN o.value_text END) AS daily_caffeine_use,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 47799 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS which_medications_is_the_woman_currently_prescribed,
    MAX(CASE WHEN o.concept_id = 47800 AND o.rn = 1 THEN o.value_numeric END) AS abortions_miscarriages,
    MAX(CASE WHEN o.concept_id = 47801 AND o.rn = 1 THEN o.value_numeric END) AS stillbirths,
    MAX(CASE WHEN o.concept_id = 47802 AND o.rn = 1 THEN val END) AS live_births,
    MAX(CASE WHEN o.concept_id = 47818 AND o.rn = 1 THEN val END) AS pregnancy_confirmed,
    MAX(CASE WHEN o.concept_id = 47820 AND o.rn = 1 THEN val END) AS pregnancy_planned,
    MAX(CASE WHEN o.concept_id = 47858 AND o.rn = 1 THEN o.value_text END) AS iron_prescription,
    MAX(CASE WHEN o.concept_id = 47859 AND o.rn = 1 THEN o.value_numeric END) AS iron_amount,
    MAX(CASE WHEN o.concept_id = 47860 AND o.rn = 1 THEN o.value_text END) AS type_of_iron_supplement_dosage,
    MAX(CASE WHEN o.concept_id = 47862 AND o.rn = 1 THEN o.value_numeric END) AS amount_of_folic_acid,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 47863 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS iron_and_folic_acid_not_prescribed,
    MAX(CASE WHEN o.concept_id = 47865 AND o.rn = 1 THEN o.value_text END) AS vitamin_a_prescription,
    MAX(CASE WHEN o.concept_id = 47867 AND o.rn = 1 THEN o.value_text END) AS vitamin_a_not_prescribed,
    MAX(CASE WHEN o.concept_id = 47875 AND o.rn = 1 THEN o.value_text END) AS aspirin_provided,
    MAX(CASE WHEN o.concept_id = 47905 AND o.rn = 1 THEN val END) AS intimateinfo,
    MAX(CASE WHEN o.concept_id = 47909 AND o.rn = 1 THEN val END) AS additional_care_provided,
    MAX(CASE WHEN o.concept_id = 47914 AND o.rn = 1 THEN val END) AS safety_assessment,
    MAX(CASE WHEN o.concept_id = 47915 AND o.rn = 1 THEN val END) AS physical_violence,
    MAX(CASE WHEN o.concept_id = 47918 AND o.rn = 1 THEN val END) AS violently_and_constantly_jealous,
    MAX(CASE WHEN o.concept_id = 47928 AND o.rn = 1 THEN val END) AS antihelminthic_treatment,
    MAX(CASE WHEN o.concept_id = 47930 AND o.rn = 1 THEN val END) AS no_preventative_treatment_provided,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 47963 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS counselling_on_diet,
    MAX(CASE WHEN o.concept_id = 47979 AND o.rn = 1 THEN o.value_numeric END) AS livebirths,
    MAX(CASE WHEN o.concept_id = 47980 AND o.rn = 1 THEN o.value_text END) AS lmnp_date,
    MAX(CASE WHEN o.concept_id = 47987 AND o.rn = 1 THEN o.value_text END) AS tt1date,
    MAX(CASE WHEN o.concept_id = 47988 AND o.rn = 1 THEN o.value_text END) AS tt2date,
    MAX(CASE WHEN o.concept_id = 48027 AND o.rn = 1 THEN val END) AS perineal_tear,
    MAX(CASE WHEN o.concept_id = 48095 AND o.rn = 1 THEN val END) AS evidence_of_amniotic_fluid,
    MAX(CASE WHEN o.concept_id = 48113 AND o.rn = 1 THEN o.value_numeric END) AS symphysis_fundal_height,
    MAX(CASE WHEN o.concept_id = 48115 AND o.rn = 1 THEN val END) AS number_of_fetuses_known,
    MAX(CASE WHEN o.concept_id = 48116 AND o.rn = 1 THEN o.value_numeric END) AS number_of_fetuses,
    MAX(CASE WHEN o.concept_id = 48119 AND o.rn = 1 THEN o.value_numeric END) AS repeated_fetal_rate,
    MAX(CASE WHEN o.concept_id = 48147 AND o.rn = 1 THEN val END) AS ultrasound_scan_status,
    MAX(CASE WHEN o.concept_id = 48199 AND o.rn = 1 THEN val END) AS tb_screening_status,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 48218 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS medical_follow_up,
    MAX(CASE WHEN o.concept_id = 48240 AND o.rn = 1 THEN val END) AS persistent_symptom,
    MAX(CASE WHEN o.concept_id = 48266 AND o.rn = 1 THEN o.value_text END) AS misuse_of_drugs,
    MAX(CASE WHEN o.concept_id = 48303 AND o.rn = 1 THEN val END) AS mode_of_delivery,
    MAX(CASE WHEN o.concept_id = 48616 AND o.rn = 1 THEN val END) AS past_pregnancies_complications,
    MAX(CASE WHEN o.concept_id = 48636 AND o.rn = 1 THEN val END) AS best_verbal_response,
    MAX(CASE WHEN o.concept_id = 48637 AND o.rn = 1 THEN val END) AS eye_opening_response,
    MAX(CASE WHEN o.concept_id = 48639 AND o.rn = 1 THEN val END) AS best_motor_response,
    MAX(CASE WHEN o.concept_id = 48867 AND o.rn = 1 THEN val END) AS abnormal_bizzarre_behaviour,
    MAX(CASE WHEN o.concept_id = 48877 AND o.rn = 1 THEN o.value_text END) AS number_of_tetanus_doses,
    MAX(CASE WHEN o.concept_id = 49126 AND o.rn = 1 THEN val END) AS anc_pregnancy_outcome,
    MAX(CASE WHEN o.concept_id = 49153 AND o.rn = 1 THEN o.value_text END) AS pregnancy_outcome_notes,
    MAX(CASE WHEN o.concept_id = 49161 AND o.rn = 1 THEN val END) AS preterm_birth,
    MAX(CASE WHEN o.concept_id = 49341 AND o.rn = 1 THEN o.value_numeric END) AS age_at_menarche,
    MAX(CASE WHEN o.concept_id = 49407 AND o.rn = 1 THEN val END) AS reason_behaviour_counselling_not_done,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 49409 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS behaviour_counselling,
    MAX(CASE WHEN o.concept_id = 49413 AND o.rn = 1 THEN val END) AS reason_any_diet_counselling_was_not_done,
    MAX(CASE WHEN o.concept_id = 49422 AND o.rn = 1 THEN val END) AS reason_clinical_counselling_not_done,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 49459 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS clinical_counselling,
    MAX(CASE WHEN o.concept_id = 49520 AND o.rn = 1 THEN val END) AS danger_signs_present,
    MAX(CASE WHEN o.concept_id = 50109 AND o.rn = 1 THEN o.value_text END) AS gestation_in_weeks,
    MAX(CASE WHEN o.concept_id = 50247 AND o.rn = 1 THEN o.value_text END) AS vaginal_examination,
    MAX(CASE WHEN o.concept_id = 50369 AND o.rn = 1 THEN o.value_text END) AS insecticide_treated_net_given,
    MAX(CASE WHEN o.concept_id = 50510 AND o.rn = 1 THEN val END) AS comment_to_fulfiller,
    MAX(CASE WHEN o.concept_id = 50560 AND o.rn = 1 THEN o.value_text END) AS regularity_of_menstrual_flow,
    MAX(CASE WHEN o.concept_id = 50562 AND o.rn = 1 THEN o.value_text END) AS amount_of_menstrual_flow,
    MAX(CASE WHEN o.concept_id = 50567 AND o.rn = 1 THEN val END) AS gynaecological_surgery,
    MAX(CASE WHEN o.concept_id = 50569 AND o.rn = 1 THEN o.value_text END) AS tdv_at_gestation_age,
    MAX(CASE WHEN o.concept_id = 50571 AND o.rn = 1 THEN o.value_text END) AS gestation_age_at_last_live_birth,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 50586 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS reason_aspirin_not_prescribed,
    MAX(CASE WHEN o.concept_id = 50588 AND o.rn = 1 THEN o.value_numeric END) AS number_of_sp_tablets_given,
    MAX(CASE WHEN o.concept_id = 50590 AND o.rn = 1 THEN o.value_text END) AS folic_acid_not_prescribed,
    MAX(CASE WHEN o.concept_id = 50592 AND o.rn = 1 THEN o.value_numeric END) AS vitamin_amount,
    MAX(CASE WHEN o.concept_id = 50598 AND o.rn = 1 THEN o.value_text END) AS hepatitis_b_vaccine_given,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 50600 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS reason_hepatitis_b_vaccination_not_conducted,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 50611 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS preventive_counselling,
    MAX(CASE WHEN o.concept_id = 50618 AND o.rn = 1 THEN o.value_datetime END) AS ultrasound_scan_date,
    MAX(CASE WHEN o.concept_id = 50619 AND o.rn = 1 THEN val END) AS reason_ultrasound_not_done,
    MAX(CASE WHEN o.concept_id = 50620 AND o.rn = 1 THEN val END) AS location_of_the_placenta_detected_during_ultrasound,
    MAX(CASE WHEN o.concept_id = 50622 AND o.rn = 1 THEN val END) AS urine_test_conducted,
    MAX(CASE WHEN o.concept_id = 50625 AND o.rn = 1 THEN val END) AS reason_urine_test_not_done,
    MAX(CASE WHEN o.concept_id = 50628 AND o.rn = 1 THEN val END) AS reason_tb_screening_not_done,
    MAX(CASE WHEN o.concept_id = 50632 AND o.rn = 1 THEN val END) AS urine_test_status,
    MAX(CASE WHEN o.concept_id = 51076 AND o.rn = 1 THEN val END) AS reason_for_test,
    MAX(CASE WHEN o.concept_id = 51290 AND o.rn = 1 THEN o.value_text END) AS arv_drugs_received,
    MAX(CASE WHEN o.concept_id = 51678 AND o.rn = 1 THEN o.value_numeric END) AS amount_dispensed,
    MAX(CASE WHEN o.concept_id = 52051 AND o.rn = 1 THEN val END) AS diagnosis,
    MAX(CASE WHEN o.concept_id = 52499 AND o.rn = 1 THEN val END) AS hiv_test,
    MAX(CASE WHEN o.concept_id = 52777 AND o.rn = 1 THEN o.value_text END) AS co_trimoxazole_given_to_patient,
    MAX(CASE WHEN o.concept_id = 52925 AND o.rn = 1 THEN o.value_text END) AS hiv_status,
    MAX(CASE WHEN o.concept_id = 53312 AND o.rn = 1 THEN o.value_numeric END) AS systolic_blood_pressure,
    MAX(CASE WHEN o.concept_id = 53316 AND o.rn = 1 THEN o.value_numeric END) AS diastolic_blood_pressure,
    MAX(CASE WHEN o.concept_id = 53319 AND o.rn = 1 THEN val END) AS pulse,
    MAX(CASE WHEN o.concept_id = 53322 AND o.rn = 1 THEN val END) AS temperature_c,
    MAX(CASE WHEN o.concept_id = 53325 AND o.rn = 1 THEN o.value_numeric END) AS weight_kg,
    MAX(CASE WHEN o.concept_id = 53328 AND o.rn = 1 THEN val END) AS height,
    MAX(CASE WHEN o.concept_id = 53333 AND o.rn = 1 THEN val END) AS sao2,
    MAX(CASE WHEN o.concept_id = 53337 AND o.rn = 1 THEN o.value_datetime END) AS appointment_date,
    MAX(CASE WHEN o.concept_id = 53478 AND o.rn = 1 THEN val END) AS respiratory_rate,
    MAX(CASE WHEN o.concept_id = 53510 AND o.rn = 1 THEN val END) AS pregnancy_status,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 53712 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS psychosocial_counseling,
    MAX(CASE WHEN o.concept_id = 53813 AND o.rn = 1 THEN val END) AS estimated_date_of_delivery,
    MAX(CASE WHEN o.concept_id = 53818 AND o.rn = 1 THEN o.value_text END) AS date_of_delivery,
    MAX(CASE WHEN o.concept_id = 53819 AND o.rn = 1 THEN o.value_text END) AS delivery_day,
    MAX(CASE WHEN o.concept_id = 54120 AND o.rn = 1 THEN o.value_text END) AS date,
    MAX(CASE WHEN o.concept_id = 54410 AND o.rn = 1 THEN o.value_text END) AS reason_for_visit,
    MAX(CASE WHEN o.concept_id = 54609 AND o.rn = 1 THEN o.value_text END) AS person_making_request,
    MAX(CASE WHEN o.concept_id = 54670 AND o.rn = 1 THEN o.value_text END) AS other,
    MAX(CASE WHEN o.concept_id = 55214 AND o.rn = 1 THEN o.value_text END) AS art_number,
    MAX(CASE WHEN o.concept_id = 55307 AND o.rn = 1 THEN val END) AS multiple_gestation,
    MAX(CASE WHEN o.concept_id = 55373 AND o.rn = 1 THEN o.value_text END) AS chronic_conditions,
    MAX(CASE WHEN o.concept_id = 55488 AND o.rn = 1 THEN val END) AS lab_test_result,
    MAX(CASE WHEN o.concept_id = 55520 AND o.rn = 1 THEN o.value_text END) AS gestation_weeks,
    MAX(CASE WHEN o.concept_id = 55537 AND o.rn = 1 THEN o.value_numeric END) AS number_of_babies,
    MAX(CASE WHEN o.concept_id = 55544 AND o.rn = 1 THEN o.value_text END) AS estimated_date,
    MAX(CASE WHEN o.concept_id = 55855 AND o.rn = 1 THEN o.value_numeric END) AS fetal_heart_rate,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 55875 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS refer_to_htc,
    MAX(CASE WHEN o.concept_id = 56025 AND o.rn = 1 THEN val END) AS syphilis_test_result,
    MAX(CASE WHEN o.concept_id = 56399 AND o.rn = 1 THEN o.value_text END) AS size,
    MAX(CASE WHEN o.concept_id = 56437 AND o.rn = 1 THEN val END) AS place_of_delivery,
    MAX(CASE WHEN o.concept_id = 57132 AND o.rn = 1 THEN val END) AS malaria_test,
    MAX(CASE WHEN o.concept_id = 57157 AND o.rn = 1 THEN o.value_text END) AS blood_pressure,
    MAX(CASE WHEN o.concept_id = 57460 AND o.rn = 1 THEN o.value_text END) AS allergies,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 57640 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS test_type,
    MAX(CASE WHEN o.concept_id = 58426 AND o.rn = 1 THEN val END) AS abnormal_vaginal_discharge_avd,
    MAX(CASE WHEN o.concept_id = 58427 AND o.rn = 1 THEN o.value_numeric END) AS abortions,
    MAX(CASE WHEN o.concept_id = 58437 AND o.rn = 1 THEN val END) AS any_deformities_present,
    MAX(CASE WHEN o.concept_id = 58438 AND o.rn = 1 THEN val END) AS any_other_clinical_enquiry_done,
    MAX(CASE WHEN o.concept_id = 58447 AND o.rn = 1 THEN o.value_text END) AS check_art_adherence,
    MAX(CASE WHEN o.concept_id = 58448 AND o.rn = 1 THEN o.value_text END) AS check_recent_viral_results,
    MAX(CASE WHEN o.concept_id = 58467 AND o.rn = 1 THEN val END) AS fetal_heart_rate_regularity,
    MAX(CASE WHEN o.concept_id = 58468 AND o.rn = 1 THEN val END) AS fetal_heartbeat_present,
    MAX(CASE WHEN o.concept_id = 58469 AND o.rn = 1 THEN o.value_numeric END) AS fetal_rate,
    MAX(CASE WHEN o.concept_id = 58478 AND o.rn = 1 THEN val END) AS has_the_woman_been_subjected_to_any_form_of_violence,
    MAX(CASE WHEN o.concept_id = 58482 AND o.rn = 1 THEN o.value_text END) AS is_client_on_art,
    MAX(CASE WHEN o.concept_id = 58483 AND o.rn = 1 THEN val END) AS is_oedema_present,
    MAX(CASE WHEN o.concept_id = 58487 AND o.rn = 1 THEN val END) AS kempt,
    MAX(CASE WHEN o.concept_id = 58489 AND o.rn = 1 THEN o.value_numeric END) AS length_of_menstrual_flow,
    MAX(CASE WHEN o.concept_id = 58490 AND o.rn = 1 THEN val END) AS linear_nigra,
    MAX(CASE WHEN o.concept_id = 58507 AND o.rn = 1 THEN o.value_numeric END) AS number_of_children_who_are_alive,
    MAX(CASE WHEN o.concept_id = 58509 AND o.rn = 1 THEN val END) AS number_of_previous_anc_contacts,
    MAX(CASE WHEN o.concept_id = 58510 AND o.rn = 1 THEN val END) AS nutritional_status,
    MAX(CASE WHEN o.concept_id = 58512 AND o.rn = 1 THEN o.value_text END) AS other_allergy_notes,
    MAX(CASE WHEN o.concept_id = 58514 AND o.rn = 1 THEN val END) AS other_diagnosis,
    MAX(CASE WHEN o.concept_id = 58519 AND o.rn = 1 THEN o.value_text END) AS other_surgery_notes,
    MAX(CASE WHEN o.concept_id = 58521 AND o.rn = 1 THEN val END) AS past_stis,
    MAX(CASE WHEN o.concept_id = 58528 AND o.rn = 1 THEN val END) AS previous_anc_visit,
    MAX(CASE WHEN o.concept_id = 58533 AND o.rn = 1 THEN val END) AS reason_physiological_counselling_not_done,
    MAX(CASE WHEN o.concept_id = 58534 AND o.rn = 1 THEN val END) AS reason_preventive_counselling_not_done,
    MAX(CASE WHEN o.concept_id = 58542 AND o.rn = 1 THEN val END) AS select_fetal_presentation,
    MAX(CASE WHEN o.concept_id = 58545 AND o.rn = 1 THEN val END) AS shape,
    MAX(CASE WHEN o.concept_id = 58551 AND o.rn = 1 THEN o.value_text END) AS specify_the_fetal_presentation,
    MAX(CASE WHEN o.concept_id = 58556 AND o.rn = 1 THEN val END) AS striae_gravidarum,
    MAX(CASE WHEN o.concept_id = 58558 AND o.rn = 1 THEN val END) AS syphilis_serologically_diagnosed,
    MAX(CASE WHEN o.concept_id = 58561 AND o.rn = 1 THEN o.value_datetime END) AS tb_screening_date,
    MAX(CASE WHEN o.concept_id = 58562 AND o.rn = 1 THEN val END) AS traditional_marks,
    MAX(CASE WHEN o.concept_id = 58567 AND o.rn = 1 THEN val END) AS varicose_veins_present,
    MAX(CASE WHEN o.concept_id = 58570 AND o.rn = 1 THEN o.value_text END) AS when_did_she_start_art,
    MAX(CASE WHEN o.concept_id = 58672 AND o.rn = 1 THEN val END) AS haemoglobin_status,
    MAX(CASE WHEN o.concept_id = 58755 AND o.rn = 1 THEN val END) AS outcome_of_baby_at_birth,
    MAX(CASE WHEN o.concept_id = 58928 AND o.rn = 1 THEN val END) AS date_of_anc_visit_1,
    MAX(CASE WHEN o.concept_id = 58929 AND o.rn = 1 THEN val END) AS date_of_anc_visit_2,
    MAX(CASE WHEN o.concept_id = 58930 AND o.rn = 1 THEN val END) AS date_of_anc_visit_3,
    MAX(CASE WHEN o.concept_id = 58931 AND o.rn = 1 THEN val END) AS date_of_anc_visit_4,
    MAX(CASE WHEN o.concept_id = 58932 AND o.rn = 1 THEN val END) AS date_of_anc_visit_5,
    MAX(CASE WHEN o.concept_id = 58933 AND o.rn = 1 THEN val END) AS date_of_anc_visit_6,
    MAX(CASE WHEN o.concept_id = 58935 AND o.rn = 1 THEN o.value_text END) AS facility_from_which_the_client_received_anc_care_1,
    MAX(CASE WHEN o.concept_id = 58936 AND o.rn = 1 THEN o.value_text END) AS facility_from_which_the_client_received_anc_care_2,
    MAX(CASE WHEN o.concept_id = 58937 AND o.rn = 1 THEN o.value_text END) AS facility_from_which_the_client_received_anc_care_3,
    MAX(CASE WHEN o.concept_id = 58938 AND o.rn = 1 THEN o.value_text END) AS facility_from_which_the_client_received_anc_care_4,
    MAX(CASE WHEN o.concept_id = 58939 AND o.rn = 1 THEN o.value_text END) AS facility_from_which_the_client_received_anc_care_5,
    MAX(CASE WHEN o.concept_id = 58940 AND o.rn = 1 THEN o.value_text END) AS facility_from_which_the_client_received_anc_care_6,
    MAX(CASE WHEN o.concept_id = 58944 AND o.rn = 1 THEN o.value_text END) AS mode_of_delivery_details,
    MAX(CASE WHEN o.concept_id = 58946 AND o.rn = 1 THEN o.value_text END) AS other_gynaecological_information,
    MAX(CASE WHEN o.concept_id = 58950 AND o.rn = 1 THEN o.value_text END) AS fetus_number,
    MAX(CASE WHEN o.concept_id = 59096 AND o.rn = 1 THEN val END) AS cough_present,
    MAX(CASE WHEN o.concept_id = 59103 AND o.rn = 1 THEN val END) AS fetal_and_neonatal_complications,
    MAX(CASE WHEN o.concept_id = 59117 AND o.rn = 1 THEN o.value_text END) AS hepatitis_b_vaccine_given_59117,
    MAX(CASE WHEN o.concept_id = 59141 AND o.rn = 1 THEN o.value_numeric END) AS other_medication_dosage,
    MAX(CASE WHEN o.concept_id = 59142 AND o.rn = 1 THEN o.value_text END) AS other_medication_duration,
    MAX(CASE WHEN o.concept_id = 59143 AND o.rn = 1 THEN o.value_text END) AS other_medication_frequency,
    MAX(CASE WHEN o.concept_id = 59180 AND o.rn = 1 THEN o.value_text END) AS viral_load_results,
    MAX(CASE WHEN o.concept_id = 59182 AND o.rn = 1 THEN val END) AS assisted_vaginal_delivery,
    MAX(CASE WHEN o.concept_id = 59249 AND o.rn = 1 THEN o.value_text END) AS previous_pregnancy_history,
    MAX(CASE WHEN o.concept_id = 59291 AND o.rn = 1 THEN val END) AS assisted_delivery_type,
    MAX(CASE WHEN o.concept_id = 59326 AND o.rn = 1 THEN o.value_numeric END) AS dosage_iron,
    MAX(CASE WHEN o.concept_id = 59327 AND o.rn = 1 THEN o.value_text END) AS frequency_iron,
    MAX(CASE WHEN o.concept_id = 59328 AND o.rn = 1 THEN o.value_text END) AS duration_iron,
    MAX(CASE WHEN o.concept_id = 59347 AND o.rn = 1 THEN o.value_numeric END) AS dosage_anti_malarial,
    MAX(CASE WHEN o.concept_id = 59348 AND o.rn = 1 THEN o.value_text END) AS frequency_anti_malarial,
    MAX(CASE WHEN o.concept_id = 59349 AND o.rn = 1 THEN o.value_text END) AS duration_anti_malarial,
    MAX(CASE WHEN o.concept_id = 59350 AND o.rn = 1 THEN o.value_numeric END) AS dosage_arvs,
    MAX(CASE WHEN o.concept_id = 59351 AND o.rn = 1 THEN o.value_text END) AS frequency_arvs,
    MAX(CASE WHEN o.concept_id = 59352 AND o.rn = 1 THEN o.value_text END) AS duration_arvs,
    MAX(CASE WHEN o.concept_id = 59353 AND o.rn = 1 THEN o.value_numeric END) AS dosage_antivirals,
    MAX(CASE WHEN o.concept_id = 59354 AND o.rn = 1 THEN o.value_text END) AS frequency_antivirals,
    MAX(CASE WHEN o.concept_id = 59355 AND o.rn = 1 THEN o.value_text END) AS duration_antivirals,
    MAX(CASE WHEN o.concept_id = 59362 AND o.rn = 1 THEN o.value_numeric END) AS dosage_folic_acid,
    MAX(CASE WHEN o.concept_id = 59363 AND o.rn = 1 THEN o.value_text END) AS frequency_folic_acid,
    MAX(CASE WHEN o.concept_id = 59364 AND o.rn = 1 THEN o.value_text END) AS duration_folic_acid,
    MAX(CASE WHEN o.concept_id = 59381 AND o.rn = 1 THEN val END) AS pregnancy_number,
    MAX(CASE WHEN o.concept_id = 59382 AND o.rn = 1 THEN val END) AS delivery_date_year,
    MAX(CASE WHEN o.concept_id = 59384 AND o.rn = 1 THEN val END) AS baby_birthweight,
    MAX(CASE WHEN o.concept_id = 59385 AND o.rn = 1 THEN val END) AS labour_duration_hours,
    MAX(CASE WHEN o.concept_id = 59386 AND o.rn = 1 THEN o.value_text END) AS gestational_age_at_birth,
    MAX(CASE WHEN o.concept_id = 59417 AND o.rn = 1 THEN o.value_text END) AS hiv_treatment_status,
    MAX(CASE WHEN o.concept_id = 59427 AND o.rn = 1 THEN o.value_text END) AS abnominal_scar,
    MAX(CASE WHEN o.concept_id = 59453 AND o.rn = 1 THEN o.value_text END) AS congenital_abnormalities,
    MAX(CASE WHEN o.concept_id = 59468 AND o.rn = 1 THEN o.value_text END) AS medication_name_iron,
    MAX(CASE WHEN o.concept_id = 59487 AND o.rn = 1 THEN o.value_text END) AS medication_name_anti_malarial,
    MAX(CASE WHEN o.concept_id = 59488 AND o.rn = 1 THEN o.value_text END) AS medication_name_arvs,
    MAX(CASE WHEN o.concept_id = 59489 AND o.rn = 1 THEN o.value_text END) AS medication_name_antivirals,
    MAX(CASE WHEN o.concept_id = 59492 AND o.rn = 1 THEN o.value_text END) AS medication_name_folic_acid,
    MAX(CASE WHEN o.concept_id = 59662 AND o.rn = 1 THEN o.value_text END) AS lab_test_status,
    MAX(CASE WHEN o.concept_id = 158992 AND o.rn = 1 THEN val END) AS genital_examination_done
    FROM decoded o
    GROUP BY o.location_id, o.person_id, o.visit_date
),

patients AS (
    SELECT
        p.person_id,
        p.gender,
        p.birthdate,
        p.birthdate_estimated,
        fv.first_anc_visit,
        TIMESTAMPDIFF(YEAR, p.birthdate, fv.first_anc_visit) AS age_years_at_first_anc_visit,
        p.dead,
        p.death_date,
        arv.arv_number_identifier
    FROM person p
    LEFT JOIN (
        -- ART/ARV clinic numbers are stored as patient identifiers (types 4 'Arv number', 30 'Legacy arv number')
        SELECT i.patient_id AS person_id, GROUP_CONCAT(DISTINCT i.identifier ORDER BY i.identifier SEPARATOR '; ') AS arv_number_identifier
        FROM patient_identifier i
        WHERE i.voided = 0 AND i.identifier_type IN (4, 30)
        GROUP BY i.patient_id
    ) arv ON arv.person_id = p.person_id
    INNER JOIN (
        SELECT e.patient_id, MIN(DATE(e.encounter_datetime)) AS first_anc_visit
        FROM encounter e WHERE e.program_id = 12 AND e.voided = 0 GROUP BY e.patient_id
    ) fv ON fv.patient_id = p.person_id
    WHERE p.voided = 0
),

pp_parents AS (
    -- one row per previous-pregnancy group obs (repeats once per past pregnancy, and again when re-saved at a later visit)
    SELECT p.obs_id AS group_obs_id, p.person_id, p.location_id, p.encounter_id,
        DATE(p.obs_datetime) AS visit_date, p.obs_datetime, p.value_text AS previous_pregnancy_label
    FROM obs p
    INNER JOIN encounter e ON e.encounter_id = p.encounter_id AND e.program_id = 12 AND e.voided = 0
    WHERE p.voided = 0 AND p.concept_id = 59249
),

pp_children AS (
    SELECT c.obs_id, c.obs_group_id, c.concept_id, c.value_coded, c.value_numeric, c.value_text, c.value_datetime
    FROM obs c
    INNER JOIN pp_parents g ON g.group_obs_id = c.obs_group_id
    WHERE c.voided = 0
),

pp_names AS (
    SELECT concept_id, name
    FROM (
        SELECT cn.concept_id, cn.name,
            ROW_NUMBER() OVER (PARTITION BY cn.concept_id
                ORDER BY (cn.locale = 'en') DESC, (cn.concept_name_type = 'FULLY_SPECIFIED') DESC, cn.concept_name_id) AS r
        FROM concept_name cn
        WHERE cn.voided = 0 AND cn.concept_id IN (SELECT DISTINCT value_coded FROM pp_children WHERE value_coded IS NOT NULL)
    ) x
    WHERE r = 1
),

pp_groups AS (
    -- one row per previous-pregnancy group with ALL its child fields
    SELECT
        g.group_obs_id, g.person_id, g.location_id, g.encounter_id, g.visit_date, g.previous_pregnancy_label,
        MAX(CASE WHEN c.concept_id = 59381 THEN c.value_numeric END) AS pregnancy_number,
        MAX(CASE WHEN c.concept_id = 48303 THEN COALESCE(n.name, c.value_text, CAST(c.value_numeric AS char), CAST(c.value_datetime AS char)) END) AS mode_of_delivery,
        MAX(CASE WHEN c.concept_id = 59182 THEN COALESCE(n.name, c.value_text, CAST(c.value_numeric AS char), CAST(c.value_datetime AS char)) END) AS assisted_vaginal_delivery,
        MAX(CASE WHEN c.concept_id = 59291 THEN COALESCE(n.name, c.value_text, CAST(c.value_numeric AS char), CAST(c.value_datetime AS char)) END) AS assisted_delivery_type,
        MAX(CASE WHEN c.concept_id = 58944 THEN COALESCE(n.name, c.value_text, CAST(c.value_numeric AS char), CAST(c.value_datetime AS char)) END) AS mode_of_delivery_details,
        MAX(CASE WHEN c.concept_id = 55307 THEN COALESCE(n.name, c.value_text, CAST(c.value_numeric AS char), CAST(c.value_datetime AS char)) END) AS multiple_gestation,
        MAX(CASE WHEN c.concept_id = 55537 THEN c.value_numeric END) AS number_of_babies,
        MAX(CASE WHEN c.concept_id = 59382 THEN c.value_datetime END) AS delivery_date_year,
        MAX(CASE WHEN c.concept_id = 58755 THEN COALESCE(n.name, c.value_text, CAST(c.value_numeric AS char), CAST(c.value_datetime AS char)) END) AS outcome_of_baby_at_birth,
        MAX(CASE WHEN c.concept_id = 59384 THEN c.value_numeric END) AS baby_birthweight,
        MAX(CASE WHEN c.concept_id = 59385 THEN c.value_numeric END) AS labour_duration_hours,
        MAX(CASE WHEN c.concept_id = 59386 THEN COALESCE(n.name, c.value_text, CAST(c.value_numeric AS char), CAST(c.value_datetime AS char)) END) AS gestational_age_at_birth
    FROM pp_parents g
    LEFT JOIN pp_children c ON c.obs_group_id = g.group_obs_id
    LEFT JOIN pp_names n ON n.concept_id = c.value_coded
    GROUP BY g.group_obs_id, g.person_id, g.location_id, g.encounter_id, g.visit_date, g.previous_pregnancy_label
),

pp_summary AS (
    -- per visit: every previous pregnancy's value, in pregnancy-number order, '-' = not recorded; same position = same pregnancy across columns
    SELECT location_id, person_id, visit_date,
        COUNT(*) AS number_of_previous_pregnancy_groups,
        COUNT(DISTINCT pregnancy_number) AS number_of_distinct_previous_pregnancies,
        MAX(delivery_date_year) AS latest_previous_delivery_date,
        GROUP_CONCAT(IFNULL(CAST(pregnancy_number AS char), '-') ORDER BY pregnancy_number, group_obs_id SEPARATOR '; ') AS prev_preg_pregnancy_number,
        GROUP_CONCAT(IFNULL(CAST(mode_of_delivery AS char), '-') ORDER BY pregnancy_number, group_obs_id SEPARATOR '; ') AS prev_preg_mode_of_delivery,
        GROUP_CONCAT(IFNULL(CAST(assisted_vaginal_delivery AS char), '-') ORDER BY pregnancy_number, group_obs_id SEPARATOR '; ') AS prev_preg_assisted_vaginal_delivery,
        GROUP_CONCAT(IFNULL(CAST(assisted_delivery_type AS char), '-') ORDER BY pregnancy_number, group_obs_id SEPARATOR '; ') AS prev_preg_assisted_delivery_type,
        GROUP_CONCAT(IFNULL(CAST(mode_of_delivery_details AS char), '-') ORDER BY pregnancy_number, group_obs_id SEPARATOR '; ') AS prev_preg_mode_of_delivery_details,
        GROUP_CONCAT(IFNULL(CAST(multiple_gestation AS char), '-') ORDER BY pregnancy_number, group_obs_id SEPARATOR '; ') AS prev_preg_multiple_gestation,
        GROUP_CONCAT(IFNULL(CAST(number_of_babies AS char), '-') ORDER BY pregnancy_number, group_obs_id SEPARATOR '; ') AS prev_preg_number_of_babies,
        GROUP_CONCAT(IFNULL(CAST(delivery_date_year AS char), '-') ORDER BY pregnancy_number, group_obs_id SEPARATOR '; ') AS prev_preg_delivery_date_year,
        GROUP_CONCAT(IFNULL(CAST(outcome_of_baby_at_birth AS char), '-') ORDER BY pregnancy_number, group_obs_id SEPARATOR '; ') AS prev_preg_outcome_of_baby_at_birth,
        GROUP_CONCAT(IFNULL(CAST(baby_birthweight AS char), '-') ORDER BY pregnancy_number, group_obs_id SEPARATOR '; ') AS prev_preg_baby_birthweight,
        GROUP_CONCAT(IFNULL(CAST(labour_duration_hours AS char), '-') ORDER BY pregnancy_number, group_obs_id SEPARATOR '; ') AS prev_preg_labour_duration_hours,
        GROUP_CONCAT(IFNULL(CAST(gestational_age_at_birth AS char), '-') ORDER BY pregnancy_number, group_obs_id SEPARATOR '; ') AS prev_preg_gestational_age_at_birth
    FROM pp_groups
    GROUP BY location_id, person_id, visit_date
)

SELECT
    a.*,
    p.gender, p.birthdate, p.birthdate_estimated, p.first_anc_visit, p.age_years_at_first_anc_visit, p.dead, p.death_date, p.arv_number_identifier,
    s.number_of_previous_pregnancy_groups, s.number_of_distinct_previous_pregnancies, s.latest_previous_delivery_date, s.prev_preg_pregnancy_number, s.prev_preg_mode_of_delivery, s.prev_preg_assisted_vaginal_delivery, s.prev_preg_assisted_delivery_type, s.prev_preg_mode_of_delivery_details, s.prev_preg_multiple_gestation, s.prev_preg_number_of_babies, s.prev_preg_delivery_date_year, s.prev_preg_outcome_of_baby_at_birth, s.prev_preg_baby_birthweight, s.prev_preg_labour_duration_hours, s.prev_preg_gestational_age_at_birth
FROM anc_pivot a
INNER JOIN patients p ON p.person_id = a.person_id
LEFT JOIN pp_summary s ON s.location_id = a.location_id AND s.person_id = a.person_id AND s.visit_date = a.visit_date
ORDER BY a.location_id, a.person_id, a.visit_date;

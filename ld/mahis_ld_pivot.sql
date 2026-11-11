-- ============================================================================
-- MAHIS LABOUR AND DELIVERY PIVOT (LABOUR AND DELIVERY PROGRAM, program_id = 36) - one row per person / visit_date
--
-- * Obs come from non-voided encounters of program 36 only (add other programs later if needed)
-- * 'Continous monitoring' encounters (one per labour-monitoring round) are excluded here -> see mahis_ld_monitoring.sql
-- * Child obs keep their OWN concept_id (groups hold real fields, unlike the neonatal answer-as-child pattern)
-- * Previous pregnancy history (group 59249) repeats once per past pregnancy: its children are NOT pivoted as ordinary columns;
--   they appear as the prev_preg_* columns at the end (all pregnancies of the visit joined with '; ' in pregnancy-number order,
--   '-' = not recorded) and as one row per pregnancy in mahis_ld_previous_pregnancies.sql
-- * Multi-select concepts (counselling, medications, ...) are joined with '; '; every other concept keeps its latest value of the day
-- * Coded values decoded to concept names; patient columns added at the end
-- ============================================================================
SET SESSION group_concat_max_len = 1000000;

WITH ld_obs AS (
    SELECT
        o.obs_id, o.person_id, o.location_id, o.concept_id, o.obs_group_id,
        DATE(o.obs_datetime) AS visit_date, o.obs_datetime,
        o.value_coded, o.value_numeric, o.value_text, o.value_datetime
    FROM obs o
    INNER JOIN encounter e ON e.encounter_id = o.encounter_id AND e.program_id = 36 AND e.voided = 0
    INNER JOIN encounter_type et ON et.encounter_type_id = e.encounter_type AND et.name <> 'Continous monitoring'
    LEFT JOIN obs p ON p.obs_id = o.obs_group_id
    WHERE o.voided = 0
        AND (p.obs_id IS NULL OR p.concept_id <> 59249)
        AND o.concept_id IN (
        152, 3475, 6294, 9763, 11540, 12819, 13203, 13247, 13251, 13312,
        13334, 13354, 13433, 13593, 13716, 13719, 18827, 22005, 22348, 22353,
        22661, 23727, 23831, 32506, 36940, 36979, 37288, 37621, 37626, 37950,
        38459, 38611, 38899, 39039, 47492, 47536, 47668, 47756, 47767, 47772,
        47792, 47799, 47800, 47801, 47802, 47814, 47836, 47979, 47988, 48037,
        48074, 48084, 48113, 48116, 48266, 48272, 48282, 48284, 48300, 48303,
        48377, 48379, 48381, 48383, 48385, 48431, 48437, 48462, 48472, 48486,
        48502, 48506, 48516, 48518, 48520, 48523, 48530, 48580, 48598, 48616,
        48877, 49070, 49085, 49305, 49308, 49311, 49314, 49336, 49341, 49358,
        49363, 49367, 49369, 49371, 49373, 49375, 49377, 49382, 49383, 49386,
        49388, 49389, 49391, 49395, 49397, 49528, 49536, 49597, 49602, 49821,
        50107, 50192, 50225, 50230, 50244, 50246, 50259, 50263, 50367, 50410,
        50414, 50418, 50560, 50562, 50567, 50615, 50639, 50672, 52925, 53048,
        53235, 53312, 53316, 53319, 53321, 53322, 53325, 53328, 53333, 53337,
        53478, 53479, 53551, 53818, 54140, 54754, 54924, 55214, 55307, 55373,
        55537, 55540, 55541, 55763, 55846, 55852, 55853, 55854, 55855, 55857,
        55859, 55860, 55866, 55953, 55956, 55994, 56097, 56100, 56434, 56437,
        56438, 56555, 56669, 56670, 56671, 56772, 56806, 56814, 56824, 57159,
        57341, 57440, 57460, 57631, 58018, 58083, 58427, 58472, 58489, 58507,
        58521, 58545, 58562, 58587, 58589, 58590, 58600, 58603, 58610, 58612,
        58616, 58617, 58621, 58634, 58637, 58640, 58642, 58643, 58644, 58646,
        58651, 58657, 58659, 58666, 58669, 58675, 58685, 58686, 58689, 58690,
        58701, 58702, 58703, 58714, 58717, 58718, 58719, 58722, 58726, 58727,
        58738, 58739, 58740, 58741, 58755, 58759, 58765, 58767, 58774, 58775,
        58789, 58802, 58805, 58808, 58812, 58813, 58822, 58823, 58824, 58826,
        58868, 58872, 58873, 58903, 58946, 58984, 59086, 59103, 59125, 59144,
        59182, 59184, 59185, 59186, 59187, 59188, 59189, 59190, 59191, 59192,
        59193, 59194, 59195, 59196, 59197, 59198, 59199, 59200, 59249, 59326,
        59327, 59328, 59347, 59348, 59349, 59381, 59382, 59384, 59385, 59386,
        59388, 59389, 59391, 59421, 59422, 59431, 59472, 59499, 59500, 59501,
        155662
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
        WHERE cn.voided = 0 AND cn.concept_id IN (SELECT DISTINCT value_coded FROM ld_obs WHERE value_coded IS NOT NULL)
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
    FROM ld_obs a
    LEFT JOIN coded_names cn ON cn.concept_id = a.value_coded
),

ld_pivot AS (
    SELECT
        o.location_id,
        o.person_id,
        o.visit_date,
    MAX(CASE WHEN o.concept_id = 152 AND o.rn = 1 THEN val END) AS sexually_transmitted_infection,
    MAX(CASE WHEN o.concept_id = 3475 AND o.rn = 1 THEN val END) AS dehydration,
    MAX(CASE WHEN o.concept_id = 6294 AND o.rn = 1 THEN o.value_text END) AS hta,
    MAX(CASE WHEN o.concept_id = 9763 AND o.rn = 1 THEN o.value_text END) AS dysmenorrhoea,
    MAX(CASE WHEN o.concept_id = 11540 AND o.rn = 1 THEN val END) AS cleft_lip,
    MAX(CASE WHEN o.concept_id = 12819 AND o.rn = 1 THEN val END) AS coma,
    MAX(CASE WHEN o.concept_id = 13203 AND o.rn = 1 THEN o.value_text END) AS palpitations,
    MAX(CASE WHEN o.concept_id = 13247 AND o.rn = 1 THEN o.value_text END) AS wheezing,
    MAX(CASE WHEN o.concept_id = 13251 AND o.rn = 1 THEN o.value_text END) AS cough,
    MAX(CASE WHEN o.concept_id = 13312 AND o.rn = 1 THEN o.value_text END) AS nausea,
    MAX(CASE WHEN o.concept_id = 13334 AND o.rn = 1 THEN o.value_text END) AS chronic_diarrhoea_more_than_1_month,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 13354 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS icterus,
    MAX(CASE WHEN o.concept_id = 13433 AND o.rn = 1 THEN val END) AS cyanosis,
    MAX(CASE WHEN o.concept_id = 13593 AND o.rn = 1 THEN o.value_text END) AS dysuria,
    MAX(CASE WHEN o.concept_id = 13716 AND o.rn = 1 THEN o.value_text END) AS prolonged_fever_over_1_mo,
    MAX(CASE WHEN o.concept_id = 13719 AND o.rn = 1 THEN val END) AS oedema,
    MAX(CASE WHEN o.concept_id = 18827 AND o.rn = 1 THEN o.value_text END) AS diabetes_mellitus_disorder_tm2,
    MAX(CASE WHEN o.concept_id = 22005 AND o.rn = 1 THEN val END) AS heart,
    MAX(CASE WHEN o.concept_id = 22348 AND o.rn = 1 THEN val END) AS palate,
    MAX(CASE WHEN o.concept_id = 22353 AND o.rn = 1 THEN val END) AS tongue,
    MAX(CASE WHEN o.concept_id = 22661 AND o.rn = 1 THEN val END) AS sacrum,
    MAX(CASE WHEN o.concept_id = 23727 AND o.rn = 1 THEN val END) AS uterus,
    MAX(CASE WHEN o.concept_id = 23831 AND o.rn = 1 THEN o.value_text END) AS neck,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 32506 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS vaccines,
    MAX(CASE WHEN o.concept_id = 36940 AND o.rn = 1 THEN o.value_text END) AS chest_pain,
    MAX(CASE WHEN o.concept_id = 36979 AND o.rn = 1 THEN val END) AS convulsion,
    MAX(CASE WHEN o.concept_id = 37288 AND o.rn = 1 THEN val END) AS pale_conjunctiva,
    MAX(CASE WHEN o.concept_id = 37621 AND o.rn = 1 THEN val END) AS nasal_blockage,
    MAX(CASE WHEN o.concept_id = 37626 AND o.rn = 1 THEN o.value_text END) AS weight_loss,
    MAX(CASE WHEN o.concept_id = 37950 AND o.rn = 1 THEN o.value_numeric END) AS parity,
    MAX(CASE WHEN o.concept_id = 38459 AND o.rn = 1 THEN o.value_numeric END) AS phone_number,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 38611 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS contraceptive_use,
    MAX(CASE WHEN o.concept_id = 38899 AND o.rn = 1 THEN o.value_numeric END) AS gravida,
    MAX(CASE WHEN o.concept_id = 39039 AND o.rn = 1 THEN o.value_datetime END) AS hiv_test_date,
    MAX(CASE WHEN o.concept_id = 47492 AND o.rn = 1 THEN o.value_text END) AS abnormal_vaginal_discharge,
    MAX(CASE WHEN o.concept_id = 47536 AND o.rn = 1 THEN o.value_text END) AS pulse_rate,
    MAX(CASE WHEN o.concept_id = 47668 AND o.rn = 1 THEN val END) AS wheezes,
    MAX(CASE WHEN o.concept_id = 47756 AND o.rn = 1 THEN o.value_text END) AS facility_for_art,
    MAX(CASE WHEN o.concept_id = 47767 AND o.rn = 1 THEN o.value_text END) AS the_woman_received_tetanus_doses_for_immunization,
    MAX(CASE WHEN o.concept_id = 47772 AND o.rn = 1 THEN o.value_text END) AS reason_tetanus_toxoid_tt_was_not_conducted,
    MAX(CASE WHEN o.concept_id = 47792 AND o.rn = 1 THEN val END) AS daily_caffeine_use,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 47799 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS which_medications_is_the_woman_currently_prescribed,
    MAX(CASE WHEN o.concept_id = 47800 AND o.rn = 1 THEN o.value_numeric END) AS abortions_miscarriages,
    MAX(CASE WHEN o.concept_id = 47801 AND o.rn = 1 THEN o.value_numeric END) AS stillbirths,
    MAX(CASE WHEN o.concept_id = 47802 AND o.rn = 1 THEN val END) AS live_births,
    MAX(CASE WHEN o.concept_id = 47814 AND o.rn = 1 THEN o.value_text END) AS other_notes,
    MAX(CASE WHEN o.concept_id = 47836 AND o.rn = 1 THEN val END) AS danger_signs,
    MAX(CASE WHEN o.concept_id = 47979 AND o.rn = 1 THEN o.value_numeric END) AS livebirths,
    MAX(CASE WHEN o.concept_id = 47988 AND o.rn = 1 THEN o.value_text END) AS tt2date,
    MAX(CASE WHEN o.concept_id = 48037 AND o.rn = 1 THEN o.value_text END) AS congenital_abnormalities,
    MAX(CASE WHEN o.concept_id = 48074 AND o.rn = 1 THEN val END) AS pallor,
    MAX(CASE WHEN o.concept_id = 48084 AND o.rn = 1 THEN val END) AS discharge,
    MAX(CASE WHEN o.concept_id = 48113 AND o.rn = 1 THEN o.value_numeric END) AS symphysis_fundal_height,
    MAX(CASE WHEN o.concept_id = 48116 AND o.rn = 1 THEN o.value_numeric END) AS number_of_fetuses,
    MAX(CASE WHEN o.concept_id = 48266 AND o.rn = 1 THEN val END) AS misuse_of_drugs,
    MAX(CASE WHEN o.concept_id = 48272 AND o.rn = 1 THEN val END) AS baby_general_condition_at_birth,
    MAX(CASE WHEN o.concept_id = 48282 AND o.rn = 1 THEN o.value_numeric END) AS apgar_score_at_1_minute,
    MAX(CASE WHEN o.concept_id = 48284 AND o.rn = 1 THEN o.value_numeric END) AS apgar_score_at_5_minutes,
    MAX(CASE WHEN o.concept_id = 48300 AND o.rn = 1 THEN val END) AS vitamin_k_given,
    MAX(CASE WHEN o.concept_id = 48303 AND o.rn = 1 THEN val END) AS mode_of_delivery,
    MAX(CASE WHEN o.concept_id = 48377 AND o.rn = 1 THEN val END) AS cord_bleeding,
    MAX(CASE WHEN o.concept_id = 48379 AND o.rn = 1 THEN val END) AS breast_feeding_in_the_first_hour_of_birth,
    MAX(CASE WHEN o.concept_id = 48381 AND o.rn = 1 THEN val END) AS skin_to_skin_contact_with_the_mother,
    MAX(CASE WHEN o.concept_id = 48383 AND o.rn = 1 THEN val END) AS delayed_bathing,
    MAX(CASE WHEN o.concept_id = 48385 AND o.rn = 1 THEN val END) AS delayed_cord_cutting,
    MAX(CASE WHEN o.concept_id = 48431 AND o.rn = 1 THEN val END) AS outcome_of_the_delivery,
    MAX(CASE WHEN o.concept_id = 48437 AND o.rn = 1 THEN val END) AS past_pregnancy_problems,
    MAX(CASE WHEN o.concept_id = 48462 AND o.rn = 1 THEN val END) AS status_of_lochia,
    MAX(CASE WHEN o.concept_id = 48472 AND o.rn = 1 THEN val END) AS episiotomy_tear,
    MAX(CASE WHEN o.concept_id = 48486 AND o.rn = 1 THEN val END) AS postnatal_complications,
    MAX(CASE WHEN o.concept_id = 48502 AND o.rn = 1 THEN o.value_numeric END) AS current_weight,
    MAX(CASE WHEN o.concept_id = 48506 AND o.rn = 1 THEN val END) AS birth_condition,
    MAX(CASE WHEN o.concept_id = 48516 AND o.rn = 1 THEN val END) AS immunisation_given,
    MAX(CASE WHEN o.concept_id = 48518 AND o.rn = 1 THEN o.value_datetime END) AS date_bcg_given,
    MAX(CASE WHEN o.concept_id = 48520 AND o.rn = 1 THEN o.value_datetime END) AS date_polio_given,
    MAX(CASE WHEN o.concept_id = 48523 AND o.rn = 1 THEN val END) AS cord_care,
    MAX(CASE WHEN o.concept_id = 48530 AND o.rn = 1 THEN val END) AS chest_in_drawing,
    MAX(CASE WHEN o.concept_id = 48580 AND o.rn = 1 THEN val END) AS vitamin_a_supplementation,
    MAX(CASE WHEN o.concept_id = 48598 AND o.rn = 1 THEN val END) AS discharge_status_of_woman,
    MAX(CASE WHEN o.concept_id = 48616 AND o.rn = 1 THEN val END) AS past_pregnancies_complications,
    MAX(CASE WHEN o.concept_id = 48877 AND o.rn = 1 THEN o.value_text END) AS number_of_tetanus_doses,
    MAX(CASE WHEN o.concept_id = 49070 AND o.rn = 1 THEN o.value_text END) AS protected_at_birth,
    MAX(CASE WHEN o.concept_id = 49085 AND o.rn = 1 THEN o.value_text END) AS how_many_doses_of_tdv_did_the_mother_receive,
    MAX(CASE WHEN o.concept_id = 49305 AND o.rn = 1 THEN o.value_datetime END) AS date_of_labour_onset,
    MAX(CASE WHEN o.concept_id = 49308 AND o.rn = 1 THEN o.value_text END) AS time_of_labour_onset,
    MAX(CASE WHEN o.concept_id = 49311 AND o.rn = 1 THEN o.value_datetime END) AS date_membranes_ruptured,
    MAX(CASE WHEN o.concept_id = 49314 AND o.rn = 1 THEN o.value_text END) AS time_membranes_ruptured,
    MAX(CASE WHEN o.concept_id = 49336 AND o.rn = 1 THEN val END) AS state_of_cervix,
    MAX(CASE WHEN o.concept_id = 49341 AND o.rn = 1 THEN o.value_numeric END) AS age_at_menarche,
    MAX(CASE WHEN o.concept_id = 49358 AND o.rn = 1 THEN o.value_text END) AS excessive_thirst,
    MAX(CASE WHEN o.concept_id = 49363 AND o.rn = 1 THEN val END) AS shape_of_brim,
    MAX(CASE WHEN o.concept_id = 49367 AND o.rn = 1 THEN val END) AS sacrospinous_ligaments,
    MAX(CASE WHEN o.concept_id = 49369 AND o.rn = 1 THEN val END) AS ischial_spines,
    MAX(CASE WHEN o.concept_id = 49371 AND o.rn = 1 THEN val END) AS sub_pubic_arch,
    MAX(CASE WHEN o.concept_id = 49373 AND o.rn = 1 THEN val END) AS intertuberous_diameter,
    MAX(CASE WHEN o.concept_id = 49375 AND o.rn = 1 THEN o.value_text END) AS conclusion_about_pelvis,
    MAX(CASE WHEN o.concept_id = 49377 AND o.rn = 1 THEN o.value_text END) AS anticipated_course_of_labour_and_delivery,
    MAX(CASE WHEN o.concept_id = 49382 AND o.rn = 1 THEN val END) AS bladder,
    MAX(CASE WHEN o.concept_id = 49383 AND o.rn = 1 THEN val END) AS what_is_the_reason_for_coming_to_the_facility,
    MAX(CASE WHEN o.concept_id = 49386 AND o.rn = 1 THEN val END) AS labour_onset_type,
    MAX(CASE WHEN o.concept_id = 49388 AND o.rn = 1 THEN val END) AS membranes_ruptured,
    MAX(CASE WHEN o.concept_id = 49389 AND o.rn = 1 THEN val END) AS has_she_had_food_in_4_hours,
    MAX(CASE WHEN o.concept_id = 49391 AND o.rn = 1 THEN val END) AS homemade_medicines_taken,
    MAX(CASE WHEN o.concept_id = 49395 AND o.rn = 1 THEN o.value_text END) AS who_is_being_referred,
    MAX(CASE WHEN o.concept_id = 49397 AND o.rn = 1 THEN val END) AS reason_for_referring_mother,
    MAX(CASE WHEN o.concept_id = 49528 AND o.rn = 1 THEN o.value_text END) AS referral_facility,
    MAX(CASE WHEN o.concept_id = 49536 AND o.rn = 1 THEN val END) AS grunting,
    MAX(CASE WHEN o.concept_id = 49597 AND o.rn = 1 THEN o.value_numeric END) AS length,
    MAX(CASE WHEN o.concept_id = 49602 AND o.rn = 1 THEN val END) AS neural_tube_defect_spina_bifida,
    MAX(CASE WHEN o.concept_id = 49821 AND o.rn = 1 THEN val END) AS capillary_refill,
    MAX(CASE WHEN o.concept_id = 50107 AND o.rn = 1 THEN o.value_numeric END) AS apgar_score_at_10_minutes,
    MAX(CASE WHEN o.concept_id = 50192 AND o.rn = 1 THEN val END) AS femoral_pulses,
    MAX(CASE WHEN o.concept_id = 50225 AND o.rn = 1 THEN val END) AS has_passed_urine,
    MAX(CASE WHEN o.concept_id = 50230 AND o.rn = 1 THEN val END) AS eyes,
    MAX(CASE WHEN o.concept_id = 50244 AND o.rn = 1 THEN val END) AS extra_digits,
    MAX(CASE WHEN o.concept_id = 50246 AND o.rn = 1 THEN val END) AS talipes,
    MAX(CASE WHEN o.concept_id = 50259 AND o.rn = 1 THEN val END) AS suck_reflex,
    MAX(CASE WHEN o.concept_id = 50263 AND o.rn = 1 THEN val END) AS moro_reflex,
    MAX(CASE WHEN o.concept_id = 50367 AND o.rn = 1 THEN val END) AS health_education,
    MAX(CASE WHEN o.concept_id = 50410 AND o.rn = 1 THEN val END) AS mother_vdrl_syphilis_result,
    MAX(CASE WHEN o.concept_id = 50414 AND o.rn = 1 THEN val END) AS mother_hepatitis_result,
    MAX(CASE WHEN o.concept_id = 50418 AND o.rn = 1 THEN o.value_text END) AS orthopnoea,
    MAX(CASE WHEN o.concept_id = 50560 AND o.rn = 1 THEN o.value_text END) AS regularity_of_menstrual_flow,
    MAX(CASE WHEN o.concept_id = 50562 AND o.rn = 1 THEN o.value_text END) AS amount_of_menstrual_flow,
    MAX(CASE WHEN o.concept_id = 50567 AND o.rn = 1 THEN val END) AS gynaecological_surgery,
    MAX(CASE WHEN o.concept_id = 50615 AND o.rn = 1 THEN o.value_numeric END) AS department,
    MAX(CASE WHEN o.concept_id = 50639 AND o.rn = 1 THEN o.value_text END) AS night_sweats,
    MAX(CASE WHEN o.concept_id = 50672 AND o.rn = 1 THEN o.value_text END) AS tremors,
    MAX(CASE WHEN o.concept_id = 52925 AND o.rn = 1 THEN o.value_text END) AS hiv_status,
    MAX(CASE WHEN o.concept_id = 53048 AND o.rn = 1 THEN val END) AS prolapse,
    MAX(CASE WHEN o.concept_id = 53235 AND o.rn = 1 THEN val END) AS application,
    MAX(CASE WHEN o.concept_id = 53312 AND o.rn = 1 THEN val END) AS systolic_blood_pressure,
    MAX(CASE WHEN o.concept_id = 53316 AND o.rn = 1 THEN val END) AS diastolic_blood_pressure,
    MAX(CASE WHEN o.concept_id = 53319 AND o.rn = 1 THEN val END) AS pulse,
    MAX(CASE WHEN o.concept_id = 53321 AND o.rn = 1 THEN val END) AS heart_rate,
    MAX(CASE WHEN o.concept_id = 53322 AND o.rn = 1 THEN val END) AS temperature_c,
    MAX(CASE WHEN o.concept_id = 53325 AND o.rn = 1 THEN o.value_numeric END) AS weight_kg,
    MAX(CASE WHEN o.concept_id = 53328 AND o.rn = 1 THEN val END) AS height,
    MAX(CASE WHEN o.concept_id = 53333 AND o.rn = 1 THEN val END) AS sao2,
    MAX(CASE WHEN o.concept_id = 53337 AND o.rn = 1 THEN o.value_datetime END) AS appointment_date,
    MAX(CASE WHEN o.concept_id = 53478 AND o.rn = 1 THEN val END) AS respiratory_rate,
    MAX(CASE WHEN o.concept_id = 53479 AND o.rn = 1 THEN val END) AS respiration_rate,
    MAX(CASE WHEN o.concept_id = 53551 AND o.rn = 1 THEN o.value_numeric END) AS head_circumference,
    MAX(CASE WHEN o.concept_id = 53818 AND o.rn = 1 THEN o.value_datetime END) AS date_of_delivery,
    MAX(CASE WHEN o.concept_id = 54140 AND o.rn = 1 THEN o.value_text END) AS shortness_of_breath,
    MAX(CASE WHEN o.concept_id = 54754 AND o.rn = 1 THEN val END) AS outcome,
    MAX(CASE WHEN o.concept_id = 54924 AND o.rn = 1 THEN val END) AS general_condition,
    MAX(CASE WHEN o.concept_id = 55214 AND o.rn = 1 THEN o.value_text END) AS art_number,
    MAX(CASE WHEN o.concept_id = 55307 AND o.rn = 1 THEN o.value_text END) AS multiple_gestation,
    MAX(CASE WHEN o.concept_id = 55373 AND o.rn = 1 THEN val END) AS chronic_conditions,
    MAX(CASE WHEN o.concept_id = 55537 AND o.rn = 1 THEN o.value_numeric END) AS number_of_babies,
    MAX(CASE WHEN o.concept_id = 55540 AND o.rn = 1 THEN val END) AS presentation,
    MAX(CASE WHEN o.concept_id = 55541 AND o.rn = 1 THEN o.value_text END) AS time_of_delivery,
    MAX(CASE WHEN o.concept_id = 55763 AND o.rn = 1 THEN o.value_text END) AS upper_gi_bleeding,
    MAX(CASE WHEN o.concept_id = 55846 AND o.rn = 1 THEN val END) AS ward,
    MAX(CASE WHEN o.concept_id = 55852 AND o.rn = 1 THEN val END) AS lie,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 55853 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS position,
    MAX(CASE WHEN o.concept_id = 55854 AND o.rn = 1 THEN val END) AS contractions,
    MAX(CASE WHEN o.concept_id = 55855 AND o.rn = 1 THEN o.value_numeric END) AS fetal_heart_rate,
    MAX(CASE WHEN o.concept_id = 55857 AND o.rn = 1 THEN o.value_text END) AS descent,
    MAX(CASE WHEN o.concept_id = 55859 AND o.rn = 1 THEN o.value_text END) AS station,
    MAX(CASE WHEN o.concept_id = 55860 AND o.rn = 1 THEN o.value_numeric END) AS cervical_dilation,
    MAX(CASE WHEN o.concept_id = 55866 AND o.rn = 1 THEN val END) AS presenting_part,
    MAX(CASE WHEN o.concept_id = 55953 AND o.rn = 1 THEN val END) AS cord,
    MAX(CASE WHEN o.concept_id = 55956 AND o.rn = 1 THEN val END) AS liquor,
    MAX(CASE WHEN o.concept_id = 55994 AND o.rn = 1 THEN val END) AS cord_prolapse,
    MAX(CASE WHEN o.concept_id = 56097 AND o.rn = 1 THEN val END) AS mother_hiv_status,
    MAX(CASE WHEN o.concept_id = 56100 AND o.rn = 1 THEN o.value_text END) AS breast_feeding,
    MAX(CASE WHEN o.concept_id = 56434 AND o.rn = 1 THEN val END) AS status_of_uterus,
    MAX(CASE WHEN o.concept_id = 56437 AND o.rn = 1 THEN val END) AS place_of_delivery,
    MAX(CASE WHEN o.concept_id = 56438 AND o.rn = 1 THEN val END) AS status_of_baby,
    MAX(CASE WHEN o.concept_id = 56555 AND o.rn = 1 THEN val END) AS lungs,
    MAX(CASE WHEN o.concept_id = 56669 AND o.rn = 1 THEN val END) AS airway,
    MAX(CASE WHEN o.concept_id = 56670 AND o.rn = 1 THEN val END) AS breathing,
    MAX(CASE WHEN o.concept_id = 56671 AND o.rn = 1 THEN val END) AS circulation,
    MAX(CASE WHEN o.concept_id = 56772 AND o.rn = 1 THEN val END) AS cervix,
    MAX(CASE WHEN o.concept_id = 56806 AND o.rn = 1 THEN val END) AS newborn_baby_complications,
    MAX(CASE WHEN o.concept_id = 56814 AND o.rn = 1 THEN val END) AS tetracycline_eye_ointment_given,
    MAX(CASE WHEN o.concept_id = 56824 AND o.rn = 1 THEN o.value_text END) AS staff_conducting_delivery,
    MAX(CASE WHEN o.concept_id = 57159 AND o.rn = 1 THEN val END) AS vitamin_k_given_57159,
    MAX(CASE WHEN o.concept_id = 57341 AND o.rn = 1 THEN val END) AS patient_enrolled,
    MAX(CASE WHEN o.concept_id = 57440 AND o.rn = 1 THEN o.value_text END) AS anuria,
    MAX(CASE WHEN o.concept_id = 57460 AND o.rn = 1 THEN o.value_text END) AS allergies,
    MAX(CASE WHEN o.concept_id = 57631 AND o.rn = 1 THEN o.value_text END) AS lochia,
    MAX(CASE WHEN o.concept_id = 58018 AND o.rn = 1 THEN val END) AS surgical_scar,
    MAX(CASE WHEN o.concept_id = 58083 AND o.rn = 1 THEN o.value_text END) AS renal_disease,
    MAX(CASE WHEN o.concept_id = 58427 AND o.rn = 1 THEN o.value_numeric END) AS abortions,
    MAX(CASE WHEN o.concept_id = 58472 AND o.rn = 1 THEN val END) AS genital_ulcer_disease_gud,
    MAX(CASE WHEN o.concept_id = 58489 AND o.rn = 1 THEN o.value_numeric END) AS length_of_menstrual_flow,
    MAX(CASE WHEN o.concept_id = 58507 AND o.rn = 1 THEN o.value_numeric END) AS number_of_children_who_are_alive,
    MAX(CASE WHEN o.concept_id = 58521 AND o.rn = 1 THEN val END) AS past_stis,
    MAX(CASE WHEN o.concept_id = 58545 AND o.rn = 1 THEN val END) AS shape,
    MAX(CASE WHEN o.concept_id = 58562 AND o.rn = 1 THEN val END) AS traditional_marks,
    MAX(CASE WHEN o.concept_id = 58587 AND o.rn = 1 THEN val END) AS abdominal_shape,
    MAX(CASE WHEN o.concept_id = 58589 AND o.rn = 1 THEN val END) AS abdominal_size,
    MAX(CASE WHEN o.concept_id = 58590 AND o.rn = 1 THEN val END) AS absence_of_the_septum,
    MAX(CASE WHEN o.concept_id = 58600 AND o.rn = 1 THEN val END) AS babinski,
    MAX(CASE WHEN o.concept_id = 58603 AND o.rn = 1 THEN val END) AS blockage,
    MAX(CASE WHEN o.concept_id = 58610 AND o.rn = 1 THEN o.value_text END) AS cadre,
    MAX(CASE WHEN o.concept_id = 58612 AND o.rn = 1 THEN val END) AS capillary_refill_less_than_3_seconds,
    MAX(CASE WHEN o.concept_id = 58616 AND o.rn = 1 THEN o.value_text END) AS chest_assesment_respiratory_rate,
    MAX(CASE WHEN o.concept_id = 58617 AND o.rn = 1 THEN val END) AS chlorhexidine_7_1_applied,
    MAX(CASE WHEN o.concept_id = 58621 AND o.rn = 1 THEN val END) AS coldness,
    MAX(CASE WHEN o.concept_id = 58634 AND o.rn = 1 THEN val END) AS descended_testicles,
    MAX(CASE WHEN o.concept_id = 58637 AND o.rn = 1 THEN o.value_text END) AS discharged_from_labourward,
    MAX(CASE WHEN o.concept_id = 58640 AND o.rn = 1 THEN val END) AS ear_discharges,
    MAX(CASE WHEN o.concept_id = 58642 AND o.rn = 1 THEN val END) AS ears_deformities,
    MAX(CASE WHEN o.concept_id = 58643 AND o.rn = 1 THEN val END) AS ears_growth,
    MAX(CASE WHEN o.concept_id = 58644 AND o.rn = 1 THEN o.value_text END) AS effacement,
    MAX(CASE WHEN o.concept_id = 58646 AND o.rn = 1 THEN val END) AS ellavi_drape_used,
    MAX(CASE WHEN o.concept_id = 58651 AND o.rn = 1 THEN val END) AS erbs_palsy,
    MAX(CASE WHEN o.concept_id = 58657 AND o.rn = 1 THEN val END) AS extra_assesment_pallor,
    MAX(CASE WHEN o.concept_id = 58659 AND o.rn = 1 THEN val END) AS false_teeth,
    MAX(CASE WHEN o.concept_id = 58666 AND o.rn = 1 THEN val END) AS fractures,
    MAX(CASE WHEN o.concept_id = 58669 AND o.rn = 1 THEN val END) AS grasping,
    MAX(CASE WHEN o.concept_id = 58675 AND o.rn = 1 THEN val END) AS heat_stable_cabitocin_100mcg_im_iv,
    MAX(CASE WHEN o.concept_id = 58685 AND o.rn = 1 THEN val END) AS is_client_on_art,
    MAX(CASE WHEN o.concept_id = 58686 AND o.rn = 1 THEN o.value_text END) AS is_referral,
    MAX(CASE WHEN o.concept_id = 58689 AND o.rn = 1 THEN o.value_datetime END) AS labourward_discharge_date,
    MAX(CASE WHEN o.concept_id = 58690 AND o.rn = 1 THEN o.value_text END) AS labourward_discharge_time,
    MAX(CASE WHEN o.concept_id = 58701 AND o.rn = 1 THEN val END) AS level_of_eyes_to_the_ears,
    MAX(CASE WHEN o.concept_id = 58702 AND o.rn = 1 THEN val END) AS lips_cyanosis,
    MAX(CASE WHEN o.concept_id = 58703 AND o.rn = 1 THEN val END) AS liver_and_spleen,
    MAX(CASE WHEN o.concept_id = 58714 AND o.rn = 1 THEN o.value_text END) AS maternal_outcome_status,
    MAX(CASE WHEN o.concept_id = 58717 AND o.rn = 1 THEN val END) AS meconium_grade,
    MAX(CASE WHEN o.concept_id = 58718 AND o.rn = 1 THEN o.value_numeric END) AS mid_upper_arm_circumference,
    MAX(CASE WHEN o.concept_id = 58719 AND o.rn = 1 THEN val END) AS misoprostol_400_600mcg_orally,
    MAX(CASE WHEN o.concept_id = 58722 AND o.rn = 1 THEN val END) AS missing_digits,
    MAX(CASE WHEN o.concept_id = 58726 AND o.rn = 1 THEN val END) AS mother_hiv_test_results,
    MAX(CASE WHEN o.concept_id = 58727 AND o.rn = 1 THEN val END) AS murmurs,
    MAX(CASE WHEN o.concept_id = 58738 AND o.rn = 1 THEN val END) AS nose_deformities,
    MAX(CASE WHEN o.concept_id = 58739 AND o.rn = 1 THEN val END) AS nose_discharges,
    MAX(CASE WHEN o.concept_id = 58740 AND o.rn = 1 THEN val END) AS nose_growth,
    MAX(CASE WHEN o.concept_id = 58741 AND o.rn = 1 THEN val END) AS nose_shape,
    MAX(CASE WHEN o.concept_id = 58755 AND o.rn = 1 THEN o.value_text END) AS outcome_of_baby_at_birth,
    MAX(CASE WHEN o.concept_id = 58759 AND o.rn = 1 THEN val END) AS oxytocin_10_iu_given,
    MAX(CASE WHEN o.concept_id = 58765 AND o.rn = 1 THEN val END) AS palmar_pallor,
    MAX(CASE WHEN o.concept_id = 58767 AND o.rn = 1 THEN val END) AS patent_anus,
    MAX(CASE WHEN o.concept_id = 58774 AND o.rn = 1 THEN val END) AS presence_of_all_required_orifices_according_to_sex,
    MAX(CASE WHEN o.concept_id = 58775 AND o.rn = 1 THEN val END) AS presence_of_eye_ball,
    MAX(CASE WHEN o.concept_id = 58789 AND o.rn = 1 THEN o.value_text END) AS referring_mother_other_specify,
    MAX(CASE WHEN o.concept_id = 58802 AND o.rn = 1 THEN val END) AS rooting,
    MAX(CASE WHEN o.concept_id = 58805 AND o.rn = 1 THEN val END) AS sacral_promontory,
    MAX(CASE WHEN o.concept_id = 58808 AND o.rn = 1 THEN val END) AS short_neck,
    MAX(CASE WHEN o.concept_id = 58812 AND o.rn = 1 THEN val END) AS sleep,
    MAX(CASE WHEN o.concept_id = 58813 AND o.rn = 1 THEN val END) AS soft_tissues,
    MAX(CASE WHEN o.concept_id = 58822 AND o.rn = 1 THEN val END) AS state_of_membranes,
    MAX(CASE WHEN o.concept_id = 58823 AND o.rn = 1 THEN val END) AS stepping,
    MAX(CASE WHEN o.concept_id = 58824 AND o.rn = 1 THEN val END) AS suckling,
    MAX(CASE WHEN o.concept_id = 58826 AND o.rn = 1 THEN val END) AS symmetry,
    MAX(CASE WHEN o.concept_id = 58868 AND o.rn = 1 THEN o.value_text END) AS vulva_inspection,
    MAX(CASE WHEN o.concept_id = 58872 AND o.rn = 1 THEN val END) AS webbing,
    MAX(CASE WHEN o.concept_id = 58873 AND o.rn = 1 THEN o.value_numeric END) AS weight_grams,
    MAX(CASE WHEN o.concept_id = 58903 AND o.rn = 1 THEN val END) AS maternal_conditions,
    MAX(CASE WHEN o.concept_id = 58946 AND o.rn = 1 THEN o.value_text END) AS other_gynaecological_information,
    MAX(CASE WHEN o.concept_id = 58984 AND o.rn = 1 THEN val END) AS ambiguous_genitalia,
    MAX(CASE WHEN o.concept_id = 59086 AND o.rn = 1 THEN val END) AS breasts_examination,
    MAX(CASE WHEN o.concept_id = 59103 AND o.rn = 1 THEN o.value_text END) AS fetal_and_neonatal_complications,
    MAX(CASE WHEN o.concept_id = 59125 AND o.rn = 1 THEN val END) AS mandatory_investigations_done_during_anc,
    MAX(CASE WHEN o.concept_id = 59144 AND o.rn = 1 THEN val END) AS other_neck_assessment,
    MAX(CASE WHEN o.concept_id = 59182 AND o.rn = 1 THEN o.value_text END) AS assisted_vaginal_delivery,
    MAX(CASE WHEN o.concept_id = 59184 AND o.rn = 1 THEN o.value_text END) AS haematological_disorder,
    MAX(CASE WHEN o.concept_id = 59185 AND o.rn = 1 THEN o.value_text END) AS cardiac_disease,
    MAX(CASE WHEN o.concept_id = 59186 AND o.rn = 1 THEN o.value_text END) AS respiratory_diseases,
    MAX(CASE WHEN o.concept_id = 59187 AND o.rn = 1 THEN o.value_text END) AS seizures_epilepsy,
    MAX(CASE WHEN o.concept_id = 59188 AND o.rn = 1 THEN o.value_text END) AS mental_health_illness,
    MAX(CASE WHEN o.concept_id = 59189 AND o.rn = 1 THEN o.value_text END) AS endocrine_disease,
    MAX(CASE WHEN o.concept_id = 59190 AND o.rn = 1 THEN o.value_text END) AS thromboembolic_disease,
    MAX(CASE WHEN o.concept_id = 59191 AND o.rn = 1 THEN o.value_text END) AS connective_tissue_disorders,
    MAX(CASE WHEN o.concept_id = 59192 AND o.rn = 1 THEN o.value_text END) AS hypersensitivity_allergies_and_reactions,
    MAX(CASE WHEN o.concept_id = 59193 AND o.rn = 1 THEN o.value_text END) AS skin_and_mucosal_conditions,
    MAX(CASE WHEN o.concept_id = 59194 AND o.rn = 1 THEN o.value_text END) AS skeletal_abnormalities,
    MAX(CASE WHEN o.concept_id = 59195 AND o.rn = 1 THEN o.value_text END) AS other_cancer,
    MAX(CASE WHEN o.concept_id = 59196 AND o.rn = 1 THEN o.value_text END) AS reduced_exercise_tolerance,
    MAX(CASE WHEN o.concept_id = 59197 AND o.rn = 1 THEN o.value_text END) AS oedema_lower_extremities,
    MAX(CASE WHEN o.concept_id = 59198 AND o.rn = 1 THEN o.value_text END) AS weakness_or_numbness,
    MAX(CASE WHEN o.concept_id = 59199 AND o.rn = 1 THEN o.value_text END) AS excessive_vomiting,
    MAX(CASE WHEN o.concept_id = 59200 AND o.rn = 1 THEN o.value_text END) AS heat_or_cold_intolerance,
    MAX(CASE WHEN o.concept_id = 59249 AND o.rn = 1 THEN o.value_text END) AS previous_pregnancy_history,
    MAX(CASE WHEN o.concept_id = 59326 AND o.rn = 1 THEN o.value_numeric END) AS dosage_iron,
    MAX(CASE WHEN o.concept_id = 59327 AND o.rn = 1 THEN o.value_text END) AS frequency_iron,
    MAX(CASE WHEN o.concept_id = 59328 AND o.rn = 1 THEN o.value_text END) AS duration_iron,
    MAX(CASE WHEN o.concept_id = 59347 AND o.rn = 1 THEN o.value_numeric END) AS dosage_anti_malarial,
    MAX(CASE WHEN o.concept_id = 59348 AND o.rn = 1 THEN o.value_text END) AS frequency_anti_malarial,
    MAX(CASE WHEN o.concept_id = 59349 AND o.rn = 1 THEN o.value_text END) AS duration_anti_malarial,
    MAX(CASE WHEN o.concept_id = 59381 AND o.rn = 1 THEN o.value_text END) AS pregnancy_number,
    MAX(CASE WHEN o.concept_id = 59382 AND o.rn = 1 THEN o.value_text END) AS delivery_date_year,
    MAX(CASE WHEN o.concept_id = 59384 AND o.rn = 1 THEN o.value_text END) AS baby_birthweight,
    MAX(CASE WHEN o.concept_id = 59385 AND o.rn = 1 THEN o.value_text END) AS labour_duration_hours,
    MAX(CASE WHEN o.concept_id = 59386 AND o.rn = 1 THEN o.value_text END) AS gestational_age_at_birth,
    MAX(CASE WHEN o.concept_id = 59388 AND o.rn = 1 THEN o.value_text END) AS cervical_cancer,
    MAX(CASE WHEN o.concept_id = 59389 AND o.rn = 1 THEN o.value_text END) AS std_stis,
    MAX(CASE WHEN o.concept_id = 59391 AND o.rn = 1 THEN o.value_text END) AS pre_existing_anaemia,
    MAX(CASE WHEN o.concept_id = 59421 AND o.rn = 1 THEN o.value_text END) AS other_health_conditions,
    MAX(CASE WHEN o.concept_id = 59422 AND o.rn = 1 THEN o.value_text END) AS when_last_did_she_pass_urine,
    MAX(CASE WHEN o.concept_id = 59431 AND o.rn = 1 THEN val END) AS does_the_woman_have_the_urge_to_push,
    MAX(CASE WHEN o.concept_id = 59472 AND o.rn = 1 THEN o.value_text END) AS is_the_assessment_within,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 59499 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS health_education_topics,
    MAX(CASE WHEN o.concept_id = 59500 AND o.rn = 1 THEN val END) AS itn_provided,
    MAX(CASE WHEN o.concept_id = 59501 AND o.rn = 1 THEN val END) AS baby_vaccines_given,
    MAX(CASE WHEN o.concept_id = 155662 AND o.rn = 1 THEN o.value_text END) AS urination
    FROM decoded o
    GROUP BY o.location_id, o.person_id, o.visit_date
),

patients AS (
    SELECT
        p.person_id,
        p.gender,
        p.birthdate,
        p.birthdate_estimated,
        fv.first_ld_visit,
        TIMESTAMPDIFF(YEAR, p.birthdate, fv.first_ld_visit) AS age_years_at_first_ld_visit,
        -- the program also holds the newborns' own records: baby = under 5 years at first visit, woman = 5+; no birthdate = unknown
        CASE WHEN p.birthdate IS NULL THEN 'unknown'
             WHEN TIMESTAMPDIFF(YEAR, p.birthdate, fv.first_ld_visit) < 5 THEN 'baby' ELSE 'woman' END AS record_type,
        rel.related_person_ids,
        rel.related_relationships,
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
    LEFT JOIN (
        -- active relationships where this person is person_b (e.g. a baby's mother); relationship wording is stored as typed in the system
        SELECT r.person_b AS person_id,
            GROUP_CONCAT(DISTINCT r.person_a ORDER BY r.person_a SEPARATOR '; ') AS related_person_ids,
            GROUP_CONCAT(DISTINCT CONCAT(t.a_is_to_b, ' of this person') ORDER BY t.a_is_to_b SEPARATOR '; ') AS related_relationships
        FROM relationship r
        INNER JOIN relationship_type t ON t.relationship_type_id = r.relationship
        WHERE r.voided = 0
        GROUP BY r.person_b
    ) rel ON rel.person_id = p.person_id
    INNER JOIN (
        SELECT e.patient_id, MIN(DATE(e.encounter_datetime)) AS first_ld_visit
        FROM encounter e WHERE e.program_id = 36 AND e.voided = 0 GROUP BY e.patient_id
    ) fv ON fv.patient_id = p.person_id
    WHERE p.voided = 0
),

pp_parents AS (
    -- one row per previous-pregnancy group obs (repeats once per past pregnancy, and again when re-saved at a later visit)
    SELECT p.obs_id AS group_obs_id, p.person_id, p.location_id, p.encounter_id,
        DATE(p.obs_datetime) AS visit_date, p.obs_datetime, p.value_text AS previous_pregnancy_label
    FROM obs p
    INNER JOIN encounter e ON e.encounter_id = p.encounter_id AND e.program_id = 36 AND e.voided = 0
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
),

anc_history AS (
    -- latest ANC-program value of each history concept per woman (other-program data; the date can differ from the labour-ward visit)
    SELECT x.person_id,
        MAX(CASE WHEN x.concept_id = 38899 AND x.rn = 1 THEN x.val END) AS anc_gravida,
        MAX(CASE WHEN x.concept_id = 47800 AND x.rn = 1 THEN x.val END) AS anc_abortions_miscarriages,
        MAX(CASE WHEN x.concept_id = 47801 AND x.rn = 1 THEN x.val END) AS anc_stillbirths,
        MAX(CASE WHEN x.concept_id = 47802 AND x.rn = 1 THEN x.val END) AS anc_live_births,
        MAX(CASE WHEN x.concept_id = 37950 AND x.rn = 1 THEN x.val END) AS anc_parity,
        MAX(CASE WHEN x.concept_id = 55373 AND x.rn = 1 THEN x.val END) AS anc_chronic_conditions,
        MAX(CASE WHEN x.concept_id = 47799 AND x.rn = 1 THEN x.val END) AS anc_medications_currently_prescribed,
        MAX(CASE WHEN x.concept_id = 47767 AND x.rn = 1 THEN x.val END) AS anc_received_tetanus_doses,
        MAX(CASE WHEN x.concept_id = 47987 AND x.rn = 1 THEN x.val END) AS anc_tt1date,
        MAX(CASE WHEN x.concept_id = 47988 AND x.rn = 1 THEN x.val END) AS anc_tt2date,
        MAX(CASE WHEN x.concept_id = 55520 AND x.rn = 1 THEN x.val END) AS anc_gestation_weeks,
        MAX(CASE WHEN x.concept_id = 47763 AND x.rn = 1 THEN x.val END) AS anc_gestation_age_to_be_used,
        MAX(CASE WHEN x.concept_id = 47980 AND x.rn = 1 THEN x.val END) AS anc_lmnp_date,
        MAX(CASE WHEN x.concept_id = 53813 AND x.rn = 1 THEN x.val END) AS anc_estimated_date_of_delivery,
        MAX(CASE WHEN x.concept_id = 55544 AND x.rn = 1 THEN x.val END) AS anc_estimated_date,
        MAX(CASE WHEN x.concept_id = 58509 AND x.rn = 1 THEN x.val END) AS anc_number_of_previous_anc_contacts,
        MAX(CASE WHEN x.concept_id = 39039 AND x.rn = 1 THEN x.val END) AS anc_hiv_test_date,
        MAX(CASE WHEN x.concept_id = 55214 AND x.rn = 1 THEN x.val END) AS anc_art_number,
        MAX(CASE WHEN x.concept_id = 58482 AND x.rn = 1 THEN x.val END) AS anc_is_client_on_art,
        MAX(CASE WHEN x.concept_id = 49126 AND x.rn = 1 THEN x.val END) AS anc_pregnancy_outcome
    FROM (
        SELECT o.person_id, o.concept_id, COALESCE((SELECT cn.name FROM concept_name cn WHERE cn.concept_id = o.value_coded AND cn.voided = 0 ORDER BY (cn.locale = 'en') DESC, (cn.concept_name_type = 'FULLY_SPECIFIED') DESC, cn.concept_name_id LIMIT 1), o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) AS val,
            ROW_NUMBER() OVER (PARTITION BY o.person_id, o.concept_id ORDER BY o.obs_datetime DESC, o.obs_id DESC) AS rn
        FROM obs o
        INNER JOIN encounter e ON e.encounter_id = o.encounter_id AND e.program_id = 12 AND e.voided = 0
        WHERE o.voided = 0
            AND o.concept_id IN (38899, 47800, 47801, 47802, 37950, 55373, 47799, 47767, 47987, 47988, 55520, 47763, 47980, 53813, 55544, 58509, 39039, 55214, 58482, 49126)
            AND o.person_id IN (SELECT person_id FROM patients)
            AND (o.value_coded IS NOT NULL OR o.value_numeric IS NOT NULL OR o.value_text IS NOT NULL OR o.value_datetime IS NOT NULL)
    ) x
    GROUP BY x.person_id
),

mon_counts AS (
    -- labour-monitoring rounds (one encounter each) per person / day; the values are in mahis_ld_monitoring.sql
    SELECT x.location_id, x.person_id, x.visit_date, COUNT(*) AS number_of_monitoring_rounds
    FROM (
        SELECT o.location_id, o.person_id, o.encounter_id, DATE(MIN(o.obs_datetime)) AS visit_date
        FROM obs o
        INNER JOIN encounter e ON e.encounter_id = o.encounter_id AND e.program_id = 36 AND e.voided = 0
        INNER JOIN encounter_type et ON et.encounter_type_id = e.encounter_type AND et.name = 'Continous monitoring'
        WHERE o.voided = 0
        GROUP BY o.location_id, o.person_id, o.encounter_id
    ) x
    GROUP BY x.location_id, x.person_id, x.visit_date
)

SELECT
    a.*,
    p.gender, p.birthdate, p.birthdate_estimated, p.first_ld_visit, p.age_years_at_first_ld_visit, p.record_type, p.related_person_ids, p.related_relationships, p.dead, p.death_date, p.arv_number_identifier,
    s.number_of_previous_pregnancy_groups, s.number_of_distinct_previous_pregnancies, s.latest_previous_delivery_date, s.prev_preg_pregnancy_number, s.prev_preg_mode_of_delivery, s.prev_preg_assisted_vaginal_delivery, s.prev_preg_assisted_delivery_type, s.prev_preg_mode_of_delivery_details, s.prev_preg_multiple_gestation, s.prev_preg_number_of_babies, s.prev_preg_delivery_date_year, s.prev_preg_outcome_of_baby_at_birth, s.prev_preg_baby_birthweight, s.prev_preg_labour_duration_hours, s.prev_preg_gestational_age_at_birth,
    COALESCE(mc.number_of_monitoring_rounds, 0) AS number_of_monitoring_rounds,
    al.anc_gravida, al.anc_abortions_miscarriages, al.anc_stillbirths, al.anc_live_births, al.anc_parity, al.anc_chronic_conditions, al.anc_medications_currently_prescribed, al.anc_received_tetanus_doses, al.anc_tt1date, al.anc_tt2date, al.anc_gestation_weeks, al.anc_gestation_age_to_be_used, al.anc_lmnp_date, al.anc_estimated_date_of_delivery, al.anc_estimated_date, al.anc_number_of_previous_anc_contacts, al.anc_hiv_test_date, al.anc_art_number, al.anc_is_client_on_art, al.anc_pregnancy_outcome
FROM ld_pivot a
INNER JOIN patients p ON p.person_id = a.person_id
LEFT JOIN pp_summary s ON s.location_id = a.location_id AND s.person_id = a.person_id AND s.visit_date = a.visit_date
LEFT JOIN anc_history al ON al.person_id = a.person_id
LEFT JOIN mon_counts mc ON mc.location_id = a.location_id AND mc.person_id = a.person_id AND mc.visit_date = a.visit_date
ORDER BY a.location_id, a.person_id, a.visit_date;

-- ============================================================================
-- MAHIS PNC PIVOT (PNC PROGRAM, program_id = 35) - one row per person / visit_date
--
-- * Obs come from non-voided encounters of program 35; every concept keeps its own concept_id (PNC has no grouped child obs)
-- * 'PNC ward monitoring mother/baby' encounters are excluded here (one encounter per round) -> mahis_pnc_ward_mother.sql / mahis_pnc_ward_baby.sql
-- * Values are raw; coded values decoded to concept names; multi-select concepts joined with '; '; other concepts keep their latest value of the day
-- * record_type: baby = under 5 years at first visit, woman = 5+, unknown = no birthdate (the program also holds the babies' own records)
-- * related_person_ids / related_relationships: active relationships where this person is person_b (e.g. a baby's mother), as stored
-- ============================================================================
SET SESSION group_concat_max_len = 1000000;

WITH pnc_obs AS (
    SELECT o.obs_id, o.person_id, o.location_id, o.concept_id, DATE(o.obs_datetime) AS visit_date, o.obs_datetime,
        o.value_coded, o.value_numeric, o.value_text, o.value_datetime
    FROM obs o
    INNER JOIN encounter e ON e.encounter_id = o.encounter_id AND e.program_id = 35 AND e.voided = 0
    INNER JOIN encounter_type et ON et.encounter_type_id = e.encounter_type AND et.name NOT IN ('PNC ward monitoring mother', 'PNC ward monitoring baby')
    WHERE o.voided = 0
        AND o.concept_id IN (
        152, 3475, 8165, 11534, 12819, 13433, 13434, 32506, 36979, 37950,
        47574, 47668, 47836, 48040, 48284, 48285, 48303, 48431, 48437, 48451,
        48457, 48462, 48472, 48474, 48502, 48518, 48520, 48530, 48534, 48538,
        48562, 48564, 48580, 48581, 48586, 48588, 48598, 48640, 49070, 49085,
        49421, 49528, 49536, 50164, 50182, 50192, 50244, 50246, 50263, 50367,
        50410, 50414, 50535, 52299, 52925, 53312, 53316, 53319, 53322, 53325,
        53328, 53333, 53337, 53478, 53551, 53818, 54106, 55366, 55537, 55541,
        55994, 56097, 56100, 56383, 56434, 56437, 56438, 56669, 56670, 56671,
        56730, 56806, 56824, 56833, 57157, 57341, 57437, 58442, 58521, 58558,
        58600, 58612, 58621, 58632, 58633, 58634, 58640, 58659, 58664, 58669,
        58722, 58727, 58738, 58739, 58741, 58767, 58802, 58808, 58823, 58872,
        58873, 58887, 58895, 58897, 58903, 58910, 58911, 58922, 58924, 58984,
        59065, 59066, 59069, 59070, 59074, 59075, 59079, 59098, 59107, 59115,
        59127, 59129, 59132, 59150, 59152, 59268, 59269, 59270, 59271, 59272,
        59275, 59278, 59279, 59280, 59283, 59284, 59285, 59406, 59464, 59473,
        59499, 59500, 59501, 59502
        )
),

coded_names AS (
    SELECT concept_id, name
    FROM (
        SELECT cn.concept_id, cn.name,
            ROW_NUMBER() OVER (PARTITION BY cn.concept_id
                ORDER BY (cn.locale = 'en') DESC, (cn.concept_name_type = 'FULLY_SPECIFIED') DESC, cn.concept_name_id) AS r
        FROM concept_name cn
        WHERE cn.voided = 0 AND cn.concept_id IN (SELECT DISTINCT value_coded FROM pnc_obs WHERE value_coded IS NOT NULL)
    ) x
    WHERE r = 1
),

decoded AS (
    SELECT a.*,
        COALESCE(cn.name, a.value_text, CAST(a.value_numeric AS char), CAST(a.value_datetime AS char)) AS val,
        ROW_NUMBER() OVER (PARTITION BY a.location_id, a.person_id, a.visit_date, a.concept_id ORDER BY a.obs_datetime DESC, a.obs_id DESC) AS rn
    FROM pnc_obs a
    LEFT JOIN coded_names cn ON cn.concept_id = a.value_coded
),

pnc_pivot AS (
    SELECT
        o.location_id,
        o.person_id,
        o.visit_date,
    MAX(CASE WHEN o.concept_id = 152 AND o.rn = 1 THEN val END) AS sexually_transmitted_infection,
    MAX(CASE WHEN o.concept_id = 3475 AND o.rn = 1 THEN val END) AS dehydration,
    MAX(CASE WHEN o.concept_id = 8165 AND o.rn = 1 THEN val END) AS umbilical_hernia,
    MAX(CASE WHEN o.concept_id = 11534 AND o.rn = 1 THEN val END) AS ankyloglossia,
    MAX(CASE WHEN o.concept_id = 12819 AND o.rn = 1 THEN val END) AS coma,
    MAX(CASE WHEN o.concept_id = 13433 AND o.rn = 1 THEN val END) AS cyanosis,
    MAX(CASE WHEN o.concept_id = 13434 AND o.rn = 1 THEN val END) AS pallor,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 32506 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS vaccines,
    MAX(CASE WHEN o.concept_id = 36979 AND o.rn = 1 THEN val END) AS convulsion,
    MAX(CASE WHEN o.concept_id = 37950 AND o.rn = 1 THEN o.value_numeric END) AS parity,
    MAX(CASE WHEN o.concept_id = 47574 AND o.rn = 1 THEN o.value_text END) AS other_neck_abnormality_notes,
    MAX(CASE WHEN o.concept_id = 47668 AND o.rn = 1 THEN val END) AS wheezes,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 47836 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS danger_signs,
    MAX(CASE WHEN o.concept_id = 48040 AND o.rn = 1 THEN o.value_text END) AS time_of_referral,
    MAX(CASE WHEN o.concept_id = 48284 AND o.rn = 1 THEN o.value_numeric END) AS apgar_score_at_5_minutes,
    MAX(CASE WHEN o.concept_id = 48285 AND o.rn = 1 THEN o.value_numeric END) AS circumference,
    MAX(CASE WHEN o.concept_id = 48303 AND o.rn = 1 THEN val END) AS mode_of_delivery,
    MAX(CASE WHEN o.concept_id = 48431 AND o.rn = 1 THEN val END) AS outcome_of_the_delivery,
    MAX(CASE WHEN o.concept_id = 48437 AND o.rn = 1 THEN val END) AS past_pregnancy_problems,
    MAX(CASE WHEN o.concept_id = 48451 AND o.rn = 1 THEN o.value_text END) AS other_danger_signs_notes,
    MAX(CASE WHEN o.concept_id = 48457 AND o.rn = 1 THEN val END) AS intervention_given,
    MAX(CASE WHEN o.concept_id = 48462 AND o.rn = 1 THEN o.value_text END) AS status_of_lochia,
    MAX(CASE WHEN o.concept_id = 48472 AND o.rn = 1 THEN val END) AS episiotomy_tear,
    MAX(CASE WHEN o.concept_id = 48474 AND o.rn = 1 THEN o.value_text END) AS condition_of_episiotomy_tear,
    MAX(CASE WHEN o.concept_id = 48502 AND o.rn = 1 THEN o.value_numeric END) AS current_weight,
    MAX(CASE WHEN o.concept_id = 48518 AND o.rn = 1 THEN o.value_datetime END) AS date_bcg_given,
    MAX(CASE WHEN o.concept_id = 48520 AND o.rn = 1 THEN o.value_datetime END) AS date_polio_given,
    MAX(CASE WHEN o.concept_id = 48530 AND o.rn = 1 THEN val END) AS chest_in_drawing,
    MAX(CASE WHEN o.concept_id = 48534 AND o.rn = 1 THEN o.value_text END) AS intervention_notes,
    MAX(CASE WHEN o.concept_id = 48538 AND o.rn = 1 THEN val END) AS cotrimoxazole_prophylaxis,
    MAX(CASE WHEN o.concept_id = 48562 AND o.rn = 1 THEN val END) AS status_of_the_mother,
    MAX(CASE WHEN o.concept_id = 48564 AND o.rn = 1 THEN val END) AS postnatal_check_period,
    MAX(CASE WHEN o.concept_id = 48580 AND o.rn = 1 THEN val END) AS vitamin_a_supplementation,
    MAX(CASE WHEN o.concept_id = 48581 AND o.rn = 1 THEN val END) AS counselling_on_family_planning,
    MAX(CASE WHEN o.concept_id = 48586 AND o.rn = 1 THEN val END) AS postnatal_visit_period,
    MAX(CASE WHEN o.concept_id = 48588 AND o.rn = 1 THEN val END) AS intervention_on_danger_signs,
    MAX(CASE WHEN o.concept_id = 48598 AND o.rn = 1 THEN val END) AS discharge_status_of_woman,
    MAX(CASE WHEN o.concept_id = 48640 AND o.rn = 1 THEN val END) AS abdominal_distention,
    MAX(CASE WHEN o.concept_id = 49070 AND o.rn = 1 THEN o.value_text END) AS protected_at_birth,
    MAX(CASE WHEN o.concept_id = 49085 AND o.rn = 1 THEN o.value_text END) AS how_many_doses_of_tdv_did_the_mother_receive,
    MAX(CASE WHEN o.concept_id = 49421 AND o.rn = 1 THEN val END) AS positioning,
    MAX(CASE WHEN o.concept_id = 49528 AND o.rn = 1 THEN o.value_text END) AS referral_facility,
    MAX(CASE WHEN o.concept_id = 49536 AND o.rn = 1 THEN val END) AS grunting,
    MAX(CASE WHEN o.concept_id = 50164 AND o.rn = 1 THEN val END) AS spinal_bifida,
    MAX(CASE WHEN o.concept_id = 50182 AND o.rn = 1 THEN val END) AS reflexes,
    MAX(CASE WHEN o.concept_id = 50192 AND o.rn = 1 THEN val END) AS femoral_pulses,
    MAX(CASE WHEN o.concept_id = 50244 AND o.rn = 1 THEN val END) AS extra_digits,
    MAX(CASE WHEN o.concept_id = 50246 AND o.rn = 1 THEN val END) AS talipes,
    MAX(CASE WHEN o.concept_id = 50263 AND o.rn = 1 THEN val END) AS moro_reflex,
    MAX(CASE WHEN o.concept_id = 50367 AND o.rn = 1 THEN val END) AS health_education,
    MAX(CASE WHEN o.concept_id = 50410 AND o.rn = 1 THEN val END) AS mother_vdrl_syphilis_result,
    MAX(CASE WHEN o.concept_id = 50414 AND o.rn = 1 THEN val END) AS mother_hepatitis_result,
    MAX(CASE WHEN o.concept_id = 50535 AND o.rn = 1 THEN val END) AS cleftlippalate,
    MAX(CASE WHEN o.concept_id = 52299 AND o.rn = 1 THEN val END) AS crackles,
    MAX(CASE WHEN o.concept_id = 52925 AND o.rn = 1 THEN o.value_text END) AS hiv_status,
    MAX(CASE WHEN o.concept_id = 53312 AND o.rn = 1 THEN o.value_numeric END) AS systolic_blood_pressure,
    MAX(CASE WHEN o.concept_id = 53316 AND o.rn = 1 THEN o.value_numeric END) AS diastolic_blood_pressure,
    MAX(CASE WHEN o.concept_id = 53319 AND o.rn = 1 THEN val END) AS pulse,
    MAX(CASE WHEN o.concept_id = 53322 AND o.rn = 1 THEN val END) AS temperature_c,
    MAX(CASE WHEN o.concept_id = 53325 AND o.rn = 1 THEN val END) AS weight_kg,
    MAX(CASE WHEN o.concept_id = 53328 AND o.rn = 1 THEN o.value_numeric END) AS height,
    MAX(CASE WHEN o.concept_id = 53333 AND o.rn = 1 THEN val END) AS sao2,
    MAX(CASE WHEN o.concept_id = 53337 AND o.rn = 1 THEN o.value_datetime END) AS appointment_date,
    MAX(CASE WHEN o.concept_id = 53478 AND o.rn = 1 THEN val END) AS respiratory_rate,
    MAX(CASE WHEN o.concept_id = 53551 AND o.rn = 1 THEN o.value_numeric END) AS head_circumference,
    MAX(CASE WHEN o.concept_id = 53818 AND o.rn = 1 THEN o.value_datetime END) AS date_of_delivery,
    MAX(CASE WHEN o.concept_id = 54106 AND o.rn = 1 THEN o.value_numeric END) AS birth_weight,
    MAX(CASE WHEN o.concept_id = 55366 AND o.rn = 1 THEN val END) AS nasal_flaring,
    MAX(CASE WHEN o.concept_id = 55537 AND o.rn = 1 THEN o.value_numeric END) AS number_of_babies,
    MAX(CASE WHEN o.concept_id = 55541 AND o.rn = 1 THEN o.value_text END) AS time_of_delivery,
    MAX(CASE WHEN o.concept_id = 55994 AND o.rn = 1 THEN val END) AS cord_prolapse,
    MAX(CASE WHEN o.concept_id = 56097 AND o.rn = 1 THEN o.value_text END) AS mother_hiv_status,
    MAX(CASE WHEN o.concept_id = 56100 AND o.rn = 1 THEN val END) AS breast_feeding,
    MAX(CASE WHEN o.concept_id = 56383 AND o.rn = 1 THEN o.value_text END) AS reason_for_referral,
    MAX(CASE WHEN o.concept_id = 56434 AND o.rn = 1 THEN o.value_text END) AS status_of_uterus,
    MAX(CASE WHEN o.concept_id = 56437 AND o.rn = 1 THEN val END) AS place_of_delivery,
    MAX(CASE WHEN o.concept_id = 56438 AND o.rn = 1 THEN val END) AS status_of_baby,
    MAX(CASE WHEN o.concept_id = 56669 AND o.rn = 1 THEN val END) AS airway,
    MAX(CASE WHEN o.concept_id = 56670 AND o.rn = 1 THEN val END) AS breathing,
    MAX(CASE WHEN o.concept_id = 56671 AND o.rn = 1 THEN val END) AS circulation,
    MAX(CASE WHEN o.concept_id = 56730 AND o.rn = 1 THEN o.value_text END) AS other_sti,
    MAX(CASE WHEN o.concept_id = 56806 AND o.rn = 1 THEN val END) AS newborn_baby_complications,
    MAX(CASE WHEN o.concept_id = 56824 AND o.rn = 1 THEN o.value_text END) AS staff_conducting_delivery,
    MAX(CASE WHEN o.concept_id = 56833 AND o.rn = 1 THEN o.value_datetime END) AS visit_date_56833,
    MAX(CASE WHEN o.concept_id = 57157 AND o.rn = 1 THEN o.value_text END) AS blood_pressure,
    MAX(CASE WHEN o.concept_id = 57341 AND o.rn = 1 THEN val END) AS patient_enrolled,
    MAX(CASE WHEN o.concept_id = 57437 AND o.rn = 1 THEN val END) AS lumps,
    MAX(CASE WHEN o.concept_id = 58442 AND o.rn = 1 THEN val END) AS birth_injuries,
    MAX(CASE WHEN o.concept_id = 58521 AND o.rn = 1 THEN val END) AS past_stis,
    MAX(CASE WHEN o.concept_id = 58558 AND o.rn = 1 THEN val END) AS syphilis_serologically_diagnosed,
    MAX(CASE WHEN o.concept_id = 58600 AND o.rn = 1 THEN val END) AS babinski,
    MAX(CASE WHEN o.concept_id = 58612 AND o.rn = 1 THEN val END) AS capillary_refill_less_than_3_seconds,
    MAX(CASE WHEN o.concept_id = 58621 AND o.rn = 1 THEN val END) AS coldness,
    MAX(CASE WHEN o.concept_id = 58632 AND o.rn = 1 THEN val END) AS degree_of_perineal_tear,
    MAX(CASE WHEN o.concept_id = 58633 AND o.rn = 1 THEN val END) AS degree_of_tear,
    MAX(CASE WHEN o.concept_id = 58634 AND o.rn = 1 THEN val END) AS descended_testicles,
    MAX(CASE WHEN o.concept_id = 58640 AND o.rn = 1 THEN val END) AS ear_discharges,
    MAX(CASE WHEN o.concept_id = 58659 AND o.rn = 1 THEN val END) AS false_teeth,
    MAX(CASE WHEN o.concept_id = 58664 AND o.rn = 1 THEN val END) AS fontanelles,
    MAX(CASE WHEN o.concept_id = 58669 AND o.rn = 1 THEN val END) AS grasping,
    MAX(CASE WHEN o.concept_id = 58722 AND o.rn = 1 THEN val END) AS missing_digits,
    MAX(CASE WHEN o.concept_id = 58727 AND o.rn = 1 THEN val END) AS murmurs,
    MAX(CASE WHEN o.concept_id = 58738 AND o.rn = 1 THEN val END) AS nose_deformities,
    MAX(CASE WHEN o.concept_id = 58739 AND o.rn = 1 THEN val END) AS nose_discharges,
    MAX(CASE WHEN o.concept_id = 58741 AND o.rn = 1 THEN val END) AS nose_shape,
    MAX(CASE WHEN o.concept_id = 58767 AND o.rn = 1 THEN val END) AS patent_anus,
    MAX(CASE WHEN o.concept_id = 58802 AND o.rn = 1 THEN val END) AS rooting,
    MAX(CASE WHEN o.concept_id = 58808 AND o.rn = 1 THEN val END) AS short_neck,
    MAX(CASE WHEN o.concept_id = 58823 AND o.rn = 1 THEN val END) AS stepping,
    MAX(CASE WHEN o.concept_id = 58872 AND o.rn = 1 THEN val END) AS webbing,
    MAX(CASE WHEN o.concept_id = 58873 AND o.rn = 1 THEN o.value_numeric END) AS weight_grams,
    MAX(CASE WHEN o.concept_id = 58887 AND o.rn = 1 THEN o.value_text END) AS art_regimen,
    MAX(CASE WHEN o.concept_id = 58895 AND o.rn = 1 THEN o.value_text END) AS condition_on_referral,
    MAX(CASE WHEN o.concept_id = 58897 AND o.rn = 1 THEN val END) AS fetal_conditions,
    MAX(CASE WHEN o.concept_id = 58903 AND o.rn = 1 THEN val END) AS maternal_conditions,
    MAX(CASE WHEN o.concept_id = 58910 AND o.rn = 1 THEN o.value_text END) AS past_modes_of_delivery_other_specify,
    MAX(CASE WHEN o.concept_id = 58911 AND o.rn = 1 THEN val END) AS placenta_conditions,
    MAX(CASE WHEN o.concept_id = 58922 AND o.rn = 1 THEN o.value_text END) AS specify_other_facility,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 58924 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS type_of_immunization_the_baby_received,
    MAX(CASE WHEN o.concept_id = 58984 AND o.rn = 1 THEN val END) AS ambiguous_genitalia,
    MAX(CASE WHEN o.concept_id = 59065 AND o.rn = 1 THEN val END) AS abdomen_abdominal_wall_defects,
    MAX(CASE WHEN o.concept_id = 59066 AND o.rn = 1 THEN val END) AS abdomen_bleeding_from_cord,
    MAX(CASE WHEN o.concept_id = 59069 AND o.rn = 1 THEN val END) AS abdomen_organomegaly,
    MAX(CASE WHEN o.concept_id = 59070 AND o.rn = 1 THEN val END) AS abdomen_umbilicus_red,
    MAX(CASE WHEN o.concept_id = 59074 AND o.rn = 1 THEN val END) AS attachment,
    MAX(CASE WHEN o.concept_id = 59075 AND o.rn = 1 THEN val END) AS audible_suck,
    MAX(CASE WHEN o.concept_id = 59079 AND o.rn = 1 THEN val END) AS baby_hiv_positive,
    MAX(CASE WHEN o.concept_id = 59098 AND o.rn = 1 THEN val END) AS did_the_baby_cry_at_birth,
    MAX(CASE WHEN o.concept_id = 59107 AND o.rn = 1 THEN o.value_text END) AS fetal_other_specify,
    MAX(CASE WHEN o.concept_id = 59115 AND o.rn = 1 THEN o.value_text END) AS gbv,
    MAX(CASE WHEN o.concept_id = 59127 AND o.rn = 1 THEN val END) AS mental_health_concerns_at_visit,
    MAX(CASE WHEN o.concept_id = 59129 AND o.rn = 1 THEN val END) AS mother_has_concerns_about_feeding,
    MAX(CASE WHEN o.concept_id = 59132 AND o.rn = 1 THEN val END) AS nipple_shape,
    MAX(CASE WHEN o.concept_id = 59150 AND o.rn = 1 THEN o.value_text END) AS placenta_other_specify,
    MAX(CASE WHEN o.concept_id = 59152 AND o.rn = 1 THEN val END) AS postpartum_family_planning_method_after_6_weeks_breastf,
    MAX(CASE WHEN o.concept_id = 59268 AND o.rn = 1 THEN val END) AS eyes_jaundice,
    MAX(CASE WHEN o.concept_id = 59269 AND o.rn = 1 THEN val END) AS eyes_presence_of_the_eye_ball,
    MAX(CASE WHEN o.concept_id = 59270 AND o.rn = 1 THEN val END) AS ear_shape,
    MAX(CASE WHEN o.concept_id = 59271 AND o.rn = 1 THEN val END) AS ear_level,
    MAX(CASE WHEN o.concept_id = 59272 AND o.rn = 1 THEN val END) AS ear_blockage,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 59275 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS sucking_reflex,
    MAX(CASE WHEN o.concept_id = 59278 AND o.rn = 1 THEN val END) AS abdomen_pus_from_cord,
    MAX(CASE WHEN o.concept_id = 59279 AND o.rn = 1 THEN val END) AS abdomen_cord_dry,
    MAX(CASE WHEN o.concept_id = 59280 AND o.rn = 1 THEN val END) AS abdomen_foul_smelling_cord,
    MAX(CASE WHEN o.concept_id = 59283 AND o.rn = 1 THEN val END) AS required_orifices_present,
    MAX(CASE WHEN o.concept_id = 59284 AND o.rn = 1 THEN val END) AS female_discharges,
    MAX(CASE WHEN o.concept_id = 59285 AND o.rn = 1 THEN val END) AS erb_s_palsy_bronchial_nerve_injury,
    MAX(CASE WHEN o.concept_id = 59406 AND o.rn = 1 THEN val END) AS has_the_woman_been_initiated_on_art_treatment,
    MAX(CASE WHEN o.concept_id = 59464 AND o.rn = 1 THEN val END) AS ear_symmetry,
    MAX(CASE WHEN o.concept_id = 59473 AND o.rn = 1 THEN val END) AS eyes_discharges,
    GROUP_CONCAT(DISTINCT CASE WHEN o.concept_id = 59499 THEN o.val END ORDER BY o.val SEPARATOR '; ') AS health_education_topics,
    MAX(CASE WHEN o.concept_id = 59500 AND o.rn = 1 THEN val END) AS itn_provided,
    MAX(CASE WHEN o.concept_id = 59501 AND o.rn = 1 THEN val END) AS baby_vaccines_given,
    MAX(CASE WHEN o.concept_id = 59502 AND o.rn = 1 THEN val END) AS abdomen_granuloma
    FROM decoded o
    GROUP BY o.location_id, o.person_id, o.visit_date
),

patients AS (
    SELECT
        p.person_id,
        p.gender,
        p.birthdate,
        p.birthdate_estimated,
        fv.first_pnc_visit,
        TIMESTAMPDIFF(YEAR, p.birthdate, fv.first_pnc_visit) AS age_years_at_first_pnc_visit,
        CASE WHEN p.birthdate IS NULL THEN 'unknown'
             WHEN TIMESTAMPDIFF(YEAR, p.birthdate, fv.first_pnc_visit) < 5 THEN 'baby' ELSE 'woman' END AS record_type,
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
        SELECT r.person_b AS person_id,
            GROUP_CONCAT(DISTINCT r.person_a ORDER BY r.person_a SEPARATOR '; ') AS related_person_ids,
            GROUP_CONCAT(DISTINCT CONCAT(t.a_is_to_b, ' of this person') ORDER BY t.a_is_to_b SEPARATOR '; ') AS related_relationships
        FROM relationship r
        INNER JOIN relationship_type t ON t.relationship_type_id = r.relationship
        WHERE r.voided = 0
        GROUP BY r.person_b
    ) rel ON rel.person_id = p.person_id
    INNER JOIN (
        SELECT e.patient_id, MIN(DATE(e.encounter_datetime)) AS first_pnc_visit
        FROM encounter e WHERE e.program_id = 35 AND e.voided = 0 GROUP BY e.patient_id
    ) fv ON fv.patient_id = p.person_id
    WHERE p.voided = 0
),

other_progs AS (
    -- HIV / ART details recorded in other programs for the same women (latest value); the date can differ from the PNC visit
    SELECT x.person_id,
        MAX(CASE WHEN x.grp = 'hiv_status' AND x.rn = 1 THEN x.val END) AS other_programs_hiv_status,
        MAX(CASE WHEN x.grp = 'art_number' AND x.rn = 1 THEN x.val END) AS other_programs_art_number,
        MAX(CASE WHEN x.grp = 'facility_for_art' AND x.rn = 1 THEN x.val END) AS other_programs_facility_for_art
    FROM (
        SELECT o.person_id,
            CASE WHEN o.concept_id IN (52925, 56097) THEN 'hiv_status' WHEN o.concept_id IN (55214, 55178) THEN 'art_number' ELSE 'facility_for_art' END AS grp,
            COALESCE((SELECT cn.name FROM concept_name cn WHERE cn.concept_id = o.value_coded AND cn.voided = 0
                      ORDER BY (cn.locale = 'en') DESC, (cn.concept_name_type = 'FULLY_SPECIFIED') DESC, cn.concept_name_id LIMIT 1),
                     o.value_text, CAST(o.value_numeric AS char), CAST(o.value_datetime AS char)) AS val,
            ROW_NUMBER() OVER (PARTITION BY o.person_id,
                CASE WHEN o.concept_id IN (52925, 56097) THEN 1 WHEN o.concept_id IN (55214, 55178) THEN 2 ELSE 3 END
                ORDER BY o.obs_datetime DESC, o.obs_id DESC) AS rn
        FROM obs o
        INNER JOIN encounter e ON e.encounter_id = o.encounter_id AND e.voided = 0 AND e.program_id IN (1, 12, 36)
        WHERE o.voided = 0 AND o.concept_id IN (52925, 56097, 55214, 55178, 47756)
            AND o.person_id IN (SELECT person_id FROM patients)
            AND (o.value_coded IS NOT NULL OR o.value_numeric IS NOT NULL OR o.value_text IS NOT NULL OR o.value_datetime IS NOT NULL)
    ) x
    GROUP BY x.person_id
),

ward_counts AS (
    -- ward-monitoring rounds (one encounter each) per person / day; the values are in the ward datasets
    SELECT x.location_id, x.person_id, x.visit_date,
        SUM(x.etype = 'PNC ward monitoring mother') AS number_of_ward_mother_rounds,
        SUM(x.etype = 'PNC ward monitoring baby') AS number_of_ward_baby_rounds
    FROM (
        SELECT o.location_id, o.person_id, o.encounter_id, et.name AS etype, DATE(MIN(o.obs_datetime)) AS visit_date
        FROM obs o
        INNER JOIN encounter e ON e.encounter_id = o.encounter_id AND e.program_id = 35 AND e.voided = 0
        INNER JOIN encounter_type et ON et.encounter_type_id = e.encounter_type AND et.name IN ('PNC ward monitoring mother', 'PNC ward monitoring baby')
        WHERE o.voided = 0
        GROUP BY o.location_id, o.person_id, o.encounter_id, et.name
    ) x
    GROUP BY x.location_id, x.person_id, x.visit_date
)

SELECT
    a.*,
    p.gender, p.birthdate, p.birthdate_estimated, p.first_pnc_visit, p.age_years_at_first_pnc_visit, p.record_type,
    p.related_person_ids, p.related_relationships, p.dead, p.death_date, p.arv_number_identifier,
    COALESCE(wc.number_of_ward_mother_rounds, 0) AS number_of_ward_mother_rounds,
    COALESCE(wc.number_of_ward_baby_rounds, 0) AS number_of_ward_baby_rounds,
    op.other_programs_hiv_status, op.other_programs_art_number, op.other_programs_facility_for_art
FROM pnc_pivot a
INNER JOIN patients p ON p.person_id = a.person_id
LEFT JOIN other_progs op ON op.person_id = a.person_id
LEFT JOIN ward_counts wc ON wc.location_id = a.location_id AND wc.person_id = a.person_id AND wc.visit_date = a.visit_date
ORDER BY a.location_id, a.person_id, a.visit_date;

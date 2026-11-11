-- ANC dictionary fields (Required = Yes / Conditional) with no column in the pivot (cannot be assessed until extracted)
-- 226 further dictionary fields are Required = No (optional) and are not assessed
SELECT dictionary_name, label, section, requirement, condition_text FROM (
    SELECT 'anc_qc_specify_danger_signs' AS dictionary_name, 'Specify the danger signs' AS label, 'page 1' AS section, 'CONDITIONAL' AS requirement, 'Shown when selection includes ''Other''' AS condition_text
    UNION ALL
    SELECT 'anc_qc_referral_required' AS dictionary_name, 'Do you want to refer the woman?' AS label, 'page 1' AS section, 'CONDITIONAL' AS requirement, 'Shown when selection includes ''None''' AS condition_text
    UNION ALL
    SELECT 'anc_qc_other_specify' AS dictionary_name, 'What are the specific health concerns for the patient - other (specify)' AS label, 'page 1' AS section, 'CONDITIONAL' AS requirement, 'Shown when selection includes ''Other''' AS condition_text
    UNION ALL
    SELECT 'anc_curr_preg_gestation_age_from_ultr' AS dictionary_name, 'Gestation age from ultrasound' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_curr_preg_tt6_date' AS dictionary_name, 'TTV 1 immunisation date' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_curr_preg_tt7_date' AS dictionary_name, 'TTV 1 immunisation date' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_curr_preg_tt8_date' AS dictionary_name, 'TTV 2 immunisation date' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_curr_preg_tt9_date' AS dictionary_name, 'TTV 1 immunisation date' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_curr_preg_tt10_date' AS dictionary_name, 'TTV 2 immunisation date' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_curr_preg_tt11_date' AS dictionary_name, 'TTV 3 immunisation date' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_curr_preg_tt3_date' AS dictionary_name, 'TTV 3 immunisation date' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_curr_preg_tt4_date' AS dictionary_name, 'TTV 4 immunisation date' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_curr_preg_tt5_date' AS dictionary_name, 'TTV 5 immunisation date' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_curr_preg_12' AS dictionary_name, 'TTV 1 immunisation date' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_curr_preg_13' AS dictionary_name, 'TTV 2 immunisation date' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_curr_preg_14' AS dictionary_name, 'TTV 3 immunisation date' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_curr_preg_15' AS dictionary_name, 'TTV 4 immunisation date' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_curr_preg_other' AS dictionary_name, 'conducted Specify other reasons PAST OBSTETRIC HISTORY' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_ob_hist_other_complications_notes' AS dictionary_name, 'complications during the past pregnancies? Specify other complications' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_ob_hist_other_notes' AS dictionary_name, 'Specify GYNAECOLOGICAL HISTORY' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_med_hist_other_chronic_notes' AS dictionary_name, 'Specify other chronic conditions' AS label, 'page 2' AS section, 'CONDITIONAL' AS requirement, 'Shown when selection includes ''Other''' AS condition_text
    UNION ALL
    SELECT 'anc_med_hist_facility_art' AS dictionary_name, 'Facility for ART' AS label, 'page 2' AS section, 'CONDITIONAL' AS requirement, 'Shown when selection includes ''hiv positive''' AS condition_text
    UNION ALL
    SELECT 'anc_med_hist_other_notes' AS dictionary_name, 'Specify' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_med_hist_specify' AS dictionary_name, 'Specify' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_med_hist_syphilis_date' AS dictionary_name, 'Syphilis test date' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_med_hist_reason' AS dictionary_name, 'Specify CURRENT MEDICATIONS' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_meds_other_medication_notes' AS dictionary_name, 'prescribed? Specify other medications WOMAN''S BEHAVIOUR & LIFESTYLE' AS label, 'page 2' AS section, 'CONDITIONAL' AS requirement, 'Shown when selection includes ''Other''' AS condition_text
    UNION ALL
    SELECT 'anc_behav_recently_quit_tobacco_prod' AS dictionary_name, 'Recently quit tobacco products' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_behav_exposure_second_hand_sm' AS dictionary_name, 'Exposure to second hand smoke' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_behav_pica' AS dictionary_name, 'Pica' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_behav_alcohol' AS dictionary_name, 'Alcohol Intake VITAL SIGNS' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_vitals_pre_gestation_weight' AS dictionary_name, 'Pre-gestation weight' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_vitals_height_weight_reason' AS dictionary_name, 'Specify Reason' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_vitals_blood_pressure_reason' AS dictionary_name, 'Specify Reason' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_vitals_pulse_rate_reason' AS dictionary_name, 'Specify Reason' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_mat_exam_other_respiratory_findi' AS dictionary_name, 'Specify other respiratory findings' AS label, 'page 3' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_mat_exam_other_notes' AS dictionary_name, 'Specify the action taken' AS label, 'page 3' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_malaria_specify' AS dictionary_name, 'Reason no preventative treatment provided -' AS label, 'page 5' AS section, 'CONDITIONAL' AS requirement, 'Shown when ''antihelminthic treatment'' = ''No'' and ''no' AS condition_text
    UNION ALL
    SELECT 'anc_malaria_counselling_malaria_prev' AS dictionary_name, 'other (specify) Was counselling on malaria prevention' AS label, 'page 5' AS section, 'MANDATORY' AS requirement, 'preventative treatment provided'' = ''Other''' AS condition_text
    UNION ALL
    SELECT 'anc_malaria_counselling_malaria_prev' AS dictionary_name, 'conducted Reason no counselling on malaria prevention' AS label, 'page 5' AS section, 'CONDITIONAL' AS requirement, 'Shown when ''counselling on malaria prevention'' =' AS condition_text
    UNION ALL
    SELECT 'anc_malaria_other_specify' AS dictionary_name, 'was not conducted Reason no counselling on malaria prevention was not conducted - other (specify) IMMUNISATION' AS label, 'page 5' AS section, 'CONDITIONAL' AS requirement, '''No'' Shown when ''counselling on malaria prevention'' = ''No'' and ''counselling on malaria prevention not conducted'' = ''Other''' AS condition_text
    UNION ALL
    SELECT 'anc_outcome_date_death' AS dictionary_name, '(specify) Date of death' AS label, 'page 5' AS section, 'CONDITIONAL' AS requirement, 'outcome'' Shown when ''ANC pregnancy outcome'' = ''Death''' AS condition_text
    UNION ALL
    SELECT 'anc_outcome_cause_death' AS dictionary_name, 'Cause of Death' AS label, 'page 5' AS section, 'CONDITIONAL' AS requirement, 'Shown when ''ANC pregnancy outcome'' = ''Death''' AS condition_text
    UNION ALL
    SELECT 'anc_outcome_specify' AS dictionary_name, 'Place of delivery - other (specify)' AS label, 'page 5' AS section, 'CONDITIONAL' AS requirement, 'Shown when ''Place of Delivery'' = ''Other''' AS condition_text
    UNION ALL
    SELECT 'anc_outcome_weight' AS dictionary_name, 'Birth weight (grams) REFERRAL' AS label, 'page 5' AS section, 'CONDITIONAL' AS requirement, 'Shown when ''ANC pregnancy outcome'' = ''Live birth''' AS condition_text
    UNION ALL
    SELECT 'anc_ref_referral_urgent_care' AS dictionary_name, 'Referral for urgent care' AS label, 'page 5' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_ref_treatment_given_before_referr' AS dictionary_name, 'Any treatment given before referral?' AS label, 'page 5' AS section, 'MANDATORY' AS requirement, 'general services''' AS condition_text
    UNION ALL
    SELECT 'anc_ref_provisional_diagnosis' AS dictionary_name, 'provided on referral? Provisional Diagnosis' AS label, 'page 5' AS section, 'MANDATORY' AS requirement, '''Yes''' AS condition_text
    UNION ALL
    SELECT 'anc_ref_referral_facility' AS dictionary_name, 'Facility' AS label, 'page 5' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_ref_date_referral_made' AS dictionary_name, 'Referral Appointment Date' AS label, 'page 6' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_ref_time_referral_made' AS dictionary_name, 'Referral Appointment Time' AS label, 'page 6' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'anc_ref_referral_notes' AS dictionary_name, 'Referral notes' AS label, 'page 6' AS section, 'MANDATORY' AS requirement, '' AS condition_text
) x ORDER BY section, requirement, dictionary_name;

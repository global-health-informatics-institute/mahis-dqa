-- Labour & Delivery dictionary fields (Required = Yes / Conditional) with no column in the pivot (cannot be assessed until extracted)
-- 262 further dictionary fields are Required = No (optional) and are not assessed
SELECT dictionary_name, label, section, requirement, condition_text FROM (
    SELECT 'ld_qc_reason_other' AS dictionary_name, 'Specify other medical/obstetric condition' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_qc_other_c' AS dictionary_name, 'Specify' AS label, 'page 1' AS section, 'CONDITIONAL' AS requirement, 'Shown when selection includes ''other danger signs''' AS condition_text
    UNION ALL
    SELECT 'ld_ob_hist_para' AS dictionary_name, 'Para' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_ob_hist_last_hb_result' AS dictionary_name, 'Last HB result' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_ob_hist_other_c' AS dictionary_name, 'Specify CURRENT LABOUR DETAILS' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_labour_specify' AS dictionary_name, 'Specify' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_labour_amount_bleeding' AS dictionary_name, 'Amount of bleeding PROFILE - CHRONIC HEALTH CONDITIONS' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_chronic_other_notes' AS dictionary_name, 'Health Conditions? Specify other chronic conditions' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_chronic_specify' AS dictionary_name, 'Specify' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_chronic_syphilis_date' AS dictionary_name, 'Syphilis test date' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_chronic_reason' AS dictionary_name, 'Specify PROFILE - ALLERGIES' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_allergy_other_notes' AS dictionary_name, 'Specify PROFILE - MEDICATIONS' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_meds_other_notes' AS dictionary_name, 'prescribed? Specify other medications PROFILE - PAST SURGERIES' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_surgery_other_notes' AS dictionary_name, 'Specify PROFILE - PAST PREGNANCY COMPLICATIONS' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_past_compl_other_notes' AS dictionary_name, 'complications during the past pregnancies? Specify PROFILE - VACCINE HISTORY' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_vaccine_tt6_date' AS dictionary_name, 'TTV 1 immunisation date' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_vaccine_tt7_date' AS dictionary_name, 'TTV 1 immunisation date' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_vaccine_tt8_date' AS dictionary_name, 'TTV 2 immunisation date' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_vaccine_tt9_date' AS dictionary_name, 'TTV 1 immunisation date' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_vaccine_tt10_date' AS dictionary_name, 'TTV 2 immunisation date' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_vaccine_tt11_date' AS dictionary_name, 'TTV 3 immunisation date' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_vaccine_tt3_date' AS dictionary_name, 'TTV 3 immunisation date' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_vaccine_tt4_date' AS dictionary_name, 'TTV 4 immunisation date' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_vaccine_tt5_date' AS dictionary_name, 'TTV 5 immunisation date' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_vaccine_12' AS dictionary_name, 'TTV 1 immunisation date' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_vaccine_13' AS dictionary_name, 'TTV 2 immunisation date' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_vaccine_14' AS dictionary_name, 'TTV 3 immunisation date' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_vaccine_15' AS dictionary_name, 'TTV 4 immunisation date' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_vaccine_other' AS dictionary_name, 'conducted Specify other reasons PROFILE - WOMAN''S BEHAVIOUR' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_exam_other_oedema' AS dictionary_name, 'Specify' AS label, 'page 3' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_exam_other' AS dictionary_name, 'Specify Presentation FETAL PRESENTATION' AS label, 'page 3' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_ve_specify' AS dictionary_name, 'Specify' AS label, 'page 3' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_mon_vitals_height_weight_reason' AS dictionary_name, 'Specify Reason' AS label, 'page 3' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_mon_vitals_blood_pressure_reason' AS dictionary_name, 'Specify Reason' AS label, 'page 3' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_mon_vitals_pulse_rate_reason' AS dictionary_name, 'Specify Reason' AS label, 'page 3' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_mon_exam_intervention' AS dictionary_name, 'Enter intervention carried out' AS label, 'page 3' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_mon_exam_specify' AS dictionary_name, 'Specify' AS label, 'page 4' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_del_estimated_blood_loss' AS dictionary_name, 'Estimated blood loss' AS label, 'page 4' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_del_first_name' AS dictionary_name, 'First name' AS label, 'page 4' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_del_last_name' AS dictionary_name, 'Last name' AS label, 'page 4' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_del_other_notes' AS dictionary_name, 'Specify' AS label, 'page 4' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_third_specify' AS dictionary_name, 'Specify' AS label, 'page 5' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_third_other_mode_delivery_notes' AS dictionary_name, 'Specify' AS label, 'page 5' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_third_other_tears' AS dictionary_name, 'Specify' AS label, 'page 5' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_third_tears_degree' AS dictionary_name, 'Specify degree' AS label, 'page 5' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_third_other_perineum_condition' AS dictionary_name, 'Specify IMMEDIATE POSTNATAL CHECKS - MOTHER' AS label, 'page 6' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'ld_post_mom_systolic_blood_pressure' AS dictionary_name, 'Systolic Pressure' AS label, 'page 6' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_post_mom_diastolic_blood_pressure' AS dictionary_name, 'Diastolic pressure' AS label, 'page 6' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_post_mom_second_systolic_blood_p' AS dictionary_name, 'Second Systolic Pressure' AS label, 'page 6' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_post_mom_second_diastolic_blood_' AS dictionary_name, 'Second Diastolic pressure' AS label, 'page 6' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_post_mom_time' AS dictionary_name, 'Time' AS label, 'page 6' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_post_mom_amount_urine' AS dictionary_name, 'Amount of urine' AS label, 'page 6' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_post_mom_color_urine' AS dictionary_name, 'Color of urine IMMEDIATE POSTNATAL CHECKS - BABY' AS label, 'page 6' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_ref_baby_identifier_specify' AS dictionary_name, 'Reason for referring baby - other (specify)' AS label, 'page 6' AS section, 'CONDITIONAL' AS requirement, 'Shown when selection includes ''other reason''' AS condition_text
    UNION ALL
    SELECT 'ld_ref_date_referral' AS dictionary_name, 'referral? Date of referral' AS label, 'page 6' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_ref_time_referral' AS dictionary_name, 'Time of referral' AS label, 'page 6' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_ref_provider_who_made_referral' AS dictionary_name, 'Provider who made referral' AS label, 'page 6' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_ref_phone_number' AS dictionary_name, 'Phone number for provider' AS label, 'page 6' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_end_closing_labour_delivery' AS dictionary_name, 'Reason for closing labour and delivery' AS label, 'page 6' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'ld_end_specify' AS dictionary_name, 'record Reason for closing labour and delivery record - other (specify)' AS label, 'page 6' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
) x ORDER BY section, requirement, dictionary_name;

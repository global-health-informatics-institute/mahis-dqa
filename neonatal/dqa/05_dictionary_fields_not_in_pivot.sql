-- Dictionary fields with no column in the pivot (cannot be assessed until extracted)
SELECT dictionary_name, label, section, requirement, condition_text FROM (
    SELECT 'nn_birth_twin_patient' AS dictionary_name, 'Search and select twin' AS label, 'Enrollment' AS section, 'CONDITIONAL' AS requirement, 'Does the baby have a twin? = Yes' AS condition_text
    UNION ALL
    SELECT 'nn_birth_place_birth_other' AS dictionary_name, 'Specify other place of birth' AS label, 'Enrollment' AS section, 'CONDITIONAL' AS requirement, 'Place of birth = Other' AS condition_text
    UNION ALL
    SELECT 'nn_ref_in_referred_from_other' AS dictionary_name, 'Specify other referral source' AS label, 'Enrollment' AS section, 'CONDITIONAL' AS requirement, 'Referred from = Other' AS condition_text
    UNION ALL
    SELECT 'nn_ref_in_mode_transport_other' AS dictionary_name, 'Specify other mode of transport' AS label, 'Enrollment' AS section, 'CONDITIONAL' AS requirement, 'Mode of transport = Other' AS condition_text
    UNION ALL
    SELECT 'nn_ref_in_admitted_from_other' AS dictionary_name, 'Specify other admission origin' AS label, 'Enrollment' AS section, 'CONDITIONAL' AS requirement, 'Admitted from = Other' AS condition_text
    UNION ALL
    SELECT 'nn_birth_assess_bvm_duration' AS dictionary_name, 'Duration of Bag Valve Mask ventilation' AS label, 'Enrollment' AS section, 'CONDITIONAL' AS requirement, 'Resuscitation includes BVM' AS condition_text
    UNION ALL
    SELECT 'nn_preg_hist_type_rupture_membranes' AS dictionary_name, 'Type of rupture of membranes' AS label, 'Enrollment' AS section, 'CONDITIONAL' AS requirement, 'Rupture of membranes = Yes' AS condition_text
    UNION ALL
    SELECT 'nn_mother_mother_on_art' AS dictionary_name, 'Is the mother on ART?' AS label, 'Enrollment' AS section, 'CONDITIONAL' AS requirement, 'Mother HIV status = Reactive' AS condition_text
    UNION ALL
    SELECT 'nn_mother_baby_given2p' AS dictionary_name, 'Was 2P given?' AS label, 'Enrollment' AS section, 'CONDITIONAL' AS requirement, 'Mother HIV status = Reactive' AS condition_text
    UNION ALL
    SELECT 'nn_mother_mother_tested_hepatitis' AS dictionary_name, 'Was the mother tested for Hepatitis?' AS label, 'Enrollment' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'nn_mother_mother_hepatitis_result' AS dictionary_name, 'Mother''s Hepatitis result' AS label, 'Enrollment' AS section, 'CONDITIONAL' AS requirement, 'Mother tested for Hepatitis = Yes (trigger not in pivot)' AS condition_text
    UNION ALL
    SELECT 'nn_triage_dehydration_level_primary' AS dictionary_name, 'Level of dehydration' AS label, 'Triage' AS section, 'CONDITIONAL' AS requirement, 'Is the baby dehydrated = Yes' AS condition_text
    UNION ALL
    SELECT 'nn_triage_first_name' AS dictionary_name, 'First name (not extracted by design)' AS label, 'Triage' AS section, 'MANDATORY' AS requirement, 'Baby not yet registered' AS condition_text
    UNION ALL
    SELECT 'nn_triage_last_name' AS dictionary_name, 'Last name (not extracted by design)' AS label, 'Triage' AS section, 'MANDATORY' AS requirement, 'Baby not yet registered' AS condition_text
    UNION ALL
    SELECT 'nn_signs_presenting_complaints_other' AS dictionary_name, 'Specify other sign/symptom' AS label, 'Signs & Symptoms' AS section, 'CONDITIONAL' AS requirement, 'Presenting complaint includes Other' AS condition_text
    UNION ALL
    SELECT 'nn_gen_exam_baby_oedema' AS dictionary_name, 'Does the baby have oedema?' AS label, 'Physical Exam' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'nn_gen_exam_congenital_abnormalities_type' AS dictionary_name, 'Type of congenital abnormality' AS label, 'Physical Exam' AS section, 'CONDITIONAL' AS requirement, 'Congenital abnormalities = Yes' AS condition_text
    UNION ALL
    SELECT 'nn_gen_exam_congenital_abnormalities_description' AS dictionary_name, 'Describe the congenital abnormality' AS label, 'Physical Exam' AS section, 'CONDITIONAL' AS requirement, 'Type = Other' AS condition_text
    UNION ALL
    SELECT 'nn_ros_why_baby_not_feeding' AS dictionary_name, 'Why is the baby not feeding?' AS label, 'Review of Systems' AS section, 'CONDITIONAL' AS requirement, 'Is the baby feeding = No' AS condition_text
    UNION ALL
    SELECT 'nn_ros_frequency_vomiting' AS dictionary_name, 'Number of times the baby vomited' AS label, 'Review of Systems' AS section, 'CONDITIONAL' AS requirement, 'Is the baby vomiting = Yes' AS condition_text
    UNION ALL
    SELECT 'nn_ros_volume_ml' AS dictionary_name, 'Volume (ml)' AS label, 'Review of Systems' AS section, 'CONDITIONAL' AS requirement, 'Passing urine = Yes and catheterized = Yes' AS condition_text
    UNION ALL
    SELECT 'nn_sys_chest_jaundice_severity' AS dictionary_name, 'Severity of jaundice' AS label, 'Systemic Exam' AS section, 'MANDATORY' AS requirement, 'Color = Yellow' AS condition_text
    UNION ALL
    SELECT 'nn_inv_test / nn_inv_specimen' AS dictionary_name, 'Lab order test and specimen' AS label, 'Lab Orders' AS section, 'MANDATORY' AS requirement, 'Lab ordered (only test type / status extracted)' AS condition_text
    UNION ALL
    SELECT 'nn_tx_other_medication' AS dictionary_name, 'Specify other medication' AS label, 'Treatment' AS section, 'CONDITIONAL' AS requirement, 'Selection includes Other' AS condition_text
    UNION ALL
    SELECT 'nn_adm_outcome_clinical_review_outcome_other' AS dictionary_name, 'Specify other outcome' AS label, 'Clinical Review Outcome' AS section, 'CONDITIONAL' AS requirement, 'Outcome = Other' AS condition_text
    UNION ALL
    SELECT 'nn_disch_outcome_outcome' AS dictionary_name, 'Discharge - what happened to the baby?' AS label, 'Discharge' AS section, 'MANDATORY' AS requirement, '' AS condition_text
    UNION ALL
    SELECT 'nn_disch_outcome_transfer_facility / _ward' AS dictionary_name, 'Receiving facility / ward' AS label, 'Discharge' AS section, 'CONDITIONAL' AS requirement, 'Outcome = Transferred' AS condition_text
    UNION ALL
    SELECT 'nn_disch_vitals_*' AS dictionary_name, 'Discharge vitals (weight, HR, RR, sats, temperature)' AS label, 'Discharge' AS section, 'MANDATORY' AS requirement, 'Outcome is not death/absconded' AS condition_text
    UNION ALL
    SELECT 'nn_disch_dx_main_diagnosis' AS dictionary_name, 'Discharge diagnosis' AS label, 'Discharge' AS section, 'MANDATORY' AS requirement, 'Outcome is not death/absconded' AS condition_text
    UNION ALL
    SELECT 'nn_disch_edu_health_education_given / insecticide net' AS dictionary_name, 'Discharge health education / ITN' AS label, 'Discharge' AS section, 'MANDATORY' AS requirement, 'Outcome is not death/absconded' AS condition_text
    UNION ALL
    SELECT 'nn_disch_signoff_*' AS dictionary_name, 'Discharge sign-off' AS label, 'Discharge' AS section, 'MANDATORY' AS requirement, '' AS condition_text
) x ORDER BY section, requirement, dictionary_name;

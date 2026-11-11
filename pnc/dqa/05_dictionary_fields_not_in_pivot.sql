-- PNC dictionary fields (Required = Yes / Conditional) with no column in the pivot (cannot be assessed until extracted)
-- 127 further dictionary fields are Required = No (optional) and are not assessed
SELECT dictionary_name, label, section, requirement, condition_text FROM (
    SELECT 'pnc_hiv_new_hiv_status' AS dictionary_name, 'New HIV test result in postnatal' AS label, 'page 1' AS section, 'MANDATORY' AS requirement, 'dictionary marks Required=Yes; no column in the PNC pivot' AS condition_text
    UNION ALL
    SELECT 'pnc_disch_other_mode_delivery_notes' AS dictionary_name, 'Specify' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, 'free-text ''Specify'' follow-up marked Required=Yes without a relevance rule' AS condition_text
    UNION ALL
    SELECT 'pnc_disch_date_referral' AS dictionary_name, 'Date of Referral' AS label, 'page 2' AS section, 'MANDATORY' AS requirement, 'dictionary marks Required=Yes without a relevance rule; applies only to referred / dead women; no pivot column' AS condition_text
    UNION ALL
    SELECT 'pnc_ref_date_referral' AS dictionary_name, 'Date of Referral' AS label, 'page 3' AS section, 'MANDATORY' AS requirement, 'dictionary marks Required=Yes without a relevance rule; applies only to referred / dead women; no pivot column' AS condition_text
    UNION ALL
    SELECT 'pnc_end_date_referral' AS dictionary_name, 'Date of Referral' AS label, 'page 3' AS section, 'MANDATORY' AS requirement, 'dictionary marks Required=Yes without a relevance rule; applies only to referred / dead women; no pivot column' AS condition_text
    UNION ALL
    SELECT 'pnc_end_time_death' AS dictionary_name, 'Time of Death' AS label, 'page 3' AS section, 'MANDATORY' AS requirement, 'dictionary marks Required=Yes without a relevance rule; applies only to referred / dead women; no pivot column' AS condition_text
) x ORDER BY section, requirement, dictionary_name;

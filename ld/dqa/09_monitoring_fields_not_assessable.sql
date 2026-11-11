-- LABOUR MONITORING ROUNDS: dictionary fields that cannot be assessed per monitoring round
SELECT dictionary_name, label, reason FROM (
    SELECT 'ld_mon_exam_intervention' AS dictionary_name, 'Enter intervention carried out' AS label, 'no column in the monitoring data' AS reason
    UNION ALL
    SELECT 'ld_mon_exam_specify' AS dictionary_name, 'Specify (free text)' AS label, 'free-text follow-up marked Required=Yes without a relevance rule' AS reason
) x ORDER BY dictionary_name;

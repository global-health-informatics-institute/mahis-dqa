-- PNC VITALS ENCOUNTERS (women): dictionary fields that cannot be assessed per Vitals encounter
SELECT dictionary_name, label, reason FROM (
    SELECT 'pnc_ward_mom_* (ward monitoring mother encounters)' AS dictionary_name, 'Dictionary lists these vitals under ''postnatal ward monitoring - mother''' AS label, 'in the data the mother''s vitals are in the Vitals encounters (assessed here); the ''PNC ward monitoring mother'' encounters hold no vitals' AS reason
) x ORDER BY dictionary_name;

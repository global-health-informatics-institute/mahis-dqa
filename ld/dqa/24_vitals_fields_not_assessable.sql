-- VITALS ENCOUNTERS (women): dictionary fields that cannot be assessed per Vitals encounter
SELECT dictionary_name, label, reason FROM (
    SELECT 'ld_mon_vitals_height_weight_reason / ld_mon_vitals_blood_pressure_reason / ld_mon_vitals_pulse_rate_reason' AS dictionary_name, 'Specify Reason (reading not taken)' AS label, 'the reason is stored in the measurement column itself (e.g. ''Machine not available'')' AS reason
) x ORDER BY dictionary_name;

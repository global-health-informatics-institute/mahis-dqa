"""Generates the DQA SQL scripts from the MNH Neonatal data dictionary rules below.

Edit RULES / NOT_IN_PIVOT here and re-run: python3 build_dqa_scripts.py
Input expected by every generated script: a table or CTE named `mahis_pivot`
(the output of mahis_neonatal_pivot.sql plus the patient columns
gender, birthdate, birthdate_estimated, first_mahis_visit, age_days_at_first_mahis_visit,
dead, death_date, cause_of_death).
"""
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
PIVOT_SQL = os.path.join(HERE, "..", "mahis_neonatal_pivot.sql")

PATIENT_COLS = ["gender", "birthdate", "birthdate_estimated", "first_mahis_visit",
                "age_days_at_first_mahis_visit", "dead", "death_date", "cause_of_death"]


def pivot_columns():
    cols = []
    for line in open(PIVOT_SQL):
        s = line.strip()
        m = re.match(r"MAX\(CASE WHEN lo\.concept_id = \d+ THEN .* END\) AS (\w+),?$", s)
        if m:
            cols.append(m.group(1))
    return cols + PATIENT_COLS


def eq(col, val):
    return f"LOWER({col}) = '{val.lower()}'"


def ne(col, val):
    return f"LOWER({col}) <> '{val.lower()}'"


def has(col, val):
    return f"LOWER({col}) LIKE '%{val.lower()}%'"


M, C = "MANDATORY", "CONDITIONAL"

# (rule_id, dictionary_name, label, encounter_section, requirement, present_expr, applicable_expr or None, trigger_text)
RULES = [
    # ---------------- NEONATAL ENROLLMENT (216)
    ("mother_identifier", "nn_demog_selected_mother", "Search and select mother", "Enrollment", M, "mother_identifier", None, ""),
    ("multiple_birth_type", "nn_birth_twin", "Does the baby have a twin?", "Enrollment", M, "multiple_birth_type", None, ""),
    ("place_of_birth", "nn_birth_place_birth", "Place of birth", "Enrollment", M, "place_of_birth", None, ""),
    ("multiple_birth", "nn_birth_type_birth", "Type of birth", "Enrollment", M, "multiple_birth", None, ""),
    ("birthdate", "nn_birth_birth_date", "Date of birth", "Enrollment", M, "birthdate", None, ""),
    ("type_of_birth", "nn_birth_birth_time", "Time of birth", "Enrollment", M, "COALESCE(type_of_birth, time_of_delivery)", None, "pivot: Time of birth / Time of delivery"),
    ("referred", "nn_ref_in_referred_from_another_facility", "Is the baby referred from another facility?", "Enrollment", M, "referred", None, ""),
    ("cried_after_birth", "nn_birth_assess_cried_after_birth", "Did the baby cry straight after birth?", "Enrollment", M, "COALESCE(cried_after_birth, cried_at_birth)", None, ""),
    ("gestation_in_weeks", "nn_preg_hist_gestation_weeks", "Gestation in weeks", "Enrollment", M, "gestation_in_weeks", None, ""),
    ("gestation_method_assessment", "nn_preg_hist_gestation_method_assessment", "Gestation method assessment", "Enrollment", M, "gestation_method_assessment", None, ""),
    ("onset_of_labor", "nn_preg_hist_onset_labor_date", "Onset of labor date/time", "Enrollment", M, "onset_of_labor", None, ""),
    ("rupture_of_membranes", "nn_preg_hist_rupture_membranes", "Rupture of membranes?", "Enrollment", M, "rupture_of_membranes", None, ""),
    ("offensive_liquor", "nn_preg_hist_offensive_liquor", "Offensive liquor?", "Enrollment", M, "offensive_liquor", None, ""),
    ("mode_of_delivery", "nn_preg_hist_mode_delivery", "Mode of delivery", "Enrollment", M, "mode_of_delivery", None, ""),
    ("meconium_present", "nn_preg_hist_meconium_present", "Meconium present?", "Enrollment", M, "meconium_present", None, ""),
    ("maternal_analgesia", "nn_preg_hist_maternal_analgesia", "Maternal analgesia?", "Enrollment", M, "maternal_analgesia", None, ""),
    ("anesthesia_used", "nn_preg_hist_anesthesia_used", "Anesthesia used?", "Enrollment", M, "anesthesia_used", None, ""),
    ("teo", "nn_preg_hist_teo", "TEO?", "Enrollment", M, "teo", None, ""),
    ("chlorohexidine_cord_care", "nn_preg_hist_chlorohexidine_cord_care", "Chlorohexidine of cord care?", "Enrollment", M, "chlorohexidine_cord_care", None, ""),
    ("vitamin_k_given", "nn_preg_hist_vitamin_kgiven", "Vitamin K given?", "Enrollment", M, "vitamin_k_given", None, ""),
    ("mother_status", "nn_mother_mother_status", "Mother's status", "Enrollment", M, "mother_status", None, ""),
    ("mother_hiv_status", "nn_mother_mother_hiv_status", "Mother HIV status", "Enrollment", M, "COALESCE(mother_hiv_status, hiv_status)", None, "pivot: Mother HIV Status / HIV status"),
    ("last_hiv_test_date", "nn_mother_last_hiv_test_date", "Last HIV test date", "Enrollment", M, "last_hiv_test_date", None, ""),
    ("mother_vdrl_result", "nn_mother_mother_vdrl_result", "Mother's VDRL/Syphilis result", "Enrollment", M, "mother_vdrl_result", None, ""),
    ("baby_tested_hepatitis", "nn_mother_baby_tested_hepatitis", "Was the baby tested for Hepatitis?", "Enrollment", M, "baby_tested_hepatitis", None, ""),
    ("known_medical_condition", "nn_med_cond_known_medical_conditions", "Mother's known medical conditions", "Enrollment", M, "known_medical_condition", None, ""),
    ("tetanus_diphtheria", "nn_med_cond_tetanus_diphtheria", "Tetanus Diphtheria", "Enrollment", M, "tetanus_diphtheria", None, ""),
    # enrollment conditional
    ("birth_facility_name", "nn_birth_birth_facility", "Name of birth facility", "Enrollment", C, "birth_facility_name",
     f"({has('place_of_birth','hospital')} OR {has('place_of_birth','health')}) AND {eq('referred','yes')}",
     "Place of birth = Hospital/Health Center and baby not born at this facility (proxy: referred = Yes)"),
    ("referred_from", "nn_ref_in_referred_from", "Referred from", "Enrollment", C, "referred_from", eq("referred", "yes"), "Referred from another facility = Yes"),
    ("referring_facility_name", "nn_ref_in_referring_facility_name", "Name of referring facility", "Enrollment", C,
     "COALESCE(referring_facility_name, referral_facility)", f"{eq('referred','yes')} AND {ne('referred_from','other')}",
     "Referred = Yes and Referred from <> Other"),
    ("mode_of_transport", "nn_ref_in_mode_transport", "Mode of transport", "Enrollment", C, "mode_of_transport", eq("referred", "yes"), "Referred = Yes"),
    ("admitted_from", "nn_ref_in_admitted_from", "Admitted from", "Enrollment", C, "admitted_from", eq("referred", "yes"), "Referred = Yes"),
    ("apgar_score_1_min", "nn_birth_assess_apgar1", "Apgar score at 1 minute", "Enrollment", C, "apgar_score_1_min", eq("COALESCE(cried_after_birth, cried_at_birth)", "no"), "Cried after birth = No"),
    ("apgar_score_5_min", "nn_birth_assess_apgar5", "Apgar score at 5 minutes", "Enrollment", C, "apgar_score_5_min", eq("COALESCE(cried_after_birth, cried_at_birth)", "no"), "Cried after birth = No"),
    ("apgar_score_10_min", "nn_birth_assess_apgar10", "Apgar score at 10 minutes", "Enrollment", C, "apgar_score_10_min", eq("COALESCE(cried_after_birth, cried_at_birth)", "no"), "Cried after birth = No"),
    ("resuscitation_method", "nn_birth_assess_resuscitation_methods", "Was resuscitation needed at birth?", "Enrollment", C, "resuscitation_method",
     f"NOT ({eq('place_of_birth','home')} AND {eq('COALESCE(cried_after_birth, cried_at_birth)','yes')})",
     "Shown unless Place of birth = Home and Cried after birth = Yes"),
    ("steroids_given", "nn_preg_hist_steroids_given", "Were steroids given?", "Enrollment", C, "steroids_given",
     "CAST(gestation_in_weeks AS DECIMAL(5,1)) > 0 AND CAST(gestation_in_weeks AS DECIMAL(5,1)) < 37", "Gestation in weeks > 0 and < 37"),
    ("ultrasound_scanning", "nn_preg_hist_ultra_sound_scanning", "Ultra sound scanning - USS", "Enrollment", C, "ultrasound_scanning",
     has("gestation_method_assessment", "ultra"), "Gestation method assessment = Ultra Sound Scanning (USS)"),
    ("duration_rupture_membranes", "nn_preg_hist_duration_rupture_membranes", "Duration of rupture of membranes", "Enrollment", C, "duration_rupture_membranes",
     eq("rupture_of_membranes", "yes"), "Rupture of membranes = Yes"),
    ("analgesia_drug", "nn_preg_hist_analgesias_drug", "Analgesia drug", "Enrollment", C, "analgesia_drug", eq("maternal_analgesia", "yes"), "Maternal analgesia = Yes"),
    ("do_hiv_retest", "nn_mother_hiv_retest", "Do a HIV re-test?", "Enrollment", C, "do_hiv_retest",
     ne("COALESCE(mother_hiv_status, hiv_status)", "reactive"), "Mother HIV status <> Reactive"),
    ("baby_given_nvp", "nn_mother_baby_given_nvp", "Was baby given NVP?", "Enrollment", C, "baby_given_nvp",
     eq("COALESCE(mother_hiv_status, hiv_status)", "reactive"), "Mother HIV status = Reactive"),
    ("mother_treated_vdrl", "nn_mother_mother_treated_vdrl", "Was the mother treated for VDRL/Syphilis?", "Enrollment", C, "mother_treated_vdrl",
     ne("mother_vdrl_result", "negative"), "Mother VDRL result <> Negative"),
    ("three_doses_completed", "nn_mother_all_three_doses_completed", "Were all 3 doses completed?", "Enrollment", C, "three_doses_completed",
     eq("mother_treated_vdrl", "yes"), "Mother treated for VDRL = Yes"),
    # ---------------- NEONATAL TRIAGE (213)
    ("tactile_trunk_temperature", "nn_triage_trunk_temperature_status", "Does the trunk feel cold or warm?", "Triage", M, "tactile_trunk_temperature", None, ""),
    ("baby_breathing_status", "nn_triage_breathing", "Is the baby breathing?", "Triage", M, "baby_breathing_status", None, ""),
    ("airway_status", "nn_triage_airway_status", "Airway", "Triage", M, "airway_status", None, ""),
    ("respiratory_rate", "nn_triage_respiratory_rate", "Respiratory rate", "Triage", M, "respiratory_rate", None, ""),
    ("warm_peripherals", "nn_triage_warm_peripherals", "Does the baby have warm peripherals?", "Triage", M, "warm_peripherals", None, ""),
    ("pulse_volume", "nn_triage_pulse_volume_primary", "Pulse volume", "Triage", M, "pulse_volume", None, ""),
    ("avpu", "nn_triage_avpu_primary", "AVPU", "Triage", M, "avpu", None, ""),
    ("convulsions_or_twitching", "nn_triage_convulsions_primary", "Convulsions, seizures or twitching?", "Triage", M, "convulsions_or_twitching", None, ""),
    ("signs_of_dehydration", "nn_triage_dehydration_signs", "Signs of dehydration", "Triage", M, "signs_of_dehydration", None, ""),
    ("pulse", "nn_triage_heart_rate", "Heart rate (bpm)", "Triage", M, "pulse", None, ""),
    ("oxygen_available_at_facility", "nn_triage_oxygen_facility_available", "Is oxygen available at the facility?", "Triage", M, "oxygen_available_at_facility", None, ""),
    ("current_weight", "nn_triage_current_weight", "Current weight", "Triage", M, "COALESCE(current_weight, weight_grams, weight)", None, "pivot: Current weight / Weight (grams) / Weight"),
    ("birth_weight", "nn_triage_birth_weight", "Birth weight", "Triage", M, "birth_weight", None, ""),
    ("gender", "nn_triage_gender", "Gender", "Triage", M, "gender", None, ""),
    ("breathing_triage", "nn_triage_breathing_assessment", "Breathing triage", "Triage", C, "breathing_triage",
     f"{eq('baby_breathing_status','no')} OR {eq('airway_status','blocked')}", "Is the baby breathing = No or Airway = Blocked"),
    ("central_capillary_refill_time", "nn_triage_capillary_refill_time_primary", "Central capillary refill time", "Triage", C, "central_capillary_refill_time",
     eq("warm_peripherals", "no"), "Warm peripherals = No"),
    ("baby_dehydrated", "nn_triage_dehydrated_primary", "Is the baby dehydrated?", "Triage", C, "baby_dehydrated",
     f"signs_of_dehydration IS NOT NULL AND {ne('signs_of_dehydration','none')}", "Signs of dehydration has any sign other than None"),
    ("temperature", "nn_triage_temperature", "Temperature (deg C)", "Triage", C, "temperature", eq("can_measure_temperature", "yes"), "Thermometer available = Yes"),
    ("oxygen_saturation", "nn_triage_oxygen_saturation_vital", "Oxygen sats in air (%)", "Triage", C, "oxygen_saturation", eq("can_measure_oxygen_saturation", "yes"), "Oxygen sats monitor available = Yes"),
    ("oxygen_unavailable_reason", "nn_triage_oxygen_unavailable_reason", "Why isn't O2 available?", "Triage", C, "oxygen_unavailable_reason", eq("oxygen_available_at_facility", "no"), "Oxygen available at facility = No"),
    ("oxygen_saturation_on_oxygen", "nn_triage_saturation_oxygen", "Saturation in oxygen", "Triage", C, "oxygen_saturation_on_oxygen",
     f"{eq('can_measure_oxygen_saturation','yes')} AND {eq('oxygen_available_at_facility','yes')} AND (CAST(oxygen_saturation AS DECIMAL(6,2)) < 90 OR CAST(respiratory_rate AS DECIMAL(6,2)) > 80)",
     "Sats monitor + oxygen available and (Sats in air < 90% or RR > 80)"),
    ("baby_symptomatic_low_blood_sugar", "nn_triage_hypoglycaemia_symptomatic_primary", "Symptomatic with low blood sugar?", "Triage", C, "baby_symptomatic_low_blood_sugar",
     "(LOWER(blood_sugar_unit) LIKE 'mg%' AND CAST(blood_sugar AS DECIMAL(6,2)) < 45) OR (LOWER(blood_sugar_unit) LIKE 'mmol%' AND CAST(blood_sugar AS DECIMAL(6,2)) < 2.5)",
     "Blood sugar low (< 2.5 mmol/L or < 45 mg/dL)"),
    # ---------------- SIGNS & SYMPTOMS (210)
    ("readmission", "nn_adm_readmission", "Is this a re-admission?", "Signs & Symptoms", M, "readmission", None, ""),
    ("presenting_complaint", "nn_signs_presenting_complaints", "Presenting complaints", "Signs & Symptoms", M, "presenting_complaint", None, ""),
    # ---------------- PHYSICAL EXAMINATION BABY (106)
    ("activity", "nn_gen_exam_activity_assessment", "How is the baby's activity?", "Physical Exam", M, "activity", None, ""),
    ("head_circumference", "nn_gen_exam_head_circumference", "Head circumference", "Physical Exam", M, "COALESCE(head_circumference, circumference_cm)", None, "pivot: Head circumference / Circumference"),
    ("fontanelle", "nn_gen_exam_fontanelle_assessment", "FEEL the fontanelle", "Physical Exam", M, "fontanelle", None, ""),
    ("head", "nn_gen_exam_mass_head_assessment", "Mass in the head", "Physical Exam", M, "head", None, ""),
    ("colour", "nn_gen_exam_baby_yellow_pale_pink", "Is the baby yellow / pale / pink?", "Physical Exam", M, "colour", None, "pivot: Colour covers yellow/pale/pink"),
    ("central_cyanosis", "nn_gen_exam_baby_cyanosis", "Does the baby have cyanosis?", "Physical Exam", M, "central_cyanosis", None, ""),
    ("palate", "nn_gen_exam_cleft_lip_palate_assessment", "Cleft lip & palate assessment", "Physical Exam", M, "palate", None, ""),
    ("capillary_refill_time", "nn_gen_exam_capillary_refill_time", "Capillary refill time (CRT)", "Physical Exam", M, "COALESCE(capillary_refill_time, crt_less_than_3_seconds, crt_3_or_more_seconds)", None, "pivot: Capillary refill time / CRT variants"),
    ("femoral_pulses", "nn_gen_exam_femoral_pulses", "Femoral pulse", "Physical Exam", M, "COALESCE(femoral_pulses, femoral_pulse_palpable)", None, ""),
    ("genitalia", "nn_gen_exam_genitalia_assessment", "Genitalia examination", "Physical Exam", M, "genitalia", None, ""),
    ("anus_assessment", "nn_gen_exam_anus_patent", "Anus", "Physical Exam", M, "anus_assessment", None, ""),
    ("congenital_abnormality", "nn_gen_exam_congenital_abnormalities", "Are there any congenital abnormalities?", "Physical Exam", M, "congenital_abnormality", None, ""),
    # ---------------- REVIEW OF SYSTEMS (211)
    ("baby_feeding", "nn_ros_baby_feeding", "Is the baby feeding?", "Review of Systems", M, "baby_feeding", None, ""),
    ("is_baby_vomiting", "nn_ros_baby_vomiting", "Is the baby vomiting?", "Review of Systems", M, "is_baby_vomiting", None, ""),
    ("passage_of_meconium", "nn_ros_passage_meconium", "Passage of meconium?", "Review of Systems", M, "passage_of_meconium", None, ""),
    ("frequency_of_stooling", "nn_ros_frequency_stooling", "Number of times the baby passed stools", "Review of Systems", M, "frequency_of_stooling", None, ""),
    ("color_of_stools", "nn_ros_color_stools", "Color of stools", "Review of Systems", M, "color_of_stools", None, ""),
    ("consistency_of_stools", "nn_ros_consistency_stools", "Consistency of stools", "Review of Systems", M, "consistency_of_stools", None, ""),
    ("baby_catheterized", "nn_ros_baby_catheterized", "Is the baby catheterized?", "Review of Systems", M, "baby_catheterized", None, ""),
    ("baby_passing_urine", "nn_ros_baby_passing_urine", "Is the baby passing urine?", "Review of Systems", M, "baby_passing_urine", None, ""),
    ("weight_trend_since_birth", "nn_ros_weight_trend_since_birth", "Weight trend since birth", "Review of Systems", M, "weight_trend_since_birth", None, ""),
    ("baby_oral_thrush", "nn_ros_baby_oral_thrush", "Oral thrush?", "Review of Systems", M, "baby_oral_thrush", None, ""),
    ("baby_oral_sores", "nn_ros_baby_oral_sores", "Oral sores?", "Review of Systems", M, "baby_oral_sores", None, ""),
    ("baby_tongue_tie", "nn_ros_baby_tongue_tie", "Tongue tie?", "Review of Systems", M, "baby_tongue_tie", None, ""),
    ("abdominal_distension", "nn_ros_abdominal_distension", "Abdominal distension?", "Review of Systems", M, "abdominal_distension", None, ""),
    ("umbilical_condition", "nn_ros_umbilical_condition", "Umbilical", "Review of Systems", M, "umbilical_condition", None, ""),
    ("skin_rash", "nn_ros_skin_rash", "Skin rash?", "Review of Systems", M, "skin_rash", None, ""),
    ("talipes", "nn_ros_talipes", "Talipes?", "Review of Systems", M, "talipes", None, ""),
    ("extra_digits", "nn_ros_extra_digits", "Extra digits?", "Review of Systems", M, "extra_digits", None, ""),
    ("spinal_bifida", "nn_ros_spinal_bifida", "Spinal bifida?", "Review of Systems", M, "spinal_bifida", None, ""),
    ("type_of_feed", "nn_ros_type_feed", "Type of feed", "Review of Systems", C, "type_of_feed", eq("baby_feeding", "yes"), "Is the baby feeding = Yes"),
    ("mode_of_feeding", "nn_ros_mode_feeding", "Mode of feeding", "Review of Systems", C, "mode_of_feeding", eq("baby_feeding", "yes"), "Is the baby feeding = Yes"),
    ("frequency_of_feeding", "nn_ros_frequency_feeding", "Frequency of feeding", "Review of Systems", C, "frequency_of_feeding", eq("baby_feeding", "yes"), "Is the baby feeding = Yes"),
    ("duration_of_feeding", "nn_ros_duration_feeding", "Duration of feeding (minutes)", "Review of Systems", C, "duration_of_feeding", eq("baby_feeding", "yes"), "Is the baby feeding = Yes"),
    ("effort_during_feeding", "nn_ros_effort_during_feeding", "Effort during feeding", "Review of Systems", C, "effort_during_feeding", eq("baby_feeding", "yes"), "Is the baby feeding = Yes"),
    ("blood_in_stools", "nn_ros_blood_stools", "Any blood in stools?", "Review of Systems", C, "blood_in_stools",
     f"{ne('color_of_stools','none')} AND {ne('consistency_of_stools','none')}", "Color and consistency of stools <> None"),
    ("mucus_in_stools", "nn_ros_mucus_stools", "Any mucus in stools?", "Review of Systems", C, "mucus_in_stools",
     f"{ne('color_of_stools','none')} AND {ne('consistency_of_stools','none')}", "Color and consistency of stools <> None"),
    ("wet_nappies_per_day", "nn_ros_number_wet_nappies", "Wet nappies changed in 24 hours", "Review of Systems", C, "wet_nappies_per_day",
     f"{eq('baby_passing_urine','yes')} AND {eq('baby_catheterized','no')}", "Passing urine = Yes and Catheterized = No"),
    ("color_of_urine", "nn_ros_color_urine", "Color of urine", "Review of Systems", C, "color_of_urine",
     f"{eq('baby_passing_urine','yes')} AND {eq('baby_catheterized','no')}", "Passing urine = Yes and Catheterized = No"),
    # ---------------- SYSTEMIC EXAMINATION (209)
    ("respiratory_distress", "nn_sys_chest_respiratory_distress", "Are there signs of respiratory distress?", "Systemic Exam", M, "respiratory_distress", None, ""),
    ("stethoscope_available", "nn_sys_chest_stethoscope_available", "Is a stethoscope available?", "Systemic Exam", M, "stethoscope_available", None, ""),
    ("abdomen_soft_normal", "nn_sys_abd_abdomen_findings", "Abdomen findings", "Systemic Exam", M, "abdomen_soft_normal", None, ""),
    ("umbilicus_healthy", "nn_sys_abd_umbilicus_findings", "Umbilicus findings", "Systemic Exam", M, "umbilicus_healthy", None, ""),
    ("abdomen_distended_veins", "nn_sys_abd_abdomen_distended_veins", "Distended veins?", "Systemic Exam", M, "abdomen_distended_veins", None, ""),
    ("abdomen_tender", "nn_sys_abd_abdomen_tender", "Tender?", "Systemic Exam", M, "abdomen_tender", None, ""),
    ("abdomen_shiny", "nn_sys_abd_abdomen_shiny", "Is the abdomen shiny?", "Systemic Exam", M, "abdomen_shiny", None, ""),
    ("abdomen_color_change", "nn_sys_abd_abdomen_color_change", "Has the abdomen changed color?", "Systemic Exam", M, "abdomen_color_change", None, ""),
    ("hepatomegaly", "nn_sys_abd_hepatomegaly", "Hepatomegaly?", "Systemic Exam", M, "hepatomegaly", None, ""),
    ("splenomegaly", "nn_sys_abd_splenomegaly", "Splenomegaly?", "Systemic Exam", M, "splenomegaly", None, ""),
    ("palpable_kidneys", "nn_sys_abd_palpable_kidneys", "Palpable kidneys?", "Systemic Exam", M, "palpable_kidneys", None, ""),
    ("tone_assessment", "nn_sys_neuro_tone_assessment", "Tone assessment", "Systemic Exam", M, "tone_assessment", None, ""),
    ("suck_reflex", "nn_sys_neuro_suck_reflex", "Suck reflex", "Systemic Exam", M, "suck_reflex", None, ""),
    ("grasp_reflex", "nn_sys_neuro_grasp_reflex", "Grasp reflex", "Systemic Exam", M, "grasp_reflex", None, ""),
    ("moro_reflex", "nn_sys_neuro_moro_reflex", "Moro reflex", "Systemic Exam", M, "moro_reflex", None, ""),
    ("musculoskeletal_deformities", "nn_sys_msk_musculoskeletal_deformities", "Musculoskeletal deformities / trauma", "Systemic Exam", M, "musculoskeletal_deformities", None, ""),
    ("skin_findings", "nn_sys_msk_skin_findings", "Skin findings", "Systemic Exam", M, "skin_findings", None, ""),
    ("birth_asphyxia_suspected", "nn_thompson_birth_asphyxia_suspected", "Birth asphyxia?", "Systemic Exam", M, "birth_asphyxia_suspected", None, ""),
    ("respiratory_distress_signs", "nn_sys_chest_respiratory_distress_symptoms", "Signs of respiratory distress present", "Systemic Exam", C,
     "COALESCE(nasal_flaring, fast_breathing, severe_respiratory_distress)", eq("respiratory_distress", "yes"), "Signs of respiratory distress = Yes"),
    ("chest_clear", "nn_sys_chest_lung_sounds", "Listen to the lungs", "Systemic Exam", C, "chest_clear", eq("stethoscope_available", "yes"), "Stethoscope available = Yes"),
    ("normal_heart_sounds", "nn_sys_chest_heart_sounds", "Murmurs / heart sounds", "Systemic Exam", C, "normal_heart_sounds", eq("stethoscope_available", "yes"), "Stethoscope available = Yes"),
] + [
    (f"thompson_{k}_score", f"nn_thompson_thompson_{n}", f"Thompson - {lbl}", "Systemic Exam", C, f"thompson_{k}_score",
     eq("birth_asphyxia_suspected", "yes"), "Birth asphyxia = Yes")
    for k, n, lbl in [("respiration", "respiration_score", "Respiration"), ("suck", "suck_score", "Suck reflex"),
                      ("moro", "moro_score", "Moro reflex"), ("grasp", "grasp_score", "Grasp reflex"),
                      ("fontanelle", "fontanelle_score", "Fontanelle"), ("tone", "tone_score", "Tone"),
                      ("consciousness", "consciousness_score", "Level of consciousness"),
                      ("fits", "fits_score", "Fits, seizures & convulsions"), ("posture", "posture_score", "Posture")]
] + [
    # ---------------- DIAGNOSIS (38), TREATMENT (22), CLINICAL REVIEW OUTCOME (214)
    ("primary_diagnosis", "nn_dx_working_diagnosis", "Primary diagnosis (working)", "Diagnosis", M, "primary_diagnosis", None, ""),
    ("treatment", "nn_tx_treatments", "Non-pharmacological treatments given", "Treatment", M, "treatment", None, ""),
    ("thermal_care", "nn_tx_thermal_care_details", "Thermal care interventions", "Treatment", C, "thermal_care", has("treatment", "thermal"), "Treatments include Thermal Care"),
    ("oxygen_therapy", "nn_tx_oxygen_therapy_details", "Oxygen therapy interventions", "Treatment", C, "oxygen_therapy", has("treatment", "oxygen"), "Treatments include Oxygen Therapy"),
    ("feeding_support", "nn_tx_feeding_support_details", "Feeding support provided", "Treatment", C, "feeding_support", has("treatment", "feeding"), "Treatments include Feeding Support"),
    ("clinical_review_outcome", "nn_adm_outcome_admission_outcome", "What happened to the baby? (clinical review)", "Clinical Review Outcome", M, "clinical_review_outcome", None, ""),
    ("clinical_review_signoff", "nn_adm_signoff_*", "Clinical review sign-off (worker id, signature, role, date)", "Clinical Review Outcome", M,
     "CASE WHEN clinician_notes LIKE '%NEONATAL_SIGNOFF%' THEN clinician_notes END", None, "pivot: sign-off JSON stored in clinician_notes"),
]

# Dictionary fields that have no column in the pivot (cannot be assessed)
NOT_IN_PIVOT = [
    ("nn_birth_twin_patient", "Search and select twin", "Enrollment", C, "Does the baby have a twin? = Yes"),
    ("nn_birth_place_birth_other", "Specify other place of birth", "Enrollment", C, "Place of birth = Other"),
    ("nn_ref_in_referred_from_other", "Specify other referral source", "Enrollment", C, "Referred from = Other"),
    ("nn_ref_in_mode_transport_other", "Specify other mode of transport", "Enrollment", C, "Mode of transport = Other"),
    ("nn_ref_in_admitted_from_other", "Specify other admission origin", "Enrollment", C, "Admitted from = Other"),
    ("nn_birth_assess_bvm_duration", "Duration of Bag Valve Mask ventilation", "Enrollment", C, "Resuscitation includes BVM"),
    ("nn_preg_hist_type_rupture_membranes", "Type of rupture of membranes", "Enrollment", C, "Rupture of membranes = Yes"),
    ("nn_mother_mother_on_art", "Is the mother on ART?", "Enrollment", C, "Mother HIV status = Reactive"),
    ("nn_mother_baby_given2p", "Was 2P given?", "Enrollment", C, "Mother HIV status = Reactive"),
    ("nn_mother_mother_tested_hepatitis", "Was the mother tested for Hepatitis?", "Enrollment", M, ""),
    ("nn_mother_mother_hepatitis_result", "Mother's Hepatitis result", "Enrollment", C, "Mother tested for Hepatitis = Yes (trigger not in pivot)"),
    ("nn_triage_dehydration_level_primary", "Level of dehydration", "Triage", C, "Is the baby dehydrated = Yes"),
    ("nn_triage_first_name", "First name (not extracted by design)", "Triage", M, "Baby not yet registered"),
    ("nn_triage_last_name", "Last name (not extracted by design)", "Triage", M, "Baby not yet registered"),
    ("nn_signs_presenting_complaints_other", "Specify other sign/symptom", "Signs & Symptoms", C, "Presenting complaint includes Other"),
    ("nn_gen_exam_baby_oedema", "Does the baby have oedema?", "Physical Exam", M, ""),
    ("nn_gen_exam_congenital_abnormalities_type", "Type of congenital abnormality", "Physical Exam", C, "Congenital abnormalities = Yes"),
    ("nn_gen_exam_congenital_abnormalities_description", "Describe the congenital abnormality", "Physical Exam", C, "Type = Other"),
    ("nn_ros_why_baby_not_feeding", "Why is the baby not feeding?", "Review of Systems", C, "Is the baby feeding = No"),
    ("nn_ros_frequency_vomiting", "Number of times the baby vomited", "Review of Systems", C, "Is the baby vomiting = Yes"),
    ("nn_ros_volume_ml", "Volume (ml)", "Review of Systems", C, "Passing urine = Yes and catheterized = Yes"),
    ("nn_sys_chest_jaundice_severity", "Severity of jaundice", "Systemic Exam", M, "Color = Yellow"),
    ("nn_inv_test / nn_inv_specimen", "Lab order test and specimen", "Lab Orders", M, "Lab ordered (only test type / status extracted)"),
    ("nn_tx_other_medication", "Specify other medication", "Treatment", C, "Selection includes Other"),
    ("nn_adm_outcome_clinical_review_outcome_other", "Specify other outcome", "Clinical Review Outcome", C, "Outcome = Other"),
    ("nn_disch_outcome_outcome", "Discharge - what happened to the baby?", "Discharge", M, ""),
    ("nn_disch_outcome_transfer_facility / _ward", "Receiving facility / ward", "Discharge", C, "Outcome = Transferred"),
    ("nn_disch_vitals_*", "Discharge vitals (weight, HR, RR, sats, temperature)", "Discharge", M, "Outcome is not death/absconded"),
    ("nn_disch_dx_main_diagnosis", "Discharge diagnosis", "Discharge", M, "Outcome is not death/absconded"),
    ("nn_disch_edu_health_education_given / insecticide net", "Discharge health education / ITN", "Discharge", M, "Outcome is not death/absconded"),
    ("nn_disch_signoff_*", "Discharge sign-off", "Discharge", M, ""),
]


def sql_str(s):
    return "'" + s.replace("'", "''") + "'"


def baby_level_cte(cols):
    lines = []
    for c in cols:
        lines.append(
            f"        SUBSTRING_INDEX(GROUP_CONCAT(NULLIF(TRIM(CAST(p.{c} AS CHAR)), '') "
            f"ORDER BY p.visit_date DESC SEPARATOR '|~|'), '|~|', 1) AS {c}")
    body = ",\n".join(lines)
    return f"""baby_level AS (
    -- One row per baby: latest non-empty value of each field across all visit days
    SELECT
        p.person_id,
        SUBSTRING_INDEX(GROUP_CONCAT(p.location_id ORDER BY p.visit_date DESC), ',', 1) AS location_id,
        MIN(p.visit_date) AS first_visit_date,
        MAX(p.visit_date) AS last_visit_date,
        COUNT(DISTINCT p.visit_date) AS number_of_visits,
        DATEDIFF(MAX(p.visit_date), MIN(p.visit_date)) + 1 AS days_spanned,
{body}
    FROM mahis_pivot p
    GROUP BY p.person_id
)"""


def field_status_cte():
    pairs = []
    for rid, dname, label, enc, req, present, applic, trig in RULES:
        a = "1" if applic is None else f"CASE WHEN COALESCE(({applic}), 0) THEN 1 ELSE 0 END"
        pairs.append(f"        {sql_str(rid)}, JSON_ARRAY({a}, CASE WHEN ({present}) IS NOT NULL THEN 1 ELSE 0 END)")
    obj = ",\n".join(pairs)
    return f"""baby_rule_results AS (
    -- baby_level is read once: every rule result is packed as [applicable, present] in one JSON object per baby
    SELECT person_id, JSON_OBJECT(
{obj}
    ) AS j
    FROM baby_level
),

field_status AS (
    -- Unpivot the JSON into one row per baby per rule
    SELECT
        b.person_id,
        k.rule_id,
        r.requirement,
        CAST(JSON_EXTRACT(b.j, CONCAT('$.', k.rule_id, '[0]')) AS UNSIGNED) AS applicable,
        CAST(JSON_EXTRACT(b.j, CONCAT('$.', k.rule_id, '[1]')) AS UNSIGNED) AS present
    FROM baby_rule_results b
    JOIN JSON_TABLE(JSON_KEYS(b.j), '$[*]' COLUMNS (rule_id VARCHAR(100) PATH '$')) k
    INNER JOIN rules r ON r.rule_id = k.rule_id
)"""


def rules_cte():
    rows = []
    for rid, dname, label, enc, req, present, applic, trig in RULES:
        rows.append(f"    SELECT {sql_str(rid)} AS rule_id, {sql_str(dname)} AS dictionary_name, {sql_str(label)} AS label, "
                    f"{sql_str(enc)} AS section, {sql_str(req)} AS requirement, {sql_str(trig)} AS condition_text")
    return "rules AS (\n" + "\n    UNION ALL\n".join(rows) + "\n)"


HEADER = """-- ============================================================================
-- {title}
-- INPUT: a table or CTE named `mahis_pivot` (output of the MAHIS pivot query, joined with
-- patient columns gender, birthdate, ... ). To use a CTE instead of a table, put this script's
-- WITH list after `WITH RECURSIVE mahis_pivot AS ( <pivot query> ),`
-- Generated by build_dqa_scripts.py from the MNH Neonatal data dictionary rules.
-- ============================================================================
SET SESSION group_concat_max_len = 1000000;

"""

DQ = """baby_dq AS (
    -- Per-baby counts of mandatory and conditional fields
    SELECT
        b.person_id,
        SUM(CASE WHEN f.requirement = 'MANDATORY' THEN 1 ELSE 0 END) AS mandatory_fields,
        SUM(CASE WHEN f.requirement = 'MANDATORY' AND f.present = 1 THEN 1 ELSE 0 END) AS mandatory_present,
        SUM(CASE WHEN f.requirement = 'MANDATORY' AND f.present = 0 THEN 1 ELSE 0 END) AS mandatory_missing,
        SUM(CASE WHEN f.requirement = 'CONDITIONAL' AND f.applicable = 1 THEN 1 ELSE 0 END) AS conditional_required,
        SUM(CASE WHEN f.requirement = 'CONDITIONAL' AND f.applicable = 1 AND f.present = 1 THEN 1 ELSE 0 END) AS conditional_present,
        SUM(CASE WHEN f.requirement = 'CONDITIONAL' AND f.applicable = 1 AND f.present = 0 THEN 1 ELSE 0 END) AS conditional_missing,
        GROUP_CONCAT(CASE WHEN f.requirement = 'MANDATORY' AND f.present = 0 THEN f.rule_id END ORDER BY f.rule_id SEPARATOR '; ') AS missing_mandatory_fields,
        GROUP_CONCAT(CASE WHEN f.requirement = 'CONDITIONAL' AND f.applicable = 1 AND f.present = 0 THEN f.rule_id END ORDER BY f.rule_id SEPARATOR '; ') AS missing_conditional_fields
    FROM baby_level b
    INNER JOIN field_status f ON f.person_id = b.person_id
    GROUP BY b.person_id
)"""


def write(name, title, ctes, final):
    cols = pivot_columns()
    cte_map = {"baby_level": baby_level_cte(cols), "field_status": field_status_cte(),
               "rules": rules_cte(), "baby_dq": DQ}
    text = HEADER.format(title=title) + "WITH " + ",\n\n".join(cte_map[c] for c in ctes) + "\n\n" + final.strip() + "\n"
    open(os.path.join(HERE, name), "w").write(text)


OVERALL = """
SELECT 'Total babies' AS measure, COUNT(*) AS babies, 100.0 AS pct FROM baby_dq
UNION ALL SELECT 'Babies with ALL mandatory fields present', SUM(mandatory_missing = 0), ROUND(100 * SUM(mandatory_missing = 0) / COUNT(*), 1) FROM baby_dq
UNION ALL SELECT 'Babies with MISSING mandatory fields', SUM(mandatory_missing > 0), ROUND(100 * SUM(mandatory_missing > 0) / COUNT(*), 1) FROM baby_dq
UNION ALL SELECT 'Babies with required conditional fields missing', SUM(conditional_missing > 0), ROUND(100 * SUM(conditional_missing > 0) / COUNT(*), 1) FROM baby_dq
UNION ALL SELECT 'Babies with all mandatory AND all required conditional fields present', SUM(mandatory_missing = 0 AND conditional_missing = 0), ROUND(100 * SUM(mandatory_missing = 0 AND conditional_missing = 0) / COUNT(*), 1) FROM baby_dq
UNION ALL SELECT 'Babies with required conditional fields (any triggered)', SUM(conditional_required > 0), ROUND(100 * SUM(conditional_required > 0) / COUNT(*), 1) FROM baby_dq
UNION ALL SELECT 'Average mandatory completeness (% of mandatory fields present per baby)', COUNT(*), ROUND(AVG(100 * mandatory_present / mandatory_fields), 1) FROM baby_dq
UNION ALL SELECT 'Average required-conditional completeness (% present per baby)', SUM(conditional_required > 0), ROUND(AVG(CASE WHEN conditional_required > 0 THEN 100 * conditional_present / conditional_required END), 1) FROM baby_dq;
"""

FIELDS = """
SELECT
    r.section,
    r.requirement,
    r.rule_id AS field,
    r.dictionary_name,
    r.label,
    r.condition_text,
    SUM(f.applicable) AS babies_where_required,
    SUM(CASE WHEN f.applicable = 1 AND f.present = 1 THEN 1 ELSE 0 END) AS babies_present,
    SUM(CASE WHEN f.applicable = 1 AND f.present = 0 THEN 1 ELSE 0 END) AS babies_missing,
    ROUND(100 * SUM(CASE WHEN f.applicable = 1 AND f.present = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(f.applicable), 0), 1) AS pct_present,
    ROUND(100 * SUM(CASE WHEN f.applicable = 1 AND f.present = 0 THEN 1 ELSE 0 END) / NULLIF(SUM(f.applicable), 0), 1) AS pct_missing,
    CASE WHEN SUM(f.applicable) = 0 THEN 'NOT TRIGGERED'
         WHEN SUM(CASE WHEN f.applicable = 1 AND f.present = 0 THEN 1 ELSE 0 END) = 0 THEN 'COMPLETE'
         WHEN SUM(CASE WHEN f.applicable = 1 AND f.present = 1 THEN 1 ELSE 0 END) = 0 THEN 'ALL MISSING'
         ELSE 'PARTIAL' END AS status
FROM rules r
INNER JOIN field_status f ON f.rule_id = r.rule_id
GROUP BY r.section, r.requirement, r.rule_id, r.dictionary_name, r.label, r.condition_text
ORDER BY r.requirement, pct_present, r.section, r.rule_id;
"""

BABY_DQ = """
SELECT
    b.person_id, b.location_id, b.first_visit_date, b.last_visit_date, b.number_of_visits,
    d.mandatory_fields, d.mandatory_present, d.mandatory_missing,
    ROUND(100 * d.mandatory_present / d.mandatory_fields, 1) AS pct_mandatory_present,
    d.conditional_required, d.conditional_present, d.conditional_missing,
    CASE WHEN d.mandatory_missing = 0 THEN 'YES' ELSE 'NO' END AS all_mandatory_present,
    d.missing_mandatory_fields,
    d.missing_conditional_fields
FROM baby_level b
INNER JOIN baby_dq d ON d.person_id = b.person_id
ORDER BY d.mandatory_missing DESC, b.person_id;
"""

BABY_LEVEL = """
SELECT * FROM baby_level ORDER BY person_id;
"""

if __name__ == "__main__":
    write("01_baby_level_records.sql", "BABY-LEVEL RECORDS - one row per baby, fields consolidated across visit days, with number_of_visits",
          ["baby_level"], BABY_LEVEL)
    write("02_summary_overall.sql", "OVERALL SUMMARY - babies with complete / missing mandatory and conditional fields",
          ["baby_level", "rules", "field_status", "baby_dq"], OVERALL)
    write("03_summary_by_field.sql", "FIELD SUMMARY - completeness of each mandatory and conditional field (with percentages)",
          ["baby_level", "rules", "field_status"], FIELDS)
    write("04_baby_dq_flags.sql", "BABY DQ FLAGS - per baby counts and the list of missing mandatory / conditional fields",
          ["baby_level", "rules", "field_status", "baby_dq"], BABY_DQ)
    with open(os.path.join(HERE, "05_dictionary_fields_not_in_pivot.sql"), "w") as f:
        f.write("-- Dictionary fields with no column in the pivot (cannot be assessed until extracted)\n")
        f.write("SELECT dictionary_name, label, section, requirement, condition_text FROM (\n")
        f.write("\n    UNION ALL\n".join(
            f"    SELECT {sql_str(d)} AS dictionary_name, {sql_str(l)} AS label, {sql_str(s)} AS section, "
            f"{sql_str(r)} AS requirement, {sql_str(t)} AS condition_text" for d, l, s, r, t in NOT_IN_PIVOT))
        f.write("\n) x ORDER BY section, requirement, dictionary_name;\n")
    print("rules:", len(RULES), "mandatory:", sum(1 for r in RULES if r[4] == M),
          "conditional:", sum(1 for r in RULES if r[4] == C), "not in pivot:", len(NOT_IN_PIVOT))

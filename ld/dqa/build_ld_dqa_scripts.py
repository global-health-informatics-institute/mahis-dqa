"""Generates the Labour & Delivery DQA SQL scripts from the MNH L&D data dictionary (ld_dictionary_fields.tsv, extracted from the PDF).
Reuses the generator of the neonatal DQA (../../neonatal/dqa/build_dqa_scripts.py) with Labour & Delivery rules.
Input expected by every generated script: a table or CTE named `mahis_pivot` = output of ../mahis_ld_pivot.sql.
Unit of analysis: one woman (latest non-empty value of each field across her labour-ward visit days)."""
import csv
import importlib.util
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("nb", os.path.join(HERE, "..", "..", "neonatal", "dqa", "build_dqa_scripts.py"))
nb = importlib.util.module_from_spec(spec)
spec.loader.exec_module(nb)
nb.HERE = HERE

M, C = "MANDATORY", "CONDITIONAL"
eq, ne, has = nb.eq, nb.ne, nb.has

# (rule_id, dictionary_name(s) joined with ' / ', label, section, requirement, present_expr, applicable_expr, trigger_text)
R = []


def m(rid, dname, label, sec, present=None):
    R.append((rid, dname, label, sec, M, present or rid, None, ""))


def c(rid, dname, label, sec, applic, trig, present=None):
    R.append((rid, dname, label, sec, C, present or rid, applic, trig))


QC, OB, LD, CH, ME, VA, EX, MO, DE, RF = ("Quick Check", "Obstetric History", "Current Labour Details", "Chronic Conditions", "Medications",
    "Vaccine History", "Examination", "Monitoring Vitals/Exam", "Delivery Details", "Referral")
m("what_is_the_reason_for_coming_to_the_facility", "ld_qc_reason", "Reason for coming to the facility", QC)
m("danger_signs", "ld_qc_danger_signs", "Danger signs", QC)
m("labour_onset_type", "ld_qc_labour_onset_type", "Labour onset type", QC)
m("time_of_labour_onset", "ld_qc_time / ld_labour_time_labour_onset", "Time of onset of labour", QC)
m("date_of_labour_onset", "ld_qc_date / ld_labour_date_labour_onset", "Date of onset of labour", QC)
m("membranes_ruptured", "ld_qc_membranes_ruptured", "Membranes ruptured?", QC)
m("time_membranes_ruptured", "ld_qc_time_membrane / ld_labour_time_membranes_ruptured", "Time membranes ruptured", QC)
m("date_membranes_ruptured", "ld_qc_date_membrane / ld_labour_date_membranes_ruptured", "Date membranes ruptured", QC)
m("has_she_had_food_in_4_hours", "ld_qc_food_4_hours", "Has she had food in 4 hours?", QC)
m("homemade_medicines_taken", "ld_qc_homemade_medicines_taken", "Homemade medicines taken?", QC)
m("sleep", "ld_qc_sleep", "Sleep", QC)
m("gravida", "ld_ob_hist_gravida", "Gravida", OB, "COALESCE(gravida, anc_gravida)")
m("abortions_miscarriages", "ld_ob_hist_abortions_miscarriages", "Abortions/Miscarriages", OB, "COALESCE(abortions_miscarriages, abortions, anc_abortions_miscarriages)")
m("stillbirths", "ld_ob_hist_stillbirths", "Stillbirths", OB, "COALESCE(stillbirths, anc_stillbirths)")
m("live_births", "ld_ob_hist_live_births", "Live births", OB, "COALESCE(live_births, livebirths, anc_live_births)")
m("parity", "ld_ob_hist_parity", "Parity", OB, "COALESCE(parity, anc_parity)")
m("how_many_doses_of_tdv_did_the_mother_receive", "ld_ob_hist_tdv_received", "TDV received", OB)
m("art_number", "ld_ob_hist_artnumber / ld_chronic_art_number", "ART number", OB, "COALESCE(art_number, anc_art_number, arv_number_identifier)")
m("chronic_conditions", "ld_chronic_chronic_conditions", "Existing chronic health conditions?", CH, "COALESCE(chronic_conditions, anc_chronic_conditions)")
m("hiv_test_date", "ld_chronic_hiv_test_date / ld_chronic_test_date", "HIV test date", CH, "COALESCE(hiv_test_date, anc_hiv_test_date)")
m("facility_for_art", "ld_chronic_facility_art", "Facility for ART", CH)
m("which_medications_is_the_woman_currently_prescribed", "ld_meds_medications_currently_prescri", "Which medications is the woman currently prescribed?", ME, "COALESCE(which_medications_is_the_woman_currently_prescribed, anc_medications_currently_prescribed)")
m("the_woman_received_tetanus_doses_for_immunization", "ld_vaccine_received_tetanus_doses_im", "Woman received tetanus doses for immunization?", VA, "COALESCE(the_woman_received_tetanus_doses_for_immunization, anc_received_tetanus_doses)")
m("tt1date", "ld_vaccine_tt1_date", "TTV 1 immunisation date", VA, "anc_tt1date")
m("tt2date", "ld_vaccine_tt2_date", "TTV 2 immunisation date", VA, "COALESCE(tt2date, anc_tt2date)")
m("gestation_age", "ld_ob_hist_gestation_age", "Gestation age (weeks)", OB, "anc_gestation_weeks")
m("lnmp", "ld_ob_hist_lnmp", "LNMP", OB, "anc_lmnp_date")
m("expected_delivery_date", "ld_ob_hist_expected_delivery_date", "Expected delivery date", OB, "COALESCE(anc_estimated_date_of_delivery, anc_estimated_date)")
m("number_of_anc_visits", "ld_ob_hist_number_anc_visits", "Number of ANC visits", OB, "anc_number_of_previous_anc_contacts")
m("state_of_cervix", "ld_ve_state_cervical", "State of cervix", EX)
m("height", "ld_mon_vitals_height_cm", "Height", MO)
m("weight_kg", "ld_mon_vitals_weight", "Weight", MO)
m("systolic_blood_pressure", "ld_mon_vitals_systolic / ld_post_mom_systolic_blood_pressure", "Systolic pressure", MO)
m("diastolic_blood_pressure", "ld_mon_vitals_diastolic / ld_post_mom_diastolic_blood_pressure", "Diastolic pressure", MO)
m("pulse", "ld_mon_vitals_pulse", "Pulse rate", MO, "COALESCE(pulse, pulse_rate)")
m("apgar_score_at_1_minute", "ld_del_apgar_score_1_minute", "APGAR score at 1 minute", DE)
m("apgar_score_at_5_minutes", "ld_del_apgar_score_5_minutes", "APGAR score at 5 minutes", DE)
m("baby_weight", "ld_del_weight", "Baby weight", DE, "COALESCE(weight_grams, current_weight)")
m("length", "ld_del_height", "Baby height", DE)
m("head_circumference", "ld_del_circumference", "Head circumference", DE)
m("time_of_delivery", "ld_del_time_delivery", "Time of delivery", DE)
m("date_of_delivery", "ld_del_date_delivery", "Date of delivery", DE)
m("who_is_being_referred", "ld_ref_referred", "Who is being referred", RF)
c("referring_mother_other_specify", "ld_ref_specify", "Reason for referring mother - other (specify)", RF, has("reason_for_referring_mother", "other"), "Reason for referring mother includes other")

cols = [x.strip() for x in open(os.path.join(HERE, "pivot_columns.txt")) if x.strip() and x.strip() not in ("location_id", "person_id", "visit_date")]
assert not [r for r in R if not set(re.findall(r"[a-z_0-9]+", re.sub(r"'[^']*'", "", r[5] + " " + (r[6] or "")))) & set(cols)], "rule without pivot column"
used = set(re.findall(r"[a-z][a-z_0-9]+", " ".join(re.sub(r"'[^']*'", "", (r[5] + " " + (r[6] or ""))) for r in R)))
missing = sorted(a for a in used if a not in cols and a not in {"coalesce", "is", "not", "null", "lower", "like", "case", "when", "then", "else", "end", "and", "or"})
assert not missing, f"aliases not in pivot: {missing}"
assert len({r[0] for r in R}) == len(R), "duplicate rule ids"

# split by who the record is about / which unit is assessed
R_BABY = [r for r in R if r[3] == DE]                    # newborn delivery details -> baby records
R_VITALS = {r[0] for r in R if r[3] == MO}               # vitals -> assessed per Vitals encounter (round-level scripts)
R_WOMAN = [r for r in R if r[3] not in (DE, MO)]
ROUND_NAMES = {"ld_mon_exam_heart", "ld_mon_exam_cervical", "ld_mon_exam_contractions", "ld_mon_exam_urine_volume", "ld_mon_exam_urine_color",
               "ld_mon_exam_urine_odour", "ld_mon_vitals_height_cm", "ld_mon_vitals_weight", "ld_mon_vitals_systolic", "ld_mon_vitals_diastolic", "ld_mon_vitals_pulse"}

# dictionary fields (Required = Yes / Conditional) that no rule covers -> reported as not extracted
mapped = {n.strip() for r in R_WOMAN + R_BABY for n in r[1].split(' / ')} | ROUND_NAMES
dic = list(csv.DictReader(open(os.path.join(HERE, "ld_dictionary_fields.tsv")), delimiter="\t"))
NIP = []
for d in dic:
    if d["required"] in ("Yes", "Conditional") and d["name"] not in mapped:
        req = M if d["required"] == "Yes" else C
        lab = re.sub(r"\s+", " ", d["label"]).strip()
        rel = re.sub(r"\s+", " ", d["relevance"]).strip()
        if not rel and re.search(r"\bspecify\b", lab, re.I):
            rel = "free-text 'Specify' follow-up marked Required=Yes without a relevance rule"
        NIP.append((d["name"], lab, f"page {d['page']}", req, rel))
n_opt = sum(1 for d in dic if d["required"] == "No")

nb.NOT_IN_PIVOT = NIP
nb.pivot_columns = lambda: cols
WOMAN_FILTER = "FROM mahis_pivot p\n    WHERE p.record_type = 'woman'\n    GROUP BY p.person_id"
BABY_FILTER = "FROM mahis_pivot p\n    WHERE p.record_type IN ('baby', 'unknown')\n    GROUP BY p.person_id"


def post(files, filt, repl):
    for fn in files:
        p = os.path.join(HERE, fn)
        t = open(p).read().replace("FROM mahis_pivot p\n    GROUP BY p.person_id", filt)
        for a_, b_ in repl:
            t = t.replace(a_, b_)
        t = t.replace("(output of the MAHIS pivot query, joined with\n-- patient columns gender, birthdate, ... )", "(output of ld/mahis_ld_pivot.sql)")
        open(p, "w").write(t)


# ---- women: record_type = 'woman'
nb.RULES = R_WOMAN
OVERALL = nb.OVERALL.replace("babies", "women").replace("Babies", "Women").replace("baby_dq", "woman_dq").replace("per baby", "per woman")
FIELDS = nb.FIELDS.replace("babies_", "women_")
BABY_DQ = nb.BABY_DQ.replace("baby_dq", "woman_dq")
nb.write("01_woman_level_records.sql", "L&D WOMAN-LEVEL RECORDS - one row per woman (record_type = woman), fields consolidated across visit days, with number_of_visits", ["baby_level"], nb.BABY_LEVEL)
nb.write("02_summary_overall.sql", "Labour & Delivery OVERALL SUMMARY (women) - complete / missing mandatory and conditional fields", ["baby_level", "rules", "field_status", "baby_dq"], OVERALL)
nb.write("03_summary_by_field.sql", "Labour & Delivery FIELD SUMMARY (women) - completeness of each mandatory and conditional field", ["baby_level", "rules", "field_status"], FIELDS)
nb.write("04_woman_dq_flags.sql", "L&D WOMAN DQ FLAGS - per woman counts and the list of missing mandatory / conditional fields", ["baby_level", "rules", "field_status", "baby_dq"], BABY_DQ)
W = ["01_woman_level_records.sql", "02_summary_overall.sql", "03_summary_by_field.sql", "04_woman_dq_flags.sql"]
post(W, WOMAN_FILTER, [("baby_level", "woman_level"), ("baby_dq", "woman_dq"), ("baby_rule_results", "woman_rule_results"), ("One row per baby", "One row per woman"),
                       ("per baby per rule", "per woman per rule"), ("one JSON object per baby", "one JSON object per woman"), ("Per-baby counts", "Per-woman counts")])

# ---- babies (newborn records in the program): record_type = 'baby' (+ the one record without birthdate that holds delivery details)
nb.RULES = R_BABY
nb.write("11_baby_level_records.sql", "L&D BABY-LEVEL RECORDS - one row per newborn record, consolidated across visit days, with number_of_visits", ["baby_level"], nb.BABY_LEVEL)
nb.write("12_baby_summary_overall.sql", "Labour & Delivery OVERALL SUMMARY (babies) - delivery details mandatory fields", ["baby_level", "rules", "field_status", "baby_dq"], nb.OVERALL)
nb.write("13_baby_summary_by_field.sql", "Labour & Delivery FIELD SUMMARY (babies) - delivery details completeness", ["baby_level", "rules", "field_status"], nb.FIELDS)
nb.write("14_baby_dq_flags.sql", "L&D BABY DQ FLAGS - per newborn record counts and the list of missing mandatory fields", ["baby_level", "rules", "field_status", "baby_dq"], nb.BABY_DQ)
post(["11_baby_level_records.sql", "12_baby_summary_overall.sql", "13_baby_summary_by_field.sql", "14_baby_dq_flags.sql"], BABY_FILTER, [])

with open(os.path.join(HERE, "05_dictionary_fields_not_in_pivot.sql"), "w") as f:
    f.write("-- Labour & Delivery dictionary fields (Required = Yes / Conditional) with no column in the pivot (cannot be assessed until extracted)\n")
    f.write(f"-- {n_opt} further dictionary fields are Required = No (optional) and are not assessed\n")
    f.write("SELECT dictionary_name, label, section, requirement, condition_text FROM (\n")
    f.write("\n    UNION ALL\n".join(f"    SELECT {nb.sql_str(a)} AS dictionary_name, {nb.sql_str(b)} AS label, {nb.sql_str(s)} AS section, {nb.sql_str(r)} AS requirement, {nb.sql_str(t)} AS condition_text" for a, b, s, r, t in NIP))
    f.write("\n) x ORDER BY section, requirement, dictionary_name;\n")
print(len(R_WOMAN), "woman rules;", len(R_BABY), "baby rules;", len(NIP), "dictionary fields not in pivot (", sum(1 for x in NIP if x[3] == M), "mandatory );", n_opt, "optional not assessed")

"""Generates the ANC DQA SQL scripts from the MNH ANC data dictionary (anc_dictionary_fields.tsv, extracted from the PDF).
Reuses the generator of the neonatal DQA (../../neonatal/dqa/build_dqa_scripts.py) with ANC rules.
Input expected by every generated script: a table or CTE named `mahis_pivot` = output of ../mahis_anc_pivot.sql.
Unit of analysis: one woman (latest non-empty value of each field across her ANC visit days)."""
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
LIVE = has("anc_pregnancy_outcome", "live birth")

# (rule_id, dictionary_name, label, section, requirement, present_expr, applicable_expr, trigger_text)
R = []


def m(rid, dname, label, sec, present=None):
    R.append((rid, dname, label, sec, M, present or rid, None, ""))


def c(rid, dname, label, sec, applic, trig, present=None):
    R.append((rid, dname, label, sec, C, present or rid, applic, trig))


QC, EN, CP, OB, GY, MH, CM, BH, VS, GE, AB, ML, MD, PO = ("Quick Check", "ANC Enrolment", "Current Pregnancy", "Past Obstetric History",
    "Gynaecological History", "Medical History", "Current Medications", "Behaviour & Lifestyle", "Vital Signs", "General Examination",
    "Abdominal & Fetal", "Deworming & Malaria", "Medication Dispensed", "Pregnancy Outcome")
m("reason_for_visit", "anc_qc_reason_visit", "Reason the woman came to the facility today", QC)
m("previous_anc_visit", "anc_qc_previous_visit", "Any previous ANC visit/s at any facility?", QC)
m("pregnancy_confirmed", "anc_enrol_pregnancy_confirmed", "Is the pregnancy confirmed?", EN)
m("gestation_age_to_be_used", "anc_curr_preg_gestation_age_used", "Gestation age to be used", CP)
m("lmnp_date", "anc_curr_preg_lmnp_date", "LNMP date", CP)
m("ultrasound_scan_date", "anc_curr_preg_date", "Date for ultrasound", CP)
m("gestation_weeks", "anc_curr_preg_gestation", "Gestation age by palpation (weeks)", CP, "COALESCE(gestation_weeks, gestation_in_weeks)")
m("the_woman_received_tetanus_doses_for_immunization", "anc_curr_preg_received_tetanus_doses", "Woman received tetanus doses for immunization?", CP)
m("tt1date", "anc_curr_preg_tt1_date", "TTV 1 immunisation date", CP)
m("tt2date", "anc_curr_preg_tt2_date", "TTV 2 immunisation date", CP)
m("gravida", "anc_ob_hist_gravida", "Gravida", OB)
m("abortions_miscarriages", "anc_ob_hist_abortions_miscarriages", "Abortions/Miscarriages", OB, "COALESCE(abortions_miscarriages, abortions)")
m("stillbirths", "anc_ob_hist_stillbirths", "Stillbirths", OB)
m("past_pregnancies_complications", "anc_ob_hist_past_pregnancies_complic", "Complications during the past pregnancies?", OB)
m("age_at_menarche", "anc_gynae_age_menarche", "Age at menarche", GY)
m("length_of_menstrual_flow", "anc_gynae_length_menstrual_flow_day", "Length of menstrual flow", GY)
m("regularity_of_menstrual_flow", "anc_gynae_regularity_menstrual_flow", "Regularity of menstrual flow", GY)
m("amount_of_menstrual_flow", "anc_gynae_amount_menstrual_flow", "Amount of menstrual flow", GY)
m("dysmenorrhoea", "anc_gynae_dysmenorrhea", "Dysmenorrhea", GY)
m("which_medications_is_the_woman_currently_prescribed", "anc_meds_medications_currently_presc", "Which medications is the woman currently prescribed?", CM)
m("daily_caffeine_use", "anc_behav_daily_caffeine_use", "Daily caffeine use", BH)
m("misuse_of_drugs", "anc_behav_misuse_drugs", "Misuse of drugs", BH)
m("height", "anc_vitals_height_cm", "Height", VS)
m("weight_kg", "anc_vitals_weight", "Weight", VS)
m("systolic_blood_pressure", "anc_vitals_systolic", "Systolic pressure", VS)
m("diastolic_blood_pressure", "anc_vitals_diastolic", "Diastolic pressure", VS)
m("pulse", "anc_vitals_pulse", "Pulse rate", VS)
m("kempt", "anc_gen_exam_kempt", "Kempt", GE)
m("gait", "anc_gen_exam_gait", "Gait", GE)
m("nutritional_status", "anc_gen_exam_nutritional_status", "Nutritional status", GE)
m("symphysis_fundal_height", "anc_abd_symphysis_fundal_height_sfh", "Symphysis-fundal height (SFH)", AB)
m("antihelminthic_treatment", "anc_malaria_antihelminthic_treatment", "Was preventative antihelminthic treatment provided?", ML)
m("folic_acid", "anc_disp_folic_acid", "Daily dose of folic acid prescribed?", MD)
m("anc_pregnancy_outcome", "anc_outcome_anc_pregnancy_outcome", "Outcome of the pregnancy", PO)

c("pregnancy_planned", "anc_enrol_pregnancy_planned", "Was the pregnancy planned?", EN, "pregnancy_confirmed IS NOT NULL", "Pregnancy confirmed has a value")
c("other_surgery_notes", "anc_med_hist_other_surgery_notes", "Specify other surgery", MH, has("past_surgeries", "other"), "Past surgeries includes Other")
c("other_allergy_notes", "anc_med_hist_other_allergy_notes", "Specify other allergy", MH, has("allergies", "other"), "Allergies includes Other")
for rid, dn, lab in [("hiv_test_date", "anc_med_hist_hiv_test_date", "HIV test date"), ("is_client_on_art", "anc_med_hist_client_art", "Is the client on ART?"),
                     ("art_number", "anc_med_hist_art_number", "ART number")]:
    c(rid, dn, lab, MH, f"({has('chronic_conditions', 'hiv')} OR {eq('hiv_status', 'positive')})", "Chronic conditions includes HIV positive, or HIV status = Positive (the data records HIV in the HIV status field)", "COALESCE(art_number, arv_number_identifier)" if rid == "art_number" else None)
c("albendazole", "anc_malaria_antihelminthic_treatment_", "Preventative antihelminthic treatment provided", ML, eq("antihelminthic_treatment", "yes"), "Antihelminthic treatment = Yes")
c("no_preventative_treatment_provided", "anc_malaria_no_preventative_treatment", "Reason no preventative treatment provided", ML, eq("antihelminthic_treatment", "no"), "Antihelminthic treatment = No")
c("pregnancy_outcome_notes", "anc_outcome_pregnancy_outcome_not", "Outcome of the pregnancy - other (specify)", PO, has("anc_pregnancy_outcome", "other"), "Pregnancy outcome = Other")
for rid, dn, lab in [("estimated_date_of_delivery", "anc_outcome_estimated_date_delivery", "Estimated date of delivery"),
                     ("place_of_delivery", "anc_outcome_place_delivery", "Place of delivery"),
                     ("preterm_birth", "anc_outcome_preterm_birth", "Preterm birth"),
                     ("mode_of_delivery", "anc_outcome_mode_delivery", "Mode of delivery")]:
    c(rid, dn, lab, PO, LIVE, "Pregnancy outcome = Live birth")

cols = [x.strip() for x in open(os.path.join(HERE, "pivot_columns.txt")) if x.strip() and x.strip() not in ("location_id", "person_id", "visit_date")]
assert not [r for r in R if not set(re.findall(r"[a-z_0-9]+", re.sub(r"'[^']*'", "", r[5] + " " + (r[6] or "")))) & set(cols)], "rule without pivot column"
used = set(re.findall(r"[a-z][a-z_0-9]+", " ".join(re.sub(r"'[^']*'", "", (r[5] + " " + (r[6] or ""))) for r in R)))
missing = sorted(a for a in used if a not in cols and a not in {"coalesce", "is", "not", "null", "lower", "like", "case", "when", "then", "else", "end", "and", "or"})
assert not missing, f"aliases not in pivot: {missing}"
assert len({r[0] for r in R}) == len(R), "duplicate rule ids"

# dictionary fields (Required = Yes / Conditional) that no rule covers -> reported as not extracted
mapped = {r[1] for r in R}
dic = list(csv.DictReader(open(os.path.join(HERE, "anc_dictionary_fields.tsv")), delimiter="\t"))
NIP = []
for d in dic:
    if d["required"] in ("Yes", "Conditional") and d["name"] not in mapped:
        req = M if d["required"] == "Yes" else C
        lab = re.sub(r"\s+", " ", d["label"]).strip()
        NIP.append((d["name"], lab, f"page {d['page']}", req, re.sub(r"\s+", " ", d["relevance"]).strip()))
n_opt = sum(1 for d in dic if d["required"] == "No")

nb.RULES = R
nb.NOT_IN_PIVOT = NIP
nb.pivot_columns = lambda: cols

TITLE = "ANC"
OVERALL = nb.OVERALL.replace("babies", "women").replace("Babies", "Women").replace("baby_dq", "woman_dq").replace("per baby", "per woman")
FIELDS = nb.FIELDS.replace("babies_", "women_")
BABY_DQ = nb.BABY_DQ.replace("baby_dq", "woman_dq")
nb.write("01_woman_level_records.sql", "ANC WOMAN-LEVEL RECORDS - one row per woman, fields consolidated across visit days, with number_of_visits", ["baby_level"], nb.BABY_LEVEL)
nb.write("02_summary_overall.sql", "ANC OVERALL SUMMARY - women with complete / missing mandatory and conditional fields", ["baby_level", "rules", "field_status", "baby_dq"], OVERALL)
nb.write("03_summary_by_field.sql", "ANC FIELD SUMMARY - completeness of each mandatory and conditional field (with percentages)", ["baby_level", "rules", "field_status"], FIELDS)
nb.write("04_woman_dq_flags.sql", "ANC WOMAN DQ FLAGS - per woman counts and the list of missing mandatory / conditional fields", ["baby_level", "rules", "field_status", "baby_dq"], BABY_DQ)
with open(os.path.join(HERE, "05_dictionary_fields_not_in_pivot.sql"), "w") as f:
    f.write("-- ANC dictionary fields (Required = Yes / Conditional) with no column in the pivot (cannot be assessed until extracted)\n")
    f.write(f"-- {n_opt} further dictionary fields are Required = No (optional) and are not assessed\n")
    f.write("SELECT dictionary_name, label, section, requirement, condition_text FROM (\n")
    f.write("\n    UNION ALL\n".join(f"    SELECT {nb.sql_str(a)} AS dictionary_name, {nb.sql_str(b)} AS label, {nb.sql_str(s)} AS section, {nb.sql_str(r)} AS requirement, {nb.sql_str(t)} AS condition_text" for a, b, s, r, t in NIP))
    f.write("\n) x ORDER BY section, requirement, dictionary_name;\n")

# woman wording in the generated files
for fn in os.listdir(HERE):
    if fn.endswith(".sql"):
        p = os.path.join(HERE, fn)
        t = open(p).read().replace("baby_level", "woman_level").replace("baby_dq", "woman_dq").replace("baby_rule_results", "woman_rule_results")
        t = t.replace("One row per baby", "One row per woman").replace("per baby per rule", "per woman per rule").replace("one JSON object per baby", "one JSON object per woman").replace("Per-baby counts", "Per-woman counts").replace("MAHIS PIVOT query", "ANC pivot query").replace("(output of the MAHIS pivot query, joined with\n-- patient columns gender, birthdate, ... )", "(output of anc/mahis_anc_pivot.sql)")
        open(p, "w").write(t)
print(len(R), "rules:", sum(1 for r in R if r[4] == M), "mandatory,", sum(1 for r in R if r[4] == C), "conditional;",
      len(NIP), "dictionary fields not in pivot (", sum(1 for x in NIP if x[3] == M), "mandatory );", n_opt, "optional not assessed")

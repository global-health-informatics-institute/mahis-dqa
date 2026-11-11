"""Generates the PNC DQA SQL scripts from the MNH PNC data dictionary (pnc_dictionary_fields.tsv, extracted from the PDF).
Reuses the generator of the neonatal DQA (../../neonatal/dqa/build_dqa_scripts.py) with PNC rules.
Input expected by every generated script: a table or CTE named `mahis_pivot` = output of ../mahis_pnc_pivot.sql.
Unit of analysis: one woman (latest non-empty value of each field across her PNC visit days)."""
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


HIV, REF, DTH = "HIV", "Referral / Discharge", "Death"
m("mother_hiv_status", "pnc_hiv_mother_hiv_status", "HIV status of woman", HIV, "COALESCE(mother_hiv_status, other_programs_hiv_status)")
m("has_the_woman_been_initiated_on_art_treatment", "pnc_hiv_started_art_treatment", "Has the woman started ART treatment?", HIV)
m("art_clinic_number", "pnc_hiv_art_clinic_registration_number", "ART clinic number", HIV, "COALESCE(other_programs_art_number, arv_number_identifier)")
# referral / death details: the dictionary marks them Required=Yes without a relevance rule; they only make sense when the woman was referred / died,
# so they are assessed as CONDITIONAL using the trigger below (my interpretation, not the dictionary's)
REFERRED = "(reason_for_referral IS NOT NULL OR referral_facility IS NOT NULL OR time_of_referral IS NOT NULL OR condition_on_referral IS NOT NULL OR " + has("discharge_status_of_woman", "refer") + ")"
c("time_of_referral", "pnc_disch_time_referral / pnc_ref_time_referral / pnc_end_time_referral", "Time of referral", REF, REFERRED, "Woman was referred (any referral detail recorded)")
c("reason_for_referral", "pnc_disch_reason_referral / pnc_end_reason_referral", "Reason for referral (free text)", REF, REFERRED, "Woman was referred (any referral detail recorded)")
c("condition_on_referral", "pnc_disch_condition_referral / pnc_end_condition_referral", "Woman's condition on referral", REF, REFERRED, "Woman was referred (any referral detail recorded)")
c("other_programs_facility_for_art", "pnc_disch_facility_art / pnc_end_facility_art", "Facility for ART", HIV, eq("has_the_woman_been_initiated_on_art_treatment", "yes"), "Woman has started ART (my interpretation: the dictionary gives no relevance rule)")
c("death_date", "pnc_end_date_death", "Date of death", DTH, "dead = '1'", "Woman recorded as dead")

cols = [x.strip() for x in open(os.path.join(HERE, "pivot_columns.txt")) if x.strip() and x.strip() not in ("location_id", "person_id", "visit_date")]
assert not [r for r in R if not set(re.findall(r"[a-z_0-9]+", re.sub(r"'[^']*'", "", r[5] + " " + (r[6] or "")))) & set(cols)], "rule without pivot column"
used = set(re.findall(r"[a-z][a-z_0-9]+", " ".join(re.sub(r"'[^']*'", "", (r[5] + " " + (r[6] or ""))) for r in R)))
missing = sorted(a for a in used if a not in cols and a not in {"coalesce", "is", "not", "null", "lower", "like", "case", "when", "then", "else", "end", "and", "or"})
assert not missing, f"aliases not in pivot: {missing}"
assert len({r[0] for r in R}) == len(R), "duplicate rule ids"

ROUND_NAMES = {"pnc_ward_mom_systolic_blood_pressu", "pnc_ward_mom_diastolic_blood_press", "pnc_ward_mom_pulse", "pnc_ward_mom_temperature",
               "pnc_ward_mom_respiratory_rate", "pnc_ward_mom_oxygen_saturation"}
R_WOMAN = R
mapped = {n.strip() for r in R_WOMAN for n in r[1].split(' / ')} | ROUND_NAMES
dic = list(csv.DictReader(open(os.path.join(HERE, "pnc_dictionary_fields.tsv")), delimiter="\t"))
NIP = []
for d in dic:
    if d["required"] in ("Yes", "Conditional") and d["name"] not in mapped:
        req = M if d["required"] == "Yes" else C
        lab = re.sub(r"\s+", " ", d["label"]).strip()
        rel = re.sub(r"\s+", " ", d["relevance"]).strip()
        if not rel and re.search(r"\bspecify\b", lab, re.I):
            rel = "free-text 'Specify' follow-up marked Required=Yes without a relevance rule"
        elif not rel and re.search(r"referral|death", d["name"]):
            rel = "dictionary marks Required=Yes without a relevance rule; applies only to referred / dead women; no pivot column"
        elif not rel:
            rel = "dictionary marks Required=Yes; no column in the PNC pivot"
        NIP.append((d["name"], lab, f"page {d['page']}", req, rel))
n_opt = sum(1 for d in dic if d["required"] == "No")

nb.NOT_IN_PIVOT = NIP
nb.pivot_columns = lambda: cols
WOMAN_FILTER = "FROM mahis_pivot p\n    WHERE p.record_type = 'woman'\n    GROUP BY p.person_id"


def post(files, filt, repl):
    for fn in files:
        p = os.path.join(HERE, fn)
        t = open(p).read().replace("FROM mahis_pivot p\n    GROUP BY p.person_id", filt)
        for a_, b_ in repl:
            t = t.replace(a_, b_)
        t = t.replace("(output of the MAHIS pivot query, joined with\n-- patient columns gender, birthdate, ... )", "(output of pnc/mahis_pnc_pivot.sql)")
        open(p, "w").write(t)


nb.RULES = R_WOMAN
OVERALL = nb.OVERALL.replace("babies", "women").replace("Babies", "Women").replace("baby_dq", "woman_dq").replace("per baby", "per woman")
FIELDS = nb.FIELDS.replace("babies_", "women_")
BABY_DQ = nb.BABY_DQ.replace("baby_dq", "woman_dq")
nb.write("01_woman_level_records.sql", "PNC WOMAN-LEVEL RECORDS - one row per woman (record_type = woman), fields consolidated across visit days, with number_of_visits", ["baby_level"], nb.BABY_LEVEL)
nb.write("02_summary_overall.sql", "PNC OVERALL SUMMARY (women) - complete / missing mandatory and conditional fields", ["baby_level", "rules", "field_status", "baby_dq"], OVERALL)
nb.write("03_summary_by_field.sql", "PNC FIELD SUMMARY (women) - completeness of each mandatory and conditional field", ["baby_level", "rules", "field_status"], FIELDS)
nb.write("04_woman_dq_flags.sql", "PNC WOMAN DQ FLAGS - per woman counts and the list of missing mandatory / conditional fields", ["baby_level", "rules", "field_status", "baby_dq"], BABY_DQ)
post(["01_woman_level_records.sql", "02_summary_overall.sql", "03_summary_by_field.sql", "04_woman_dq_flags.sql"], WOMAN_FILTER,
     [("baby_level", "woman_level"), ("baby_dq", "woman_dq"), ("baby_rule_results", "woman_rule_results"), ("One row per baby", "One row per woman"),
      ("per baby per rule", "per woman per rule"), ("one JSON object per baby", "one JSON object per woman"), ("Per-baby counts", "Per-woman counts")])

with open(os.path.join(HERE, "05_dictionary_fields_not_in_pivot.sql"), "w") as f:
    f.write("-- PNC dictionary fields (Required = Yes / Conditional) with no column in the pivot (cannot be assessed until extracted)\n")
    f.write(f"-- {n_opt} further dictionary fields are Required = No (optional) and are not assessed\n")
    f.write("SELECT dictionary_name, label, section, requirement, condition_text FROM (\n")
    f.write("\n    UNION ALL\n".join(f"    SELECT {nb.sql_str(a)} AS dictionary_name, {nb.sql_str(b)} AS label, {nb.sql_str(s)} AS section, {nb.sql_str(r)} AS requirement, {nb.sql_str(t)} AS condition_text" for a, b, s, r, t in NIP))
    f.write("\n) x ORDER BY section, requirement, dictionary_name;\n")
print(len(R_WOMAN), "woman rules;", len(NIP), "dictionary fields not in pivot (", sum(1 for x in NIP if x[3] == M), "mandatory );", n_opt, "optional not assessed")

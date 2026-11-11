"""Build share-safe copies of the DQA workbooks in ./shared.

The full workbooks (<program>/dqa/output/) contain one row per woman / baby / visit, with person ids, birthdates, free text and
names. Those must stay internal. The copies written here keep only the aggregate sheets (counts and percentages) and are checked
so that no identifying column or value can slip through.
"""
import glob
import os
import re
import sys

import pandas as pd

ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ROOT, "shared")
KEEP = re.compile(r"(Overall|Field_Summary|Not_In_Pivot|Not_Assessable)", re.I)
BLOCKED_COLUMNS = {"person_id", "encounter_id", "location_id", "birthdate", "mother_name", "mother_identifier", "phone_number",
                   "identifier", "related_person_ids", "clinician_notes", "arv_number_identifier", "art_number", "visit_date"}
BLOCKED_VALUE = re.compile(r"ARV-?\d|NEONATAL_SIGNOFF|electronicSignature", re.I)

workbooks = sorted(glob.glob(os.path.join(ROOT, "*", "dqa", "output", "*_summary.xlsx")))
if not workbooks:
    sys.exit("No workbooks found. Run python3 run_all.py first.")
os.makedirs(OUT, exist_ok=True)
for wb in workbooks:
    program = wb.split(os.sep)[-4]
    sheets = pd.read_excel(wb, sheet_name=None)
    kept = {n: df for n, df in sheets.items() if KEEP.search(n)}
    for n, df in kept.items():
        bad = BLOCKED_COLUMNS & set(df.columns)
        if bad:
            sys.exit(f"{program}/{n} has identifying columns {sorted(bad)}; not written.")
        if df.astype(str).apply(lambda c: c.str.contains(BLOCKED_VALUE)).any().any():
            sys.exit(f"{program}/{n} has identifying text; not written.")
    target = os.path.join(OUT, f"{program}_dqa_summary_shareable.xlsx")
    with pd.ExcelWriter(target, engine="openpyxl") as xl:
        for n, df in kept.items():
            df.to_excel(xl, sheet_name=n[:31], index=False)
            ws = xl.sheets[n[:31]]
            ws.freeze_panes = "A2"
            for i, c in enumerate(df.columns, 1):
                ws.column_dimensions[ws.cell(1, i).column_letter].width = min(60, max(len(str(c)), *(len(str(v)) for v in df[c].head(100))) + 2) if len(df) else len(str(c)) + 2
    print(f"{program}: kept {len(kept)} of {len(sheets)} sheets -> {os.path.relpath(target, ROOT)}")
print("\nDropped sheets are the row-level ones (flags and records). Do not share the files in <program>/dqa/output/.")

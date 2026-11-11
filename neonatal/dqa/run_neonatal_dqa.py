"""Runs the DQA SQL scripts against the database (pivot query used as the `mahis_pivot` CTE)
and writes mahis_dqa_summary.xlsx plus one CSV per sheet into ./output.
Database settings come from environment variables or .env (see mahis_db.py and the README)."""
import os
import re
import sys

import io
import subprocess

import pandas as pd

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
sys.path.insert(0, os.path.join(HERE, "..", ".."))
from mahis_db import DB_CONFIG  # noqa: E402

OUT = os.path.join(HERE, "output")
os.makedirs(OUT, exist_ok=True)

pivot = open(os.path.join(ROOT, "mahis_neonatal_pivot.sql")).read()
pivot = re.sub(r"(?m)^\s*--.*$", "", pivot).strip().rstrip(";")
# other_progs columns already exist in the base pivot; a CTE cannot carry duplicate column names
pivot = re.sub(r",\s*op\.\*", "", pivot)

MAHIS_PIVOT = f"mahis_pivot AS (\n{pivot}\n)"

SHEETS = [
    ("02_summary_overall.sql", "Overall_Summary"),
    ("03_summary_by_field.sql", "Field_Summary"),
    ("04_baby_dq_flags.sql", "Baby_DQ_Flags"),
    ("01_baby_level_records.sql", "Baby_Level_Records"),
    ("05_dictionary_fields_not_in_pivot.sql", "Not_In_Pivot"),
]


def run(script):
    text = open(os.path.join(HERE, script)).read()
    text = re.sub(r"(?m)^\s*--.*$", "", text).replace("SET SESSION group_concat_max_len = 1000000;", "").strip().rstrip(";")
    if text.startswith("WITH "):
        text = "WITH RECURSIVE " + MAHIS_PIVOT + ",\n\n" + text[len("WITH "):]
    env = dict(os.environ, MYSQL_PWD=DB_CONFIG["password"])
    r = subprocess.run(["mysql", "-h", DB_CONFIG["host"], "-P", DB_CONFIG["port"], "-u", DB_CONFIG["user"], DB_CONFIG["database"],
                        "--batch"], input="SET SESSION group_concat_max_len = 1000000;\n" + text + ";", text=True,
                       capture_output=True, env=env)
    if r.returncode:
        raise SystemExit(r.stderr)
    return pd.read_csv(io.StringIO(r.stdout), sep="\t", keep_default_na=False, na_values=["NULL"], dtype=str, escapechar="\\")


results = [(sheet, run(script)) for script, sheet in SHEETS]  # run everything first so a failure never leaves a half-written file

tmp = os.path.join(OUT, "mahis_dqa_summary.tmp.xlsx")
with pd.ExcelWriter(tmp, engine="openpyxl") as xl:
    for sheet, df in results:
        df.to_csv(os.path.join(OUT, f"{sheet}.csv"), index=False)
        df.to_excel(xl, sheet_name=sheet, index=False)
        ws = xl.sheets[sheet]
        ws.freeze_panes = "A2"
        for i, c in enumerate(df.columns, 1):
            width = min(60, max(len(str(c)), *(len(str(v)) for v in df[c].head(200))) + 2) if len(df) else len(str(c)) + 2
            ws.column_dimensions[ws.cell(1, i).column_letter].width = width
        print(sheet, df.shape)
os.replace(tmp, os.path.join(OUT, "mahis_dqa_summary.xlsx"))

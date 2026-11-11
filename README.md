# MAHIS MNH data quality assessment (DQA)

Scripts that check how completely the MAHIS database fills the fields required by the MNH data dictionaries, for four programs: **Neonatal, ANC, Labour and Delivery (L&D) and PNC**. One command rebuilds every result.

The findings are summarised in [docs/MAHIS_DQA_Summary.md](docs/MAHIS_DQA_Summary.md).

> **Data protection.** The scripts are safe to share. Their *outputs* are not, except the files in `shared/`. See [Data protection](#data-protection) before sending anything to anyone.

## What you need

- Python 3.9 or newer
- The `mysql` command-line client on your PATH (`mysql --version` should work)
- Network access to a MAHIS database and a **read-only** database user
- Optional: `pdftotext` (poppler-utils), only to re-extract a dictionary from its PDF

## Run it

```bash
git clone <this repository>
cd mahis-mnh-dqa

python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env        # then edit .env with your database settings

python3 run_all.py
```

This takes about 4 to 5 minutes (ANC is the slowest). When it finishes:

| Where | What | Share it? |
|---|---|---|
| `shared/<program>_dqa_summary_shareable.xlsx` | Counts and percentages only | Yes |
| `<program>/dqa/output/*.xlsx` and `*.csv` | Full results, with one row per woman, baby or visit | **No** |

To run one or two programs, or skip the share-safe step:

```bash
python3 run_all.py --only anc pnc
python3 run_all.py --skip-shareable
```

If a run stops, the message says which program failed. Nothing half-written is left behind, because each workbook is only saved once all its queries have succeeded.

## What each program produces

Each full workbook has the same kinds of sheets (the names start with the group they cover, for example `Women_`, `Babies_`, `Monitoring_`, `Vitals_`):

- **Overall summary:** how many records have all mandatory fields, missing mandatory fields, and missing conditional fields, with percentages.
- **Field summary:** one row per checked field, with how many records had it filled and the percentage.
- **DQ flags:** one row per record, with the names of its missing fields.
- **Level records:** one row per woman or baby, with all visits combined and `number_of_visits`.
- **Not in pivot / Not assessable:** required dictionary fields that could not be checked, and why.

Labour and Delivery and PNC also assess monitoring rounds and vitals visits on their own, as the dictionaries make those fields mandatory per visit.

## How it works

1. **A pivot script** (`mahis_<program>_pivot.sql`) turns the program's data into one wide table, one row per person per visit date. Coded answers are decoded to their names, and values are kept as stored.
2. **The DQA scripts** (`<program>/dqa/0*.sql`) take that table (called `mahis_pivot` inside each script) and check it against the dictionary rules.
3. **A runner** (`run_<program>_dqa.py`) runs the pivot and each DQA script against your database and writes the workbook.

The DQA SQL files are generated from the dictionary rules in `build_*_dqa_scripts.py`. To change a rule, edit that file and run it, then run the runner again:

```bash
python3 anc/dqa/build_anc_dqa_scripts.py
python3 anc/dqa/run_anc_dqa.py
```

If a dictionary changes, regenerate its field list from the PDF, then rebuild:

```bash
python3 tools/extract_dictionary.py "MNH Data Dictionary.xlsx - ANC.pdf" anc/dqa/anc_dictionary_fields.tsv
```

The dictionary PDFs are not in this repository.

## Layout

```
mahis_db.py              reads the database settings from .env or environment variables
run_all.py               runs every program, then make_shareable.py
make_shareable.py        builds shared/*.xlsx from the aggregate sheets only (and checks them)
neonatal/                mahis_neonatal_pivot.sql, dqa/ (rules, SQL, runner)
anc/                     mahis_anc_pivot.sql, dqa/
ld/                      mahis_ld_pivot.sql, mahis_ld_monitoring.sql, mahis_ld_vitals.sql, dqa/
pnc/                     mahis_pnc_pivot.sql, mahis_pnc_vitals.sql, dqa/
tools/                   extract_dictionary.py
docs/                    the plain-language summary
```

## Data protection

The database holds personal health information. **Only the files in `shared/` may leave the team.** Everything else the scripts write is git-ignored on purpose; do not force-add it.

These are the identifying items in the full outputs. None of them appear in `shared/`:

| Item | Where it appears |
|---|---|
| **Names**: `mother_name` holds full names | Neonatal records |
| **Staff usernames** (for example in sign-off text) | `clinician_notes`, `person_making_request`, `staff_conducting_delivery` |
| **ART / ARV numbers** | `art_number`, `arv_number_identifier`, `other_programs_art_number` |
| **Other identifiers**: `mother_identifier`, national and other ID numbers | Neonatal records |
| **Phone numbers** | `phone_number` (L&D) |
| **Dates and place** | `birthdate`, visit and delivery dates |
| **Free text** (can contain anything, including names) | notes, "specify" and comment columns |
| **HIV and ART status** | sensitive health information, row-level |

Rules:

- Share `shared/*.xlsx` and the summary document, nothing else from `output/`.
- Never commit `.env`. Use a read-only database user, and change the password if it was ever shared.

## Troubleshooting

| Message | What to do |
|---|---|
| `Missing database settings` | Create `.env` from `.env.example`, or export the `MAHIS_DB_*` variables. |
| `mysql: command not found` | Install the MySQL or MariaDB client. |
| `Can't connect to MySQL server` (error 110 or 2003) | The database is not reachable. Check your VPN or network and run again. |
| `Access denied` | Check the user and password in `.env`. The user only needs read access. |
| A run takes much longer than 5 minutes | The ANC pivot reads about 60,000 observations; a slow connection makes it slower. |

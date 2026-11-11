# MAHIS Data Quality Summary: Maternal and Newborn Health Programs

Prepared November 2026. Programs: Neonatal, ANC, Labour and Delivery (L&D), PNC. HIV is at an early stage.

**Method.** For each program, the fields the MNH data dictionary marks as required were checked against the data in the MAHIS database. A field counts as filled if anything was recorded, including "No", "None" or "Unknown". Records are one woman or one baby with all their visits combined. Only active (non-voided) data was used.

## Headline results

| Program | Records checked | Records with every mandatory field filled | Average share of mandatory fields filled | Required fields not found in the data |
|---|---|---|---|---|
| Neonatal | 8 babies | 0 | 69% | 31 |
| ANC | 741 women | 0 | 53% | 52 |
| L&D | 33 women, 13 baby records | 0 women, 1 baby | 42% women, 22% babies | 60 |
| PNC | 75 women | 3 | 22% | 6 |

No program reaches full completeness, and the low-scoring fields differ by program. Data windows are short (ANC from 4 July, L&D and PNC from 29 July, all to 20 August 2026; the 8 neonatal babies run to 20 October), and three of the samples are small, so read the percentages as a pattern, not a rate. "Not found" means the dictionary requires the field but no matching column exists in the extract; whether MAHIS does not capture it or stores it elsewhere still needs checking.

## Neonatal

**Results.** 13 of 95 mandatory fields are filled for every baby, and 25 are filled for under half. Weakest: frequency of stooling 12%, colour 25%, and head circumference, vitamin K, type of birth and TEO at 38%. 6 of 8 babies are missing at least one conditional field (wet nappies per day 17%).

| Measure | Count | % |
|---|---|---|
| Total babies | 8 | 100.0% |
| Babies with ALL mandatory fields present | 0 | 0.0% |
| Babies with MISSING mandatory fields | 8 | 100.0% |
| Babies with required conditional fields missing | 6 | 75.0% |
| Babies with all mandatory AND all required conditional fields present | 0 | 0.0% |
| Babies with required conditional fields (any triggered) | 8 | 100.0% |
| Average mandatory completeness (% per baby) | - | 68.9% |
| Average required-conditional completeness (% per baby) | - | 84.4% |

**Observations.** Lab orders for these babies sit in the lab program. Some newborn details (weight, HIV status) sit in the PNC record. The columns for "type of birth" and "time of birth" hold each other's content. Sign-off details are stored as text inside the clinician notes. "Flat", "Pink skin" and "Hyperthermia" exist as fields but are really answers to other questions, and six defined fields have no data anywhere.

**Recommendations.** Make the weakest mandatory fields required on the form. Correct the birth-type and birth-time naming. Store sign-off in its own fields. Retire answer-type and unused concepts. Show lab results with the baby's neonatal record.

## ANC

**Results.** 9 of 34 mandatory fields are filled for under half the women: ultrasound date 0%, first tetanus vaccine date 0%, last menstrual period 1%, pregnancy outcome 10%. Pregnancy confirmed is 98%. 15 women (2%) miss a conditional field. Among 16 HIV-positive women, ART status is 100%, HIV test date 75% and ART number 56%.

| Measure | Count | % |
|---|---|---|
| Total women | 741 | 100.0% |
| Women with ALL mandatory fields present | 0 | 0.0% |
| Women with MISSING mandatory fields | 741 | 100.0% |
| Women with required conditional fields missing | 15 | 2.0% |
| Women with all mandatory AND all required conditional fields present | 0 | 0.0% |
| Women with required conditional fields (any triggered) | 740 | 99.9% |
| Average mandatory completeness (% per woman) | - | 53.2% |
| Average required-conditional completeness (% per woman) | - | 99.3% |

**Observations.** History questions are mostly asked at the first contact, so women who started before the extract window look incomplete; 167 of 908 patients with visits have no recorded data at all. Previous pregnancies, fetuses and lab tests repeat: 498 previous-pregnancy entries were saved for 459 distinct pregnancies. Gestation weeks are stored as text, and measurement fields contain "Machine not available" (oxygen saturation has more of these than readings). Dates are stored as text in two formats. HIV is recorded in the HIV status field, not in chronic conditions as the dictionary expects. 15 tetanus-date fields are required, many duplicates.

**Recommendations.** Save previous-pregnancy history once, with a pregnancy number. Store numbers and dates as typed values and record "reason not measured" separately. Make pregnancy outcome and last menstrual period required. Base the dictionary's HIV conditions on HIV status, and remove the duplicate tetanus-date fields.

## Labour and Delivery

**Results.** Women: no one has every mandatory field. Weakest are HIV test date, expected delivery date, last menstrual period and tetanus details (0%); strongest are danger signs 88% and medications 85%. Baby records: baby weight is filled for all 13, but APGAR, head circumference, delivery date and time for only 1. Labour monitoring: 1 of 11 rounds is complete and urine fields are 9 to 18%. Vitals: 31 of 35 visits are complete.

**Women**

| Measure | Count | % |
|---|---|---|
| Total women | 33 | 100.0% |
| Women with ALL mandatory fields present | 0 | 0.0% |
| Women with MISSING mandatory fields | 33 | 100.0% |
| Women with required conditional fields missing | 0 | 0.0% |
| Women with all mandatory AND all required conditional fields present | 0 | 0.0% |
| Women with required conditional fields (any triggered) | 1 | 3.0% |
| Average mandatory completeness (% per woman) | - | 42.3% |
| Average required-conditional completeness (% per woman) | - | 100.0% |

**Baby records**

| Measure | Count | % |
|---|---|---|
| Total babies | 13 | 100.0% |
| Babies with ALL mandatory fields present | 1 | 7.7% |
| Babies with MISSING mandatory fields | 12 | 92.3% |
| Babies with required conditional fields missing | 0 | 0.0% |
| Babies with all mandatory AND all required conditional fields present | 1 | 7.7% |
| Babies with required conditional fields (any triggered) | 0 | 0.0% |
| Average mandatory completeness (% per baby) | - | 22.0% |
| Average required-conditional completeness (% per baby) | - | - |

**Labour monitoring rounds**

| Measure | Count | % |
|---|---|---|
| Total monitoring rounds | 11 | 100.0% |
| Women with at least one monitoring round | 9 | - |
| Monitoring rounds with ALL mandatory fields present | 1 | 9.1% |
| Monitoring rounds with MISSING mandatory fields | 10 | 90.9% |
| Average mandatory completeness (% per monitoring round) | - | 48.5% |

**Vitals visits**

| Measure | Count | % |
|---|---|---|
| Total Vitals encounters | 35 | 100.0% |
| Women with at least one Vitals encounter | 31 | - |
| Vitals encounters with ALL mandatory fields present | 31 | 88.6% |
| Vitals encounters with MISSING mandatory fields | 4 | 11.4% |
| Average mandatory completeness (% per Vitals encounter) | - | 95.4% |

**Observations.** Of 46 patients, 13 are baby records. Only 3 of 12 babies are linked to a mother; the other 9 were registered with only a registration and a vitals visit. One record has no birthdate or sex and is linked to another person as "Aunt/Uncle", saved twice. The woman's obstetric history is largely missing here, though ANC holds it for a few. The dictionary requires membrane-rupture date and time for every woman. Each monitoring round is a separate visit.

**Recommendations.** Require birthdate, sex and mother link when a baby is registered, restrict newborn relationship types and block duplicates. Show ANC history inside the L&D record. Number monitoring rounds. Make APGAR, baby weight and delivery date/time required, and make membrane-rupture fields conditional.

## PNC

**Results.** The dictionary requires only 25 fields and none for babies. Women: 3 of 75 have all three mandatory HIV fields (mother's HIV status 56%, started ART 7%, ART clinic number 4%). Of 5 HIV-positive women, all have ART started recorded, 3 have an ART number and none has an ART facility. Vitals: 9 of 38 visits (24%) are complete; oxygen saturation is the gap at 32%.

**Women**

| Measure | Count | % |
|---|---|---|
| Total women | 75 | 100.0% |
| Women with ALL mandatory fields present | 3 | 4.0% |
| Women with MISSING mandatory fields | 72 | 96.0% |
| Women with required conditional fields missing | 5 | 6.7% |
| Women with all mandatory AND all required conditional fields present | 0 | 0.0% |
| Women with required conditional fields (any triggered) | 6 | 8.0% |
| Average mandatory completeness (% per woman) | - | 22.2% |
| Average required-conditional completeness (% per woman) | - | 16.7% |

**Vitals visits**

| Measure | Count | % |
|---|---|---|
| Total Vitals encounters | 38 | 100.0% |
| Women with at least one Vitals encounter | 37 | - |
| Vitals encounters with ALL mandatory fields present | 9 | 23.7% |
| Vitals encounters with MISSING mandatory fields | 29 | 76.3% |
| Average mandatory completeness (% per Vitals encounter) | - | 79.4% |

**Observations.** 62 of 84 baby records are linked to a mother, the best of any program. The dictionary lists the mother's vitals under ward monitoring, but they are recorded in the Vitals visits. Referral and death details are required for everyone.

**Recommendations.** Capture oxygen saturation or the reason it was not taken. Show ART number and facility on the form. Add conditions to the referral and death fields. Link the remaining 22 babies to their mothers.

## Issues for all developers

- **Typed values.** Save numbers as numbers and dates as dates, and keep "reason not measured" in its own field, not inside the measurement.
- **Explicit blanks.** Offer "Unknown", "Not done" and "Not applicable" so a blank always means "not asked".
- **Dictionary.** Add conditions to fields that do not apply to everyone, remove duplicates, and publish a machine-readable version with concept ids.
- **ART numbers** are held in the patient identifier table (types "Arv number" and "Legacy arv number"). Read that table as well as the form fields.
- **Reporting.** A maintained flattened view per program, and a scheduled run of the DQA scripts, would keep this visible without manual rework. Database access dropped repeatedly during this work, so a dedicated read-only reporting copy is worth considering.

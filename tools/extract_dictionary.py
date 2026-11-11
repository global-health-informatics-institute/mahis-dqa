"""Extract the field list (label, name, required, relevance) from an MNH data dictionary PDF into a TSV.

    python3 tools/extract_dictionary.py "MNH Data Dictionary.xlsx - ANC.pdf" anc/dqa/anc_dictionary_fields.tsv

Needs the `pdftotext` command (poppler-utils). The TSVs already committed under <program>/dqa/ were produced this way, so this is only
needed when a dictionary changes. Check the result by eye: long names can be cut off in the PDF.
"""
import csv
import html
import os
import re
import subprocess
import sys
import tempfile

pdf, out = sys.argv[1], sys.argv[2]
with tempfile.TemporaryDirectory() as tmp:
    bbox = os.path.join(tmp, "bbox.html")
    subprocess.run(["pdftotext", "-bbox", "-layout", pdf, bbox], check=True)
    pages = re.split(r"<page ", open(bbox).read())[1:]
rows = []
for page_no, pg in enumerate(pages, 1):
    words = [(float(a), float(b), float(c), float(d), html.unescape(w))
             for a, b, c, d, w in re.findall(r'<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">(.*?)</word>', pg)]
    hdr = {w[4]: w for w in words if w[4] in ("Label", "Name", "Description", "Required", "Editable?", "Relevance")}
    if "Required" not in hdr:
        continue
    xl, xn, xd, xr, xe, xv = (hdr[k][0] for k in ("Label", "Name", "Description", "Required", "Editable?", "Relevance"))
    body = [w for w in words if w[1] > hdr["Name"][3]]
    names = sorted([w for w in body if xn - 2 <= w[0] < xd - 2 and re.match(r"^[a-z]+_[a-z0-9_]+", w[4])], key=lambda w: w[1])
    req = [w for w in body if xr - 6 <= w[0] < xe - 2 and w[4] in ("Yes", "No", "Conditional")]
    for i, n in enumerate(names):
        y, ny = n[1], (names[i + 1][1] if i + 1 < len(names) else 1e9)
        r = [w for w in req if abs(w[1] - y) < 5]
        rel = " ".join(w[4] for w in sorted([w for w in body if w[0] >= xv - 2 and y - 4 <= w[1] < ny - 4], key=lambda w: (round(w[1]), w[0])))
        lab = " ".join(w[4] for w in sorted([w for w in body if xl - 2 <= w[0] < xn - 2 and y - 4 <= w[1] < ny - 4], key=lambda w: (round(w[1]), w[0])))
        rows.append((page_no, lab, n[4], r[0][4] if r else "?", rel))
with open(out, "w", newline="") as f:
    w = csv.writer(f, delimiter="\t")
    w.writerow(["page", "label", "name", "required", "relevance"])
    w.writerows(rows)
print(len(rows), "fields written to", out)

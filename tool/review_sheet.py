#!/usr/bin/env python3
"""Proofreading round-trip between assets/questions.json and a CSV sheet.

  export:  python3 tool/review_sheet.py export assets/questions.json review.csv
  import:  python3 tool/review_sheet.py import assets/questions.json review.csv

Open the CSV in Google Sheets or Excel (UTF-8 with BOM). For each row:
  - Fix text / passage / script / choice_1..4 / answer / explanation_en in place.
  - Furigana is written {漢字|かんじ}; fix wrong readings the same way.
  - Put 1 (or y / ok / ✓) in "ok" when the row is proofread.
  - Write anything for Claude in "comment" (questions, requests to rewrite).
Import applies every edit, sets "reviewed": true for rows marked ok, and
prints the comments so they can be handed back to Claude.
Rows not marked ok keep "reviewed": false (still edited).
"""
import csv
import json
import re
import sys

COLS = ["id", "section", "ok", "comment", "text", "passage", "script",
        "choice_1", "choice_2", "choice_3", "choice_4", "answer",
        "explanation_en", "noFurigana"]
OK = {"1", "y", "yes", "ok", "✓", "○", "true", "済"}
RUBY = re.compile(r"\{([^{}|]+)\|([^{}|]+)\}")


def load(path):
    return json.load(open(path, encoding="utf-8"))


def save(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
        f.write("\n")


def export(json_path, csv_path):
    data = load(json_path)
    with open(csv_path, "w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, COLS)
        w.writeheader()
        for q in data["questions"]:
            w.writerow({
                "id": q["id"],
                "section": q["category"],
                "ok": "1" if q.get("reviewed") else "",
                "comment": "",
                "text": q["text"],
                "passage": q.get("passage", ""),
                "script": "\n".join(f'{l["speaker"]}: {l["text"]}' for l in q.get("script", [])),
                **{f"choice_{i + 1}": c for i, c in enumerate(q["choices"])},
                "answer": q["answer"] + 1,
                "explanation_en": q["explanation"].get("en", ""),
                "noFurigana": "1" if q.get("noFurigana") else "",
            })
    print(f"exported {len(data['questions'])} rows -> {csv_path}")


def problems(q):
    errs = []
    texts = [q["text"], q.get("passage", ""), *q["choices"],
             *(l["text"] for l in q.get("script", []))]
    for t in texts:
        if RUBY.sub("", t).count("{") or RUBY.sub("", t).count("}"):
            errs.append(f"broken furigana: {t}")
    plain = [RUBY.sub(lambda m: m[1], c) for c in q["choices"]]
    if len(set(plain)) != 4 or any(not c.strip() for c in plain):
        errs.append("choices must be 4 distinct non-empty values")
    if not 0 <= q["answer"] < 4:
        errs.append("answer must be 1-4")
    if q["category"] == "listen" and not q.get("script"):
        errs.append("listening question needs a script")
    if q["category"] == "read" and not q.get("passage"):
        errs.append("reading question needs a passage")
    return errs


def parse_script(s):
    lines = []
    for raw in s.splitlines():
        raw = raw.strip()
        if not raw:
            continue
        m = re.match(r"^([MFN])\s*[:：]\s*(.*)$", raw)
        if not m:
            raise ValueError(f"script line must start with M:/F:/N: -> {raw}")
        lines.append({"speaker": m[1], "text": m[2]})
    return lines


def do_import(json_path, csv_path):
    data = load(json_path)
    by_id = {q["id"]: q for q in data["questions"]}
    rows = list(csv.DictReader(open(csv_path, encoding="utf-8-sig", newline="")))
    changed, approved, comments, failed = 0, 0, [], []
    for r in rows:
        q = by_id.get(r["id"].strip())
        if q is None:
            failed.append((r["id"], ["unknown id"]))
            continue
        before = json.dumps(q, ensure_ascii=False, sort_keys=True)
        new = dict(q)
        new["text"] = r["text"].strip()
        if r.get("passage", "").strip():
            new["passage"] = r["passage"].strip()
        else:
            new.pop("passage", None)
        try:
            script = parse_script(r.get("script", ""))
        except ValueError as e:
            failed.append((q["id"], [str(e)]))
            continue
        if script:
            new["script"] = script
        else:
            new.pop("script", None)
        new["choices"] = [r[f"choice_{i}"].strip() for i in range(1, 5)]
        try:
            new["answer"] = int(str(r["answer"]).strip()) - 1
        except ValueError:
            failed.append((q["id"], ["answer must be 1-4"]))
            continue
        new["explanation"] = {**q["explanation"], "en": r["explanation_en"].strip()}
        if r.get("noFurigana", "").strip():
            new["noFurigana"] = True
        else:
            new.pop("noFurigana", None)
        ok = r.get("ok", "").strip().lower() in OK
        errs = problems(new)
        if errs:
            failed.append((q["id"], errs))
            continue
        new.pop("reviewed", None)
        new["reviewed"] = ok  # keep "reviewed" as the last key
        q.clear()
        q.update(new)
        if json.dumps(q, ensure_ascii=False, sort_keys=True) != before:
            changed += 1
        approved += ok
        if r.get("comment", "").strip():
            comments.append((q["id"], r["comment"].strip()))
    save(json_path, data)
    total = len(data["questions"])
    done = sum(1 for q in data["questions"] if q.get("reviewed"))
    print(f"rows: {len(rows)}  changed: {changed}  marked ok: {approved}")
    print(f"reviewed overall: {done}/{total}")
    for qid, errs in failed:
        print(f"NOT APPLIED {qid}: " + "; ".join(errs))
    if comments:
        print("\n--- comments for Claude ---")
        for qid, c in comments:
            print(f"{qid}: {c}")
    return 1 if failed else 0


if __name__ == "__main__":
    if len(sys.argv) != 4 or sys.argv[1] not in ("export", "import"):
        sys.exit(__doc__)
    sys.exit(export(*sys.argv[2:]) if sys.argv[1] == "export" else do_import(*sys.argv[2:]))

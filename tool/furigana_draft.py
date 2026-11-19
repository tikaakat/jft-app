#!/usr/bin/env python3
"""Adds draft furigana markup {漢字|かんじ} to assets/questions.json.

- Skips questions with "noFurigana": true and text that already has markup.
- Uses SudachiPy (pip install sudachipy sudachidict_core) + correction rules.
- Output is a DRAFT: readings must be checked during proofreading.

Usage:
  python3 tool/furigana_draft.py assets/questions.json            # write
  python3 tool/furigana_draft.py assets/questions.json --dry-run  # list readings
"""
import json
import re
import sys
from collections import Counter

from sudachipy import Dictionary, SplitMode

KANJI = r"[一-鿿々]"  # CJK + 々
tok = Dictionary().create(SplitMode.C)


def hira(s: str) -> str:
    return "".join(chr(ord(c) - 0x60) if "ァ" <= c <= "ヶ" else c for c in s)


def annotate_token(surface: str, reading: str) -> str:
    """Align okurigana so only kanji runs get ruby: 買い物 -> {買|か}い{物|もの}."""
    if not re.search(KANJI, surface):
        return surface
    reading = hira(reading)
    runs = re.findall(rf"{KANJI}+|[^一-鿿々]+", surface)
    pattern = "".join("(.+?)" if re.match(KANJI, r) else re.escape(hira(r)) for r in runs)
    m = re.fullmatch(pattern, reading)
    if not m:
        return f"{{{surface}|{reading}}}"
    out, g = [], iter(m.groups())
    for r in runs:
        out.append(f"{{{r}|{next(g)}}}" if re.match(KANJI, r) else r)
    return "".join(out)


WEEKDAY = dict(zip("月火水木金土日", ["げつ", "か", "すい", "もく", "きん", "ど", "にち"]))

# Context fixes Sudachi gets wrong (applied to the marked-up text).
FIXES = [
    (r"\{何\|なん\}(?=[をがもかと])", "{何|なに}"),
    (r"(?<=[3３])\{階\|かい\}", "{階|がい}"),
    (r"\{何\|なに\}(?=\{(?:階|時|曜日|番|枚|人|年|月|日|回|個|分|歳)\|)", "{何|なん}"),
    (r"\{何\|なん\}\{階\|かい\}", "{何|なん}{階|がい}"),
    (r"\{一\|いち\}\{つ\|つ\}", "{一|ひと}つ"),
    (r"\{日本\|にっぽん\}", "{日本|にほん}"),
    (r"\{日本語\|にっぽんご\}", "{日本語|にほんご}"),
    (r"\{方\|ほう\}(?=は)", "{方|かた}"),  # ご希望の方は
    (r"\{明日\|あす\}", "{明日|あした}"),
    (r"\{箱\|ばこ\}", "{箱|はこ}"),
    (r"\{開\|ひら\}(?=いて)", "{開|あ}"),  # 窓が/店が 開いて いる
    (r"\{角\|かく\}", "{角|かど}"),
    (r"\{何時\|いつ\}", "{何時|なんじ}"),
    (r"\{何\|が\}", "{何|なん}"),
    (r"\{今日\|こんにち\}\{中\|ちゅう\}", "{今日|きょう}{中|じゅう}"),
    (r"\{何曜\|なんよう\}\{日\|ひ\}", "{何曜日|なんようび}"),
    (r"\{割\|わり\}\{引\|ひ\}き", "{割引|わりび}き"),
    (r"\{日・祝\|にちしゅく\}\{日\|ひ\}", "{日|にち}・{祝日|しゅくじつ}"),
    # Weekday abbreviations in schedules: 月・水・金, 水：缶, （土）
    (r"(?:^|(?<=[・\n（(：:]))\{([月火水木金土日])\|[^{}|]+\}(?=[・：:）)\s　])",
     lambda m: "{%s|%s}" % (m[1], WEEKDAY[m[1]])),
    (r"\{日\|にち\}\{中\|ちゅう\}", "{日|にち}{中|じゅう}"),  # 一日中
    (r"(?<=[013468])\{分\|ふん\}", "{分|ぷん}"),  # 10分, 30分 -> ぷん
]


def annotate(text: str) -> str:
    if "{" in text:
        return text  # already annotated
    out = []
    for line in text.split("\n"):
        out.append("".join(annotate_token(m.surface(), m.reading_form())
                           for m in tok.tokenize(line)))
    s = "\n".join(out)
    for pat, rep in FIXES:
        s = re.sub(pat, rep, s, flags=re.M)
    return s


def main():
    path = sys.argv[1]
    dry = "--dry-run" in sys.argv
    data = json.load(open(path, encoding="utf-8"))
    pairs = Counter()
    for q in data["questions"]:
        if q.get("noFurigana"):
            continue
        q["text"] = annotate(q["text"])
        if "passage" in q:
            q["passage"] = annotate(q["passage"])
        q["choices"] = [annotate(c) for c in q["choices"]]
        for line in q.get("script", []):
            line["text"] = annotate(line["text"])
        blob = json.dumps(q, ensure_ascii=False)
        pairs.update(re.findall(r"\{([^{}|]+)\|([^{}|]+)\}", blob))
    for (b, r), n in sorted(pairs.items()):
        print(f"{b}\t{r}\t{n}")
    if not dry:
        json.dump(data, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        open(path, "a", encoding="utf-8").write("\n")


if __name__ == "__main__":
    main()

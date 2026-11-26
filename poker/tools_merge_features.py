"""公式サイトから自動で取り出した、ポーカー特有の項目を店のデータに足す。
見つかった項目だけを「あり」として載せる（記載が見つからない＝無い、とはしない）。サイトの文章そのものは保存しない。"""
import json, re, sys, unicodedata
cr = json.load(open(sys.argv[1])); feat = json.load(open(sys.argv[2]))
d = json.load(open("data/tokyo_venues.json"))
NOT_VENUE = re.compile(r"株式会社|合同会社|有限会社|協会|Japan Open Poker Tour")
def N(s): return unicodedata.normalize("NFKC", s)
kept = []
for v in d["venues"]:
    if NOT_VENUE.search(v["name"]):
        continue  # 会社の事務所など、店ではないもの
    f = feat.get(v["name"])
    if f:
        t = N(cr[v["name"]]["text"])
        addrs = list(dict.fromkeys(re.findall(r"東京都" + re.escape(v["ward"]) + r"[^\n\s、,]{2,40}", t)))
        addr = None
        if len(addrs) == 1: addr = addrs[0]
        else:
            for a in addrs:
                if any(tok in a for tok in re.findall(r"[一-龠]{2,}", v["name"])): addr = a; break
        if addr and not v.get("address"):
            v["address"] = addr; v["address_source"] = "official"
        v["features"] = [k for k in ("lesson", "tournament", "ring", "satellite", "drink_free", "nonsmoking", "women_student", "rental", "no_cash") if f.get(k)]
        if v.get("nonsmoking"): v["features"].append("nonsmoking")
        if f.get("tables"): v["tables"] = f["tables"]
        if f.get("min_price"): v["min_price"] = f["min_price"]
        v["features_checked_on"] = "2026-11-26"
    else:
        v.setdefault("features", ["nonsmoking"] if v.get("nonsmoking") else [])
    if v.get("late_night") and "late_night" not in v["features"]: v["features"].append("late_night")
    v["features"] = sorted(set(v["features"]))
    kept.append(v)
d["venues"] = kept
json.dump(d, open("data/tokyo_venues.json", "w"), ensure_ascii=False, indent=1)
from collections import Counter
v23 = [v for v in kept if v["in_23wards"]]
print(len(v23), "with address", sum(1 for v in v23 if v.get("address")), Counter(f for v in v23 for f in v["features"]))

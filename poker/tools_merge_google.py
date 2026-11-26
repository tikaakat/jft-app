"""Google Places の検索結果（店の発見と営業状況の確認に使う）を、東京の店のデータに統合する。
Google の規約に合わせ、保存するのは place_id、店名、区、公式サイトの URL、営業状況と確認日だけにする。住所や営業時間は、店の掲載情報や公式サイトを出典にする。"""
import json, re, sys, unicodedata
g = json.load(open(sys.argv[1]))
DROP = {"イタリア酒場 casino カジーノ", "株式会社INSPIRE VIP CASINO CLUB"}
d = json.load(open("data/tokyo_venues.json"))
def norm(s): return unicodedata.normalize("NFKC", s or "").replace("−", "-").replace("ー", "-").replace("‐", "-")
def akey(a):
    a = norm(a).replace("丁目", "-").replace("番地", "-").replace("番", "-").replace("号", "")
    m = re.search(r"区([^\d\s]+?)(\d+)-(\d+)(?:-(\d+))?", a)
    return m and (m.group(1), m.group(2), m.group(3), m.group(4) or "")
def nkey(s): return re.sub(r"[^a-z0-9ぁ-んァ-ヶ一-龠]", "", norm(s).lower())
existing = d["venues"]
by_addr = {}
for v in existing:
    k = akey(v.get("address"))
    if k: by_addr.setdefault(k, []).append(v)
added = matched = closed = 0
for p in g:
    name = p["displayName"]["text"]
    if name in DROP: continue
    gk = akey(p.get("formattedAddress"))
    cands = by_addr.get(gk, []) if gk else []
    hit = None
    for v in cands:
        a, b = nkey(v["name"]), nkey(name)
        if a[:4] in b or b[:4] in a or len(cands) == 1: hit = v; break
    status = p.get("businessStatus", "")
    if hit:
        hit.update(google_place_id=p["id"], google_status=status, google_checked_on="2026-11-26")
        if p.get("websiteUri") and not hit.get("official"): hit["official"] = p["websiteUri"]
        matched += 1; continue
    if status == "CLOSED_PERMANENTLY": closed += 1; continue
    k = {"poker": "ポーカー専門", "casino": "カジノバー（ポーカーを含む）"}.get(p["_k"], "要確認")
    existing.append({"name": name, "kind": k, "ward": p["_ward"], "in_23wards": True,
                     "google_place_id": p["id"], "google_status": status, "google_checked_on": "2026-11-26",
                     "official": p.get("websiteUri", ""), "status": "google", "checked_on": "2026-11-26",
                     "source": f"https://www.google.com/maps/place/?q=place_id:{p['id']}"})
    added += 1
# Google で見つからなかった既存の店に印を付ける
for v in existing:
    if v.get("status") != "google" and "google_place_id" not in v and v["in_23wards"]:
        v["google_status"] = "NOT_FOUND"
# 手がかりのうち、Google で見つかった名前を消す
names = " ".join(nkey(v["name"]) for v in existing)
d["leads"] = [l for l in d["leads"] if not (nkey(l["name"])[:5] and nkey(l["name"])[:5] in names)]
d["note"] += " / google = Google マップで営業中を確認（住所などは店の公式情報で確認中）"
d["venues"] = sorted(existing, key=lambda v: (v["ward"], v["name"]))
json.dump(d, open("data/tokyo_venues.json", "w"), ensure_ascii=False, indent=1)
from collections import Counter
print("matched", matched, "added", added, "closed skipped", closed, "leads left", len(d["leads"]))
print("23区内", sum(v["in_23wards"] for v in d["venues"]), Counter(v["status"] for v in d["venues"]))
print(Counter(v["kind"] for v in d["venues"] if v["in_23wards"]))
print("NOT_FOUND:", [v["name"] for v in d["venues"] if v.get("google_status") == "NOT_FOUND"])
print("leads:", [l["name"] for l in d["leads"]])

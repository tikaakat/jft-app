"""ホットペッパーの店舗掲載情報（店が載せた事実）と、手がかりの一覧から、東京の店のデータを作る。"""
import csv, json, re, sys
src = json.load(open(sys.argv[1]))
EXCLUDE = {"ECHIGO PORKer 燕三", "ボードゲームカフェONE", "FUTURE LAND TOKYO　下北沢", "ポーカードッグ"}
BAR = ["トリガー", "HATAGAYA", "EDGE", "side", "starry eye", "NINE THREE", "LIBERTY", "Cheers", "635Lounge", "COZY", "煌", "BACKDOOR"]
CASINO = ["BLOW", "ARIES"]
RENTAL = ["Family Pot"]
def kind(n):
    if any(k in n for k in RENTAL): return "レンタルスペース"
    if any(k in n for k in CASINO): return "カジノバー（ポーカーを含む）"
    if any(k in n for k in BAR): return "ポーカーも遊べるバー"
    return "ポーカー専門"
def late(h):
    return bool(re.search(r"翌[1-9]:", h or ""))
venues = []
for x in src:
    n = x["name"].strip()
    if n in EXCLUDE or "住所" not in x: continue
    addr = x["住所"]
    m = re.search(r"東京都(.+?[区市])", addr)
    ward = m.group(1) if m else ""
    venues.append({
        "name": re.sub(r"\s+", " ", n).replace("　", " "), "kind": kind(n), "ward": ward,
        "in_23wards": ward.endswith("区"), "address": addr, "access": x.get("アクセス", ""),
        "hours": x.get("営業時間", ""), "closed": x.get("定休日", ""),
        "smoking": x.get("禁煙・喫煙", ""), "nonsmoking": "全席禁煙" in x.get("禁煙・喫煙", ""),
        "late_night": late(x.get("営業時間")), "seats": x.get("総席数", ""),
        "status": "store_listing", "source": x["url"], "checked_on": "2026-11-26",
    })
names = " ".join(v["name"] for v in venues)
leads = []
for r in csv.DictReader(open("data/tokyo_venue_leads.csv")):
    key = re.sub(r"[（(].*", "", r["name"]).replace(" ", "")[:6]
    if key and key in names.replace(" ", ""):
        continue
    leads.append({"name": r["name"], "ward": r["ward"], "area": r["area"], "in_23wards": r["in_23wards"] == "yes", "status": "lead", "note": r["status"]})
out = {"checked_on": "2026-11-26",
       "note": "status: store_listing = 店がホットペッパーに載せた情報で、住所と営業時間を確認 / lead = 手がかりのみ（未確認）",
       "venues": sorted(venues, key=lambda v: (v["ward"], v["name"])), "leads": leads}
json.dump(out, open("data/tokyo_venues.json", "w"), ensure_ascii=False, indent=1)
from collections import Counter
print(len(venues), "venues;", sum(v["in_23wards"] for v in venues), "in 23 wards;", len(leads), "leads left")
print(Counter(v["kind"] for v in venues)); print(Counter(v["ward"] for v in venues).most_common())
print("nonsmoking", sum(v["nonsmoking"] for v in venues), "late", sum(v["late_night"] for v in venues))

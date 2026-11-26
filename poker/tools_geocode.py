"""住所から位置（緯度・経度）を求める。国土地理院の住所検索（無料、キー不要）を使う。"""
import json, time, urllib.parse, urllib.request, re, unicodedata
d = json.load(open("data/tokyo_venues.json"))
n = ok = 0
for v in d["venues"]:
    if not v.get("address") or v.get("lat"): continue
    a = unicodedata.normalize("NFKC", v["address"])
    a = re.sub(r"^〒?\d{3}-\d{4}\s*", "", a)
    a = re.match(r"東京都\S+?区[^\s]*?\d+(?:[-丁目番地号]+\d+)*", a)
    if not a: continue
    q = a.group(0)
    url = "https://msearch.gsi.go.jp/address-search/AddressSearch?q=" + urllib.parse.quote(q)
    n += 1
    try:
        r = json.load(urllib.request.urlopen(url, timeout=20))
    except Exception as e:
        continue
    if r:
        lon, lat = r[0]["geometry"]["coordinates"]
        if 35.5 < lat < 35.9 and 139.5 < lon < 140.0:
            v["lat"], v["lng"] = round(lat, 5), round(lon, 5); v["geo_source"] = "国土地理院 住所検索"; ok += 1
    time.sleep(0.3)
json.dump(d, open("data/tokyo_venues.json", "w"), ensure_ascii=False, indent=1)
print("queried", n, "located", ok)

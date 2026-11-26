"""東京 23 区の境界（国土数値情報 行政区域データ）を、SVG の地図用に間引いて保存する。"""
import json, math, sys
from pathlib import Path
# 使い方: python3 tools_make_wardmap.py <GeoJSON のフォルダ> [ファイル名のパターン 出力先 経度の西端 経度の東端 緯度の北端 緯度の南端]
src = Path(sys.argv[1])
PATTERN = sys.argv[2] if len(sys.argv) > 2 else "131*.json"
OUTFILE = sys.argv[3] if len(sys.argv) > 3 else "data/tokyo_wards_svg.json"
W, H = 1000, 860
LON0, LON1, LAT0, LAT1 = (map(float, sys.argv[4:8]) if len(sys.argv) > 7 else (139.555, 139.935, 35.835, 35.515))
K = math.cos(math.radians(35.68))
sx = W / ((LON1 - LON0) * K); sy = H / (LAT0 - LAT1); s = min(sx, sy)
def xy(lon, lat): return ((lon - LON0) * K * s, (LAT0 - lat) * s)
def simplify(pts, tol=1.2):
    out = [pts[0]]
    for p in pts[1:]:
        if math.dist(p, out[-1]) >= tol: out.append(p)
    return out
def area(pts): return abs(sum(a[0]*b[1]-b[0]*a[1] for a, b in zip(pts, pts[1:]+pts[:1]))) / 2
wards = {}
for f in sorted(src.glob(PATTERN)):
    try:
        json.load(open(f))["features"][0]
    except Exception:
        continue
    gj = json.load(open(f))
    name = gj["features"][0]["properties"]["N03_004"]
    paths = []; cx = cy = tot = 0
    for feat in gj["features"]:
        g = feat["geometry"]; polys = g["coordinates"] if g["type"] == "MultiPolygon" else [g["coordinates"]]
        for poly in polys:
          for rr in poly:
            ring = simplify([xy(*c) for c in rr])
            a = area(ring)
            if len(ring) < 4 or a < 30: continue
            paths.append("M" + "L".join(f"{x:.0f},{y:.0f}" for x, y in ring) + "Z")
            mx = sum(p[0] for p in ring) / len(ring); my = sum(p[1] for p in ring) / len(ring)
            cx += mx * a; cy += my * a; tot += a
    wards[name] = {"d": "".join(paths), "cx": round(cx / tot), "cy": round(cy / tot)}
out = {"source": "国土数値情報（行政区域データ）を加工して作成", "viewBox": f"0 0 {W} {H}",
       "proj": {"lon0": LON0, "lat0": LAT0, "k": K, "s": s}, "wards": wards}
json.dump(out, open(OUTFILE, "w"), ensure_ascii=False)
print(len(wards), Path(OUTFILE).stat().st_size, "bytes")

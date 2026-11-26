"""ガイドの Markdown と大会の JSON から、静的なサイトを poker/site/ に生成する。"""
import html, json, re, shutil
from pathlib import Path
import markdown

ROOT = Path(__file__).parent
OUT = ROOT / "site"
SITE_NAME = "ポーカーマップ（仮）"
BASE_URL = "https://example.com"  # ドメイン取得後に差し替える

REGIONS = {
    "KR": ("韓国（済州・仁川）", "korea"),
    "TW": ("台湾（台北）", "taiwan"),
    "PH": ("フィリピン（マニラ）", "philippines"),
    "MO": ("マカオ", "macau"),
    "US": ("ラスベガス（WSOP）", "lasvegas"),
}
STATUS = {
    "official": ("公式発表", "s-official"),
    "third_party": ("第三者情報", "s-third"),
    "expected": ("見込み", "s-expected"),
    "conflict": ("要確認：中止の情報あり", "s-third"),
}

CSS = """
:root{--bg:#fbfaf7;--fg:#1d1d1f;--muted:#6b6b70;--line:#e3e1dc;--card:#fff;--accent:#0b6e4f;
--ok:#0b6e4f;--warn:#9a6700;--info:#3b5bdb}
@media (prefers-color-scheme:dark){:root:not([data-theme=light]){--bg:#141416;--fg:#ececee;--muted:#a1a1a8;
--line:#2c2c30;--card:#1c1c1f;--accent:#4fd1a5;--ok:#4fd1a5;--warn:#e3b341;--info:#8da2fb;color-scheme:dark}}
:root[data-theme=dark]{--bg:#141416;--fg:#ececee;--muted:#a1a1a8;--line:#2c2c30;--card:#1c1c1f;--accent:#4fd1a5;--ok:#4fd1a5;--warn:#e3b341;--info:#8da2fb;color-scheme:dark}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);
font:16px/1.75 system-ui,-apple-system,"Hiragino Sans","Noto Sans JP",sans-serif}
header,main,footer{max-width:1040px;margin:0 auto;padding:0 16px}
header{display:flex;gap:16px;align-items:center;flex-wrap:wrap;padding-top:16px;padding-bottom:8px;border-bottom:1px solid var(--line)}
header .logo{font-weight:700;color:var(--fg);text-decoration:none;margin-right:auto}
header nav a{color:var(--muted);text-decoration:none;margin-left:12px;font-size:14px}
a{color:var(--accent)}h1{font-size:1.6rem;line-height:1.4}h2{font-size:1.2rem;margin-top:2em;border-bottom:1px solid var(--line);padding-bottom:4px}
blockquote{margin:1em 0;padding:8px 14px;border-left:4px solid var(--accent);background:var(--card);color:var(--muted)}
.checked{color:var(--muted);font-size:14px}
.tbl{width:100%;overflow-x:auto}table{border-collapse:collapse;width:100%;font-size:14px}
th,td{border-bottom:1px solid var(--line);padding:8px 6px;text-align:left;vertical-align:top}
th{color:var(--muted);font-weight:600;white-space:nowrap}
.badge{display:inline-block;font-size:12px;padding:1px 8px;border-radius:999px;border:1px solid currentColor;white-space:nowrap}
.s-official{color:var(--ok)}.s-third{color:var(--warn)}.s-expected{color:var(--info)}
.cards{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:12px;padding:0;list-style:none}
.cards li{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:12px 14px}
.cards a{text-decoration:none;font-weight:600}
footer{margin-top:48px;padding-top:16px;padding-bottom:32px;border-top:1px solid var(--line);color:var(--muted);font-size:13px}
.venue{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:12px 14px;margin:10px 0}
.venue h3{margin:0 0 4px;font-size:1.05rem}.venue dl{display:grid;grid-template-columns:5.5em 1fr;gap:2px 8px;margin:6px 0 0;font-size:14px}
.venue dt{color:var(--muted)}.venue dd{margin:0}.tags{display:flex;gap:6px;flex-wrap:wrap}
.filters{display:flex;gap:8px;flex-wrap:wrap;margin:12px 0}.filters label{font-size:14px;border:1px solid var(--line);border-radius:999px;padding:4px 10px;background:var(--card)}
.filters select{font:inherit;font-size:14px;padding:4px 8px;border-radius:8px;border:1px solid var(--line);background:var(--card);color:var(--fg)}

.lead{font-size:1.05rem}.muted{color:var(--muted)}.small{font-size:13px}.h-small{font-size:1rem;border:0;margin:1.4em 0 .6em;padding:0}
.crumb{font-size:13px;color:var(--muted);margin:12px 0 0}
.stats{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin:16px 0}.stats div{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:12px}
.stats b{display:block;font-size:1.7rem;line-height:1.2;font-variant-numeric:tabular-nums;color:var(--accent)}.stats span{font-size:13px;color:var(--muted)}
.two{display:grid;grid-template-columns:1fr 1fr;gap:24px}@media(max-width:640px){.two{grid-template-columns:1fr}}
.bars{list-style:none;padding:0;margin:0;display:grid;gap:6px}.bars li{display:grid;grid-template-columns:minmax(0,11em) 1fr 2.5em;gap:8px;align-items:center;font-size:13px}
.bl{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.bt{background:var(--line);border-radius:4px;height:10px;overflow:hidden}.bf{display:block;height:100%;background:var(--accent);border-radius:4px}.bn{text-align:right;font-variant-numeric:tabular-nums}
.finder{background:var(--bg);border-bottom:1px solid var(--line);padding:4px 0 8px;margin-top:20px}
.pchips{display:flex;flex-wrap:wrap;gap:6px}.pchip{font:inherit;font-size:13px;padding:6px 12px;border-radius:999px;border:1px solid var(--line);background:var(--card);color:var(--fg);cursor:pointer}
.pchip[aria-pressed=true]{background:var(--accent);border-color:var(--accent);color:var(--bg);font-weight:600}.pchip:focus-visible,.btn:focus-visible,.linkbtn:focus-visible{outline:2px solid var(--accent);outline-offset:2px}
.frow{display:flex;flex-wrap:wrap;gap:10px;align-items:center;margin-top:8px}.frow select{font:inherit;font-size:14px;padding:6px 8px;border-radius:8px;border:1px solid var(--line);background:var(--card);color:var(--fg)}
.tog{font-size:14px}.linkbtn{font:inherit;font-size:13px;background:none;border:0;color:var(--accent);cursor:pointer;text-decoration:underline}
.fcount{margin:6px 0 0;font-size:14px;font-weight:600}
.group h2 span{font-size:.85rem;font-weight:400;margin-left:4px}
.vgrid{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:12px}
.v{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px;display:flex;flex-direction:column;gap:8px;min-width:0}
.v[hidden],.group[hidden]{display:none}
.v-head{display:flex;justify-content:space-between;gap:8px;align-items:flex-start}.v-head h3{margin:0;font-size:1rem;line-height:1.4;overflow-wrap:anywhere}
.kind{flex:none;font-size:11px;padding:2px 8px;border-radius:999px;border:1px solid currentColor;white-space:nowrap}.k-ok{color:var(--ok)}.k-chk{color:var(--warn)}
.v-loc{margin:0;font-size:13px;color:var(--muted);overflow-wrap:anywhere}
.chips{list-style:none;padding:0;margin:0;display:flex;flex-wrap:wrap;gap:4px}.chips li{font-size:12px;padding:2px 8px;border-radius:6px;background:color-mix(in srgb,var(--accent) 14%,transparent);color:var(--fg)}
.v-actions{display:flex;gap:8px;flex-wrap:wrap}.btn{font-size:13px;padding:5px 12px;border-radius:8px;border:1px solid var(--accent);color:var(--accent);text-decoration:none}
details summary{cursor:pointer;font-size:13px;color:var(--muted)}details dl{display:grid;grid-template-columns:5.5em 1fr;gap:2px 8px;font-size:13px;margin:8px 0}details dt{color:var(--muted)}details dd{margin:0;overflow-wrap:anywhere}
.note{margin-top:32px}
@media(min-width:900px){.finder{position:sticky;top:0;z-index:5}}
ul.task{list-style:none;padding-left:0}ul.task li::before{content:"☐ ";color:var(--accent)}
"""


def load_events():
    data = json.loads((ROOT / "data/overseas_events.json").read_text())
    evs = sorted(data["events"], key=lambda e: e["start"])
    return data["checked_on"], evs


def fmt_date(e):
    s, t = e["start"], e.get("end")
    def f(d):
        p = d.split("-")
        return f"{int(p[0])}年{int(p[1])}月" + (f"{int(p[2])}日" if len(p) == 3 else "ごろ")
    if not t:
        return f(s)
    if len(s) == 10 and len(t) == 10:
        if s[:4] == t[:4]:
            return f(s) + "〜" + f"{int(t[5:7])}月{int(t[8:10])}日"
    return f(s) + "〜" + f(t)


def events_table(evs, show_region=True):
    rows = []
    for e in evs:
        label, cls = STATUS[e["status"]]
        region = REGIONS[e["country"]][0]
        venue = " / ".join(x for x in [e.get("city"), e.get("venue")] if x)
        buyin = e.get("main_buyin") or "—"
        memo = f"<br><small>{html.escape(e['memo'])}</small>" if e.get("memo") else ""
        rows.append(
            "<tr>"
            f"<td>{fmt_date(e)}</td>"
            f"<td><strong>{html.escape(e['name'])}</strong>{memo}</td>"
            + (f"<td><a href=\"/guide/{REGIONS[e['country']][1]}/\">{region}</a></td>" if show_region else "")
            + f"<td>{html.escape(venue)}</td><td>{html.escape(buyin)}</td>"
            f"<td><span class=\"badge {cls}\">{label}</span> <a href=\"{html.escape(e['source'])}\" rel=\"nofollow noopener\">出典</a></td>"
            "</tr>")
    head = "<tr><th>日程</th><th>大会</th>" + ("<th>地域</th>" if show_region else "") + "<th>場所</th><th>メインの参加費</th><th>確かさ</th></tr>"
    return f'<div class="tbl"><table><thead>{head}</thead><tbody>{"".join(rows)}</tbody></table></div>'


def jsonld(evs):
    items = []
    for e in evs:
        if e["status"] != "official" or len(e["start"]) != 10:
            continue
        items.append({
            "@context": "https://schema.org", "@type": "Event", "name": e["name"],
            "startDate": e["start"], "endDate": e.get("end") or e["start"],
            "eventAttendanceMode": "https://schema.org/OfflineEventAttendanceMode",
            "eventStatus": "https://schema.org/EventScheduled",
            "location": {"@type": "Place", "name": e.get("venue") or e["city"],
                         "address": {"@type": "PostalAddress", "addressLocality": e["city"], "addressCountry": e["country"]}},
            "url": e["source"],
        })
    if not items:
        return ""
    return '<script type="application/ld+json">' + json.dumps(items, ensure_ascii=False) + "</script>"


def page(path, title, desc, body, extra_head=""):
    full = f"{title} | {SITE_NAME}" if title != SITE_NAME else title
    doc = f"""<!doctype html><html lang="ja"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{html.escape(full)}</title><meta name="description" content="{html.escape(desc)}">
<link rel="canonical" href="{BASE_URL}{path}">
<meta property="og:title" content="{html.escape(full)}"><meta property="og:description" content="{html.escape(desc)}">
<meta property="og:type" content="website"><link rel="icon" href="data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22%3E%3Ctext y=%22.9em%22 font-size=%2290%22%3E%E2%99%A0%3C/text%3E%3C/svg%3E"><style>{CSS}</style>{extra_head}</head><body>
<header><a class="logo" href="/">{SITE_NAME}</a><nav><a href="/">海外の大会</a><a href="/guide/">遠征ガイド</a><a href="/tokyo/">東京の店</a><a href="/about/">編集方針</a></nav></header>
<main>{body}</main>
<footer>掲載内容は確認日時点のものです。参加や支払いの前に、必ず主催者と政府の公式情報を確認してください。
このサイトはオンラインポーカー・オンラインカジノを案内しません。<a href="/owners/">店主の方へ</a><br>© {SITE_NAME}</footer></body></html>"""
    dest = OUT / path.strip("/") / "index.html" if path != "/" else OUT / "index.html"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(doc)
    return path


def parse_md(p):
    meta_txt, body = p.read_text().split("\n---\n", 1)
    meta = dict(l.split(": ", 1) for l in meta_txt.strip().splitlines())
    return meta, body


def render_md(body, evs):
    def repl(m):
        sub = [e for e in evs if e["country"] == m.group(1)]
        return events_table(sub, show_region=False) if sub else "<p>掲載できる大会はまだありません。</p>"
    out = markdown.markdown(body, extensions=["tables"])
    out = re.sub(r"<li>\[ \] ", "<li>", out)
    out = re.sub(r"<ul>(\s*<li>)", r'<ul class="task">\1', out) if "[ ]" in body else out
    return re.sub(r"<p>\{\{events:(\w\w)\}\}</p>", repl, out)


def main():
    if OUT.exists():
        shutil.rmtree(OUT)
    checked, evs = load_events()
    paths = []

    body = f"""<h1>海外のポーカー大会の日程と、遠征で損をしないためのガイド</h1>
<p>アジア（韓国、台湾、フィリピン、マカオ）とラスベガスで開かれるライブのポーカー大会を、日本から参加する人向けにまとめています。
おすすめや感想ではなく、公式情報の出典と確認日を付けて、<strong>誰がやっても同じ結果になる手順</strong>を載せます。</p>
<p class="checked">大会情報の最終確認日：{checked}</p>
<h2>今後の大会</h2>{events_table(evs)}
<h2>遠征ガイド</h2>{guide_cards()}"""
    paths.append(page("/", SITE_NAME, "アジアとラスベガスのポーカー大会の日程と、日本から参加するときの入国手続き、お金、税金のチェックリスト。出典と確認日付き。", body, jsonld(evs)))

    paths.append(page("/guide/", "遠征ガイド", "海外のポーカー大会に日本から参加するための、共通チェックリストと地域別ガイドの一覧。",
                      "<h1>遠征ガイド</h1><p>まず共通チェックリストを読み、次に行き先の地域のページを確認してください。</p>" + guide_cards()))

    for p in sorted((ROOT / "content/guide").glob("*.md")):
        meta, body = parse_md(p)
        sub = [e for e in evs if e["country"] == meta.get("region")]
        html_body = render_md(body, evs)
        if meta.get("checked"):
            html_body = html_body.replace("</h1>", f"</h1><p class=\"checked\">最終確認日：{meta['checked']}</p>", 1)
        paths.append(page(f"/guide/{p.stem}/", meta["title"], meta["description"], html_body, jsonld(sub)))

    tokyo_pages(paths)
    meta, body = parse_md(ROOT / "content/owners.md")
    paths.append(page("/owners/", meta["title"], meta["description"], render_md(body, evs)))
    meta, body = parse_md(ROOT / "content/about.md")
    paths.append(page("/about/", meta["title"], meta["description"], render_md(body, evs)))

    page("/404/", "ページが見つかりません", "ページが見つかりません。", '<h1>ページが見つかりません</h1><p><a href="/">トップへ戻る</a></p>')
    (OUT / "404.html").write_text((OUT / "404/index.html").read_text())
    (OUT / "robots.txt").write_text(f"User-agent: *\nAllow: /\nSitemap: {BASE_URL}/sitemap.xml\n")
    urls = "".join(f"<url><loc>{BASE_URL}{p}</loc><lastmod>{checked}</lastmod></url>" for p in paths)
    (OUT / "sitemap.xml").write_text(f'<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">{urls}</urlset>')
    print(f"built {len(paths)} pages -> {OUT}")


WARDS = {"千代田区":"chiyoda","中央区":"chuo","港区":"minato","新宿区":"shinjuku","文京区":"bunkyo","台東区":"taito","墨田区":"sumida","江東区":"koto","品川区":"shinagawa","目黒区":"meguro","大田区":"ota","世田谷区":"setagaya","渋谷区":"shibuya","中野区":"nakano","杉並区":"suginami","豊島区":"toshima","北区":"kita","荒川区":"arakawa","板橋区":"itabashi","練馬区":"nerima","足立区":"adachi","葛飾区":"katsushika","江戸川区":"edogawa"}
VSTATUS = {"store_listing": "店舗の掲載情報", "press": "記事など", "google": "Google マップ"}
AREAS = [
    ("shinjuku-area", "新宿・高田馬場", ["新宿区"]),
    ("shibuya-area", "渋谷・恵比寿・目黒", ["渋谷区", "目黒区"]),
    ("minato-area", "六本木・赤坂・新橋", ["港区"]),
    ("central-area", "銀座・日本橋・秋葉原・神田", ["中央区", "千代田区"]),
    ("ikebukuro-area", "池袋・大塚・巣鴨", ["豊島区", "文京区"]),
    ("east-area", "上野・浅草・錦糸町", ["台東区", "墨田区", "江東区", "荒川区"]),
    ("north-area", "北千住・赤羽・葛西ほか", ["足立区", "北区", "葛飾区", "江戸川区", "板橋区"]),
    ("south-area", "品川・五反田・蒲田", ["品川区", "大田区"]),
    ("setagaya-area", "下北沢・三軒茶屋", ["世田谷区"]),
    ("west-area", "中野・高円寺・荻窪・練馬", ["中野区", "杉並区", "練馬区"]),
]
WARD_AREA = {w: (aid, an) for aid, an, ws in AREAS for w in ws}
FEATS = [
    ("lesson", "初心者講習あり", "はじめてでも安心"),
    ("tournament", "トーナメントあり", "トーナメントに出たい"),
    ("ring", "リングゲームあり", "リングゲームで遊びたい"),
    ("satellite", "大会の予選・提携あり", "大きな大会を目指したい"),
    ("drink_free", "飲み放題あり", "飲み放題で遊びたい"),
    ("nonsmoking", "全席禁煙", "たばこの煙が苦手"),
    ("late_night", "深夜営業", "仕事帰りに遅くまで"),
    ("rental", "貸切・貸卓あり", "仲間内で貸し切りたい"),
    ("women_student", "女性・学生割引", "女性・学生の割引"),
]
FEAT_LABEL = {k: l for k, l, _ in FEATS}
KIND_SHORT = {"ポーカー専門": "ポーカー専門店", "カジノバー（ポーカーを含む）": "カジノバー", "ポーカーも遊べるバー": "ポーカーも遊べるバー", "レンタルスペース": "レンタルスペース", "要確認": "ポーカーの有無を確認中"}


def venue_card(v):
    kind = KIND_SHORT.get(v["kind"], v["kind"])
    area = WARD_AREA.get(v["ward"], ("", v["ward"]))
    loc = v.get("address") or f'{v["ward"]}（詳しい住所は地図で確認）'
    chips = "".join(f'<li>{FEAT_LABEL[f]}</li>' for f, _, _ in FEATS if f in v.get("features", []))
    chips = f'<ul class="chips">{chips}</ul>' if chips else '<p class="muted small">特徴はまだ確認できていません</p>'
    meta = []
    if v.get("hours"): meta.append(("営業時間", v["hours"]))
    if v.get("closed"): meta.append(("定休日", v["closed"]))
    if v.get("access"): meta.append(("行き方", v["access"]))
    if v.get("smoking"): meta.append(("たばこ", v["smoking"]))
    if v.get("tables"): meta.append(("卓の数", f'{v["tables"]} 卓（公式サイトの記載）'))
    NOLINK = ("ggpoker",)  # オンラインポーカーとの提携を公表している店の公式サイトにはリンクしない
    btns = []
    if v.get("google_place_id"): btns.append(f'<a class="btn" href="https://www.google.com/maps/place/?q=place_id:{v["google_place_id"]}" rel="nofollow noopener">地図を開く</a>')
    if v.get("official") and not any(k in v["official"].lower() for k in NOLINK): btns.append(f'<a class="btn" href="{html.escape(v["official"])}" rel="noopener">公式サイト</a>')
    srcs = [f'店の情報：{VSTATUS[v["status"]]}' + ("" if v["status"] == "google" else f'（<a href="{html.escape(v["source"])}" rel="nofollow noopener">出典</a>）') + f'、{v["checked_on"]}確認']
    if v.get("features_checked_on"): srcs.append(f'特徴：公式サイトの記載から読み取り、{v["features_checked_on"]}確認（記載が見つからない項目は表示していません）')
    if v.get("note"): srcs.append(html.escape(v["note"]))
    dl = "".join(f"<dt>{k}</dt><dd>{html.escape(x)}</dd>" for k, x in meta)
    details = f'<details><summary>詳しい情報と出典</summary>{"<dl>" + dl + "</dl>" if dl else ""}<p class="muted small">{"<br>".join(srcs)}</p></details>'
    return (f'<article class="v" data-kind="{html.escape(v["kind"])}" data-area="{area[0]}" data-f="{" ".join(v.get("features", []))}">'
            f'<div class="v-head"><h3>{html.escape(v["name"])}</h3><span class="kind k-{"chk" if v["kind"] == "要確認" else "ok"}">{kind}</span></div>'
            f'<p class="v-loc">{html.escape(area[1])}・{html.escape(loc)}</p>{chips}'
            f'<div class="v-actions">{"".join(btns)}</div>{details}</article>')


def filter_ui(show_area=True):
    chips = "".join(f'<button type="button" class="pchip" data-f="{k}" aria-pressed="false">{p}</button>' for k, _, p in FEATS)
    areas = "".join(f'<option value="{aid}">{an}</option>' for aid, an, _ in AREAS)
    area_sel = f'<select id="farea" aria-label="エリア"><option value="">すべてのエリア</option>{areas}</select>' if show_area else ""
    return f"""<section class="finder" aria-label="店を探す"><h2 class="h-small">目的から探す</h2><div class="pchips">{chips}</div>
<div class="frow">{area_sel}<label class="tog"><input type="checkbox" id="fpro"> ポーカー専門店だけ</label><button type="button" id="freset" class="linkbtn">条件をクリア</button></div>
<p class="fcount" id="fcount" aria-live="polite"></p></section>
<script>(function(){{function f(){{const on=[...document.querySelectorAll('.pchip[aria-pressed=true]')].map(b=>b.dataset.f);
const a=document.getElementById('farea'),pro=document.getElementById('fpro');let n=0;
document.querySelectorAll('.v').forEach(v=>{{const fs=v.dataset.f.split(' ');const ok=on.every(x=>fs.includes(x))&&(!a||!a.value||v.dataset.area===a.value)&&(!pro.checked||v.dataset.kind==='ポーカー専門');v.hidden=!ok;if(ok)n++}});
document.querySelectorAll('.group').forEach(g=>{{g.hidden=![...g.querySelectorAll('.v')].some(v=>!v.hidden)}});
document.getElementById('fcount').textContent=n+' 店が見つかりました'+(on.length?'（'+on.length+' つの条件）':'');}}
document.querySelectorAll('.pchip').forEach(b=>b.addEventListener('click',()=>{{b.setAttribute('aria-pressed',b.getAttribute('aria-pressed')!=='true');f()}}));
const a=document.getElementById('farea');if(a)a.addEventListener('change',f);document.getElementById('fpro').addEventListener('change',f);
document.getElementById('freset').addEventListener('click',()=>{{document.querySelectorAll('.pchip').forEach(b=>b.setAttribute('aria-pressed','false'));if(a)a.value='';document.getElementById('fpro').checked=false;f()}});
document.addEventListener('DOMContentLoaded',f);if(document.readyState!=='loading')f();}})();</script>"""


def bars(items, total):
    mx = max(n for _, n, _ in items) or 1
    rows = "".join(f'<li><span class="bl">{html.escape(l)}</span><span class="bt"><span class="bf" style="width:{n / mx * 100:.1f}%"></span></span><span class="bn">{n}</span></li>' for l, n, _ in items)
    return f'<ul class="bars">{rows}</ul>'


def venue_jsonld(vs):
    items = [{"@context": "https://schema.org", "@type": "EntertainmentBusiness", "name": v["name"],
              "address": {"@type": "PostalAddress", "streetAddress": v["address"], "addressRegion": "東京都", "addressCountry": "JP"}}
             for v in vs if v.get("address")]
    return '<script type="application/ld+json">' + json.dumps(items, ensure_ascii=False) + "</script>" if items else ""


def tokyo_pages(paths):
    d = json.loads((ROOT / "data/tokyo_venues.json").read_text())
    vs = [v for v in d["venues"] if v["in_23wards"]]
    KORDER = {"ポーカー専門": 0, "カジノバー（ポーカーを含む）": 1, "ポーカーも遊べるバー": 2, "レンタルスペース": 3, "要確認": 4}
    vs.sort(key=lambda v: (KORDER.get(v["kind"], 9), -len(v.get("features", [])), v["name"]))
    by_area = {aid: [v for v in vs if WARD_AREA.get(v["ward"], ("",))[0] == aid] for aid, _, _ in AREAS}
    pro = sum(1 for v in vs if v["kind"] == "ポーカー専門")
    area_items = sorted([(an, len(by_area[aid]), aid) for aid, an, _ in AREAS], key=lambda x: -x[1])
    feat_items = [(l, sum(1 for v in vs if k in v.get("features", [])), k) for k, l, _ in FEATS]
    groups = "".join(f'<section class="group" id="{aid}"><h2>{an}<span class="muted">（{len(by_area[aid])} 店）</span></h2>'
                     f'<p class="muted small">{"・".join(f"<a href=\"/tokyo/{WARDS[w]}/\">{w}</a>" for w in ws if w in WARDS)}</p>'
                     f'<div class="vgrid">{"".join(venue_card(v) for v in by_area[aid])}</div></section>' for aid, an, ws in AREAS if by_area[aid])
    lead_names = "、".join(html.escape(l["name"]) for l in d["leads"] if l.get("in_23wards"))
    body = f"""<h1>東京のポーカー店ガイド</h1>
<p class="lead">東京 23 区のアミューズメントポーカーの店を、<strong>ポーカーならではの特徴</strong>（初心者講習、トーナメントとリングゲーム、大きな大会の予選、飲み放題、禁煙）で探せるようにまとめました。特徴は各店の公式サイトの記載から確認しています。</p>
<div class="stats"><div><b>{len(vs)}</b><span>掲載している店</span></div><div><b>{pro}</b><span>ポーカー専門店</span></div><div><b>{sum(1 for v in vs if v.get("features"))}</b><span>特徴を確認できた店</span></div></div>
<div class="two"><section><h2 class="h-small">どこに集まっているか</h2>{bars(area_items, len(vs))}</section>
<section><h2 class="h-small">特徴ごとの店の数</h2>{bars(feat_items, len(vs))}</section></div>
{filter_ui()}{groups}
<section class="note"><h2 class="h-small">このページについて</h2><p class="muted small">確認日：{d['checked_on']}。店の場所と営業状況は、店が掲載している情報、記事、Google マップで確認しています。来店前に、店の公式情報で最新の営業状況を確認してください。確認中の店：{lead_names}。<a href="/owners/">店主の方は、掲載内容の訂正や追加を無料で受け付けます</a>。</p></section>"""
    paths.append(page("/tokyo/", "東京のポーカー店ガイド", f"東京 23 区のアミューズメントポーカーの店 {len(vs)} 店を、初心者講習、トーナメント、リングゲーム、大会の予選、飲み放題、禁煙などの特徴で探せます。", body))
    by = {}
    for v in vs: by.setdefault(v["ward"], []).append(v)
    for w in [w for w in WARDS if w in by]:
        fi = [(l, sum(1 for v in by[w] if k in v.get("features", [])), k) for k, l, _ in FEATS]
        b = f"""<p class="crumb"><a href="/tokyo/">東京のポーカー店ガイド</a> › {w}</p><h1>{w}のポーカー店</h1>
<p class="lead">{w}にあるアミューズメントポーカーの店 {len(by[w])} 店を、初心者講習やトーナメントなどの特徴で探せます。</p>
{filter_ui(show_area=False)}<section class="group"><div class="vgrid">{"".join(venue_card(v) for v in by[w])}</div></section>"""
        paths.append(page(f"/tokyo/{WARDS[w]}/", f"{w}のポーカー店（{len(by[w])}店）", f"{w}のアミューズメントポーカーの店 {len(by[w])} 店。初心者講習、トーナメント、リングゲーム、飲み放題、禁煙などの特徴と場所。", b, venue_jsonld(by[w])))


def guide_cards():
    items = ['<li><a href="/guide/common/">共通チェックリスト</a><br><small>渡航前、お金、参加登録、入賞後、帰国後</small></li>']
    for code, (name, slug) in REGIONS.items():
        items.append(f'<li><a href="/guide/{slug}/">{name}</a><br><small>入国、会場、お金、今後の大会</small></li>')
    return f'<ul class="cards">{"".join(items)}</ul>'


if __name__ == "__main__":
    main()

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
--line:#2c2c30;--card:#1c1c1f;--accent:#4fd1a5;--ok:#4fd1a5;--warn:#e3b341;--info:#8da2fb}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);
font:16px/1.75 system-ui,-apple-system,"Hiragino Sans","Noto Sans JP",sans-serif}
header,main,footer{max-width:820px;margin:0 auto;padding:0 16px}
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
<meta property="og:type" content="website"><style>{CSS}</style>{extra_head}</head><body>
<header><a class="logo" href="/">{SITE_NAME}</a><nav><a href="/">大会日程</a><a href="/guide/">遠征ガイド</a><a href="/about/">編集方針</a></nav></header>
<main>{body}</main>
<footer>掲載内容は確認日時点のものです。参加や支払いの前に、必ず主催者と政府の公式情報を確認してください。
このサイトはオンラインポーカー・オンラインカジノを案内しません。<br>© {SITE_NAME}</footer></body></html>"""
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

    meta, body = parse_md(ROOT / "content/about.md")
    paths.append(page("/about/", meta["title"], meta["description"], render_md(body, evs)))

    (OUT / "robots.txt").write_text(f"User-agent: *\nAllow: /\nSitemap: {BASE_URL}/sitemap.xml\n")
    urls = "".join(f"<url><loc>{BASE_URL}{p}</loc><lastmod>{checked}</lastmod></url>" for p in paths)
    (OUT / "sitemap.xml").write_text(f'<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">{urls}</urlset>')
    print(f"built {len(paths)} pages -> {OUT}")


def guide_cards():
    items = ['<li><a href="/guide/common/">共通チェックリスト</a><br><small>渡航前、お金、参加登録、入賞後、帰国後</small></li>']
    for code, (name, slug) in REGIONS.items():
        items.append(f'<li><a href="/guide/{slug}/">{name}</a><br><small>入国、会場、お金、今後の大会</small></li>')
    return f'<ul class="cards">{"".join(items)}</ul>'


if __name__ == "__main__":
    main()

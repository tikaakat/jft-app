"""ガイドの Markdown と大会の JSON から、静的なサイトを poker/site/ に生成する。"""
import html, json, re, shutil
from pathlib import Path
import markdown

ROOT = Path(__file__).parent
OUT = ROOT / "site"
SITE_NAME = "ポーカー旅"
BASE_URL = "https://pokertabi.com"

REGIONS = {
    "KR": ("韓国（済州・仁川）", "korea"),
    "TW": ("台湾（台北）", "taiwan"),
    "PH": ("フィリピン（マニラ）", "philippines"),
    "MO": ("マカオ", "macau"),
    "US": ("ラスベガス", "lasvegas"),
}
STATUS = {
    "official": ("公式発表", "s-official"),
    "third_party": ("第三者情報", "s-third"),
    "expected": ("見込み", "s-expected"),
    "conflict": ("要確認：中止の情報あり", "s-third"),
}

CSS = """
:root{--bg:#f3f5f2;--fg:#14201a;--muted:#5b6a62;--line:#dbe2dc;--card:#fff;--accent:#0c6a4b;--gold:#9c7118;
--ok:#0c6a4b;--warn:#a05a00;--info:#3552b0;--felt:#0d5a41;--onfelt:#f4f0e3;--display:"Zen Kaku Gothic New",system-ui,"Hiragino Sans",sans-serif}
@media (prefers-color-scheme:dark){:root:not([data-theme=light]){--bg:#0b1310;--fg:#e7eee9;--muted:#98a79f;--line:#21302a;--card:#111c17;--accent:#4cc89c;--gold:#d8b058;
--ok:#4cc89c;--warn:#e2a54b;--info:#91a7ff;--felt:#0e3a2c;--onfelt:#f4f0e3;color-scheme:dark}}
:root[data-theme=dark]{--bg:#0b1310;--fg:#e7eee9;--muted:#98a79f;--line:#21302a;--card:#111c17;--accent:#4cc89c;--gold:#d8b058;--ok:#4cc89c;--warn:#e2a54b;--info:#91a7ff;--felt:#0e3a2c;--onfelt:#f4f0e3;color-scheme:dark}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);
font:16px/1.75 system-ui,-apple-system,"Hiragino Sans","Noto Sans JP",sans-serif}
header,main,footer{max-width:1040px;margin:0 auto;padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px))}
.topbar{border-bottom:1px solid var(--line);background:var(--bg)}
header{display:flex;gap:8px 20px;align-items:center;flex-wrap:wrap;padding-top:14px;padding-bottom:12px}
header .logo{display:flex;align-items:center;gap:8px;font:700 1.25rem/1 var(--display);color:var(--fg);text-decoration:none;margin-right:auto;letter-spacing:.02em}
header .logo svg{width:28px;height:28px}
header nav{display:flex;gap:4px 16px;flex-wrap:wrap}header nav a{color:var(--fg);text-decoration:none;font-size:14px;opacity:.75}header nav a:hover{opacity:1;color:var(--accent)}
a{color:var(--accent)}h1,h2,h3{font-family:var(--display);text-wrap:balance}h1{font-size:1.75rem;line-height:1.35;letter-spacing:.01em}
h2{font-size:1.25rem;margin-top:2em;padding-bottom:6px;border-bottom:2px solid var(--line)}
.hero{background:radial-gradient(120% 140% at 85% 0%,color-mix(in srgb,var(--felt) 70%,#2a7a5c) 0%,var(--felt) 55%,color-mix(in srgb,var(--felt) 80%,#000) 100%);color:var(--onfelt)}
.hero-in{max-width:1040px;margin:0 auto;padding:40px max(16px,env(safe-area-inset-right,0px)) 36px max(16px,env(safe-area-inset-left,0px));display:grid;gap:14px}
.hero .eyebrow{font-size:13px;letter-spacing:.12em;color:color-mix(in srgb,var(--onfelt) 75%,var(--gold))}
.hero h1{font-size:clamp(1.7rem,4.5vw,2.6rem);margin:0;color:var(--onfelt)}
.hero p{margin:0;max-width:38em;opacity:.9}
.cta{display:flex;gap:10px;flex-wrap:wrap;margin-top:6px}.cta a{padding:10px 18px;border-radius:10px;text-decoration:none;font-weight:600;font-size:15px}
.cta .pri{background:var(--onfelt);color:var(--felt)}.cta .sec{border:1px solid color-mix(in srgb,var(--onfelt) 55%,transparent);color:var(--onfelt)}
.suits{font-size:14px;letter-spacing:.4em;opacity:.55}
.evcards{display:grid;grid-template-columns:repeat(auto-fill,minmax(230px,1fr));gap:12px;margin-top:12px}
.ev{display:grid;grid-template-columns:auto 1fr;gap:12px;background:var(--card);border:1px solid var(--line);border-radius:12px;padding:12px;text-decoration:none;color:var(--fg);min-width:0}
.ev:hover{border-color:var(--accent)}
.ev .date{display:grid;place-items:center;align-content:center;width:58px;height:62px;border-radius:10px;background:color-mix(in srgb,var(--accent) 10%,var(--card));color:var(--accent);font-family:var(--display);line-height:1.1}
.ev .date b{font-size:1.35rem}.ev .date span{font-size:11px}
.ev h3{font-size:.95rem;margin:0 0 2px;line-height:1.4;overflow-wrap:anywhere}.ev p{margin:0;font-size:12.5px;color:var(--muted)}
.ctag{display:inline-block;font-size:11px;padding:0 7px;border-radius:5px;background:color-mix(in srgb,var(--gold) 16%,transparent);color:var(--fg);margin-right:4px}
.dests{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:10px;margin-top:12px}
.dest{display:block;background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px;text-decoration:none;color:var(--fg)}
.dest:hover{border-color:var(--accent)}.dest b{display:block;font-family:var(--display);font-size:1.05rem}.dest span{font-size:12.5px;color:var(--muted)}
.dest.jp{background:color-mix(in srgb,var(--accent) 8%,var(--card))}
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
.stats{grid-template-columns:repeat(4,1fr)}@media(max-width:520px){.stats{grid-template-columns:repeat(2,1fr)}}
.map{margin:16px 0;background:var(--card);border:1px solid var(--line);border-radius:12px;padding:8px}.map svg{width:100%;height:auto;display:block}
.ward{fill-rule:evenodd;stroke:var(--bg);stroke-width:2;transition:opacity .15s}.ward:hover{opacity:.8}
.l0{fill:var(--line)}.l1{fill:color-mix(in srgb,var(--accent) 18%,var(--card))}.l2{fill:color-mix(in srgb,var(--accent) 35%,var(--card))}.l3{fill:color-mix(in srgb,var(--accent) 55%,var(--card))}.l4{fill:color-mix(in srgb,var(--accent) 78%,var(--card))}
.wl{font-size:17px;fill:var(--fg);text-anchor:middle;pointer-events:none;paint-order:stroke;stroke:var(--card);stroke-width:4px;opacity:.85}
.dot{fill:var(--warn);stroke:var(--card);stroke-width:2;cursor:pointer}.dot.off{opacity:.12}
.map figcaption{display:flex;flex-wrap:wrap;gap:6px 16px;align-items:center;padding:6px 6px 2px}
.legend{display:flex;gap:14px;flex-wrap:wrap;font-size:12px}.legend span{display:inline-flex;align-items:center;gap:5px}.sw{display:inline-block;width:14px;height:10px;border-radius:2px}
.sw.l1{background:color-mix(in srgb,var(--accent) 18%,var(--card))}.sw.l4{background:color-mix(in srgb,var(--accent) 78%,var(--card))}
@media(max-width:640px){.pchips{flex-wrap:nowrap;overflow-x:auto;padding-bottom:4px;scrollbar-width:thin}.pchip{flex:none}.wl{font-size:24px}}
.dot-i{display:inline-block;width:9px;height:9px;border-radius:50%;background:var(--warn)}
.pchip .cnt{margin-left:6px;font-size:11px;opacity:.7;font-variant-numeric:tabular-nums}
.v{scroll-margin-top:12px}.v:target{outline:2px solid var(--warn)}

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


def page(path, title, desc, body, extra_head="", hero=""):
    full = f"{title} | {SITE_NAME}" if title != SITE_NAME else title
    doc = f"""<!doctype html><html lang="ja"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{html.escape(full)}</title><meta name="claude:viewport-fit-sides" content="cover"><meta name="description" content="{html.escape(desc)}">
<link rel="canonical" href="{BASE_URL}{path}">
<meta property="og:title" content="{html.escape(full)}"><meta property="og:description" content="{html.escape(desc)}">
<meta property="og:type" content="website"><link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Zen+Kaku+Gothic+New:wght@500;700&display=swap"><link rel="icon" href="data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22%3E%3Ctext y=%22.9em%22 font-size=%2290%22%3E%E2%99%A0%3C/text%3E%3C/svg%3E"><style>{CSS}</style>{extra_head}</head><body>
<div class="topbar"><header><a class="logo" href="/"><svg viewBox="0 0 32 32" aria-hidden="true"><circle cx="16" cy="16" r="15" fill="var(--felt)"/><circle cx="16" cy="16" r="12" fill="none" stroke="var(--gold)" stroke-width="1.2" stroke-dasharray="3 2.2"/><path d="M16 8c-3 3.6-6 5.6-6 8.4a3.2 3.2 0 0 0 5.2 2.5L14.4 23h3.2l-.8-4.1a3.2 3.2 0 0 0 5.2-2.5C22 13.6 19 11.6 16 8z" fill="var(--onfelt)"/></svg>{SITE_NAME}</a><nav><a href="/">世界の大会</a><a href="/guide/">遠征ガイド</a><a href="/tokyo/">日本の店</a><a href="/about/">編集方針</a></nav></header></div>{hero}
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

    today = "2026-11-26"
    upcoming = [e for e in evs if (e.get("end") or e["start"]) >= today[:len(e.get("end") or e["start"])]]
    CN = {"KR": "韓国", "TW": "台湾", "PH": "フィリピン", "MO": "マカオ", "US": "アメリカ"}
    def evcard(e):
        st = e["start"].split("-"); md = (f'<b>{int(st[2])}</b><span>{int(st[1])}月</span>' if len(st) == 3 else f'<b>{int(st[1])}月</b><span>ごろ</span>')
        label, cls = STATUS[e["status"]]
        return (f'<a class="ev" href="/guide/{REGIONS[e["country"]][1]}/"><div class="date">{md}</div><div><h3>{html.escape(e["name"])}</h3>'
                f'<p><span class="ctag">{CN[e["country"]]}</span>{html.escape(e.get("city") or "")}{"・〜" + str(int(e["end"][5:7])) + "/" + str(int(e["end"][8:10])) if e.get("end") and len(e["end"]) == 10 else ""}</p><p><span class="badge {cls}">{label}</span></p></div></a>')
    dests = "".join(f'<a class="dest" href="/guide/{slug}/"><b>{name}</b><span>大会 {sum(1 for e in upcoming if e["country"] == code)} 件・入国とお金</span></a>' for code, (name, slug) in REGIONS.items())
    tokyo_n = len([v for v in json.loads((ROOT / "data/tokyo_venues.json").read_text())["venues"] if v["in_23wards"]])
    dests += f'<a class="dest jp" href="/tokyo/"><b>日本</b><span>東京の店 {tokyo_n} 店</span></a>'
    hero = f"""<section class="hero"><div class="hero-in"><span class="eyebrow">WORLD POKER TRAVEL GUIDE</span>
<h1>世界のポーカー大会へ、<br>損をしない旅を。</h1>
<p>アジアとラスベガスの大会日程と、入国・お金・税金の手順。すべて公式情報の出典と確認日付きです。</p>
<div class="cta"><a class="pri" href="#events">次の大会を見る</a><a class="sec" href="/guide/common/">遠征の準備リスト</a></div>
<span class="suits" aria-hidden="true">♠ ♥ ♦ ♣</span></div></section>"""
    body = f"""<h2 id="events">次の大会</h2><div class="evcards">{"".join(evcard(e) for e in upcoming[:8])}</div>
<h2>行き先から選ぶ</h2><div class="dests">{dests}</div>
<h2>これからの大会の一覧</h2><p class="checked">確認日 {checked}。「公式発表」以外は、参加前に必ず主催者の発表を確認してください。</p>{events_table(upcoming)}"""
    paths.append(page("/", SITE_NAME, "世界のポーカー大会の日程と、日本から遠征するときの入国手続き、お金、税金のチェックリスト。アジアとラスベガスを中心に、出典と確認日付きで掲載。", body, jsonld(evs), hero))

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
    loc = re.sub(r"^(〒\S+\s*)?東京都", "", v.get("address") or v["ward"])
    chips = "".join(f'<li>{FEAT_LABEL[f]}</li>' for f, _, _ in FEATS if f in v.get("features", []))
    chips = f'<ul class="chips">{chips}</ul>' if chips else ""
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
    vid = "v-" + (v.get("google_place_id") or re.sub(r"\W", "", v["name"]))[-16:]
    return (f'<article class="v" id="{vid}" data-kind="{html.escape(v["kind"])}" data-area="{area[0]}" data-f="{" ".join(v.get("features", []))}">'
            f'<div class="v-head"><h3>{html.escape(v["name"])}</h3><span class="kind k-{"chk" if v["kind"] == "要確認" else "ok"}">{kind}</span></div>'
            f'<p class="v-loc">{html.escape(loc)}</p>{chips}'
            f'<div class="v-actions">{"".join(btns)}</div>{details}</article>')


def filter_ui(show_area=True, counts=None):
    counts = counts or {}
    chips = "".join(f'<button type="button" class="pchip" data-f="{k}" aria-pressed="false">{p}<span class="cnt">{counts.get(k, "")}</span></button>' for k, _, p in FEATS)
    areas = "".join(f'<option value="{aid}">{an}</option>' for aid, an, _ in AREAS)
    area_sel = f'<select id="farea" aria-label="エリア"><option value="">すべてのエリア</option>{areas}</select>' if show_area else ""
    return f"""<section class="finder" aria-label="店を探す"><div class="pchips">{chips}</div>
<div class="frow">{area_sel}<label class="tog"><input type="checkbox" id="fpro"> ポーカー専門店だけ</label><button type="button" id="freset" class="linkbtn">条件をクリア</button></div>
<p class="fcount" id="fcount" aria-live="polite"></p></section>
<script>(function(){{function f(){{const on=[...document.querySelectorAll('.pchip[aria-pressed=true]')].map(b=>b.dataset.f);
const a=document.getElementById('farea'),pro=document.getElementById('fpro');let n=0;
document.querySelectorAll('.v').forEach(v=>{{const fs=v.dataset.f.split(' ');const ok=on.every(x=>fs.includes(x))&&(!a||!a.value||v.dataset.area===a.value)&&(!pro.checked||v.dataset.kind==='ポーカー専門');v.hidden=!ok;if(ok)n++}});
document.querySelectorAll('.group').forEach(g=>{{g.hidden=![...g.querySelectorAll('.v')].some(v=>!v.hidden)}});
document.querySelectorAll('.dot').forEach(c=>{{const v=document.getElementById(c.dataset.v);c.classList.toggle('off',!v||v.hidden)}});
document.getElementById('fcount').textContent=n+' 店が見つかりました'+(on.length?'（'+on.length+' つの条件）':'');}}
document.querySelectorAll('.pchip').forEach(b=>b.addEventListener('click',()=>{{b.setAttribute('aria-pressed',b.getAttribute('aria-pressed')!=='true');f()}}));
const a=document.getElementById('farea');if(a)a.addEventListener('change',f);document.getElementById('fpro').addEventListener('change',f);
document.getElementById('freset').addEventListener('click',()=>{{document.querySelectorAll('.pchip').forEach(b=>b.setAttribute('aria-pressed','false'));if(a)a.value='';document.getElementById('fpro').checked=false;f()}});
document.addEventListener('DOMContentLoaded',f);if(document.readyState!=='loading')f();}})();</script>"""


def bars(items, total):
    mx = max(n for _, n, _ in items) or 1
    rows = "".join(f'<li><span class="bl">{html.escape(l)}</span><span class="bt"><span class="bf" style="width:{n / mx * 100:.1f}%"></span></span><span class="bn">{n}</span></li>' for l, n, _ in items)
    return f'<ul class="bars">{rows}</ul>'


def ward_map(vs):
    m = json.loads((ROOT / "data/tokyo_wards_svg.json").read_text()); pr = m["proj"]
    cnt = {}
    for v in vs: cnt[v["ward"]] = cnt.get(v["ward"], 0) + 1
    mx = max(cnt.values())
    def lvl(n): return 0 if not n else min(4, 1 + int(n / mx * 4))
    shapes = "".join(f'<a href="/tokyo/{WARDS[w]}/"><path class="ward l{lvl(cnt.get(w, 0))}" d="{g["d"]}"><title>{w}：{cnt.get(w, 0)} 店</title></path></a>' for w, g in m["wards"].items())
    labels = "".join(f'<text class="wl" x="{g["cx"]}" y="{g["cy"]}">{w[:-1]}</text>' for w, g in m["wards"].items())
    dots = ""
    for v in vs:
        if not v.get("lat"): continue
        x = (v["lng"] - pr["lon0"]) * pr["k"] * pr["s"]; y = (pr["lat0"] - v["lat"]) * pr["s"]
        vid = "v-" + (v.get("google_place_id") or re.sub(r"\W", "", v["name"]))[-16:]
        dots += f'<a href="#{vid}"><circle class="dot" data-v="{vid}" cx="{x:.1f}" cy="{y:.1f}" r="6"><title>{html.escape(v["name"])}</title></circle></a>'
    legend = '<div class="legend"><span><i class="sw l1"></i>少ない</span><span><i class="sw l4"></i>多い</span><span><i class="dot-i"></i>店の場所（住所を確認できた店）</span></div>'
    return (f'<figure class="map"><svg viewBox="{m["viewBox"]}" role="img" aria-label="東京 23 区のポーカー店の分布">{shapes}{labels}{dots}</svg>'
            f'<figcaption>{legend}<span class="muted small">区を押すと区のページへ。地図：{m["source"]}</span></figcaption></figure>')


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
                     
                     f'<div class="vgrid">{"".join(venue_card(v) for v in by_area[aid])}</div></section>' for aid, an, ws in AREAS if by_area[aid])
    lead_names = "、".join(html.escape(l["name"]) for l in d["leads"] if l.get("in_23wards"))
    fcounts = {k: sum(1 for v in vs if k in v.get("features", [])) for k, _, _ in FEATS}
    body = f"""<h1>東京のポーカー店ガイド</h1>
<p class="lead">23 区の {len(vs)} 店を、講習・トーナメント・大会の予選など<strong>ポーカーならではの特徴</strong>で探せます。</p>
<div class="stats"><div><b>{len(vs)}</b><span>店</span></div><div><b>{pro}</b><span>専門店</span></div><div><b>{fcounts["lesson"]}</b><span>講習あり</span></div><div><b>{fcounts["tournament"]}</b><span>大会あり</span></div></div>
{ward_map(vs)}
{filter_ui(counts=fcounts)}{groups}
<p class="muted small note">確認日 {d['checked_on']}。来店前に店の公式情報を確認してください。<a href="/owners/">店主の方へ（掲載・訂正は無料）</a></p>"""
    paths.append(page("/tokyo/", "東京のポーカー店ガイド", f"東京 23 区のアミューズメントポーカーの店 {len(vs)} 店を、初心者講習、トーナメント、リングゲーム、大会の予選、飲み放題、禁煙などの特徴で探せます。", body))
    by = {}
    for v in vs: by.setdefault(v["ward"], []).append(v)
    for w in [w for w in WARDS if w in by]:
        fi = [(l, sum(1 for v in by[w] if k in v.get("features", [])), k) for k, l, _ in FEATS]
        b = f"""<p class="crumb"><a href="/tokyo/">東京のポーカー店ガイド</a> › {w}</p><h1>{w}のポーカー店</h1>
<p class="lead">{len(by[w])} 店。特徴で絞り込めます。</p>
{filter_ui(show_area=False, counts={k: sum(1 for v in by[w] if k in v.get("features", [])) for k, _, _ in FEATS})}<section class="group"><div class="vgrid">{"".join(venue_card(v) for v in by[w])}</div></section>"""
        paths.append(page(f"/tokyo/{WARDS[w]}/", f"{w}のポーカー店（{len(by[w])}店）", f"{w}のアミューズメントポーカーの店 {len(by[w])} 店。初心者講習、トーナメント、リングゲーム、飲み放題、禁煙などの特徴と場所。", b, venue_jsonld(by[w])))


def guide_cards():
    items = ['<li><a href="/guide/common/">共通チェックリスト</a><br><small>渡航前、お金、参加登録、入賞後、帰国後</small></li>']
    for code, (name, slug) in REGIONS.items():
        items.append(f'<li><a href="/guide/{slug}/">{name}</a><br><small>入国、会場、お金、今後の大会</small></li>')
    return f'<ul class="cards">{"".join(items)}</ul>'


if __name__ == "__main__":
    main()

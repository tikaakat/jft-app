"""公開前のチェック：オンラインカジノ・オンラインポーカーへのリンクや、宣伝の語句が無いかを調べる。
リンク先（href）は、オンラインの賭博を運営する会社や、そのつながりがある店のドメインを禁止する。本文は宣伝の語句だけを禁止する（大会名や会場名に社名が入るのは許す）。"""
import re, sys
from pathlib import Path
BAD_HREF = re.compile(r"ggpoker|natural8|pokerstars|wptglobal|worldpokertour\.com|wsop\.com|kkpoker|kklive|pokerfans|theasianpokertour|stake\.com|online-?casino|vera-?john|bet365", re.I)
BAD_TEXT = re.compile(r"オンカジ|ベラジョン|入金ボーナス|初回入金|登録ボーナス")
ALLOW_HREF = ("npa.go.jp",)  # 警察庁のオンラインカジノ注意喚起ページ
bad = 0
for f in Path(__file__).parent.joinpath("site").rglob("*.html"):
    t = f.read_text()
    for h in re.findall(r'href="([^"]+)"', t):
        if BAD_HREF.search(h) and not any(a in h for a in ALLOW_HREF):
            print(f"{f}: link {h}"); bad += 1
    for m in BAD_TEXT.finditer(re.sub(r"<[^>]+>", " ", t)):
        print(f"{f}: text {m.group(0)}"); bad += 1
print("NG" if bad else "OK: no links to online gambling operators"); sys.exit(1 if bad else 0)

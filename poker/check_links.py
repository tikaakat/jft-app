"""公開前のチェック：オンラインカジノ・オンラインポーカーへのリンクや語句が無いかを調べる。"""
import re, sys
from pathlib import Path
BAD = re.compile(r"ggpoker|natural8|pokerstars\.(com|net|eu)|wpt global|wptglobal|stake\.com|online-?casino|オンカジ|ベラジョン|入金ボーナス", re.I)
ALLOW = ("このサイトはオンラインポーカー・オンラインカジノを案内しません",)
bad = 0
for f in Path(__file__).parent.joinpath("site").rglob("*.html"):
    for m in BAD.finditer(f.read_text()):
        print(f"{f}: {m.group(0)}"); bad += 1
print("NG" if bad else "OK: online gambling links not found"); sys.exit(1 if bad else 0)

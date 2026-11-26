"""site/ をプレビュー用（相対リンク、claude.ai の Artifact で見られる形）に変換して preview/ に出す。"""
import re, shutil
from pathlib import Path
ROOT = Path(__file__).parent; SRC = ROOT / "site"; OUT = ROOT / "preview"
if OUT.exists(): shutil.rmtree(OUT)
for f in SRC.rglob("*.html"):
    rel = f.relative_to(SRC)
    if rel.parts[0] == "404" or rel.name == "404.html": continue
    depth = len(rel.parts) - 1
    up = "../" * depth
    t = f.read_text()
    def fix(m):
        path = m.group(1).strip("/")
        return f'href="{up}{path + "/" if path else ""}index.html"'
    t = re.sub(r'href="(/[^"#]*?)"', fix, t)
    if rel.as_posix() == "index.html":  # main page: the host adds the document skeleton
        head = re.search(r"<head>(.*?)</head>", t, re.S).group(1)
        head = re.sub(r'<meta charset="utf-8">|<meta name="viewport"[^>]*>', "", head)
        body = re.search(r"<body>(.*)</body>", t, re.S).group(1)
        t = head + body
    dest = OUT / rel; dest.parent.mkdir(parents=True, exist_ok=True); dest.write_text(t)
print(len(list(OUT.rglob("*.html"))), "files")

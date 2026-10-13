"""One-time independent snapshot. Never modifies the original workspace."""
from pathlib import Path
import shutil, sqlite3
root = Path(__file__).resolve().parents[2]
source = root / 'output/asset-canvas'
dest = root / 'output/cat-studio'
if not dest.exists():
    dest.mkdir()
    for item in source.iterdir():
        if item.is_dir(): shutil.copytree(item, dest/item.name)
    with sqlite3.connect(source/'studio.sqlite') as src, sqlite3.connect(dest/'studio.sqlite') as dst:
        src.backup(dst)
    print('Independent snapshot created:', dest)
else:
    print('Existing snapshot retained:', dest)

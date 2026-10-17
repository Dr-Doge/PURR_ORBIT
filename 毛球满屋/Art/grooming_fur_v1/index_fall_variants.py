"""Index the 12 connected fur pieces without modifying the supplied PNG."""
from pathlib import Path
import hashlib
import json
from PIL import Image
import numpy as np

root = Path(__file__).parent
source = root / 'fur_fall_fx.png'
alpha = np.asarray(Image.open(source))[:, :, 3]
active = alpha > 32
height, width = active.shape
pieces = []
for y in range(height):
    for x in range(width):
        if not active[y, x]:
            continue
        stack = [(x, y)]
        active[y, x] = False
        xmin = xmax = x
        ymin = ymax = y
        area = 0
        while stack:
            px, py = stack.pop()
            area += 1
            xmin, xmax = min(xmin, px), max(xmax, px)
            ymin, ymax = min(ymin, py), max(ymax, py)
            for nx, ny in ((px-1, py), (px+1, py), (px, py-1), (px, py+1)):
                if 0 <= nx < width and 0 <= ny < height and active[ny, nx]:
                    active[ny, nx] = False
                    stack.append((nx, ny))
        if area > 2000:
            pieces.append([xmin, ymin, xmax+1, ymax+1, area])
pieces.sort(key=lambda p: (int(p[1] >= 450), p[0]))
assert len(pieces) == 12, pieces
sprites = {}
for i, (x0, y0, x1, y1, area) in enumerate(pieces):
    palette = 'gray' if i < 6 else 'cream'
    ordinal = i % 6
    role = 'clump' if ordinal < 3 else 'shard'
    name = f'fall_variant_{palette}_{ordinal+1}'
    x0, y0 = max(0, x0-2), max(0, y0-2)
    x1, y1 = min(width, x1+2), min(height, y1+2)
    sprites[name] = dict(file=source.name, region=[x0, y0, x1-x0, y1-y0], palette=palette, role=role)
    atlas_dir = root / 'fall_variants'
    atlas_dir.mkdir(exist_ok=True)
    (atlas_dir / f'{name}.tres').write_text(
        '[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n'
        '[ext_resource type="Texture2D" path="res://Art/grooming_fur_v1/fur_fall_fx.png" id="1"]\n\n'
        '[resource]\natlas = ExtResource("1")\n'
        f'region = Rect2({x0}, {y0}, {x1-x0}, {y1-y0})\nfilter_clip = true\n', encoding='utf-8')
result = dict(source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(), sprites=sprites)
(root / 'fall_variants.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print(json.dumps(result, ensure_ascii=False))

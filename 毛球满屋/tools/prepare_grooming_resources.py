"""Inspect generated PNGs without changing pixels; write Godot atlas resources."""
from pathlib import Path
import hashlib
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "Art" / "grooming_demo_v1"
NAMES = {
    "dirt_atlas": ["dust", "knot", "trash", "flea", "oil", "fingerprints", "soot", "tar"],
    "effects_atlas": ["fur_white", "fur_orange", "fur_gray", "dust_puff", "dirt_chips", "oil_fleck", "nail_tip", "sparkle"],
    "tools_atlas": ["comb", "cloth", "clipper", "coin"],
    "calico_states": ["calico_neutral", "calico_happy", "calico_discomfort", "calico_dirty_reference"],
    "robot_states": ["robot_neutral", "robot_happy", "robot_discomfort", "robot_dirty_reference"],
    "claw_atlas": ["claw_long", "claw_shallow", "claw_perfect", "claw_deep"],
}


def inspect():
    manifest = json.loads((ART / "asset_manifest.json").read_text(encoding="utf-8-sig"))
    resources = ART / "resources"
    resources.mkdir(exist_ok=True)
    data = {"logical_canvas": [1920, 1080], "images": {}, "sprites": {}, "checks": []}
    for asset in manifest["assets"]:
        path = ART / asset["file"]
        with Image.open(path) as image:
            width, height = image.size
            alpha = image.getchannel("A") if "A" in image.getbands() else None
            if asset["transparent_requested"]:
                assert alpha is not None and alpha.getextrema()[0] == 0, asset["id"]
                assert alpha.getpixel((0, 0)) == 0, asset["id"] + " corner"
            columns, rows = asset["grid"]
            data["images"][asset["id"]] = {
                "file": asset["file"], "size": [width, height], "mode": image.mode,
                "alpha_range": list(alpha.getextrema()) if alpha is not None else None,
                "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                "grid": [columns, rows],
            }
            names = NAMES.get(asset["id"], [asset["id"]])
            assert len(names) == columns * rows
            for index, name in enumerate(names):
                column, row = index % columns, index // columns
                left, top = width * column // columns, height * row // rows
                right, bottom = width * (column + 1) // columns, height * (row + 1) // rows
                region = [left, top, right - left, bottom - top]
                bounds = None
                if alpha is not None:
                    # Analysis-only region; no bitmap is cropped, resized or saved.
                    bounds = alpha.crop((left, top, right, bottom)).point(lambda a: 255 if a >= 32 else 0).getbbox()
                    assert bounds is not None, name
                bounds = list(bounds) if bounds else [0, 0, right-left, bottom-top]
                root_anchor = [(bounds[0] + bounds[2]) / 2, bounds[3]]
                data["sprites"][name] = {
                    "file": asset["file"], "region": region, "alpha_bbox_local": bounds,
                    "root_anchor_local": root_anchor,
                    "atlas_resource": "resources/" + name + ".tres",
                }
                text = (
                    '[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n'
                    f'[ext_resource type="Texture2D" path="res://Art/grooming_demo_v1/{asset["file"]}" id="1"]\n\n'
                    '[resource]\n'
                    'atlas = ExtResource("1")\n'
                    f'region = Rect2({left}, {top}, {right-left}, {bottom-top})\n'
                    'filter_clip = true\n'
                )
                (resources / (name + ".tres")).write_text(text, encoding="utf-8")
            data["checks"].append({"id": asset["id"], "image_readable": True, "alpha_checked": alpha is not None})
    data["limits"] = [
        "Native source PNGs retain generated dimensions; scenes use a precise 1920x1080 logical viewport.",
        "AI states are not pixel-identical. Keep neutral base during cleaning; normalize visible bounds for reaction previews.",
        "Dirty-reference atlas cells are not interactive dirt masks. Use independent dirt sprites and model-owned masks.",
        "Root anchors are alpha-bounds hints, not manually approved final anatomical anchors.",
    ]
    (ART / "atlas_index.json").write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"images": len(data["images"]), "sprites": len(data["sprites"]), "rgba_images": sum(i["mode"] == "RGBA" for i in data["images"].values())}))


if __name__ == "__main__":
    inspect()

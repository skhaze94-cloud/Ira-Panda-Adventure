#!/usr/bin/env python3
"""Measure alpha-bounded atlas pieces. Original artwork pixels remain unchanged.

Optional developer dependencies: Pillow, NumPy and SciPy. Godot reads the saved
regions.json directly and does not require this script or those dependencies.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1] / "assets" / "keepsake"
result = {"characters": {}, "settings": {}}
for group, names, count in [
    ("characters", ["ara", "ira", "pip", "bramble", "moss", "friends"], 4),
    ("settings", ["woods", "glade", "brook", "hollow", "garden"], 6),
]:
    for name in names:
        image = Image.open(ROOT / group / (name + ".png"))
        assert image.mode == "RGBA", f"{name}: missing alpha"
        alpha = np.asarray(image.getchannel("A"))
        assert np.mean(alpha < 8) > .12, f"{name}: background is opaque"
        labels, _ = ndimage.label(alpha > 48)
        areas = np.bincount(labels.ravel())
        objects = ndimage.find_objects(labels)
        candidates = sorted(
            [(int(areas[i + 1]), box) for i, box in enumerate(objects) if box],
            key=lambda item: item[0], reverse=True,
        )[:count]
        assert len(candidates) == count and min(a for a, _ in candidates) > 4000
        boxes = []
        for _, (y, x) in candidates:
            x0, y0 = max(0, x.start - 3), max(0, y.start - 3)
            x1, y1 = min(image.width, x.stop + 3), min(image.height, y.stop + 3)
            boxes.append([x0, y0, x1 - x0, y1 - y0])
        # Generated poses are not exactly equal cells. Sort real subjects into
        # reading order, then use their complete bounds rather than a fixed grid.
        boxes.sort(key=lambda r: r[1] + r[3] / 2)
        ordered = []
        for row in range(count // 2):
            ordered.extend(sorted(boxes[row * 2:row * 2 + 2], key=lambda r: r[0]))
        result[group][name] = ordered
        print(f"{name}: {len(ordered)} complete alpha-bounded illustrations")
(ROOT / "regions.json").write_text(json.dumps(result, indent=2) + "\n")

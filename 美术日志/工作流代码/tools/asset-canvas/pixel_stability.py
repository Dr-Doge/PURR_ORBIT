"""Opt-in, reversible pixel-grid experiment. No changes to the normal pipeline."""
import numpy as np
from PIL import Image


def align_blocks(current, reference):
    """Integer local motion matching; never warp the output geometry."""
    h, w = current.shape[:2]
    padded = np.pad(reference.astype(np.float32), ((2, 2), (2, 2), (0, 0)), mode='edge')
    aligned = reference.copy()
    confidence = np.zeros((h, w), bool)
    for y in range(0, h, 8):
        for x in range(0, w, 8):
            block = current[y:y+8, x:x+8].astype(np.float32)
            bh, bw = block.shape[:2]
            scores = []
            for dy in range(-2, 3):
                for dx in range(-2, 3):
                    candidate = padded[y+2+dy:y+2+dy+bh, x+2+dx:x+2+dx+bw]
                    score = np.mean(np.abs(block-candidate)) + .25*(abs(dx)+abs(dy))
                    scores.append((score, dy, dx))
            score, dy, dx = min(scores)
            aligned[y:y+bh, x:x+bw] = padded[y+2+dy:y+2+dy+bh, x+2+dx:x+2+dx+bw]
            confidence[y:y+bh, x:x+bw] = score < 18
    return aligned, confidence


def stabilize_frames(frames, size=256, cell=1, strength='standard', loop=True):
    if size not in (128, 256, 512) or cell not in (1, 2, 4) or strength not in ('gentle', 'standard'):
        raise ValueError('无效像素稳定设置')
    if not frames or len(frames) > 200 or any(im.size != frames[0].size for im in frames):
        raise ValueError('帧数量或尺寸不一致')
    grid = size // cell
    arrays = []
    for im in frames:
        # Shared full canvas, never a per-frame bounding box. Premultiplied area sampling.
        a = np.array(im.convert('RGBa').resize((grid, grid), Image.Resampling.BOX).convert('RGBA'))
        a[:, :, 3] = np.where(a[:, :, 3] >= 128, 255, 0)
        a[a[:, :, 3] == 0, :3] = 0
        arrays.append(a)
    fixed = []
    count = 0
    for i, current in enumerate(arrays):
        result = current.copy()
        if len(arrays) >= 3 and (loop or 0 < i < len(arrays)-1):
            prev, cp = align_blocks(current, arrays[(i-1) % len(arrays)])
            nxt, cn = align_blocks(current, arrays[(i+1) % len(arrays)])
            consensus = (prev[:, :, :3].astype(float) + nxt[:, :, :3]) / 2
            agreement = np.max(np.abs(prev[:, :, :3].astype(float)-nxt[:, :, :3]), axis=2) <= 12
            delta = np.max(np.abs(current[:, :, :3]-consensus), axis=2)
            opaque = (current[:, :, 3] == 255) & (prev[:, :, 3] == 255) & (nxt[:, :, 3] == 255)
            mask = cp & cn & agreement & opaque & (delta >= 3) & (delta <= (32 if strength == 'gentle' else 64))
            result[mask, :3] = np.rint(consensus[mask]).astype(np.uint8)
            count += int(mask.sum())
        fixed.append(Image.fromarray(result).resize((size, size), Image.Resampling.NEAREST))
    return fixed, {'algorithm': 'motion-grid-v1', 'cell': cell, 'size': size, 'strength': strength,
                   'corrected_cells': count, 'frame_count': len(frames), 'alpha_temporal_edits': 0}

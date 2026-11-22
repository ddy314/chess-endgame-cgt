"""Hold kings and one man fixed in the knight-fork geometry and audit skewer edges."""

import csv
import sys
from collections import defaultdict
from pathlib import Path

import chess
import numpy as np
import validate as v
from network import Network
from summarize import write

from effects import batches, delta, secant
from tactical import load


def fork(root, out, net, ids):
    # Potential fork squares shared by the king and rook; the knight must reach one now.
    attacks = np.array(chess.BB_KNIGHT_ATTACKS, dtype="uint64")
    v.state(4, 2, 0, 0, 0, 0)
    st = v.maps[4, 2]
    sumstats = defaultdict(lambda: np.zeros(len(ids) + 2))
    for w in range(64):
        if w % 8 >= 4:
            continue
        common = attacks[w] & attacks
        reached = (attacks[:, None] & common[None, :]) != 0
        for k in range(64):
            valid = st[w, k]["v"] > 0
            y, x = np.where(valid)
            if not len(y):
                continue
            features = []
            for u in ids:
                black = u < 1024
                king = k if black else w
                flip = 56 * int(black) + 7 * (king % 8 < 4)
                canon = king ^ flip
                bucket = 31 - 4 * (canon // 8) - (canon % 8 - 4)
                W = net.w[bucket, :, :, u % 1024]
                raw = (
                    net.bias[u % 1024]
                    + W[10, w ^ flip]
                    + W[10, k ^ flip]
                    + W[2 + int(not black), y ^ flip]
                    + W[6 + int(black), x ^ flip]
                )
                M = np.zeros((64, 64))
                M[y, x] = raw.clip(0, 127)
                features.append(M)
            F = np.stack(features, axis=-1)
            for axis, name in [(0, "move_knight"), (1, "move_rook")]:
                on = valid & reached
                off = valid & ~reached & (common != 0)
                n, m = on.sum(axis), off.sum(axis)
                use = (n * m) > 0
                if not use.any():
                    continue
                change = (F * on[:, :, None]).sum(axis)[use] / n[use, None] - (
                    F * off[:, :, None]
                ).sum(axis)[use] / m[use, None]
                counts = (n * m)[use]
                weights = counts[:, None]
                sumstats[name, "signed"] += np.r_[
                    use.sum(), counts.sum(), (weights * change).sum(0)
                ]
                sumstats[name, "abs_context_mean"] += np.r_[
                    use.sum(), counts.sum(), (weights * abs(change)).sum(0)
                ]
    records = []
    for (edit, stat), vls in sumstats.items():
        for u, score in zip(ids, vls[2:]):
            records.append(
                {
                    "edit": edit,
                    "stat": stat,
                    "ft": u,
                    "fixed_contexts": int(vls[0]),
                    "contrasts": int(vls[1]),
                    "mean_contrast": score / vls[1],
                }
            )
    write(out / "fork-geometry.csv", records)


def skewer(root, out, net, ids):
    rows = load(root, "validation", 3, 4)
    records = []
    sums = defaultdict(float)
    for r in batches(rows):
        for a in (3, 5):
            raw, p, _ = net.encode(r, a, 4)
            x = raw.clip(0, 127)
            t = net.forward(raw, p)
            sec = secant(t["h2"], t["z2"])[:, 2]
            edges = delta(t["h1"]) * net.w2[2] * sec[:, None] * net.out[2] / 16
            assert np.allclose(edges.sum(1), delta(t["h2"])[:, 2] * net.out[2] / 16)
            for i in range(8):
                sums[a, "H1_to_H2", i] += np.array(
                    [
                        edges[:, i].sum(),
                        abs(edges[:, i]).sum(),
                        t["h1"][:, :, i].mean(1).sum(),
                    ]
                )
            for u in ids:
                sums[a, "FT", u] += np.array(
                    [
                        delta(x)[:, u].sum(),
                        abs(delta(x)[:, u]).sum(),
                        x[:, :, u].mean(1).sum(),
                    ]
                )
    for (a, l, i), z in sums.items():
        records.append(
            {
                "white": a,
                "component": l,
                "unit": i,
                "n": len(rows),
                "signed": z[0] / len(rows),
                "absolute": z[1] / len(rows),
                "mean_byte": z[2] / len(rows),
            }
        )
    write(out / "skewer-edges.csv", records)


if __name__ == "__main__":
    root, out = Path(sys.argv[1]).resolve(), Path(sys.argv[2])
    v.init(root)
    net = Network(root)
    with (out / "tactical-inputs.csv").open() as f:
        ranks = list(csv.DictReader(f))
    ids = lambda b: [int(r["ft"]) for r in ranks if int(r["black"]) == b]
    fork(root, out, net, ids(2))
    skewer(root, out, net, ids(4))

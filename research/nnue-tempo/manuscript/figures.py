"""Publication figures from frozen paired results and native validation traces."""

import csv
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from network import Network

from effects import batches
from tactical import load

TEAL = "#19586a"
GOLD = "#b76828"
DARK = "#263740"
plt.rcParams.update(
    {
        "font.size": 9,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "svg.fonttype": "none",
        "font.family": "DejaVu Sans",
        "svg.hashsalt": "chess-nnue",
    }
)


def save(fig, path):
    fig.savefig(path, format="svg", bbox_inches="tight", metadata={"Date": None})
    path.write_text(
        "\n".join(line.rstrip() for line in path.read_text().splitlines()) + "\n"
    )
    plt.close(fig)


def draw(root, out):
    fig, ax = plt.subplots(figsize=(7.1, 2.45))
    with (out / "results/promotion.csv").open() as f:
        rows = list(csv.DictReader(f))
    for name, shift, color, marker, title in [
        ("activity_four", -0.19, "#86898a", "s", "Four activity-matched controls"),
        ("first", 0, GOLD, "o", "Leading channel"),
        ("first_four", 0.19, TEAL, "D", "Four leading channels"),
    ]:
        ss = sorted(
            (r for r in rows if r["intervention"] == name), key=lambda r: r["file"]
        )
        val, lo, hi = np.array(
            [[float(r[k]) * 100 for k in ("drop", "lower", "upper")] for r in ss]
        ).T
        ax.errorbar(
            np.arange(8) + shift,
            val,
            yerr=np.array([val - lo, hi - val]),
            fmt=marker,
            color=color,
            ms=4,
            capsize=2,
            lw=1,
            label=title,
        )
    ax.set_xticks(range(8), list("abcdefgh"))
    ax.set_xlabel("Pawn file in the white king’s orientation")
    ax.set_ylabel("Ordering points lost (pp)")
    ax.axhline(0, c="gray", lw=0.6)
    ax.legend(
        frameon=False,
        fontsize=8,
        ncol=3,
        loc="upper center",
        bbox_to_anchor=(0.51, 1.20),
    )
    save(fig, out / "promotion.svg")
    net = Network(root)
    r = load(root, "validation", 3, 4)
    fig, (ax, bar) = plt.subplots(
        1, 2, figsize=(7.15, 2.25), gridspec_kw={"width_ratios": [1.4, 1]}
    )
    for a, c, l in [(3, TEAL, "Bishop"), (5, GOLD, "Queen")]:
        values = []
        for chunk in batches(r):
            raw, p, _ = net.encode(chunk, a, 4)
            values.extend(net.forward(raw, p)["z2"][:, :, 2].ravel() / 64)
        ax.hist(
            values,
            bins=np.arange(-132, 205, 4),
            weights=np.full(len(values), 100 / len(values)),
            histtype="step",
            color=c,
            lw=1.5,
            label=l,
        )
    ax.axvline(0, ls="--", lw=0.7, color=DARK)
    ax.axvline(127, ls="--", lw=0.7, color=DARK)
    ax.set_xlabel("H2 unit 2 before clipping (byte scale)")
    ax.set_ylabel("Endpoints per bin (%)")
    ax.legend(frameon=False, fontsize=8)
    with (out / "results/verdicts.csv").open() as f:
        verdict = [r for r in csv.DictReader(f) if r["sample"] == "validation"]
    bottom = np.zeros(2)
    for field, c, l in [
        ("zero", "#d6e1e4", "Zero signal"),
        ("nonzero_both_orders_preserved", "#7297a3", "Signal, order stable"),
        ("some_verdict_changes", GOLD, "Order changed"),
    ]:
        v = np.array([100 * int(r[field]) / int(r["n"]) for r in verdict])
        bar.bar([0, 1], v, bottom=bottom, color=c, width=0.58, label=l)
        bottom += v
    bar.set_xticks([0, 1], ["Bishop", "Queen"])
    bar.set_ylabel("Pairs (%)")
    bar.legend(
        fontsize=7,
        frameon=False,
        loc="upper center",
        bbox_to_anchor=(0.52, 1.42),
        ncol=1,
    )
    fig.subplots_adjust(wspace=0.45)
    save(fig, out / "skewer.svg")


if __name__ == "__main__":
    draw(Path(sys.argv[1]).resolve(), Path(__file__).resolve().parent)

# How a static chess evaluator distinguishes moves that hand evaluation ties

[Read the research manuscript (PDF)](paper.pdf) · [Typst source](paper.typ)

The paper traces classical-score collisions through two king-relative inputs, eight first-hidden units, 32 second-hidden units and the native positional and direct scores of Stockfish 14.1. Sections 2–4 derive the ranking obstruction and threshold identity and test them against earlier endgame censuses. Sections 5–8 give new king-layout and game-position tests. All destination pairs in the new decision panels have a shared legal source and distinct Syzygy outcome signs. Paired errors, board placements, four-board rectangles and trajectory nodes have different counting units.

## Evidence by claim

| Question | Source and measurement |
|---|---|
| How much information does the classical scalar lose? | [Classical lookup error and move ordering](../atlas/results/census.csv) and [strict reversal rectangles](../atlas/results/crossovers.csv). Counts cover the stated 25 material classes. |
| What chess action drives an escort or a failure on a pin? | [Exact king and pawn tests](../atlas/horizon/kings/README.md) and [matched input and hidden-layer interventions](../atlas/horizon/kings/routes/README.md). |
| Which of the three omitted pawn files nearly pass the original screen? | [Bucket counts and off-ray minus clear-ray contrasts](results/screen.csv). This table lists candidates with at least 24 unique maxima; the full input-weight scan covers all 1,024 coordinates. |
| Which channels contribute on new layouts? | [Promotion donor scores and king-group resampling intervals](results/promotion.csv), [coverage-specific strict wins, errors and ties](results/promotion-errors.csv), [mean selected-channel activations](results/promotion-geometry.csv), [perspective census](results/perspective-census.csv) and [one-square king relocations between d and e](results/king-crossing.csv). Material codes 2, 3, 4 and 5 denote knight, bishop, rook and queen; 0 denotes a pooled summary in the error table. |
| When do useful promotion channels hurt? | [Straight versus capturing promotions](results/promotion-actions.csv), [grouped intervention intervals](results/promotion-action-intervals.csv) and [misordered FENs with all optimal Black replies](results/promotion-witnesses.csv). The first four deletion labels form a partition. The underpromotion test overlaps that partition. |
| Does the ordering loss repeat in games? | [Two calendar panels](results/played.csv). Columns named drop report ordering credit *after* the intervention. One played move is compared to a legal alternative. The previous five-file panels form a subset of these same archives. |
| Why does H2 unit 2 respond to an attacked bishop? | [Material and single-unit exchanges](results/tactical-switch.csv), [selected FT weights](results/tactical-inputs.csv), [H1-to-H2 edge contributions](results/skewer-edges.csv), [all H1/H2 donor scores](results/tactical-layers.csv) and [per-pair verdict accounting](results/verdicts.csv). The H1 mean term in the layer ledger is its contribution to H2 unit 2's mean logit divided by 64; the H2 term is its signed contribution to the positional score margin divided by 16. |
| Which inputs carry the knight fork? | [Selective FT-to-H1 path interventions](results/fork-path.csv) and [geometric one-piece edits](results/fork-geometry.csv). A geometric edit is a comparison of legal placements. The tactical outcome test separately requires an available safe checking jump. |
| Which samples transfer? | [Matched cohort flow](results/cohorts.csv) and [fixed-material cohorts outside the matched placements](results/outside-layouts.csv). The latter can share kings across materials or with discovery; by construction the complete king–king–attacker triple is new relative to the original matched panel. |

## Reproduction

Start from the [Stockfish and Syzygy setup](../README.md), the [complete atlas](../atlas/README.md), the [horizon study](../atlas/horizon/README.md), the [king study](../atlas/horizon/kings/README.md) and the [input route experiment](../atlas/horizon/kings/routes/README.md). Those runs produce the pinned network, dense classical/neural/Syzygy board tables, both quiet-reply partitions and game panels. The final study uses a CPU, GNU C++, Python with NumPy, python-chess, Matplotlib, and Typst.

~~~bash
bash research/nnue-tempo/manuscript/run.sh .scratch/nnue
~~~

For a PDF build from the archived figures run the following from the repository root.

~~~bash
typst compile research/nnue-tempo/manuscript/paper.typ
~~~

The discovery and validation king groups are disjoint under dihedral symmetry and king interchange. The split is defined over all square pairs before material or label filtering. The original pair selector uses seed 591234; validation uses 728903 and excludes previously selected destination pairs on the same triple. Each oriented pawn file pools the four defending pieces for discovery. All rankings, including the common-target fork path and the contributors to the bishop-to-queen H2 logit shift, are recomputed from discovery. Intervals in Figure 1 resample king groups within each file, conditional on the chosen channels. The control quadruple matches each target greedily by discovery mean absolute activation difference within its own viewpoint. Alternate selectors and single-coordinate donors can produce different estimates. Floating-point secant accounting is checked against exact integer endpoint margins for each scored promotion batch; chess scores in both enumerated validation and outside-layout tests are checked against the native atlas.

# Mathematical research and collaboration instructions

## Mandatory English-language policy

- English is the sole language for repository-authored explanatory prose. Write and maintain `README.md`, `AGENTS.md`, `PROOF.md`, research notes, Markdown documentation, manuscript exposition, source-code comments/docstrings, and pull-request descriptions in English. Use English for new or revised public-facing messages and instructions.
- Audit **all tracked Markdown files**, including nested directories and archives, for Chinese-language explanatory text. Translate existing Chinese proofs and documentation into precise, idiomatic mathematical English in dedicated PRs. Preserve definitions, hypotheses, quantifiers, equations, proof dependencies, numbering, cross-references, bibliographic details, code behavior, and the exact strength of every claim. Never silently shorten or reinterpret a proof during translation.
- Keep mathematical notation, source identifiers, and faithful quotations or official titles in their original form when required; provide an English explanation around any unavoidable original-language quotation. Do not leave mixed-language paragraphs, headings, tables, or code comments.
- Before completing a documentation PR, inspect every changed file for residual Chinese prose and broken links/references. Review mathematical equivalence against the original and run existing relevant checks. A character scan is a useful audit aid, not a replacement for reading or proof review.
- This requirement applies to all future contributions and edits, not only the present translation cleanup. Do not create new Chinese prose or alternate Chinese documentation copies. Keep English clear, direct, and technically specific; avoid defensive boilerplate and unsupported claims.

This repository presently develops mathematical theory for chess search algorithms. Research, prove, and independently verify results before deciding whether the separate EvilChess engineering project should adopt them. The relevant outputs are theorems, counterexamples, rigorous algorithmic bounds, and proofs.

## Research method

- Use [RESEARCH_PLAN.md](RESEARCH_PLAN.md) as the active agenda. Independently select narrow, precise problems and pursue them without interrupting work for stage reports.
- Read relevant prior literature. Distinguish established results, immediate deductions, open conjectures, and original proofs. Verify mathematical novelty; failure to find matching keywords is insufficient.
- Specify the game model, quantifiers, boundary conditions, termination rules, and proof dependencies. Repetition, the 50/75-move rules, draws, and position history in full chess must not disappear silently in model reductions.
- Distinguish exact results, conditional/probabilistic claims, and empirical heuristics. Random trials, fixed-depth enumerations, and finite samples do not prove infinite-family theorems.
- Actively test counterexamples. If a conjecture fails, seek a provable correction or a more valuable negative theorem.
- Prefer reusable general lemmas, algorithmic bounds, and structural statements over isolated numerical results lacking a route to generalization.

## Content and layout

- `README.md` is a concise introduction; `RESEARCH_PLAN.md` is the current research agenda.
- On substantial progress, create or update root `PROOF.md`, organized by mathematical topic with definitions, theorems, proofs, and counterexamples. Do not split research into stage logs or progress reports.
- `archive/elkies-pawn-endgames/` retains earlier Elkies pawn-endgame work. Respect its model and proof scope when citing it. Apart from necessary corrections, do not repackage historical results as new findings.
- Necessary mathematical checking scripts may go under `scripts/`. This repository does not implement a chess engine, interface, inference service, training model, or hardware optimization.
- Do not commit execution logs, temporary datasets, unnecessary certificate bundles, SHA manifests, release pipelines, or administrative scaffolding. Ignore build and temporary computational files.
- Use direct, concise technical statements in README, proofs, and PRs. Avoid defensive declarations or exaggerated claims about performance and novelty.

## Submission principle

Submit a PR when a clear mathematical result exists, stating the problem, theorem, proof location, and verification procedure. Unfinished conjectures may remain in active research; do not package intermediate steps as achievements merely to produce a PR.
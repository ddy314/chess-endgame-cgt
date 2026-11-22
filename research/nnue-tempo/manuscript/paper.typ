#set document(date: datetime(year: 2026, month: 11, day: 22), title: "How a static chess evaluator distinguishes moves that hand evaluation ties")
#set page(paper:"a4",margin:(left:21mm,right:21mm,top:21mm,bottom:18mm),numbering:"1",header:align(right,text(8pt,fill:rgb("#59666a"))[Stockfish 14.1 · Endgame evaluation]))
#set text(font:"Libertinus Serif",size:11pt,lang:"en")
#set par(leading:.56em,justify:false)
#set heading(numbering:none)
#let teal=rgb("#19586a")
#show heading.where(level:1): it => block(above:8pt,below:6pt,text(size:18pt,weight:"bold",fill:teal,it.body))
#show heading.where(level:2): it => block(above:6pt,below:3pt,text(size:12pt,weight:"bold",it.body))
#let tbl(cols,headers,rows) = {
  set text(size:9.6pt)
  table(columns:cols,stroke:none,inset:(x:5pt,y:3.5pt),align:left,
    fill:(x,y)=>if y==0 {rgb("#dfecee")} else if calc.even(y) {rgb("#f5f7f7")},
    table.header(..headers.map(h=>text(weight:"bold",h))),..rows.flatten())
}
#let cap(body)=block(above:3pt,below:6pt,text(size:9.3pt,body))
#let evidence="https://github.com/dongxuelian2/chess-endgame-cgt/pull/3"
#text(size:26pt,weight:"bold")[How a static chess evaluator distinguishes moves that hand evaluation ties]
#v(2pt)
#text(size:14pt,fill:teal)[King-relative coordinates and conditional signal transmission in Stockfish NNUE]
#v(3pt)
#text(size:10pt)[Research manuscript · November 2026]
= Abstract
Which chess distinctions can a learned static evaluator recover after the hand evaluator has assigned two moves the same score? We study the released Stockfish 14.1 network, using exact endgame outcomes to label choices and legal-move deletions to isolate the action that separates them. Across 214,063,938 four-man boards, classical-score collisions include 1,313,752 four-board configurations whose strict preference reverses when the opponent's piece moves. An additive piece-square score cannot realize both preferences; the full network does so on 663,639 configurations. We trace particular decisions to the king-relative input accumulators, both hidden layers and the final integer score. A change of material can shift the range of one hidden unit while a different unit supplies its move-dependent signal. In 3,029 held-out rook-skewer comparisons, replacing two first-layer coordinates from the queen moves the bishop's second-layer unit 2 almost entirely to its floor. Promotion control is encoded in both king perspectives. Four discovery-selected coordinates per file account for losses of 10.8–28.3 ordering points on fresh layouts when their joint move difference is removed. On 1,314 played-position alternatives this intervention costs 12.4 points. On three previously unexplained files, the intact network scores 97.54% when straight promotion decides the choice and 44.05% when capture-promotion decides it. The same framework explains a recurring failure on quiet bishop pins. The results separate the chess action that changes the outcome, its representation in a fixed network, and the part of that representation that changes a decision.

= 1. The comparison to make
White has a choice in a queen-versus-pawn ending. With Ka5 and Qb8 against Kg2 and Pf3, Qb6 permits the saving ...f2, while Qb7 pins the pawn and wins. Stockfish's specialized hand formula assigns both children −2494 from Black's perspective. The static neural evaluator assigns −17 and −889. This example motivates two questions. Which information did the hand formula discard? What computation makes the neural ranking sensitive to it?

We first identify a class of rankings that requires two piece placements to interact. We then trace the interaction on three chess motifs: escort and promotion, a rook check skewering the king and a man behind it, and a knight check forking a rook. Across these motifs, three operations recur. King-relative inputs encode access to particular squares. Piece identity and placement move later sums across thresholds. A signal affects the selected move when its contribution is large enough relative to the other score terms. Each step admits a separate experimental intervention.

#let diagram = {
  let pieces = (b8: "♕", a5: "♔", g2: "♚", f3: "♟")
  let files = ("a","b","c","d","e","f","g","h")
  grid(columns:(9pt,) + (14pt,)*8,rows:(14pt,)*8 + (9pt,),align:center+horizon,
    ..range(72).map(i => {
      let row=calc.floor(i/9)
      let col=calc.rem(i,9)
      if col==0 {text(7pt,str(8-row))} else {
        let key=files.at(col - 1)+str(8-row)
        let tint=if key in ("b7","b6","f2") {rgb("#e4bb7d")} else if calc.odd(row+col) {rgb("#eef2ef")} else {rgb("#a6bcc0")}
        box(width:14pt,height:14pt,fill:tint,align(center+horizon,text(font:"DejaVu Sans",size:12pt,pieces.at(key,default:""))))
      }
    }),[],..files.map(f => text(7pt,f)))
}
#v(4pt)
#align(center,grid(columns:(auto,195pt),gutter:16pt,align:horizon,
  diagram, [*Position 1. White to move.* The marked squares are the two queen destinations and Black's prospective pawn push. From b7 the queen attacks the black king along b7–c6–d5–e4–f3–g2. Advancing the f3 pawn would expose its own king. From b6 the pawn can advance legally.]))

#pagebreak()
= 2. Positions, labels and interventions
*Chess domain.* Each side has a king and one man from pawn, knight, bishop, rook or queen. The main atlas fixes Black to move; the 25 ordered material classes distinguish colors. Positions are locally legal, nonterminal and check-free, with empty castling and en-passant rights. The target is the sign of the five-valued Syzygy WDL code at a fresh clock, counting cursed wins and blessed losses by their sign. This convention measures theoretical outcome with zeroed history. A complete census contains 214,063,938 boards, or 107,031,969 representatives under horizontal reflection. All neural scores agree across paired reflections. White's king occupies files a–d in the canonical enumeration.

*Classical score and choices.* We use 14.1's classical evaluator with both lazy cutoffs disabled, before its final grain truncation, retaining its specialized endings. Some endings have an especially transparent collision: the queen-versus-pawn formula reads the two kings and the pawn and omits the queen square. In a fixed context (material, both kings, black man's square), stratify by classical score. The smallest attainable number of WDL errors for a lookup that sees this context and score is the sum of each stratum's size minus its modal label count. This is 13,265,530; adding the native neural score to the key reduces it to 2,673,035. This measures available information on the finite census. For move tests we additionally require a single White source square from which both destinations are legal. Let $H$ and $L$ be the resulting children with higher and lower outcome for Black. A positive neural margin earns one point, a tie one half. On 342,175,835 distinct-outcome classical ties within fixed contexts, including pairs without a common source, the network earns 69.65%.

*Action test.* At the selected Black decision delete every move satisfying a named chess condition, then optimize over the surviving moves using orthodox tablebase values for the continuations. The escort test restricts a later Black action and backs up through both players by minimax. If a deletion would empty a node, retain its orthodox value. A pair qualifies if the deletion erases or reverses its strict order. For promotion the action is any legal first-turn promotion. A skewer is a rook check with the white king strictly between the checking rook and the white man on a rank or file. A safe fork is a knight check attacking that man with no legal immediate capture of the knight. Fork tests also require the action on $H$ alone. In a substitution test both materials must qualify with identical baseline outcome signs, the same kings and the same moves. Quiet panels exclude immediate captures and promotions. Promotion panels admit them.

*Circuit test.* We use the four-man head of the released network #raw("nn-13406b1dcbe0.nnue"). Each perspective supplies 1,024 clipped accumulator bytes to an eight-unit hidden layer, then a 32-unit hidden layer and a scalar positional output. A learned direct piece-square branch joins at the output. Unit indices are zero-based; FT0–1023 denote the Black view in these children. For a nominated coordinate set, replace its value at $H$ by its value at $L$ and rescore $H$ against intact $L$; also test the reciprocal donor. Average the two ordering credits. The recipient retains its own direct score and all untargeted coordinates. For a material substitution we also transplant the other material's values at the same endpoints. Native scores are checked against the dense atlas. Earlier independent Stockfish traces checked 4,146 scalar values per board observation on 968 observations.

*Validation design.* Discovery uses one fixed-hash pair per eligible king–king–attacker placement. We split unordered king pairs grouped under all eight square symmetries, then select a different pair by a second hash on held-out king groups. Validation excludes unchanged destination pairs. Every retained test pair is relabelled using legal play. A second tactical test drops the substitution requirement and samples fixed-material placements entirely outside the matched panel. In game panels one candidate was played and a legal alternative was available from that parent. Units of counting are specified for each result. These cohorts overlap earlier research at the level of motifs and game archives.

#pagebreak()
= 3. What the network must compute
*Proposition 1 (a ranking obstruction).* Fix both kings and material. Put the white man at $i$ or $j$ and the black man at $y$ or $z$. Suppose the true WDL order between $i$ and $j$ is strict and opposite on the two rows. A separable score $S(x,t)=f(x)+g(t)$ followed by a fixed monotone quantizer cannot be strictly correct on both. If the target takes values in $\{-1,0,1\}$, the maximum absolute approximation error of a separable score on the rectangle is at least $1/2$.

_Proof._ The margin of the separable score on either row is $f(i)-f(j)$. Quantization preserves weak order. The target's mixed difference has magnitude at least two; that of $S$ is zero. The four endpoint errors bound the magnitude of their alternating sum by four times the largest error. The same ranking obstruction holds after adding a function of features constant within each row. #sym.square.filled

In the atlas we additionally match the pre-grain classical score and 48 reply-availability flags within each row and require a common legal White source. There are 1,313,752 reversing rectangles. The direct learned piece-square branch solves zero, the nonlinear positional branch solves 658,097, and the complete score solves 663,639. Requiring all four classical scores and flag vectors to coincide leaves 250,321 rectangles; the full network solves 141,837. A rectangle can share boards with others. These counts establish a need for interaction and locate sufficient machinery for some of it.

*Proposition 2 (threshold transmission).* Write an input accumulator at fixed kings as $a(x,t)=b+p(t)+m(x)$. Its raw move difference is independent of $t$. After clipping, for integer bounds $0$ and $127$, the signed move difference counts thresholds between the two endpoints. More generally let $Q_s(z)=min(127,max(0,floor(z/s)))$, with $s=1$ at the accumulator and $s=64$ at a hidden unit. For $v>=u$,
$ Q_s(v)-Q_s(u)= sum_(j=1)^127 bold(1){u<s j<=v}. $
_Proof._ $Q_s(v)$ equals the number of positive thresholds $s,2s,…,127s$ at or below $v$. Subtraction counts those crossed by the move. A background shift of both endpoints can therefore change the transmitted gap with the raw move difference fixed. #sym.square.filled

*Accounting and intervention.* For an affine layer $z=W h+b$, let $d_j=Delta Q(z_j)/Delta z_j$ for unequal endpoints, and set it to zero for equal endpoints. Then $Delta h'_j=d_j sum_i W_(j i) Delta h_i$. Recursing gives exact signed edge allocations for the positional margin before final truncation. These are endpoint identities; different edges can cancel. We rank input coordinates by mean signed allocation on the discovery set, then test a finite donor intervention on separate layouts. Material-gate discovery ranks the reduction in a designated downstream preactivation under a piece exchange. Fork discovery ranks the contribution passing through H1 units 0, 1 and 4.

*Decision margin.* Let $M$ denote the difference in total native pre-output units (including the direct branch). Equalizing second-layer unit $j$ subtracts $c_j=w_j Delta h_j$ from this margin in either donor direction. Each integer score is truncated toward zero after division by 16. Each patched score difference is within 2 of $(M-c_j)/16$, so $|M-c_j|>=32$ certifies its sign. The counts below distinguish zero transmitted signal, a nonzero signal with the same order, and a changed verdict.

#pagebreak()
= 4. From a hand rule to a learned defensive route
*The king changes a pawn race.* A reduced game lets the minor try to stop a black pawn while the kings are absent. Of 1,359,347 classically tied, informative bishop–pawn pairs, 295 have the strict opposite order to that race. In 253 of those, the white king obstructs the apparent capture diagonal. The resulting full-chess possibilities expose a network error with a concrete mechanism. On 108 quiet-pin cases, the direct branch earns 84 points; retaining the native difference of first-hidden unit 6 alone in addition to that branch reduces the total to 15, also the full network result. In 42 cases where the black king attacks the bishop and guards promotion, the intact network gets all 42 right. The same bottleneck can repair one omitted relation and overwrite a useful preference on another.

*Escort and material.* In a fresh set of 240 played comparisons, a conversion test with a thirteen-ply horizon still had overlapping bounds in 28. The static network ranked 24 of these correctly. One resulting hypothesis concerns support following a pawn push. After a black pawn push, remove a black king move on its next turn that guards the pawn's next square. In 2,830 rook/queen substitutions the removal erases the order in both materials. These pairs reduce to 23 different king–king–pawn placements. With the rook, the mean absolute gaps at H1 units 2, 6 and 7 are 29.60, 1.36 and 0.16 bytes. Substitute just the queen's Black-perspective accumulator at both endpoints and the gaps become 1.29, 28.36 and 72.94. In all 562 distinct seed children, Black-view coordinate FT625 is positive with the rook and zero with the queen. Its outgoing weights to the three units are +39, −29 and −41. FT961 changes from 0 to 127 on every child. A coordinate constant across the two moves can thus change a later unit's move sensitivity. Testing each material alone yields 2,586 different rook escort placements on ranks 3–7. Full score and unit-2-only ordering earn 77.88% and 76.28%.

*Advance the pawn.* Retaining the same kings, piece and choices and moving the seed pawn from the third to the second rank leaves 2,487 legal comparisons. With the white rook still present, H1 unit 7's mean absolute gap rises from 0.17 to 104.64 bytes. The raw accumulator move difference is exactly unchanged in every coordinate, as Proposition 2 predicts. The white viewpoint becomes especially informative. With a c2 pawn in that viewpoint, FT1424 averages 100.69 when the rook is off the promotion ray, 2.14 with a clear ray to c1 after the push and 123.49 with a king in the way. In all 641 eligible one-square white-king edits opening that rook ray, its activation drops.

*Why the original test found five files.* White-view coordinates were selected by three conditions: the same unique strongest pawn-square weight in all 32 king buckets, consistent defender-weight suppression by a promotion ray, and an off-ray minus clear-ray gap above 32 bytes in each of four defending materials. Five files qualified (a, c, d, e and f). On b, FT1869 has the b2 maximum and weight suppression in all buckets. Its activation gaps for knight, bishop, rook and queen are 72.4, 58.9, 42.8 and 13.4 bytes. The queen case removes it from this screen. Its individual output ablation costs just 0.25 ordering points on fresh b layouts. On g the highest bucket agreement for a unique g2 maximum is 29/32; on h it is 31/32. The next experiment relaxes viewpoint and selectivity and tests which input differences actually carry useful score.

#pagebreak()
= 5. Promotion control across all eight files
The file labels in this section always use the white king's orientation. Each king independently reflects its own input horizontally. Black additionally reverses the ranks. A single Black-view channel can consequently serve multiple White-view files. For b and g the leading score contributor found in discovery is the same channel, FT273. Its largest own-pawn weight is on its own b7 in all 32 buckets. On White-view b with a defending rook, when Black also sees file b, its mean is 114.13 off the promotion ray and 4.17 on the clear ray. When Black sees g these means are 0.003 and 0. A king blocking the ray on Black-view b gives a mean of just 5.46. The feature responds strongly to alignment even on many obstructed lines. A one-square d/e-file king relocation preserves the Black king bucket while reflecting its input coordinates. Holding both other men and the white king fixed, with the rook off-ray in both positions, FT273 falls from mean 110.20 to exactly zero in the b-file panel (6,454 edits) and from 100.08 to zero on g (5,583). On White-view h, FT1282 prefers h2 in 27 buckets and b2 in five; the leading four include FT1166 and FT1867 with h2 maxima in 31 and 30 buckets respectively.

#image("promotion.svg",width:100%)
#cap[*Figure 1.* Loss of ordering credit after each file's chosen FT differences are equalized. Channels were ranked on discovery layouts. Bars give pointwise 95% percentile intervals from 2,000 resamples of whole held-out king groups. Each control is matched within viewpoint on discovery mean absolute move difference, excluding the leading eight. pp denotes percentage points.]

#tbl((1fr,1fr,1fr,1fr,1fr,1fr),([File],[Pairs],[Native],[Drop first],[Drop four],[Drop eight]),(
([b],[1,623],[90.14%],[86.44%],[73.83%],[61.97%]),
([g],[1,819],[89.83%],[86.78%],[79.04%],[64.03%]),
([h],[1,708],[92.71%],[87.53%],[71.12%],[60.55%])))
#cap[*Table 1.* Scores after removing discovery-ranked inputs on the three omitted files. Each pair requires an actual promotion for its strict order. The sample covers 120 held-out king groups on each file. The four-channel sets are b (273, 360, 1282, 629), g (273, 1192, 360, 1182) and h (1282, 1166, 1867, 1192).]

*Where the network errs.* On b, g and h, when only the better White destination establishes a clear promotion attack and the worse is off the ray, strict correct counts are 1,126/1,126, 1,143/1,149 and 1,255/1,269. For pairs with the same coverage class at both ends, ordering scores are 74.71%, 73.99% and 76.85%. Both distributed use and concrete errors occur. On 733 played alternatives on these three files the four-channel intervention reduces credit from 97.89% to 86.39%; the April–September and October–December losses are 11.10 and 11.95 points. Across all files the 1,314 played comparisons give 97.56% and 85.12%. Channel selection used enumerated discovery choices; played positions can recur across games.

#pagebreak()
= 6. When the same promotion channels hurt
A white piece can cover the square straight ahead of the pawn while standing on a square the pawn can capture into. For example, White has Kb1 and Ne2 against Kd1 and Pb2. After Nc1 Black wins with ...bxc1=Q+ or ...bxc1=R+; after Nd4 Black can draw. The neural scores for Black are +68 and +101. The two choices tie the hand evaluator, and the neural evaluator strictly reverses their tablebase order. Physical b2 appears as g2 in the white king's orientation.

We reopened all 13,523 held-out promotion decisions. First delete just straight promotions at Black's first turn; separately delete just capture-promotions. Table 2 gives disjoint cases in which one of the two deletions erases the orthodox order and the other preserves it. The b, g and h panel also contains seven comparisons requiring the combined deletion, and the other files contain seventeen. Each cohort uses the four channels ranked for its own file on discovery, with both donor directions.

#tbl((1.45fr,1fr,1fr,1fr,1fr),([White-view files],[Deletion],[Pairs],[Native],[Drop four]),(
([b, g, h],[Straight],[4,504],[97.54%],[77.98%]),
([b, g, h],[Capture],[639],[44.05%],[52.39%]),
([a, c, d, e, f],[Straight],[7,155],[98.02%],[72.37%]),
([a, c, d, e, f],[Capture],[1,201],[54.33%],[50.85%])))
#cap[*Table 2.* Sorting after equalizing the same four selected FT move differences, conditional on which chess action supplies the order. Outcomes after deletion use orthodox tablebases from the next ply.]

On b, g and h the sign of the intervention changes with the chess action. Removing the channels costs 19.56 ordering points on straight promotions (95% king-group interval 18.47–20.71); on capture-promotions the same edit gains 8.33 points (6.39–10.38). The latter group contributes 356 of the 467 strict errors on these files. The contrast is present within every defending material. Native capture-promotion scores are 45.3% against knights (43 pairs), 79.2% against bishops (24), 71.4% against rooks (145) and 32.7% against queens (427); straight-promotion scores exceed 95% in all four. Material composition therefore matters to the pooled effect size.

The pattern identifies a failure mode of using the forward promotion square to evaluate a choice where the decisive promotion lands elsewhere. The interventions establish the sign of these four coordinates' joint effect on this population. On the original five files their effect on capture-promotions is smaller and has the opposite sign. Game alternatives support the intrinsic difficulty contrast on b, g and h: native scores are 98.99% on 693 straight-promotion pairs and 73.44% on 32 capture-promotion pairs. Equalizing four channels takes the latter to 67.97%. Thus the pooled ablation gain on captures is specific to the enumerated distribution here. The two panels differ in both support and material mix.

#pagebreak()
= 7. Why a skewer depends on second-layer unit 2
A skewer can preserve its geometry and tablebase role while the attacked piece changes. In an initial 19,032 matched comparisons, removing H2 unit 2's difference moved bishop accuracy from 73.81% to 50.58%; the same edit changed queen accuracy from 71.96% to 71.95%. The 3,029 new matched comparisons change both king groups relative to channel discovery and destination pairs relative to the original sample.

The preactivation of H2 unit 2, in native logit units, is exactly
$ 1873 + (65,-34,15,-17,7,23,10,-50) dot h, $
where $h$ is the vector of eight H1 bytes. With the bishop, H1 units 1 and 3 average 1.88 and 3.07; with the queen they average 125.33 and 126.99. Their weights are both negative. FT1691 goes from mean 79.75 to 0.57; it feeds these same units with weights −28 and −45. FT577 goes from 2.54 to 34.10 and feeds them with +81 and +104. FT961 goes from 0 to 123.84. The eight greatest discovery-selected contributions to the downward logit shift, transplanted jointly into the bishop, reduce the H2 unit's gap from 18.49 to 0.71. Transplanting just H1 units 1 and 3 reduces it to 0.60, with 97.67% of endpoints at zero. Across materials, the native mean preactivation divided by 64 moves from +73.77 to −8.43.

#image("skewer.svg",width:96%)
#cap[*Figure 2.* Left, native preactivations before the floor and ceiling (dashed lines). Right, what happens to the ordering when the unit's two endpoint values are equalized. Both panels use the same 3,029 paired geometries per material.]

With the bishop the move-dependent signal chiefly enters through H1 unit 7. Its edge supplies +16.59 of the +20.25 mean signed score units carried by H2 unit 2. With the queen the same edge supplies +0.23. For 2,096 queen pairs the H2 difference is exactly zero; in 919 it is nonzero and both donor orderings survive. Only 14 change either verdict, against 1,151 bishop pairs. The queen retains useful information elsewhere: removing H1 unit 6 takes its native credit from 69.10% to 62.70%. Switching the bishop's two gate coordinates into the queen reopens H2 unit 2 (15.37-byte gap); the rest of the recipient network still conditions its output.

On placements absent from the entire original substitution panel, the same skewer deletion identifies 3,979 bishop and 33,828 queen choices. Equalizing H2 unit 2 takes the bishop from 81.30% to 61.00%, and the queen from 71.64% to 71.73%. These fixed-material tests admit distinct outcome and position distributions. The same-board substitutions isolate the material effect.

#pagebreak()
= 8. A knight fork takes a different path
On a safe knight fork, the attacker has a legal checking jump that attacks the opponent's man. An upstream geometric condition is that the knight's current square, the king's square and the man's square all attack a common square by knight displacement. To isolate the last relation, write $N(x)$ for the squares a knight attacks from $x$. Keep the king $w$ and rook $x$ such that $N(w) inter N(x)$ is nonempty. Moving the black knight $y$ can then change whether $N(y)$ intersects this set. The analogous test moves the rook with the knight and kings fixed. Both tests use check-free legal endpoints and admit a king or other piece on the hypothetical target. The geometric contrast concerns reachability; the decision panel separately enforces check, legality, safety and WDL necessity.

In the original 2,051 matched fork choices with the rook, retaining H1 units 0, 1 and 4 gives 72.17% against native 72.21%. We ranked FT contributions going specifically through those three units on 1,052 discovery pairs. Seven of the leading eight coordinates are in the white viewpoint. FT1111, FT1227 and FT1594 have weights −55, −30 and −51 into H1 unit 4. Opening a common target by relocating the knight raises their mean activations by 4.15, 5.20 and 6.17 bytes respectively over 7,951,960 contrasts; moving the rook gives 4.28, 4.06 and 5.26 over 1,264,812. Each contrast edits one piece with the other three fixed. Geometry and signed downstream influence are measured separately.

#tbl((1.42fr,.64fr,1fr,1fr,1fr,1fr),([Rook panel],[Pairs],[Native],[All edges],[Via 0/1/4],[Other edges]),(
([Changed choices],[202],[73.02%],[57.80%],[57.43%],[73.02%]),
([Outside layouts],[972],[75.15%],[66.85%],[66.77%],[75.15%])))
#cap[*Table 3.* Remove the same eight FT differences from all H1 inputs, only their edges into H1 units 0, 1 and 4, or their edges into the other five units. Every downstream layer is recomputed. Each row comes from a distinct set of king–king–attacker placements.]

The pathway prediction is particularly sharp on the 972 outside-layout choices: removing its eight input differences through the nominated three units costs 60.09 mean score units, compared with 59.71 through all eight H1 units and −0.41 through the five-unit complement. A near match in average scores alone could arise from cancellation; the separate ordering endpoint in Table 3 replicates the distinction. The role changes with material here too. On 16,454 queen-versus-knight choices outside the original placements, native credit is 66.76%; targeting the three units gives 61.77%, while targeting their complement gives 64.56%. Additional pathways participate on the queen.

== What the three experiments explain together
A chess concept can keep the same legal definition while its implementation changes with the material or the king used to orient the input. The threshold identity predicts how a background coordinate can change the network's sensitivity to a move. Endpoint accounting identifies which incoming signals actually cross thresholds. The margin criterion identifies when those signals matter to an ordering. The bishop skewer exhibits all three steps in one circuit. Promotion adds a coordinate-system explanation, and the fork isolates a different group of input-to-hidden edges. Quiet bishop pins give a case in which the learned transmission is strong and directionally wrong.

#pagebreak()
= 9. Relation to earlier work and scope
Pálsson and Björnsson [1] probed hand-evaluation concepts in Stockfish 14.1 and inspected positions that highlighted forks, promotions and king safety. McGrath et al. [2] traced concept acquisition in AlphaZero. Jenner et al. [3] patched Leela Chess Zero to investigate look-ahead along optimal lines; Lin et al. [4] traced tactical features in a chess transformer. Interchange interventions have a general foundation in causal-abstraction work [5]. Our contribution is a specific combination: a classical-score collision with an exact outcome order, an intervention on the legal continuations that give this order, and an intervention on native quantized coordinates under matched changes to the chessboard. This permits tests of a useful representation, a harmful representation and a signal too small to affect a decision under the same protocol.

*Scope.* The algebra applies to coordinatewise quantized affine networks under the stated hypotheses. Coordinate identities, measured frequencies and substitution effects belong to the released four-man head of SF14.1. Selection on a classical tie and a WDL difference enriches these cohorts for decisions the hand evaluator finds difficult. Group ablations test jointly used information within the chosen coordinate basis. Other subsets can also suffice, and donor activations can produce internal states absent from ordinary play. Layout resampling quantifies variation among the eligible king groups; fresh training seeds, other releases and middlegames require separate validation. The monotonicity bound restricts additive models; hand-coded interaction features and exact bitbases can resolve distinctions within their domains.

*Static scoring and search.* In an earlier side-to-move control on 352,000 positions in fourteen three- to five-man classes, the 14.1 NNUE outranked its classical evaluator for beneficial first moves in thirteen classes. The hand evaluator's exact king–pawn bitbase won the remaining comparison. On 6,000 decision roots the 14.1 production neural mode saved a net 94 tablebase outcomes at 64 search nodes and 15 at 4,096 nodes in that experiment. The present interventions target a static forward pass. The practical prediction is specific: the circuits matter most when search leaves these choices to the evaluator. Measuring search with these very edges intervened on is an open test.

*Reproduction and evidence.* The #link(evidence)[repository and research pull request] include the pinned Stockfish release and network retrieval procedure, native integer replay, machine-readable result tables and legal-action tests. Run the atlas, horizon, kings and routes experiments, then run #raw("manuscript/run.sh") on their scratch tree. The companion guide maps proofs and numbers to files. The paper's two figures are regenerated from held-out native traces and the archived tables. The Lichess panels derive from the #link("https://database.lichess.org/")[rated game archives]; tablebases and the probing implementation are specified in the reproducibility guide.

== References
#text(size:9.8pt)[
1. Pálsson, A. and Björnsson, Y. (2023). #link("https://www.ijcai.org/proceedings/2023/541")[Unveiling Concepts Learned by a World-Class Chess-Playing Agent]. IJCAI.
2. McGrath, T. et al. (2022). #link("https://doi.org/10.1073/pnas.2206625119")[Acquisition of Chess Knowledge in AlphaZero]. PNAS 119.
3. Jenner, E. et al. (2024). #link("https://arxiv.org/abs/2406.00877")[Evidence of Learned Look-Ahead in a Chess-Playing Neural Network].
4. Lin, R. et al. (2026). #link("https://arxiv.org/abs/2604.10158")[Tracing the Thought of a Grandmaster-level Chess-Playing Transformer].
5. Geiger, A., Lu, H., Icard, T. and Potts, C. (2021). #link("https://arxiv.org/abs/2106.02997")[Causal Abstractions of Neural Networks]. NeurIPS.
6. Stockfish developers. #link("https://github.com/official-stockfish/Stockfish/tree/sf_14.1/src")[Stockfish 14.1 evaluation and NNUE source].
7. de Man, R. #link("https://github.com/syzygy1/tb")[Syzygy endgame tablebase generator].]

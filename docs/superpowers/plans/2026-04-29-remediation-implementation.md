# Remediation Plan — Implementation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Alle Fehler und Inkonsistenzen aus der Notebook-Review beheben (1 kritischer Bug, 6 hohe, 11 mittlere Punkte).

**Architecture:** Jede Task bearbeitet ein Notebook. Änderungen sind einzelne Edits in .ipynb JSON-Zellen. Verifikation durch Ausführen aller Code-Zellen des Notebooks via `julia --project=.`. Am Ende Gesamtcheck mit `nbconvert --execute` oder manuellem Durchlauf.

**Tech Stack:** Julia 1.12, Jupyter Notebooks (.ipynb JSON), Edit-Tool für präzise String-Replacements, Julia-Script zur Zellverifikation.

**Spec:** `docs/remediation-plan.md` (Quelle aller Issues, Entscheidungen getroffen).

---

### Task 1: R1 — Notebook 04 Text-Bug beheben

**Files:**
- Modify: `04_operations_on_qtts.ipynb`

**Warning:** Das Notebook ist JSON. Alle `oldString`-Matches müssen exakt sein (Zeilenumbrüche `\n` am Ende jeder Quellzeile, korrekte Einrückung nach dem `"source": [`-Prefix).

- [ ] **Step 1: Markdown Z. 91–98 — `cosh(x)` → `x^2`**

Edit in Zelle id=`12020321` (source-Zeilen 91–98): Ersetze `\cosh(x)` durch `x^2`, passe Text an dass klar ist: zwei moderate Funktionen, Produkt erhöht Bond-Dims.

Old:
```
"$$f(x) = \\cosh(x)$$\n",
"$$g(x) = \\sin(10 x)$$\n",
"\n",
"on the interval $[0, 1)$. The first factor is the same function from Notebook 01, chosen because its QTT stays unusually compact. The second factor is oscillatory and needs more internal rank."
```
New:
```
"$$f(x) = x^2$$\n",
"$$g(x) = \\sin(10 x)$$\n",
"\n",
"on the interval $[0, 1)$. Both factors need a moderate internal rank. The second factor is oscillatory."
```

- [ ] **Step 2: Kommentar Z. 125 — `#f(x) = cosh(x)` → `# f(x) = x^2`**

Old:
```
"#f(x) = cosh(x)\n",
```
New:
```
"# f(x) = x^2\n",
```

- [ ] **Step 3: Print-Output Z. 149–150**

Das Print-Statement gibt `f(x) = cosh(x)` aus. Die Variable `f` ist bereits das Funktionsobjekt, die Ausgabe müsste den tatsächlichen Funktionsnamen zeigen. Kein hartkodierter Text — prüfen ob das `println` einfach den Funktionsnamen ausgibt. Wenn es hartkodiert ist, ändern auf `f(x) = x^2`.

Old (suche nach):
```
"f(x) = cosh(x), g(x) = sin(10x) on [0, 1).\n"
```
New:
```
"f(x) = x^2, g(x) = sin(10x) on [0, 1).\n"
```

- [ ] **Step 4: Print-Output Z. 168 — gleiche Korrektur**

Old:
```
"f(x) = cosh(x), g(x) = sin(10x) on [0, 1).\n"
```
New:
```
"f(x) = x^2, g(x) = sin(10x) on [0, 1).\n"
```

- [ ] **Step 5: Markdown Z. 184 — Produkt-Formel korrigieren**

Old:
```
"To build a QTT for $h(x) = f(x) \\cdot g(x) = \\cosh(x) \\cdot \\sin(10 x)$, we evaluate both factors on the full grid, multiply the pointwise values, and build a new QTT from the product array. This is the simplest path when the TreeTN-based product API is not available in the Julia frontend.\n",
```
New:
```
"To build a QTT for $h(x) = f(x) \\cdot g(x) = x^2 \\cdot \\sin(10 x)$, we evaluate both factors on the full grid, multiply the pointwise values, and build a new QTT from the product array.\n",
```

- [ ] **Step 6: Plot Legende Z. 335 — `L"\\cosh(x)"` → `L"x^2"`**

Old:
```
"lines!(ax1, xs, f.(xs); color=:black, linewidth=2, label=L\"\\cosh(x)\")\n",
```
New:
```
"lines!(ax1, xs, f.(xs); color=:black, linewidth=2, label=L\"x^2\")\n",
```

- [ ] **Step 7: Plot Legende Z. 337 — Produkt-Label korrigieren**

Old:
```
"lines!(ax1, xs, product.(xs); color=:goldenrod2, linewidth=2, label=L\"\\cosh(x)\\cdot\\sin(10x)\")\n",
```
New:
```
"lines!(ax1, xs, product.(xs); color=:goldenrod2, linewidth=2, label=L\"x^2\\cdot\\sin(10x)\")\n",
```

- [ ] **Step 8: Plot Legende Z. 347 — Bond-Dims Legende für `f` korrigieren**

Old:
```
"lines!(ax2, idx_f, bond_f; color=:black, linewidth=2, label=L\"\\cosh(x)\")\n",
```
New:
```
"lines!(ax2, idx_f, bond_f; color=:black, linewidth=2, label=L\"x^2\")\n",
```

- [ ] **Step 9: Plot Legende Z. 355 — Produkt-Label Bond-Dims korrigieren**

Old:
```
"lines!(ax2, idx_h, bond_h; color=:goldenrod2, linewidth=2, label=L\"\\cosh(x)\\cdot\\sin(10x)\")\n",
```
New:
```
"lines!(ax2, idx_h, bond_h; color=:goldenrod2, linewidth=2, label=L\"x^2\\cdot\\sin(10x)\")\n",
```

- [ ] **Step 10: Interpretation Z. 371–374 — Text an x² anpassen**

Old:
```
"`cosh(x)` stays at bond dimension 2 throughout, as we saw in Notebook 01. `sin(10x)` needs a moderate rank. The product of the two functions has larger bond dimensions than either factor alone: this is rank growth under multiplication."
```
New:
```
"`x^2` has a moderate bond-dimension profile with a maximum of 3. `sin(10x)` is compact at bond dimension 2. The product of the two functions has larger bond dimensions than either factor alone: this is rank growth under multiplication."
```

- [ ] **Step 11: "What to notice" Z. 567–568 — Bullet korrigieren**

Old:
```
"- `cosh(x)` stays at bond dimension 2, but multiplying with an oscillatory function increases the internal rank.\n",
```
New:
```
"- The product QTT has larger bond dimensions than either factor alone, illustrating rank growth under multiplication.\n",
```

- [ ] **Step 12: Verifikation — NB04 Code-Zellen ausführen**

```bash
cd /Users/selinadirnbock/_PhD/learning-QTTs/Tensor4all.jl-TUTORIALS && julia --project=. -e '
using Tensor4all; using CairoMakie
const QG=Tensor4all.QuanticsGrids; const QTCI=Tensor4all.QuanticsTCI
const TN=Tensor4all.TensorNetworks; const STT=Tensor4all.SimpleTT
R=7; npoints=1<<R; value_type=Float64; tolerance=1e-12; maxbonddim=32; maxiter=200
f(x)=x^2; g(x)=sin(10*x); product(x)=f(x)*g(x)
grid=QG.DiscretizedGrid{1}(R,0.0,1.0;includeendpoint=false)
xvals=[QG.grididx_to_origcoord(grid,i) for i in 1:npoints]
qtt_f,_,_=QTCI.quanticscrossinterpolate(value_type,f,grid;tolerance=tolerance,maxbonddim=maxbonddim,maxiter=maxiter)
qtt_g,_,_=QTCI.quanticscrossinterpolate(value_type,g,grid;tolerance=tolerance,maxbonddim=maxbonddim,maxiter=maxiter)
f_values=[real(qtt_f(i)) for i in 1:npoints]
g_values=[real(qtt_g(i)) for i in 1:npoints]
h_values=f_values.*g_values
qtt_h,_,_=QTCI.quanticscrossinterpolate(h_values;tolerance=tolerance,maxbonddim=maxbonddim,maxiter=maxiter)
exact_h=f.(xvals).*g.(xvals)
h_qtt_values=[real(qtt_h(i)) for i in 1:npoints]
h_max_abs_error=maximum(abs.(exact_h.-h_qtt_values))
function get_bond_dims(qtt)
  simple_tt=STT.TensorTrain(qtt.tci)
  sites=[Tensor4all.Index(2;tags=["x","bit=$i"]) for i in 1:length(simple_tt)]
  indexed_tt=TN.TensorTrain(simple_tt,sites)
  return TN.linkdims(indexed_tt)
end
bond_f=get_bond_dims(qtt_f); bond_g=get_bond_dims(qtt_g); bond_h=get_bond_dims(qtt_h)
println("f(x)=x^2 bond dims: $bond_f")
println("g(x)=sin(10x) bond dims: $bond_g")
println("product bond dims: $bond_h")
println("max abs error: $h_max_abs_error")
if h_max_abs_error<1e-14 && length(bond_f)==6 && length(bond_g)==6 && length(bond_h)==6
  println("PASS: NB04 product section works correctly")
else
  error("FAIL: NB04 product section has issues")
end
'
```

Erwartet: `PASS: NB04 product section works correctly`, bond_f hat Werte (z.B. `[2, 3, 3, 3, 3, 2]`), max abs error < 1e-14.

- [ ] **Step 13: Commit**

```bash
cd /Users/selinadirnbock/_PhD/learning-QTTs/Tensor4all.jl-TUTORIALS && git add 04_operations_on_qtts.ipynb && git commit -m "fix: NB04 product section uses x^2 consistently (text + labels)"
```

---

### Task 2: H1 — README Status aktualisieren

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Z. 78 ersetzen**

Old (exakte Zeile in README.md):
```
The first four notebooks are currently implemented.
```
New:
```
All six notebooks are implemented:
01 through 05 are ready; 06 is a first draft.
```

- [ ] **Step 2: Commit**

```bash
cd /Users/selinadirnbock/_PhD/learning-QTTs/Tensor4all.jl-TUTORIALS && git add README.md && git commit -m "fix: update README notebook status to include NB05 and NB06"
```

---

### Task 3: H6 — NB06 Learning-Goals-Zelle trennen

**Files:**
- Modify: `06_affine_transformations.ipynb`

- [ ] **Step 1: `## Learning goals` in eigene Zelle auslagern**

Die Zelle id=`f8b7d359` enthält aktuell:
```
"## Learning goals\n",
"\n",
"After working through this notebook,...
```

Ersetze den `source`-Array dieser Zelle durch:
```
"## Learning goals\n"
```

- [ ] **Step 2: Neue Markdown-Zelle für den Lernziel-Text einfügen**

Füge direkt nach der Learning-Goals-Zelle eine neue Markdown-Zelle ein mit id=`nb06-learning-goals-text` (oder lasse sie leer für Auto-Generierung). Der source-Array:
```
"- explain what an affine pullback does to a sampled two-dimensional function,\n",
"- distinguish periodic and open boundary behavior for the same affine map,\n",
"- build and apply a multivariate affine pullback operator in `Tensor4all.jl`,\n",
"- compare transformed QTT values against dense analytic references,\n",
"- read bond-dimension profiles for the source state, transformed states, and affine MPOs.\n"
```

- [ ] **Step 3: Commit**

```bash
cd /Users/selinadirnbock/_PhD/learning-QTTs/Tensor4all.jl-TUTORIALS && git add 06_affine_transformations.ipynb && git commit -m "fix: NB06 separate Learning goals heading from body text"
```

---

### Task 4: H2 — NB02 toter Code in palette-Definition

**Files:**
- Modify: `02_accuracy_bonddims_and_sweeps.ipynb`

- [ ] **Step 1: Erste palette-Zeile löschen**

Die Zelle id=`e4c4851c` (R-Sweep-Plot) hat im source-Array die Zeilen 399-415. Die erste palette-Definition (die sofort überschrieben wird) löschen:

Old:
```
"palette = [:darkorange2, :dodgerblue3, :seagreen3,  :firebrick3, :slateblue3, :goldenrod2, :mediumorchid3, :darkgreen]\n",
"marker_cycle = [:circle, :rect, :diamond, :utriangle, :xcross, :star5, :dtriangle, :hexagon]\n",
"palette = [palette[mod1(i, length(palette))] for i in eachindex(sweep_R_values)]\n",
"markers = [marker_cycle[mod1(i, length(marker_cycle))] for i in eachindex(sweep_R_values)]\n",
```
New:
```
"marker_cycle = [:circle, :rect, :diamond, :utriangle, :xcross, :star5, :dtriangle, :hexagon]\n",
"palette = [marker_cycle[mod1(i, length(marker_cycle))] for i in eachindex(sweep_R_values)]\n",
"marker_cycle = [:circle, :rect, :diamond, :utriangle, :xcross, :star5, :dtriangle, :hexagon]\n",
"markers = [marker_cycle[mod1(i, length(marker_cycle))] for i in eachindex(sweep_R_values)]\n",
```

Halt stopp — das zerstört die Farblogik. Besser: die erste palette-Definition löschen, aber das Mapping mit den tatsächlichen Farben machen.

Old:
```
"palette = [:darkorange2, :dodgerblue3, :seagreen3,  :firebrick3, :slateblue3, :goldenrod2, :mediumorchid3, :darkgreen]\n",
"marker_cycle = [:circle, :rect, :diamond, :utriangle, :xcross, :star5, :dtriangle, :hexagon]\n",
"palette = [palette[mod1(i, length(palette))] for i in eachindex(sweep_R_values)]\n",
"markers = [marker_cycle[mod1(i, length(marker_cycle))] for i in eachindex(sweep_R_values)]\n",
```
New:
```
"raw_colors = [:darkorange2, :dodgerblue3, :seagreen3, :firebrick3, :slateblue3, :goldenrod2, :mediumorchid3, :darkgreen]\n",
"marker_cycle = [:circle, :rect, :diamond, :utriangle, :xcross, :star5, :dtriangle, :hexagon]\n",
"palette = [raw_colors[mod1(i, length(raw_colors))] for i in eachindex(sweep_R_values)]\n",
"markers = [marker_cycle[mod1(i, length(marker_cycle))] for i in eachindex(sweep_R_values)]\n",
```

- [ ] **Step 2: Commit**

```bash
cd /Users/selinadirnbock/_PhD/learning-QTTs/Tensor4all.jl-TUTORIALS && git add 02_accuracy_bonddims_and_sweeps.ipynb && git commit -m "fix: NB02 remove dead palette code by renaming first definition"
```

---

### Task 5: H3 — NB02 exact_values im Sweep neu berechnen

**Files:**
- Modify: `02_accuracy_bonddims_and_sweeps.ipynb`

- [ ] **Step 1: Vor der Fehlerberechnung exact_values neu berechnen**

In der Zelle id=`6abad5c4` (maxbonddim-Sweep), vor Z. 518–519. 

Suche nach dem Block der die Fehler berechnet (etwa Z. 518 `"    sweep_values = [real(sweep_qtt(i)) for i in 1:npoints]\n"`):

Old:
```
"sweep_values = [real(sweep_qtt(i)) for i in 1:npoints]\n",
"sweep_max_abs_error = maximum(abs.(exact_values .- sweep_values))\n",
```
New:
```
"sweep_values = [real(sweep_qtt(i)) for i in 1:npoints]\n",
"sweep_exact = target_function.(xvals)\n",
"sweep_max_abs_error = maximum(abs.(sweep_exact .- sweep_values))\n",
```

- [ ] **Step 2: Commit**

```bash
cd /Users/selinadirnbock/_PhD/learning-QTTs/Tensor4all.jl-TUTORIALS && git add 02_accuracy_bonddims_and_sweeps.ipynb && git commit -m "fix: NB02 maxbonddim sweep recomputes exact_values locally"
```

---

### Task 6: H4 — `worst_case_bond_dims` in NB01 vereinheitlichen

**Files:**
- Modify: `01_first_qtt_function_and_grid.ipynb`

- [ ] **Step 1: Zelle 109 — begin...end-Block durch Einzeiler ersetzen**

Die Plot-Zelle (id=`f45707cb`) hat aktuell einen `begin...end`-Block für die `worst_case_bond_dims`-Definition. 

Old (erster Teil der Zelle):
```
"worst_case_bond_dims(num_bonds; base=2) = begin\n",
"    num_sites = num_bonds + 1\n",
"    half = num_sites ÷ 2\n",
"    up = [base^x for x in 1:half]\n",
"    down = reverse(up)\n",
"    if length(up) + length(down) >= num_sites\n",
"        down = down[2:end]\n",
"    end\n",
"    [up..., down...]\n",
"end\n",
```
New:
```
"worst_case_bond_dims(num_bonds; base=2) = [base^min(k, num_bonds + 1 - k) for k in 1:num_bonds]\n",
```

- [ ] **Step 2: Commit**

```bash
cd /Users/selinadirnbock/_PhD/learning-QTTs/Tensor4all.jl-TUTORIALS && git add 01_first_qtt_function_and_grid.ipynb && git commit -m "fix: NB01 unify worst_case_bond_dims with other notebooks"
```

---

### Task 7: H5 — Julia-Version im README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Z. 12 ersetzen**

Old:
```
Install Julia 1.9 or later first.
```
New:
```
Install Julia 1.12 or later (tested with Julia 1.12).
```

- [ ] **Step 2: Commit**

```bash
cd /Users/selinadirnbock/_PhD/learning-QTTs/Tensor4all.jl-TUTORIALS && git add README.md && git commit -m "fix: README Julia version tested with 1.12"
```

---

### Task 8: M1–M9 — Alle mittleren Issues

**Files:**
- Modify: `03_multivariate_qtts_and_layouts.ipynb`
- Modify: `05_fourier_transforms.ipynb`
- Modify: `06_affine_transformations.ipynb`
- Modify: `01_first_qtt_function_and_grid.ipynb`
- Modify: `02_accuracy_bonddims_and_sweeps.ipynb`
- Modify: `04_operations_on_qtts.ipynb`

#### M1: maxiter überall auf 200

- [ ] **NB03 Z. 161:** `maxiter = 16` → `maxiter = 200`
- [ ] **NB05 Zelle 130** (2D-Bereich): `maxiter = 20` → `maxiter = 200`
- [ ] **NB06 Z. 145:** `maxiter = 20` → `maxiter = 200`

Commit:
```bash
git add 03_multivariate_qtts_and_layouts.ipynb 05_fourier_transforms.ipynb 06_affine_transformations.ipynb
git commit -m "fix: unify maxiter=200 across all notebooks"
```

#### M2: LaTeXStrings in allen Notebooks

- [ ] **NB01 Setup-Zelle:** `using LaTeXStrings` ergänzen. Im source-Array der Setup-Zelle (id=`b0c6094f`) nach `"using CairoMakie\n"` einfügen:

```
"using LaTeXStrings\n",
```

- [ ] **NB01 Plot-Zellen:** Labels für Funktionsnamen auf `L"..."` umstellen:
  - `"cosh(x)"` → `L"\\cosh(x)"` 
  - `"QTT samples"` → `L"QTT samples"`? Nein — laut Entscheidung: LaTeX NUR für Variablen und Funktionen, nicht für plain Labels wie "QTT samples", "exact cosh(x)", "value".
  - Also: nur `"exact cosh(x)"` → `L"\\cosh(x)"` (Funktionsname)
  - `"x^2"` → `L"x^2"` (im Experiment-Teil)

- [ ] **NB03 Setup-Zelle:** `using LaTeXStrings` hinzufügen (id=`b1dda11e`)

- [ ] **NB04 Setup-Zelle:** `using LaTeXStrings` hinzufügen (id=`b76f1305`)

- [ ] **NB05:** Prüfen ob bereits korrekt (hat import)

- [ ] **NB06 Setup-Zelle:** `using LaTeXStrings` hinzufügen (id=`262ab8c7`)

Commit:
```bash
git add 01_first_qtt_function_and_grid.ipynb 03_multivariate_qtts_and_layouts.ipynb 04_operations_on_qtts.ipynb 06_affine_transformations.ipynb
git commit -m "fix: add LaTeXStrings import to NB01,03,04,06"
```

#### M3: NB01 worst_case_bond_dims in eigene Zelle auslagern

(Die H4-Änderung ersetzt bereits den begin...end-Block durch einen Einzeiler. M3 fügt eine separate Zelle hinzu.)

- [ ] **Step 1:** Die bereits in H4 geänderte Zelle (Plot) behält NUR den Plot-Code. Der `worst_case_bond_dims`-Einzeiler kommt in eine neue Code-Zelle DIREKT VOR der Plot-Zelle.

Neue Code-Zelle vor id=`f45707cb`:
```json
{
  "cell_type": "code",
  "execution_count": null,
  "id": "nb01-worst-case-helper",
  "metadata": {},
  "outputs": [],
  "source": [
    "worst_case_bond_dims(num_bonds; base=2) = [base^min(k, num_bonds + 1 - k) for k in 1:num_bonds]\n"
  ]
}
```

- [ ] **Step 2:** Aus der Plot-Zelle (id=`f45707cb`) die `worst_case_bond_dims`-Zeile entfernen (sollte schon durch H4 passiert sein).

Commit:
```bash
git add 01_first_qtt_function_and_grid.ipynb && git commit -m "refactor: NB01 move worst_case_bond_dims to own cell"
```

#### M4: scatterlines! überall verwenden

Für jede Plot-Zelle in jedem Notebook, wo `lines!` + `scatter!` für dieselbe Datenreihe verwendet wird, durch `scatterlines!` ersetzen.

- [ ] **NB01 Zelle 109 (erster Plot):** `lines!(ax1, ...)` + `scatter!(ax1, ...)` → `scatterlines!(ax1, ...)`
- [ ] **NB01 Zelle 112 (zweiter Plot):** Selbes Muster
- [ ] **NB02 Zelle 5 (Baseline):** `lines!`+`scatter!` → `scatterlines!` für bond_dimension
- [ ] **NB02 Zelle 10 (maxbonddim-Sweep):** `lines!`+`scatter!` → `scatterlines!`
- [ ] **NB03 Zelle 45 (Bond-Dims):** `lines!`+`scatter!` → `scatterlines!` für interleaved und grouped
- [ ] **NB05 Zelle 129 (Bond-Dims):** `lines!`+`scatter!` → `scatterlines!` für input, after_fourier, after_recompression
- [ ] **NB05 Zelle 136 (2D Bond-Dims):** `lines!`+`scatter!` → `scatterlines!`
- [ ] **NB06 Zelle 37 (State Bond-Dims):** `lines!`+`scatter!` → `scatterlines!` für source, periodic, open
- [ ] **NB06 Zelle 37 (MPO Bond-Dims):** `lines!`+`scatter!` → `scatterlines!` für periodic MPO, open MPO

Für jedes scatterlines!-Paar: die zwei Zeilen (`lines!` + `scatter!`) durch eine `scatterlines!`-Zeile ersetzen mit allen `lines!`-Argumenten plus `markersize=`.

Beispiel:
```julia
# Vorher:
lines!(ax, idx, bond_dims; color=:goldenrod2, linewidth=2, label="bond dimension")
scatter!(ax, idx, bond_dims; color=:goldenrod2, markersize=6)
# Nachher:
scatterlines!(ax, idx, bond_dims; color=:goldenrod2, linewidth=2, markersize=6, label="bond dimension")
```

Commit:
```bash
git add . && git commit -m "refactor: use scatterlines! consistently across all notebooks"
```

#### M5: NB02 Figure-Größen

- [ ] Zelle id=`e4c4851c`: `Figure(size=(1200, 420))` → `Figure(size=(1200, 460))`

Commit:
```bash
git add 02_accuracy_bonddims_and_sweeps.ipynb && git commit -m "fix: NB02 consistent figure height 460"
```

#### M6: NB01 "What to notice" um Experiment ergänzen

- [ ] Vor dem letzten Bullet in Zelle id=`24cf61f5` einfügen:
```
"- The same workflow works on a shifted interval with a different target function.\n",
```

Commit:
```bash
git add 01_first_qtt_function_and_grid.ipynb && git commit -m "fix: NB01 What to notice mentions shifted interval experiment"
```

#### M7: 1-basierte Quantics-Erklärung

- [ ] **NB01 Z. 92–97 (id=`9dd3ec1c`):** Nach "binary coordinates" ergänzen:
  "In the quantics representation, the digit `1` stands for bit value `0` and `2` stands for bit value `1`, because Julia uses 1-based indexing."

  Old:
```
"shows the binary coordinates used by the QTT representation for that grid point."
```
  New:
```
"shows the binary coordinates used by the QTT representation for that grid point. In the quantics representation, the digit `1` stands for bit value `0` and `2` stands for bit value `1`, because Julia uses 1-based indexing."
```

- [ ] **NB05 Z. 323-326 (id=`72415005`):** Über der `quantics_digits`-Funktion einen Kommentar oder Markdown-Text ergänzen. Da die Funktion in einer Code-Zelle ist, entweder:
  - Eine Markdown-Zelle davor mit der Erklärung, ODER
  - Einen Code-Kommentar einfügen: `# Convert 0-based bits to 1-based quantics digits (0→1, 1→2)`

Commit:
```bash
git add 01_first_qtt_function_and_grid.ipynb 05_fourier_transforms.ipynb && git commit -m "docs: explain 1-based quantics digits in NB01 and NB05"
```

#### M8: NB06 Setup-Text vereinheitlichen

- [ ] Zelle id=`74cd7036`: Ersetze den gesamten `source`-Array mit dem Standard-Text aus NB01:

```
"From a terminal in the repository root, run:\n",
"\n",
"```bash\n",
"julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.build(\"Tensor4all\"); Pkg.precompile()'\n",
"```\n",
"\n",
"Then open the notebook in VS Code or Jupyter and select the Julia kernel that matches the version you used for setup. This notebook was last tested with Julia 1.12.\n"
```

Commit:
```bash
git add 06_affine_transformations.ipynb && git commit -m "fix: NB06 standardize setup text to match other notebooks"
```

#### M9: NB06 Learning Goals als Bullet-Liste

- [ ] Zelle nach `## Learning goals` (id=`f8b7d359`): Den Text ersetzen. Vorher Fließtext mit "After working through...", nachher Bullet-Liste:

```
"- explain what an affine pullback does to a sampled two-dimensional function\n",
"- distinguish periodic and open boundary behavior for the same affine map\n",
"- build and apply a multivariate affine pullback operator in `Tensor4all.jl`\n",
"- compare transformed QTT values against dense analytic references\n",
"- read bond-dimension profiles for the source state, transformed states, and affine MPOs\n"
```

Commit:
```bash
git add 06_affine_transformations.ipynb && git commit -m "fix: NB06 convert learning goals to bullet list"
```

---

### Task 9: Gesamt-Verifikation

- [ ] **Step 1: NB01-Check — alle Code-Zellen ausführen**

```bash
cd /Users/selinadirnbock/_PhD/learning-QTTs/Tensor4all.jl-TUTORIALS && julia --project=. -e '
using Tensor4all; using CairoMakie; using LaTeXStrings
const QG=Tensor4all.QuanticsGrids; const QTCI=Tensor4all.QuanticsTCI
const TN=Tensor4all.TensorNetworks; const STT=Tensor4all.SimpleTT
R=7; npoints=1<<R; grid=QG.DiscretizedGrid{1}(R,0.0,1.0;includeendpoint=true)
xvals=[QG.grididx_to_origcoord(grid,i) for i in 1:npoints]
target_function(x)=cosh(x); value_type=Float64; tolerance=1e-12; maxbonddim=32; maxiter=200
qtt,_,_=QTCI.quanticscrossinterpolate(value_type,target_function,grid;tolerance=tolerance,maxbonddim=maxbonddim,maxiter=maxiter)
simple_tt=STT.TensorTrain(qtt.tci); sites=[Tensor4all.Index(2;tags=["x","bit=$i"]) for i in 1:length(simple_tt)]
indexed_tt=TN.TensorTrain(simple_tt,sites); bond_dims=TN.linkdims(indexed_tt)
cosh_exact=target_function.(xvals); cosh_qtt=[real(qtt(i)) for i in 1:npoints]
cosh_max_abs_error=maximum(abs.(cosh_exact.-cosh_qtt))
println("NB01 cosh max error: $cosh_max_abs_error")
worst_case_bond_dims(num_bonds;base=2)=[base^min(k,num_bonds+1-k) for k in 1:num_bonds]
wc=worst_case_bond_dims(length(bond_dims))
if cosh_max_abs_error<1e-14 && length(bond_dims)==6 && wc==[2,4,8,8,4,2]
  println("PASS: NB01 basic workflow correct")
else error("FAIL: NB01")
end
'
```

- [ ] **Step 2: NB02-Check**

```bash
cd /Users/selinadirnbock/_PhD/learning-QTTs/Tensor4all.jl-TUTORIALS && julia --project=. -e '
using Tensor4all; using CairoMakie; using LaTeXStrings
const QG=Tensor4all.QuanticsGrids; const QTCI=Tensor4all.QuanticsTCI
const TN=Tensor4all.TensorNetworks; const STT=Tensor4all.SimpleTT
R=7; npoints=1<<R; target_function(x)=sin(30x)*cos(2x)+sin(50*x)
grid=QG.DiscretizedGrid{1}(R,0.0,1.0;includeendpoint=false)
xvals=[QG.grididx_to_origcoord(grid,i) for i in 1:npoints]
qtt,_,_=QTCI.quanticscrossinterpolate(Float64,target_function,grid;tolerance=1e-12,maxbonddim=32,maxiter=200)
qtt_values=[real(qtt(i)) for i in 1:npoints]
exact_values=target_function.(xvals)
max_abs_error=maximum(abs.(exact_values.-qtt_values))
println("NB02 baseline max error: $max_abs_error")
if max_abs_error<1e-13
  println("PASS: NB02 baseline correct")
else error("FAIL: NB02")
end
'
```

- [ ] **Step 3: NB03-Check**

```bash
cd /Users/selinadirnbock/_PhD/learning-QTTs/Tensor4all.jl-TUTORIALS && julia --project=. -e '
using Tensor4all; using CairoMakie; using LaTeXStrings
const QG=Tensor4all.QuanticsGrids; const QTCI=Tensor4all.QuanticsTCI
const TN=Tensor4all.TensorNetworks; const STT=Tensor4all.SimpleTT
R=4; npoints=1<<R; target_function(x,y)=x^2+x*y+y^3*cos(y)
grid=QG.DiscretizedGrid((:x,:y),(R,R);lower_bound=0.0,upper_bound=1.0,unfoldingscheme=:interleaved,includeendpoint=false)
qtt,_,_=QTCI.quanticscrossinterpolate(Float64,(x,y)->target_function(x,y),grid;tolerance=1e-10,maxbonddim=32,maxiter=200)
err=maximum(abs.([target_function(QG.grididx_to_origcoord(grid,(i,1))[1],QG.grididx_to_origcoord(grid,(1,j))[2])-real(qtt([i,j])) for i in 1:npoints, j in 1:npoints]))
println("NB03 max error: $err")
if err<1e-13; println("PASS: NB03 correct"); else error("FAIL: NB03"); end
'
```

- [ ] **Step 4: NB04-Check**

Siehe Task 1, Step 12 (wird dort schon ausgeführt).

- [ ] **Step 5: NB05-Check**

```bash
cd /Users/selinadirnbock/_PhD/learning-QTTs/Tensor4all.jl-TUTORIALS && julia --project=. -e '
using Tensor4all; using CairoMakie; using FFTW; using LaTeXStrings
const QG=Tensor4all.QuanticsGrids; const QTCI=Tensor4all.QuanticsTCI
const QT=Tensor4all.QuanticsTransform; const TN=Tensor4all.TensorNetworks
const STT=Tensor4all.SimpleTT
R=7; npoints=1<<R; target_function(x)=exp(-0.5*x^2)
grid=QG.DiscretizedGrid{1}(R,-10.0,10.0;includeendpoint=true)
qtt,_,_=QTCI.quanticscrossinterpolate(Float64,target_function,grid;tolerance=1e-10,maxbonddim=32,maxiter=200)
simple_tt=STT.TensorTrain(qtt.tci); sites=[Tensor4all.Index(2;tags=["x","bit=$i"]) for i in 1:length(simple_tt)]
state=TN.TensorTrain(simple_tt,sites); op=QT.fourier_operator(R;forward=true,maxbonddim=32,tolerance=1e-10)
TN.set_iospaces!(op,sites,sites); result=TN.apply(op,state)
op_bd=TN.linkdims(op.mpo); result_bd=TN.linkdims(result)
delta_x=20.0/(npoints-1); freq_step=1.0/(npoints*delta_x)
kvals=range(-(npoints/2)*freq_step,-(npoints/2)*freq_step+(npoints-1)*freq_step,length=npoints)
function qdigits(i,r); d=Base.digits(i-1;base=2,pad=r); return[x==0?1:2 for x in reverse(d)] end
out_sites=[only(inds) for inds in TN.siteinds(result)]; errors=Float64[]
for (ki,k) in enumerate(kvals)
  cb=ki-1-npoints÷2; ci=mod(cb,npoints); sv=qdigits(ci+1,R); reverse!(sv)
  raw=TN.evaluate(result,out_sites,sv); scale=delta_x*sqrt(Float64(npoints))
  phase=exp(-2π*im*k*(-10.0)); qval=raw*scale*phase
  exact=sqrt(2π)*exp(-2π^2*k^2); push!(errors,abs(qval-exact))
end
max_err=maximum(errors)
println("NB05 1D Fourier max error: $(round(max_err,sigdigits=3))")
if max_err<1e-8; println("PASS: NB05 correct"); else error("FAIL: NB05"); end
'
```

- [ ] **Step 6: NB06-Check**

```bash
cd /Users/selinadirnbock/_PhD/learning-QTTs/Tensor4all.jl-TUTORIALS && julia --project=. -e '
using Tensor4all; using CairoMakie; using LaTeXStrings
const QG=Tensor4all.QuanticsGrids; const QTCI=Tensor4all.QuanticsTCI
const QT=Tensor4all.QuanticsTransform; const TN=Tensor4all.TensorNetworks
const STT=Tensor4all.SimpleTT
R=6; npoints=1<<R
grid=QG.DiscretizedGrid((:x,:y),(R,R);lower_bound=0.0,upper_bound=Float64(npoints),unfoldingscheme=:fused,includeendpoint=false)
source_function(u,v,N)=sin(2π*u/N)+0.5*cos(2π*v/N)+0.25*sin(2π*(u+2v)/N)
qtt,_,_=QTCI.quanticscrossinterpolate(Float64,(u,v)->source_function(u,v,npoints),grid;tolerance=1e-12,maxbonddim=64,maxiter=200)
sv=[real(qtt([i,j])) for i in 1:npoints, j in 1:npoints]
ex=[source_function(x,y,npoints) for x in 0:npoints-1, y in 0:npoints-1]
err=maximum(abs.(ex.-sv))
println("NB06 source QTT max error: $err")
if err<1e-12; println("PASS: NB06 correct"); else error("FAIL: NB06"); end
'
```

- [ ] **Step 7: Abschluss-Commit**

```bash
cd /Users/selinadirnbock/_PhD/learning-QTTs/Tensor4all.jl-TUTORIALS && git status
```

---

## Reihenfolge (empfohlen)

Task 1 → Task 4 → Task 5 → Task 6 → Task 2 → Task 7 → Task 3 → Task 8 → Task 9

Tasks 2,3,7 können parallel zu Tasks 4-6 laufen (unterschiedliche Dateien).
Task 8 sollte NACH Task 6 kommen (NB01 muss schon korrigiert sein).
Task 9 IMMER ZULETZT.

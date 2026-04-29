# Remediation Plan: Notebook Review Findings

> **Status:** active
> **Basis:** Review vom 2026-04-29 (alle 5 Notebooks + Docs)
> **Vorgehen:** Ein Notebook nach dem anderen, von 01 bis 05 + README.

---

## 🔴 Kritisch (muss sofort gefixt werden)

### R1: Notebook 04 — `f(x) = x^2` statt `cosh(x)` im Text

**Problem:** Der Markdown-Text (Z. 91–98) und der `println`-Output (Z. 149–150, 168) behaupten, dass
`f(x) = cosh(x)` verwendet wird. Tatsächlich definiert der Code `f(x) = x^2` (Z. 127).
Die ausgegebenen Bond-Dimensionen `[2, 3, 3, 3, 3, 2]` sind für `x^2` korrekt, aber ein Student, der
den Text liest, erwartet die cosh-Bond-Dimensionen `[2, 2, 2, 2, 2, 2]`.

**Entscheidung:** Text auf `x^2` korrigieren. Markdown, Print-Statements und Kommentare anpassen.

**Datei:** `04_operations_on_qtts.ipynb`

Alle Stellen, die `cosh(x)` referenzieren (vollständige Liste):
- [ ] **Markdown Z. 92–98:** `f(x) = \cosh(x)` → `f(x) = x^2`; `sin(10x)` bleibt
- [ ] **Kommentar Z. 125:** `#f(x) = cosh(x)` → `# f(x) = x^2`
- [ ] **Print-Output Z. 149–150:** Aus dem Code entfernbar oder Text anpassen
- [ ] **Print-Output Z. 168:** `f(x) = cosh(x)` → `f(x) = x^2`
- [ ] **Markdown Z. 184:** `\cosh(x)·\sin(10x)` → `x^2 · \sin(10x)`
- [ ] **Plot Legende Z. 335:** `L"\\cosh(x)"` → `L"x^2"`
- [ ] **Plot Legende Z. 337:** `L"\\cosh(x)\\cdot\\sin(10x)"` → `L"x^2\\cdot\\sin(10x)"`
- [ ] **Plot Legende Z. 347:** `L"\\cosh(x)"` → `L"x^2"`
- [ ] **Plot Legende Z. 355:** `L"\\cosh(x)\\cdot\\sin(10x)"` → `L"x^2\\cdot\\sin(10x)"`
- [ ] **Interpretation Z. 371–374:** Muss komplett neu, da `x^2` max bond dim 3 hat (nicht 2 wie cosh).
  Z.B.: `x^2 has a moderate bond-dimension profile. sin(10x) stays at bond dimension 2. The product of the two functions has larger bond dimensions than either factor alone: this is rank growth under multiplication.`
- [ ] **What to notice Z. 567–568:** Zweiter Bullet umformulieren:
  `x^2 and sin(10x) both have moderate internal rank; the pointwise product increases the bond dimensions to a higher profile.`
  (Der fünfte Bullet über `x^2` in Part 2 bleibt unverändert.)

---

## 🟠 Hoch (muss gefixt werden)

### H1: README.md — Status veraltet

**Problem:** Z. 78: "The first four notebooks are currently implemented" — Notebook 05 existiert jetzt.

**Entscheidung:** Status aktualisieren auf "five notebooks" oder die konkrete Liste nennen.

**Datei:** `README.md`
**Aufgaben:**
- [ ] Z. 78: `The first four notebooks are currently implemented.` durch konkrete Liste ersetzen

### H2: Notebook 02 — toter Code in palette-Definition

**Problem:** Z. 411–413: `palette` wird definiert und in der nächsten Zeile sofort mit `[palette[mod1(...)] ...]` überschrieben.

**Entscheidung:** Erste `palette`-Definition löschen, nur die zweite (gemappte) behalten.

**Datei:** `02_accuracy_bonddims_and_sweeps.ipynb`
**Aufgaben:**
- [ ] Z. 411 (`palette = [:darkorange2, ...]`) löschen
- [ ] `marker_cycle` ggf. behalten, wenn es auch gemappt wird (Z. 414)

### H3: Notebook 02 — `exact_values` wird stillschweigend aus Zelle 4 weitergenutzt

**Problem:** Der `maxbonddim`-Sweep (Zelle 9, Z. 519) verwendet `exact_values`, das in Zelle 4 (Z. 180)
definiert wurde. Kein Hinweis auf diese Abhängigkeit.

**Entscheidung:** `exact_values` im Sweep neu berechnen (Z. 518–519), damit die Zelle self-contained ist.

**Datei:** `02_accuracy_bonddims_and_sweeps.ipynb`
**Aufgaben:**
- [ ] Vor Z. 519: `sweep_exact = target_function.(xvals)` einfügen
- [ ] Z. 519: `exact_values` → `sweep_exact`

### H4: Notebook 01 + 02 — `worst_case_bond_dims` vereinheitlichen

**Problem:** Notebook 01 definiert den Helfer als `begin...end`-Block mit eigener Logik (Z. 312–321).
Notebook 02 und 04 nutzen die Einzeiler-Version `[base^min(k, num_bonds + 1 - k) for k in 1:num_bonds]`.

**Entscheidung:** Einheitlich die NB02-Kurzform in allen Notebooks verwenden.

**Datei:** `01_first_qtt_function_and_grid.ipynb`
**Aufgaben:**
- [ ] Z. 312–321: `begin...end`-Block durch Einzeiler ersetzen

### H5: Julia-Version im README

**Problem:** README sagt "Julia 1.9 or later", Notebook-Metadaten sagen 1.12.5. Version 1.9 enthält
möglicherweise nicht alle genutzten Features.

**Entscheidung:** Konkrete Testversion nennen, z.B. "This repository was tested with Julia 1.12."

**Datei:** `README.md`
**Aufgaben:**
- [ ] Z. 12: `Install Julia 1.9 or later first.` → `Install Julia 1.12 or later first (tested with Julia 1.12).`

---

## 🟡 Mittel (sollte gefixt werden)

### M1: `maxiter` konsistent machen

**Problem:** NB01/02/04 nutzen `maxiter = 200`, NB03 nutzt `maxiter = 16` (R=4, 2D, 256 Punkte),
NB05 nutzt `maxiter = 200` für 1D und `maxiter = 20` für 2D. Keine Erklärung für die Abweichungen.

**Entscheidung:** `maxiter = 200` für alle Notebooks (sichere obere Schranke, frühzeitige Termination
bei Konvergenz).

**Dateien:** `03_multivariate_qtts_and_layouts.ipynb`, `05_fourier_transforms.ipynb`
**Aufgaben:**
- [ ] NB03 Z. 161: `maxiter = 16` → `maxiter = 200`
- [ ] NB05: Prüfen ob 20 für 2D reicht, ggf. auf 200 setzen

### M2: LaTeXStrings konsistent nutzen

**Problem:** Nur NB02 importiert `using LaTeXStrings`. Andere Notebooks nutzen Plain-Strings auch für
Funktionsnamen, wo LaTeX schöner wäre.

**Entscheidung:** `using LaTeXStrings` in allen Notebooks importieren, LaTeX-Labels für Variablen und
Funktionen verwenden (z.B. `L"\\cosh(x)"`), Plain-Strings für Achsenbeschriftungen wie `"x"`, `"value"`.

**Dateien:** Alle Notebooks
**Aufgaben:**
- [ ] NB01: `using LaTeXStrings` hinzufügen, Labels für Funktionen auf L"" umstellen
- [ ] NB03: `using LaTeXStrings` hinzufügen
- [ ] NB04: `using LaTeXStrings` hinzufügen
- [ ] NB05: Prüfen ob alle L""-Labels Variablen/Funktionen betreffen

### M3: Notebook 01 — `worst_case_bond_dims` in eigene Zelle auslagern

**Problem:** Der Helfer wird in derselben Zelle wie der Plot-Code definiert, was die Zelle überladen macht.

**Entscheidung:** Helfer in eine separate Code-Zelle direkt vor der Plot-Zelle auslagern.

**Datei:** `01_first_qtt_function_and_grid.ipynb`
**Aufgaben:**
- [ ] Neue Code-Zelle vor Zelle 109 (Plot) mit der `worst_case_bond_dims`-Definition
- [ ] Plot-Zelle: `begin...end`-Block entfernen, nur Plot-Code behalten

### M4: `scatterlines!` konsistent verwenden

**Problem:** NB04 verwendet `scatterlines!` (Z. 527), andere Notebooks nutzen getrennte `lines!` + `scatter!`.

**Entscheidung:** `scatterlines!` in allen Notebooks verwenden, wo es passt (vereinfacht den Code).

**Dateien:** `01_first_qtt_function_and_grid.ipynb`, `02_accuracy_bonddims_and_sweeps.ipynb`,
`03_multivariate_qtts_and_layouts.ipynb`, `05_fourier_transforms.ipynb`
**Aufgaben:**
- [ ] NB01: Plot-Zellen prüfen, wo `lines!` + `scatter!` zu `scatterlines!` werden kann
- [ ] NB02: Gleiches
- [ ] NB03: Gleiches
- [ ] NB05: Gleiches
- [ ] NB04: Bereits in Benutzung

### M5: Notebook 02 — Figure-Größen vereinheitlichen

**Problem:** Baseline (1000×460), R-Sweep (1200×420), maxbonddim (1000×460), Playground (1000×460).

**Entscheidung:** Einheitlich `Figure(size=(1000, 460))` für Zwei-Panel-Plots, ggf. `(1200, ...)` für
breitere Layouts.

**Datei:** `02_accuracy_bonddims_and_sweeps.ipynb`
**Aufgaben:**
- [ ] Z. 399: `Figure(size=(1200, 420))` → `Figure(size=(1200, 460))` (460 beibehalten, 1200 für das breite Layout OK)

### M6: Notebook 01 — "What to notice" erwähnt Experiment nicht

**Problem:** Die Liste in Z. 529–535 fasst nur die `cosh(x)`-Ergebnisse zusammen, das zweite Experiment
(`x^2` auf verschobenem Intervall) fehlt.

**Entscheidung:** Punkt zum Experiment hinzufügen.

**Datei:** `01_first_qtt_function_and_grid.ipynb`
**Aufgaben:**
- [ ] Neuen Bullet-Point im "What to notice": "The same workflow works on a shifted interval with a different target function."

### M7: Notebook 02 — 1-basierte Quantics-Darstellung erklären

**Problem:** `grididx_to_quantics(grid, 1)` gibt `[1, 1, ..., 1]` zurück, was für Studierende ohne
Kontext verwirrend ist (Julia ist 1-basiert, Bitwert 0 → Index 1, Bitwert 1 → Index 2).

**Entscheidung:** Kurze Erklärung im Text ergänzen.

**Dateien:** `01_first_qtt_function_and_grid.ipynb`, `05_fourier_transforms.ipynb`
**Aufgaben:**
- [ ] NB01 Z. 92–97: Nach "binary coordinates" kurz erklären: Julia 1-basiert, 1 = Bit 0, 2 = Bit 1
- [ ] NB05: Gleiche Erklärung bei `quantics_digits`-Funktion (Z. 323-326)

---

## 🟢 Niedrig (optional, Quality of Life)

### N1: `Project.toml` UUID — geprüft, OK

**Status:** Die UUID `a1b2c3d4-...` ist konsistent in Project.toml, Manifest.toml und
im Tensor4all.jl-Package selbst. Kein Handlungsbedarf.

### N2: NB02 Playground — anonyme Funktionen beibehalten (entschieden)

**Entscheidung:** So lassen, wie beschlossen.

---

## Reihenfolge der Bearbeitung

1. **R1** (NB04 Funktions-Bug) — höchste Priorität, betrifft Lernerlebnis direkt
2. **H1** (README Status)
3. **H2** (NB02 Dead Code) + **H3** (NB02 Hidden Dependency) + **H4** (worst_case_bond_dims)
4. **H5** (Julia Version)
5. **M1–M7** (mittel, können parallel gemacht werden)
6. **N1** (optional)

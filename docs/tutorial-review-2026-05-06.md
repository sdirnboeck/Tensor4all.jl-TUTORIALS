# Tutorial-Review: Priorisierte Korrekturliste

Datum: 2026-05-06

Geprüft: `README.md`, `Project.toml`, Notebooks 01-06,
`docs/tutorial-learning-path.md`.

Zusätzlicher Ausführungstest: alle sechs Notebooks wurden als Code-Zellen in
Reihenfolge in frischen Julia-Sessions mit `julia --project=.` ausgeführt.
Ergebnis: alle sechs Notebooks liefen ohne Laufzeitfehler durch.
`jupyter` selbst ist in dieser Umgebung nicht installiert; der Test prüft also
die technische Zell-Ausführbarkeit, nicht die Jupyter-UI.

Zielgruppe laut README: Master- und frühe PhD-Studis, die QTTs zum ersten Mal
kennenlernen. Hauptkriterium dieses Reviews: Kann ein:e Anfänger:in sinnvoll
starten, die Zellen ausführen und die Begriffe ohne Vorwissen einordnen?

Hinweis: Der gewünschte `agentic-test` Skill ist in dieser Session nicht als
Skill verfügbar. Der Anfänger:innen-Test wurde deshalb manuell simuliert:
Setup lesen, Lernpfad lesen, Notebooks in Reihenfolge ausführen und
Erklärlücken aus Sicht eines Masterstudis bewerten.

---

## Implementation Status

This review has been turned into an implementation plan:

- Plan file: `docs/superpowers/plans/2026-05-07-tutorial-review-implementation.md`
- Decisions are resolved; remaining work is implementation and verification.
- Color check result: no global color refactor needed; only Notebook 02's
  R-sweep palette needs a colorblind-safe categorical replacement.

---

## Prioritätsdefinition

- **P0 - blockierend:** Laufzeitfehler, falsches Ergebnis, Setup verhindert
  Einstieg.
- **P1 - vor Verteilung beheben:** starke didaktische Reibung,
  Anfänger:innen verlieren den roten Faden oder können Begriffe/API-Aufrufe
  nicht einordnen.
- **P2 - Qualitätshebung:** kein Blocker, aber spürbar bessere Verständlichkeit
  und Konsistenz. Nur umsetzen, wenn der Punkt beim Durchgehen wirklich stört.
- **P3 - Optionaler Polish:** kleine Glättungen. Nicht "for the sake of it"
  ändern; nur anfassen, wenn die Stelle ohnehin bearbeitet wird oder sichtbar
  verwirrt.

---

## Kurzfazit

Es gibt aktuell keinen technischen P0-Blocker: die Notebooks laufen durch.

Die wichtigsten Probleme sind nicht numerisch, sondern didaktisch:

1. Fused Layout, `PartialContractionSpec` und affine Pullback-Parameter kommen
   zu abrupt.
2. Bei den Farben ist kein globaler Fix nötig; nur die 8-Farben-Palette in
   Notebook 02 sollte auf eine etablierte farbenblind-sichere Palette wechseln.
3. Der Einstiegspfad sagt noch nicht klar genug, was man zuerst tun soll und
   was jedes Notebook leistet.

---

## P0 - Kritisch

### P0-1. Keine bestätigten Laufzeitfehler

**Befund:** Alle sechs Notebooks liefen in frischen Julia-Sessions mit
`julia --project=.` durch.

**Rest-Risiko:** Jupyter/IJulia-UI wurde nicht getestet, weil `jupyter` in
dieser Umgebung nicht installiert ist.

**Empfehlung:** Kein Code-Fix notwendig. Vor Veröffentlichung optional einmal
in VS Code oder Jupyter Lab öffnen und "Run all" ausführen.

---

## P1 - Vor breiterer Verteilung beheben

### P1-1. Farbenblind-sichere Plot-Konvention: nur ein kleiner Fix nötig

**Befund:** Die Plots verwenden mehrere Farben und Colormaps, z. B.
`:dodgerblue3`, `:deepskyblue4`, `:goldenrod2`, `:firebrick3`, `:red`,
`:seagreen3`, `:gray40`, `:gray60`, `:navia`.

**Prüfergebnis:** Kein globaler Farb-Fix nötig. `:navia` kann bleiben: es
gehört zu den Scientific Colour Maps und ist damit als bewusst entworfene,
farbenblindheitsfreundlichere Colormap plausibel. Auch die wiederkehrenden
Linienfarben sind meist durch Labels, Marker oder Linienstile zusätzlich
unterscheidbar.

Der einzige konkrete Fix-Kandidat ist Notebook 02: Die R-Sweep-Zelle nutzt
eine 8-Farben-`raw_colors`-Palette mit mehreren ad-hoc Farben
(`:darkorange2`, `:dodgerblue3`, `:seagreen3`, `:firebrick3`, `:slateblue3`,
`:goldenrod2`, `:mediumorchid3`, `:darkgreen`). Weil dort viele Kategorien
gleichzeitig auftreten, sollte diese Palette auf eine bekannte
farbenblind-sichere kategoriale Palette umgestellt werden. Die vorhandenen
Marker sollten bleiben.

**Neue Anforderung:** Es sollen nur Farben verwendet werden, die für möglichst
alle Arten von Farbenblindheit gut sichtbar sind. Referenzen:

- ColorSchemes.jl scientific catalogue:
  <https://juliagraphics.github.io/ColorSchemes.jl/dev/catalogue/#scientific>
- Fabio Crameri Scientific Colour Maps:
  <https://www.fabiocrameri.ch/colourmaps/>

**Fix:**

- `:navia` in Heatmaps beibehalten.
- Bestehende 2- bis 4-Kurven-Plots nicht nur wegen der Farben ändern.
- Nur die Notebook-02-`raw_colors`-Palette durch eine etablierte
  farbenblind-sichere kategoriale Palette ersetzen, z. B. Okabe-Ito:
  `#000000`, `#E69F00`, `#56B4E9`, `#009E73`, `#F0E442`, `#0072B2`,
  `#D55E00`, `#CC79A7`.
- Marker und Linienstile dort beibehalten.

### P1-2. Fused Layout wird zu spät eingeführt

**Befund:** Notebook 03 erklärt `:interleaved` und `:grouped`. Das dritte
Schema `:fused` taucht erst in Notebook 04 Part 2 auf und wird in Notebook 06
benutzt.

**Auswirkung:** Lernende sehen plötzlich Site-Dimension 4 und fused Sites,
ohne vorher gelernt zu haben, warum ein Site mehrere Variablenbits enthalten
kann.

**Empfohlener Fix:** Notebook 03 um einen kurzen dritten Layout-Abschnitt
"Fused layout" ergänzen. Minimaler Inhalt:

- ein fused `DiscretizedGrid`,
- Site-Dim 4 erklären,
- Bond-Dims mit base-4-Worst-Case-Hülle vergleichen,
- ein Satz: fused Sites sind nicht mehr reine `x`- oder `y`-Sites.

**Entscheidung:** Notebook 03 erweitern. Keine reine Brücke in Notebook 04.

### P1-3. `PartialContractionSpec` und affine Pullback-API sind zu abrupt

**Befund Notebook 04:** Dieser Aufruf wird nicht ausreichend erklärt:

```julia
selected_product_spec = TN.PartialContractionSpec(
    Pair{Tensor4all.Index,Tensor4all.Index}[],
    t_diagonal_pairs;
    output_order=full_sites,
)
```

Unklar für Anfänger:innen:

- Warum ist das erste Pair-Array leer?
- Was ist der Unterschied zwischen normalen Kontraktions-Pairs und
  Diagonal-Pairs?
- Warum ist `output_order` nötig?

**Befund Notebook 06:** Die rationale Matrix-API ist nicht erklärt:

```julia
a_num = [1, 0, 1, 1]
a_den = [1, 1, 1, 1]
b_num = [0, 0]
b_den = [1, 1]
```

Unklar:

- Wie werden die flachen Arrays als Matrix gelesen?
- Warum Numerator/Denominator statt Float-Matrix?
- Was bedeuten die positionellen `2, 2`?

**Empfohlener Fix:** Vor dem ersten API-Aufruf je eine kurze Markdown-Zelle
einfügen:

- "What the arguments mean"
- ein ausgeschriebenes Mini-Beispiel,
- warum rationale Werte verwendet werden,
- was der zurückgegebene Wert strukturell ist.

### P1-4. Standardparameter soweit sinnvoll vereinheitlichen

**Befund:** `tolerance`, `maxbonddim` und `includeendpoint` wechseln zwischen
den Notebooks.

| Notebook | tolerance | maxbonddim | includeendpoint |
|---|---:|---:|---|
| 01 | `1e-12` | 32 | true |
| 02 | `1e-12` | 32 | false |
| 03 | `1e-10` | 32 | false |
| 04 P1 | `1e-12` | 32 | false |
| 04 P2 | `1e-10` | 32 | false |
| 04 P3 | `1e-12` | 32 | true |
| 05 P1 | `1e-10` | 32 | true |
| 05 P2 | `1e-10` / `1e-8` | 64 | true |
| 06 | `1e-12` | 64 | false |

**Entscheidung:** Die Parameterwahl muss nicht ausführlich erklärt werden; die
Choices sind hier teils bewusst pragmatisch/arbitrary. Trotzdem ist es gut,
unnötige Variation zu reduzieren.

**Fix:**

- `tolerance` überall auf `1e-12` setzen.
- `maxbonddim` nach Möglichkeit überall auf `64` setzen.
- `includeendpoint` nicht ändern; die vorhandenen Werte bleiben.
- Keine Konventionstabelle ergänzen und keine künstlichen Erklärsätze einfügen.

### P1-5. README/Learning Path soll kurz sagen, was jedes Notebook abdeckt

**Befund:** Man kann der Reihenfolge über die Dateinamen folgen, aber README
und Learning Path zeigen noch nicht knapp genug, was jedes Notebook konkret
abdeckt.

**Entscheidung:** Keine Next-Footer in jedem Notebook einfügen. Man weiß, dass
man nach 01 zu 02 usw. geht.

**Fix:** Im README oder Learning Path eine kleine Übersicht ergänzen: pro
Notebook ein kurzer Satz, was darin behandelt wird.

---

## P2 - Qualitätshebung

### P2-1. Notebook 04 Part 3 Integration wirkt entkoppelt

**Befund:** Notebook 04 springt von 2D selected-variable products zurück zu
1D integration.

**Auswirkung:** Inhaltlich ist Integration eine QTT-Operation, aber die
Lernkurve bricht nach dem komplexeren Part 2 ab.

**Optionen:**

- **A:** Integration in ein eigenes Notebook auslagern.
- **B:** Integration innerhalb Notebook 04 an den Anfang ziehen.
- **C:** Integration im Notebook lassen, aber mit einer klaren Brücke
  einleiten: "After multiplication, we look at a second basic operation:
  summing/integrating a QTT."

**Entscheidung/Fix:** Option C umsetzen: Integration bleibt in Notebook 04,
wird aber mit einer kurzen Brücke eingeleitet. A oder B sind aktuell nicht
nötig.

### P2-2. Notebook 05: `sites2`-Tags sind semantisch falsch

**Befund:** `grid2` ist interleaved über `(x, t)`, aber `sites2` taggt alle
Sites als `"x"`.

**Auswirkung:** Kein Laufzeitfehler, aber pädagogisch falsch, wenn jemand die
Site-Tags inspiziert.

**Fix:** `sites2` analog zu Notebook 03/04 aus dem Grid ableiten, z. B. über
`sites_from_grid(grid2)`.

### P2-3. Helper-Duplikate kontrollieren

**Befund:** `worst_case_bond_dims` wird in allen Notebooks neu definiert;
`sites_from_grid` existiert in leicht unterschiedlichen Varianten.

**Auswirkung:** Kopieren zwischen Notebooks kann stilles Verhalten ändern
(`base=2` vs. `base=4`).

**Entscheidung/Fix:** Helper bewusst lokal in den Notebooks lassen, weil das
für Anfänger:innen sichtbarer ist. Dabei aber gleiche Namen, gleiche Defaults
und gleiche Erklärung verwenden.

### P2-4. Notebook 01: TCI ausschreiben

**Befund:** TCI wird als Begriff benutzt, ohne "Tensor Cross Interpolation"
auszuschreiben.

**Fix:** Beim ersten Auftreten:

```text
TCI (Tensor Cross Interpolation) builds the QTT by querying selected function
values instead of evaluating all 2^R grid points.
```

### P2-5. Notebook 05 Konzept-Sektion entzerren

**Befund:** Die Fourier-Konzeptzelle ist mathematisch dicht.

**Fix:** Kein zusätzliches Orientierungsschema einfügen; das wäre hier eher
verwirrend. Stattdessen nach der Herleitung kurze TL;DR-Sätze ergänzen:

- `sqrt(N)` kompensiert die unitäre Normalisierung.
- `Δx` macht aus der Summe eine Integralapproximation.

### P2-6. Notebook 05: `quantics_digits` und `reverse!` erklären oder glätten

**Befund:** `quantics_digits` reversed intern und `reverse!(site_vals)` kehrt
danach erneut um.

**Auswirkung:** Der Code funktioniert, wirkt aber unnötig rätselhaft.

**Fix:** Den Helper so umstellen, dass die Reihenfolge einfacher lesbar ist
und nur einmal angepasst wird.

### P2-7. Notebook 05: `using LaTeXStrings` konsistent machen

**Befund:** Notebook 05 nutzt `L"..."`, importiert aber nicht explizit
`LaTeXStrings`; andere Notebooks tun das.

**Fix:** `using LaTeXStrings` in den Setup-Block aufnehmen.

---

## P3 - Polish

### P3-1. README/Learning Path klarer machen

**Befund:** README/Learning Path sollten noch schneller zeigen, was die Reihe
abdeckt.

**Fix:** Pro Notebook ein kurzer Satz, was darin behandelt wird. Das ersetzt
die Idee von Next-Footern in den einzelnen Notebooks.

### P3-2. Jupyter-Troubleshooting ergänzen

**Befund:** Troubleshooting ist aktuell VS-Code-spezifisch.

**Fix:** Ein kurzer Jupyter-Lab/classic-Jupyter-Absatz:
Kernel restart, Setup-Befehl im Terminal erneut ausführen, Jupyter neu starten.

### P3-3. Keine zusätzliche `maxiter`-Erklärung nötig

**Befund:** Der Wert taucht in mehreren Notebooks auf.

**Entscheidung:** Keine zusätzliche Erklärung einfügen. Die Parameterchoices
sind hier ausreichend pragmatisch und sollen nicht künstlich didaktisiert
werden.

### P3-4. Leere Markdown-Zelle in Notebook 06 entfernen

**Befund:** Notebook 06 endet mit einer leeren Markdown-Zelle.

**Fix:** Entfernen.

### P3-5. Setup-Block wiederholt sich sechsmal

**Befund:** Jedes Notebook enthält einen langen "Before you run this notebook"
Block.

**Entscheidung:** Die Notebooks sollen einzeln lesbar bleiben. Der ausführliche
Setup-Hinweis muss aber nicht überall stehen, wenn README/Learning Path den
Einstieg gut erklären.

**Fix:** Setup im README klar beschreiben und die Notebook-Setup-Blöcke bei
Gelegenheit kürzen:

```text
Setup: see README.md. Use the Julia 1.12 project environment.
```

Die Notebooks dürfen auf README verweisen, sollten aber weiterhin ohne
zusätzlichen Kontext verständlich bleiben.

---

## Empfohlene Reihenfolge

### Runde 1 - Anfänger:innen sofort entlasten

1. **P1-1 Farbenblind-sichere Plot-Konvention**: `:navia` beibehalten und nur
   die Notebook-02-`raw_colors`-Palette ersetzen.
2. **P1-4 Standardparameter vereinheitlichen**: `tolerance=1e-12`,
   `maxbonddim=64`, `includeendpoint` unverändert.
3. **P1-5 README/Learning Path**: kurze Übersicht ergänzen, was jedes Notebook
   abdeckt.

### Runde 2 - harte Verständnisbrücken

4. **P1-2 Fused Layout in Notebook 03**: vor Notebook 04/06 einführen.
5. **P1-3 API-Erklärungen**: `PartialContractionSpec` und rationale affine
   Matrix-API erklären.
6. **P2-1 Integration in Notebook 04**: mit kurzer Brücke einleiten.

### Runde 3 - Nur wenn beim Durchgehen wirklich nötig

7. **P2-2 bis P2-7**: Site-Tags, Helper, TCI, Fourier-TL;DR,
   LaTeXStrings.
8. **P3-2 bis P3-5**: Troubleshooting, leere Zelle, Setup-Block,
    kleinere Formulierungen.

---

## Entscheidungen Vor Umsetzung

Aktuell keine offenen Entscheidungen mehr. Die noch verbleibenden Punkte sind
Umsetzungsarbeit, keine Richtungsfragen.

---

## Was Bereits Gut Funktioniert

- Die Notebook-Struktur ist wiedererkennbar: Learning goals, Konzept, Code,
  Interpretation, API recap.
- Notebook 01 eignet sich gut als Einstieg, weil es mit `cosh(x)` ein
  verständliches 1D-Beispiel nutzt.
- Notebook 02 erklärt `includeendpoint=false` vs. `includeendpoint=true`
  bereits sehr gut.
- Die Plot-Idee "Funktion plus Bond-Dimensionen" ist stark und sollte
  beibehalten werden.
- Worst-Case-Hüllen in Bond-Dim-Plots sind eine gute wiederkehrende
  Orientierung.
- Notebook 04 Part 2 ist numerisch sauber; der fused selected-variable product
  liefert Fehler im Bereich `~8.5e-14`.

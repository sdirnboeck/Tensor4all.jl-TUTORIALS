# Notebook 02 Reference Notes

> **Status:** implemented and reviewed. This file is no longer an expansion
> checklist. It now records the design decisions that Notebook 02 established
> so later notebooks can reuse them without rediscovering the same trade-offs.

## Scope

This note describes the current teaching design of
`02_accuracy_bonddims_and_sweeps.ipynb`.

It should be used as:

- a reference for future sweep notebooks,
- a reminder of decisions already made,
- a guard against reintroducing older Notebook 02 ideas that were tried and
  then removed.

## Notebook Outcome

Notebook 02 now justifies being separate from Notebook 01 by focusing on:

1. one baseline example,
2. a sweep over `R`,
3. a sweep over `maxbonddim`,
4. an optional small playground section for trying another target function
   under the same workflow,
5. `## What to notice`,
6. `## API recap`.

## Decisions That Are Now Fixed

### 1. No dedicated tolerance sweep

`tolerance` remains visible in the code, but Notebook 02 does **not** contain a
full tolerance sweep.

Reason:

- it did not produce a strong enough teaching story for this notebook,
- `R` and `maxbonddim` are much easier to interpret,
- keeping the notebook focused makes it more clearly distinct from Notebook 01.

Future notebooks may still mention or use `tolerance`, but they should not add
a tolerance sweep by default unless it clearly teaches something important.

### 2. `R` and `maxbonddim` are the two main control parameters

Notebook 02 teaches two different ideas:

- changing `R` changes the grid resolution,
- changing `maxbonddim` imposes an artificial structural cap.

These should not be blended into one generic “larger parameter gives a better
result” story.

### 3. The function-comparison section is a playground

If Notebook 02 includes a second target function at the end, it should be
framed as a small **playground** rather than as a benchmark or as a third main
pillar of the notebook.

Its job is to show that:

- the same workflow can be reused,
- students have one explicit place where they can swap in another function and
  rerun a limited part of the notebook.

It is intentionally secondary to the main teaching thread, which is still:

- how `R` changes the sample grid,
- how `maxbonddim` changes the approximation ceiling.

### 4. The `R`-sweep plot is not an error-vs-parameter plot

For Notebook 02, the most instructive `R`-sweep figure is:

- left panel: exact function plus QTT sample points for several values of `R`,
- right panel: bond-dimension profiles for those same values of `R`.

We explicitly do **not** force the `R` sweep into a left-panel error curve.

Reason:

- with the current measurement setup, the pointwise grid error stays tiny,
- that error plot did not explain the role of `R` well,
- the changing sample locations and bond-dimension profiles are the more
  informative teaching objects.

### 5. The `R` sweep uses `includeendpoint=false`

Notebook 02 now uses `includeendpoint=false` in the baseline and in the `R`
sweep.

Reason:

- this produces nested sample grids on `[0, 1)`,
- points from smaller `R` reappear at larger `R`,
- the overlay plot becomes much easier to interpret.

The notebook also contains a short explanation of the contrast with
`includeendpoint=true`:

- `includeendpoint=false` gives points at multiples of `1 / 2^R`,
- `includeendpoint=true` gives points at multiples of `1 / (2^R - 1)`,
- the second version is evenly spaced but no longer nested in the same way.

### 6. Avoid jargon like `dyadic` when a clearer phrase exists

Notebook 02 now prefers phrases such as:

- “built by repeated halving”
- “nested grid”
- “points at multiples of `1 / 2^R`”

This is the preferred learner-facing wording for future notebooks too.

## Plot Decisions Established By Notebook 02

### Baseline figure

Keep the baseline two-panel figure:

- left: exact function in black, QTT values in blue,
- right: observed bond dimensions in `:goldenrod2`, worst-case envelope in
  dashed gray,
- `yscale=log2` on the bond-dimension panel.

### `R`-sweep figure

Use:

- exact function as a black line,
- one scatter series per `R`,
- named Makie colors,
- different marker shapes,
- larger markers for smaller `R`,
- optional `xlims!` if zooming helps the nesting become visible,
- bond-dimension profiles on the right with the same colors as the left panel.

This figure should make the changing grid visible, not just the existence of
another parameter study.

### `maxbonddim`-sweep figure

Use:

- left panel: maximum absolute error with `yscale=log10`,
- right panel: maximum observed bond dimension with `yscale=log2`,
- dashed gray reference line for the requested cap where useful.

## Text And Explanation Decisions

Notebook 02 established a few explanation patterns worth keeping:

- if a new function appears, say why that function is being used,
- if a sweep is being run, say what is fixed and what is varied,
- if an empirical claim depends on a plot, show the plot first and then state
  the conclusion,
- if a grid choice affects what the reader sees, explain it directly rather
  than leaving it as a code comment,
- use a short explanatory section when a concept such as nested grids is easier
  to understand before the main figure.

## What To Reuse In Later Notebooks

Later notebooks should reuse Notebook 02 when they need:

- sweep design,
- side-by-side structural comparison,
- a small playground section,
- an explanation of why a plotting choice changed from the Notebook 01 pattern,
- a reminder that the most pedagogically useful plot is not always the most
  obvious quantitative summary.

## What Not To Reintroduce

Do not reintroduce the following into Notebook 02 or later notebooks without a
clear reason:

- a dedicated tolerance sweep just because the parameter exists,
- the earlier “error vs `R`” left-panel plot when the grid-geometry view is
  more informative,
- unexplained use of `includeendpoint=true` in the `R` sweep,
- jargon-heavy wording when a simpler phrase works,
- old partial Notebook 02 scaffolding that predates the current reviewed file.

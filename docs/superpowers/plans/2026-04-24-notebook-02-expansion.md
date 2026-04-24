# Notebook 02 Expansion Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn `02_accuracy_bonddims_and_sweeps.ipynb` into a genuinely independent tutorial notebook that teaches how QTT accuracy and internal complexity depend on `R`, `tolerance`, and `maxbonddim`.

**Architecture:** Keep the current notebook as the starting point, but expand it into a sequence of clearly separated study blocks: one baseline example, three parameter sweeps, one two-function comparison, then closing summary sections. Preserve the teaching style and visual grammar of Notebook 01.

**Tech Stack:** Julia, Tensor4all.jl, CairoMakie, Jupyter notebooks (`.ipynb`), Markdown prose.

---

## Scope

This plan covers only:

- `02_accuracy_bonddims_and_sweeps.ipynb`

Do not modify later notebooks while executing this plan.

Do not redesign the notebook style from scratch. The style source of truth is:

- `01_first_qtt_function_and_grid.ipynb`
- `docs/tutorial-learning-path.md`
- `docs/superpowers/plans/2026-04-23-tensor4all-jl-tutorial-notebooks.md`

If a required Tensor4all.jl capability is missing or unclear:

1. record it in `docs/library-gap-log.md`,
2. make the gap-log entry understandable without notebook context,
3. stop and report rather than inventing a notebook-local workaround.

---

## Notebook Outcome Requirements

When complete, Notebook 02 must contain all of the following:

1. a baseline example,
2. a real sweep over `R`,
3. a real sweep over `tolerance`,
4. a real sweep over `maxbonddim`,
5. a short comparison between two target functions,
6. `## What to notice`,
7. `## API recap`.

If one of these is missing, the notebook is not complete enough to stand apart
from Notebook 01.

---

## Style Requirements

Carry forward the established notebook style:

- prose in English,
- major headings in their own Markdown cells,
- calm learner-facing tone,
- visible code for all pedagogically important steps,
- short interpretation near each major result,
- CairoMakie plots,
- stable plot colors and figure sizing,
- compact `println(...)` output,
- no large raw arrays or raw tensor dumps.

Plot defaults to preserve unless there is a strong reason not to:

- `Figure(size=(1000, 380))` for standard two-panel figures,
- exact/reference curves: `:black`, `linewidth=2`,
- approximation or error curves: `:deepskyblue4`,
- structural curves: `:goldenrod2`,
- reference or ceiling lines: `:gray60`,
- bond-dimension plots with `yscale=log2`,
- positive error sweeps with `yscale=log10`,
- legends at `:lt` or `:rb` following the current notebook conventions.

---

## Content Design

### Baseline example

Start with one function and one fixed parameter set.

Baseline parameters should be visible in code:

- `R`
- `value_type`
- `tolerance`
- `maxbonddim`
- `maxiter`

The baseline must:

- build one QTT,
- compute the maximum absolute error on the notebook grid,
- inspect the bond-dimension profile,
- show one two-panel figure:
  - left: exact/reference function and QTT values,
  - right: bond-dimension profile with a worst-case envelope.

The chosen baseline function must be motivated in prose before or immediately
around the code. Do not introduce a new function without saying why it is being
used.

### Sweep over `R`

Add a section that varies only `R` while keeping:

- target function fixed,
- interval fixed,
- `tolerance` fixed,
- `maxbonddim` fixed,
- `maxiter` fixed.

This section should collect, for each `R`:

- `npoints = 2^R`,
- maximum absolute error,
- maximum observed bond dimension.

Recommended plot structure:

- left panel: `R` versus maximum absolute error,
- right panel: `R` versus maximum observed bond dimension.

Interpretation must explain:

- why `R` changes the grid resolution,
- why changing `R` does not automatically mean the QTT gets structurally more
  complex,
- when more grid resolution does or does not help.

### Sweep over `tolerance`

Add a section that varies only `tolerance` while keeping:

- target function fixed,
- interval fixed,
- `R` fixed,
- `maxbonddim` fixed,
- `maxiter` fixed.

This section should collect:

- maximum absolute error,
- maximum observed bond dimension.

Recommended plot structure:

- left panel: `tolerance` versus measured error,
- right panel: `tolerance` versus maximum observed bond dimension.

The sweep should show the relationship between requested interpolation accuracy
and the internal size of the approximation.

### Sweep over `maxbonddim`

Keep the current bond-cap sweep idea, but make it one part of a bigger notebook
rather than the whole notebook.

This section should vary only `maxbonddim` while keeping:

- target function fixed,
- interval fixed,
- `R` fixed,
- `tolerance` fixed,
- `maxiter` fixed.

Collect:

- maximum absolute error,
- maximum observed bond dimension.

Recommended plot structure:

- left panel: `maxbonddim` versus maximum absolute error,
- right panel: `maxbonddim` versus maximum observed bond dimension.

Use a dashed gray horizontal line for the requested tolerance in the error
panel if it helps readability.

Use a dashed gray comparison line for the requested cap in the structural
panel.

Important teaching rule: do not announce the exact outcome before showing the
sweep results. Ask the question first, then summarize the conclusion after the
plot or printed results.

### Two-function comparison

Add one section that compares two functions under the same parameter settings.

Purpose:

- show that parameter response depends not only on `R`, `tolerance`, and
  `maxbonddim`,
- but also on the structure of the function itself.

Possible pairing:

- a compact function such as `cosh(x)` or `x^2`,
- a more oscillatory function such as `sin(30x)`.

This section does not need to be as large as the three sweep sections, but it
must clearly show that different functions can exhibit different bond-dimension
profiles or different error behavior under the same settings.

---

## Required Section Order

Use this order unless there is a strong reason not to:

1. notebook title
2. learning goals
3. before-you-run section
4. baseline introduction
5. baseline code and baseline figure
6. sweep over `R`
7. sweep over `tolerance`
8. sweep over `maxbonddim`
9. two-function comparison
10. `## What to notice`
11. `## API recap`

---

## Teaching Constraints

The notebook must explicitly help students distinguish between:

- grid resolution effects from changing `R`,
- interpolation-quality effects from changing `tolerance`,
- artificial rank limitation from changing `maxbonddim`.

Make these differences visible both in the code and in the interpretation.

Do not let all three ideas blur into one generic “bigger parameter makes it
better” story.

Whenever possible, explain:

- what is being held fixed,
- what is being varied,
- what quantity is being measured.

This is especially important in sweep sections.

---

## Plot Requirements

### Baseline figure

Use a two-panel figure:

- left panel:
  - exact/reference function in black,
  - QTT values or samples in blue,
  - literal title,
  - labeled axes,
  - legend at `:lt`.
- right panel:
  - observed bond dimensions in golden/orange,
  - worst-case envelope in dashed gray,
  - `yscale=log2`,
  - labeled axes,
  - legend at `:rb`.

### Sweep figures

Use the Notebook 02 sweep pattern consistently:

- left panel for error quantity,
- right panel for structural quantity.

For positive error quantities:

- use `yscale=log10`,
- blue line plus blue scatter markers,
- gray dashed tolerance reference when relevant.

For structural quantities:

- use golden/orange line,
- gray dashed comparison line when relevant,
- `yscale=log2` when bond dimension is shown.

---

## Output Requirements

Printed output should remain compact and readable.

Good examples:

- “For R = 7, the maximum absolute error is ...”
- “For tolerance = 1e-8, the maximum bond dimension is ...”
- “For maxbonddim = 2, the observed maximum bond dimension is ...”

Do not print:

- full vectors of values,
- full TT core arrays,
- large object representations,
- internal structs unless they are immediately interpreted.

---

## Verification Requirements

Before considering the notebook complete, verify:

- it runs end to end,
- all section headings are in their own Markdown cells,
- all major figures have nearby interpretation,
- the notebook still matches the tone and visual style of Notebook 01,
- each of the three required sweeps is present,
- the two-function comparison is present,
- the closing sections are present.

---

## Suggested Review Questions

When reviewing the completed notebook, check:

1. Does Notebook 02 now clearly justify being separate from Notebook 01?
2. Can a student explain the different roles of `R`, `tolerance`, and
   `maxbonddim` after reading it?
3. Does the notebook make empirical claims only after showing the evidence?
4. Is each new target function motivated?
5. Do the plots follow the established visual grammar?
6. Is the notebook still readable on GitHub without being executed?


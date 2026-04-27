# Tensor4all.jl Tutorial Notebooks Implementation Plan

> **For agentic workers:** Work one notebook at a time. Treat the existing
> notebooks as source-of-truth examples. Do not regenerate earlier notebooks
> from stale planning text. If a local instruction here conflicts with the
> current notebook files, the notebook files win.

## Purpose

This repository contains a Jupyter-first tutorial series for learning QTTs with
`Tensor4all.jl`.

The main goal is pedagogical:

- teach Master students and early PhD students how to think about QTTs,
- make the `Tensor4all.jl` workflow visible and modifiable,
- give readers runnable notebooks that also work later as reference material.

The main content source remains `../rust-Tensor4all`, but the current notebook
files are now the primary style reference.

## Current Status

The current notebook set is:

```text
01_first_qtt_function_and_grid.ipynb
02_accuracy_bonddims_and_sweeps.ipynb
03_multivariate_qtts_and_layouts.ipynb
04_operations_on_qtts.ipynb
05_fourier_transforms.ipynb
06_affine_transformations.ipynb
```

Current implementation status:

- `01_first_qtt_function_and_grid.ipynb` exists and is the main reference for
  tone, workflow explanation, visible code, and overall layout.
- `02_accuracy_bonddims_and_sweeps.ipynb` exists and is the main reference for
  parameter sweeps, function-comparison playgrounds, and sweep-specific plot
  design.
- `03_multivariate_qtts_and_layouts.ipynb` exists and is the main reference
  for multivariate grids, layout comparison, and full-grid error heatmaps.
- later notebooks are still to be written.

## Repository Files

The current working set is:

- `README.md`
- `Project.toml`
- `docs/tutorial-learning-path.md`
- `docs/library-gap-log.md`
- `docs/superpowers/plans/2026-04-24-notebook-02-expansion.md`
- `01_first_qtt_function_and_grid.ipynb`
- `02_accuracy_bonddims_and_sweeps.ipynb`

Later notebooks should continue to live in the repository root.

## Non-Negotiable Global Rules

Use these rules for every notebook:

- write prose in English,
- use CairoMakie,
- keep pedagogically important code visible,
- do not hide main logic in helper files,
- keep outputs compact,
- do not print full tensors or large arrays,
- label plots clearly,
- do not mention missing library features inside learner-facing notebooks,
- do not mention the Rust tutorials, Rust source files, or Rust parity inside
  learner-facing notebooks,
- if a missing feature blocks work, record it in `docs/library-gap-log.md`,
- do not invent notebook-local implementations for missing functionality.

Rust material may be used while authoring the Julia notebooks, but only as an
internal content source. The learner-facing notebooks should read as
standalone Julia teaching material.

Gap-log entries must be understandable without the notebooks. A short note
about where an issue surfaced is useful, but the main description must stand on
its own as a package-level note.

## Style Source Of Truth

Use these in order:

1. the current notebook files,
2. `docs/tutorial-learning-path.md`,
3. any notebook-specific plan file still marked as active.

Do not revive older notebook scaffolding text once a notebook has been reviewed
and refined by hand.

## Notebook Style Summary

Every notebook should read like a guided worksheet, not like package
documentation and not like a test script.

Preferred sequence:

1. title
2. learning goals
3. setup reminder if needed
4. concept section
5. runnable example
6. immediate interpretation
7. deeper explanation after output is visible
8. experiment or controlled variation
9. `What to notice`
10. `API recap`

Additional rules:

- major headings go in their own Markdown cells,
- explanations should sit close to the code they explain,
- do not state empirical conclusions before showing the evidence,
- when a new target function appears, say why that function is being used,
- avoid unnecessary jargon,
- if a term like `dyadic` is not essential, prefer a clearer phrase such as
  “built by repeated halving”.

## Plotting Summary

### Common function plots

- exact/reference curve: `:black`, `linewidth=2`
- QTT samples: `:deepskyblue4` when there is only one sample series
- legends and axes must be explicit

### Bond-dimension plots

- observed bond dimensions: `:goldenrod2`, `linewidth=2`
- worst-case envelope or comparison ceiling: `:gray60`
- `linestyle=Linestyle([0, 10, 15])` for dashed reference curves
- `yscale=log2`
- labels:
  - `xlabel="bond link"`
  - `ylabel="bond dimension"`

### Sweep plots

Notebook 02 established two different sweep patterns:

1. **Error/structure sweep**
   - left panel: error quantity
   - right panel: structural quantity
   - positive error quantities use `yscale=log10`
   - structural bond-dimension quantities use `yscale=log2`

2. **Grid-resolution sweep**
   - left panel: exact function plus QTT sample points for several values of
     `R`
   - right panel: bond-dimension profiles for those same values of `R`

Use the pattern that actually teaches the intended point. Do not force every
sweep into the same plot template.

### Stable color semantics

Keep meanings stable where possible:

- black = exact or reference object
- blue = QTT approximation values
- golden/orange = observed structural quantity
- gray = bound, worst-case envelope, or comparison ceiling

When several `R` values or several functions appear in one plot, use named
Makie colors and readable marker changes rather than custom RGB definitions.

## Notebook 01 Reference

Notebook 01 established:

- how to introduce a first target function,
- how to explain `Float64` in `quanticscrossinterpolate`,
- how to explain representation conversions,
- how to compare one sample point and then the whole grid,
- how to keep code visible without drowning the reader,
- how to end with `What to notice` and `API recap`.

It is the main reference for:

- tone,
- pacing,
- visible parameter presentation,
- print-statement style,
- baseline function/bond-dimension plotting.

## Notebook 02 Reference

Notebook 02 established:

- how to build a notebook that is genuinely distinct from Notebook 01,
- how to compare the roles of `R` and `maxbonddim`,
- how to choose a sweep visualization that actually matches the teaching goal,
- how to explain the effect of `includeendpoint`.

Important decisions now fixed by Notebook 02:

- there is **no dedicated tolerance sweep** in Notebook 02,
- `tolerance` remains visible as a fixed parameter,
- the main sweeps are over `R` and `maxbonddim`,
- the notebook may end with a small **playground** section for trying another
  function under the same workflow, but this is secondary to the `R` and
  `maxbonddim` story,
- for the `R` sweep we currently use `includeendpoint=false` so the sample
  grids stay nested on `[0, 1)`,
- the notebook explicitly explains how the grid changes when
  `includeendpoint=true` versus `false`.

For the `R`-sweep overlay plot:

- use several named colors,
- vary markers as well as color,
- make smaller `R` markers larger so coarse grids remain visible,
- keep the exact function as a black line behind the samples.

## Notebook 03 Reference

Notebook 03 established:

- how to introduce a two-dimensional target function,
- how to explain interleaved versus grouped layouts,
- how to compare layouts while keeping the represented function fixed,
- how to use full-grid error heatmaps as a correctness check,
- how to keep the main emphasis on internal structure rather than on a second
  target-function experiment.

Important decisions now fixed by Notebook 03:

- the main comparison is between layouts of the same target function,
- layout comparison should focus on bond-dimension profiles and full-grid
  reconstruction quality,
- a second target-function playground is not required here and should not be
  treated as a defining feature of the notebook,
- multivariate notebooks may use heatmaps for exact values and error fields
  when those are more instructive than one-dimensional line plots.

## Learning Path

### 01_first_qtt_function_and_grid.ipynb

Purpose:

- first contact with QTTs,
- quantics grids,
- basic evaluation,
- first bond-dimension intuition.

### 02_accuracy_bonddims_and_sweeps.ipynb

Purpose:

- understand the different roles of grid resolution `R` and rank cap
  `maxbonddim`,
- inspect how bond-dimension profiles evolve,
- learn how grid construction changes when the endpoint is included or omitted.

Content focus:

- one baseline example,
- `R` sweep,
- `maxbonddim` sweep,
- optional small playground for trying another target function.

### 03_multivariate_qtts_and_layouts.ipynb

Purpose:

- extend the workflow to multivariate functions,
- show that index layout matters.

Content focus:

- one two-dimensional target function,
- interleaved versus grouped `DiscretizedGrid` layouts,
- full-grid reconstruction check,
- error heatmaps,
- bond-dimension comparison by layout.

### 04_operations_on_qtts.ipynb

Purpose:

- show that QTTs are computational objects, not only compressed
  representations.

### 05_fourier_transforms.ipynb

Purpose:

- keep Fourier-related material together in one place for both learning and
  lookup.

### 06_affine_transformations.ipynb

Purpose:

- collect more advanced transformation material after the core ideas are in
  place.

## Environment And Setup

The repository should keep a single Julia project environment for all
notebooks.

Learner setup should remain as small as possible:

```bash
git clone https://github.com/sdirnboeck/Tensor4all.jl-TUTORIALS.git
cd Tensor4all.jl-TUTORIALS
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.build("Tensor4all"); Pkg.precompile()'
```

Contributor override for a local `Tensor4all.jl` checkout remains allowed but
must stay out of notebook cells.

## Active Next Steps

The next implementation work should focus on:

1. `04_operations_on_qtts.ipynb`
2. `05_fourier_transforms.ipynb`
3. `06_affine_transformations.ipynb`

Work one notebook at a time.

Before starting a new notebook:

- review the current notebook files,
- review `docs/library-gap-log.md`,
- review `docs/tutorial-learning-path.md`,
- check whether a notebook-specific plan file exists and is still active.

If a notebook-specific plan has already been fully implemented, convert it into
a short reference note or archive it rather than letting it accumulate stale
instructions.

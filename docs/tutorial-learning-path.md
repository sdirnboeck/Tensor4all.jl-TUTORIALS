# Tensor4all Tutorial Learning Path

This document records the current Pluto-only tutorial structure.

## Format

The learner-facing artifacts are Pluto notebooks saved as `.jl` files. There are
no Jupyter notebooks and no repository-level Julia environment. Each notebook is
self-contained through Pluto's embedded package environment.

Learners need only Julia 1.12 and Pluto.jl. They open a notebook in Pluto and let
Pluto instantiate the embedded environment.

## Notebooks

1. `01_first_qtt_function_and_grid.jl`  
   First one-dimensional quantics grid, first QTT approximation, bond dimensions,
   `TN.evaluate`, and a small exercise.

2. `02_accuracy_bonddims_and_sweeps.jl`  
   Accuracy checks, grid-depth sweeps, and bond-dimension cap sweeps.

3. `03_multivariate_qtts_and_layouts.jl`  
   Two-dimensional QTTs and layout choices: interleaved, grouped, and fused.

4. `04_operations_on_qtts.jl`  
   Elementwise products, selected-variable products, fused-layout products, and
   integration.

5. `05_fourier_transforms.jl`  
   One-dimensional Fourier transforms and a two-dimensional partial transform.

6. `06_affine_transformations.jl`  
   Periodic and open-boundary affine pullback operators on fused grids.

7. `07_interpolative_qtts.jl`  
   Interpolative QTT construction with single-scale, adaptive, and sparse
   methods.

## Authoring principles

- Keep Tensor4all learner-facing code visible.
- Fold support code such as plotting helpers, styling, setup plumbing, and
  guard-message implementation.
- Prefer Pluto interactivity when it clarifies a concept, but avoid turning
  notebooks into dashboards.
- Use CairoMakie for polished static figures.
- Use Pluto's recommended LaTeX syntax: double backticks for inline math and
  fenced `math` code blocks for display equations.
- Do not maintain parallel Jupyter notebooks.

## Setup model

Each notebook contains:

- a visible import/setup cell for the Tensor4all APIs used in the lesson,
- a backend setup cell that builds the Tensor4all native backend if missing,
- embedded Pluto `Project.toml` and `Manifest.toml` contents at the bottom of
  the file.

The repository root intentionally does not contain `Project.toml` or
`Manifest.toml`; the notebooks are the source of truth for their environments.

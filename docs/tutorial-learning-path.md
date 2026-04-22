# Tensor4all.jl Tutorial Learning Path

This document records the current design for a Jupyter-first tutorial set for
learning QTTs with `Tensor4all.jl`.

The main goal is pedagogical: the tutorials should help Master students and
early PhD students build intuition for quantics tensor trains and learn how to
use `Tensor4all.jl` in practice. The notebooks should be useful both as a
guided learning path and as later reference material for specific topics.

## Format Decision

The tutorial material will be notebook-first:

- The primary artifacts are Jupyter notebooks.
- Pluto is out of scope for this tutorial set.
- Plain Julia source files are not the main teaching format.
- Website documentation is secondary and should be handled after the notebooks
  are usable.
- Notebook prose should be in English.

This prioritizes interactive learning. Students should be able to open a
notebook, run the cells, modify parameters, regenerate plots, and observe how
QTT behavior changes.

## Repository Layout

The notebooks should live in the repository root so they are immediately
visible and easy to open from GitHub, Jupyter, VS Code, or another IDE:

```text
01_first_qtt_function.ipynb
02_grids_intervals_and_indices.ipynb
03_accuracy_bonddims_and_sweeps.ipynb
04_multivariate_qtts_and_layouts.ipynb
05_operations_on_qtts.ipynb
06_fourier_transforms.ipynb
07_affine_transformations.ipynb
```

Supporting material should live in dedicated folders:

```text
docs/      design notes and planning documents
plots/     optional exported figures
data/      optional small input or reference data
```

The initial notebooks should not depend on pre-generated CSV files or plot
files. They should generate their examples when run. The `plots/` folder is
only for figures we deliberately export for reuse in README files, slides, or
later website documentation.

## Website Role

The website should not duplicate the full notebook content. A useful website
layer would contain:

- setup instructions,
- the recommended learning order,
- short conceptual orientation,
- links to the notebooks,
- possibly selected polished excerpts later.

The notebooks remain the main course material.

We should first finish the notebook set in this repository. Once at least the
prototype notebook and the overall style are stable, a later pull request to
`tensor4all/Tensor4all.jl` can add a small learning or tutorial landing page to
the official documentation. That page should point to this tutorial material
and explain the recommended order.

## Handling Missing Features

Missing `Tensor4all.jl` functionality should not be discussed inside the
teaching notebooks. The notebooks should feel coherent and learner-facing, not
like a development backlog.

If a tutorial topic requires functionality that is missing in `Tensor4all.jl`,
we should record it separately, for example in a gap log or in GitHub issues.
We should not create ad hoc implementations inside the notebooks just to force
a topic to work.

## Notebook Structure

Each notebook should follow a consistent teaching structure:

1. Learning goals
2. Concept
3. Tensor4all.jl workflow
4. Runnable example
5. Experiment section
6. What to notice
7. API recap

The notebooks should use short explanations, visible executable code, and
well-labeled plots. They should encourage parameter changes, for example
changing the bit depth, target function, tolerance, or maximum bond dimension.

## Notebook Conventions

The notebooks should be written as teaching material, not as API test files.
They should stay readable when viewed on GitHub and useful when run
interactively.

Conventions:

- Use English prose throughout.
- Use one main idea per notebook.
- Keep the pedagogically important code visible in the notebook. Parameters,
  target functions, construction steps, evaluation steps, and plotting calls
  should be readable directly in the notebook.
- Keep code cells short enough that students can modify them locally without
  first understanding a large helper framework.
- Prefer named parameters near the top of a section, for example `R`,
  `tolerance`, `maxbonddim`, interval bounds, and the target function.
- Use CairoMakie consistently for plotting.
- Plot inline in the notebook.
- Label plots carefully: axes, legends, titles where useful, and units or
  coordinate meaning where relevant.
- Save plots only when the figure is intentionally reused outside the notebook.
- Avoid hidden setup cells with important logic.
- Avoid moving teaching logic into helper files. Small helpers are acceptable
  only when they remove distracting boilerplate, for example repeated plot
  styling or simple error metrics.
- Avoid ad hoc implementations of missing `Tensor4all.jl` functionality.
- End each notebook with a short API recap.
- Keep the tone learner-facing: explain what to notice, not just what the code
  does.

Notebook outputs means the saved results inside `.ipynb` files: rendered plots,
small tables, printed scalar values, and short textual output. These can remain
in the notebooks while the tutorials are being developed because rendered
outputs make review and GitHub browsing easier.

The notebooks should avoid printing full tensors, large arrays, or long raw
objects. They should print compact summaries instead, for example dimensions,
bond dimensions, errors, and a few representative values.

## Environment and Setup Decision

The repository should provide one Julia project environment for all notebooks.
This is the recommended setup; there is no separate decision for each notebook.

The repository should contain a root-level `Project.toml` and eventually a
`Manifest.toml` with:

- `Tensor4all.jl`,
- `IJulia`,
- `CairoMakie`,
- any lightweight helper packages needed by the notebooks, if they become
  necessary.

`IJulia` is the Julia package that lets Jupyter run Julia notebooks. It
provides the Julia kernel that appears inside Jupyter or notebook-capable IDEs.

The downloaded repository should work without relying on the author's local
directory layout. Therefore the committed environment should point to a normal
source for `Tensor4all.jl`, such as the registered package once available or
the GitHub repository.

During local development, contributors can override that dependency and use a
nearby checkout instead:

```text
../../code/Tensor4all/Tensor4all.jl
```

A typical local development setup command would be:

```julia
using Pkg
Pkg.activate(".")
Pkg.develop(path="../../code/Tensor4all/Tensor4all.jl")
Pkg.instantiate()
```

After that, students can open the notebooks with Jupyter, VS Code, or another
IDE that supports Julia notebooks.

The notebooks should avoid relying on local machine-specific paths inside code
cells. The local Tensor4all.jl path belongs in setup instructions for
contributors, not in every notebook and not as the only setup path.

## Proposed Learning Path

### 01_first_qtt_function.ipynb

First contact with QTTs.

Content:

- build a QTT approximation of a scalar function,
- start with `cosh(x)`, because its QTT bond dimension can be explained by a
  simple hand calculation,
- evaluate the QTT on grid points,
- compare against the analytic function,
- plot the function and QTT samples,
- inspect bond dimensions once,
- include a second, more complex function as an experiment after the main
  `cosh(x)` example.

Purpose:

Give students a quick success experience and establish the basic workflow:
function to QTT to values to plot.

### 02_grids_intervals_and_indices.ipynb

Quantics grids and physical coordinates.

Content:

- bit depth `R` and grid size `2^R`,
- discrete indices versus physical coordinates,
- intervals such as `[0, 1]` and `[-1, 2]`,
- how sampled functions become quantics objects,
- indexing conventions and common pitfalls.

Purpose:

Build the mental model for what the QTT represents before discussing accuracy
or operations.

### 03_accuracy_bonddims_and_sweeps.ipynb

Approximation quality, bond dimensions, and parameter sweeps.

Content:

- approximation error,
- tolerance and maximum bond dimension,
- rank or bond-dimension profiles,
- sweeps over `R`,
- sweeps over tolerance,
- comparison of different target functions,
- runtime and accuracy observations when useful.

Purpose:

Teach students how to experiment responsibly with QTT approximations and how to
interpret compression behavior.

### 04_multivariate_qtts_and_layouts.ipynb

QTTs for multivariate functions.

Content:

- two-dimensional target functions,
- coordinate grids in more than one variable,
- layout choices such as interleaved, grouped, or fused representations where
  supported,
- comparison of bond dimensions for different layouts,
- visual comparison of reference values and QTT values.

Purpose:

Show that multivariate QTTs are not just a trivial extension of the 1D case:
index layout matters.

### 05_operations_on_qtts.ipynb

First computations with QTTs.

Content:

- elementwise product of two QTT-represented functions,
- validation against the analytic product,
- rank growth under multiplication,
- optional compression or truncation after the product if supported by the
  public API,
- integration of a QTT-represented function on an interval,
- comparison of the integral against an analytic or high-resolution numerical
  reference.

Purpose:

Show that QTTs are not only compressed storage formats. They are objects we can
compute with. The notebook should remain univariate and focused.

### 06_fourier_transforms.ipynb

Fourier transformations in QTT format.

Content:

- one-dimensional Fourier transform,
- comparison against a dense or analytic reference,
- bond dimensions before and after the transform,
- two-dimensional partial Fourier transform,
- explanation of transforming one coordinate while leaving another coordinate
  untouched.

Purpose:

Keep Fourier-related material together so the notebook also works as a
reference for users who specifically want to know how Fourier transforms work
in `Tensor4all.jl`.

### 07_affine_transformations.ipynb

Affine transformations as an advanced operator topic.

Content:

- affine pullbacks or transformations,
- periodic versus open boundary behavior if supported,
- comparison against reference values,
- bond dimensions of operators and transformed states.

Purpose:

Present affine transformations after students already understand QTTs,
operations, and Fourier transforms.

## Mapping From Existing Rust Tutorials

The existing `../rust-tensor4all` tutorials can be used as source material, but
the Julia notebook order should follow the pedagogical learning path rather
than a strict one-to-one migration order.

Approximate mapping:

| Rust tutorial | Julia notebook |
|---|---|
| `qtt_function` | `01_first_qtt_function.ipynb` |
| `qtt_interval` | `02_grids_intervals_and_indices.ipynb` |
| `qtt_r_sweep` | `03_accuracy_bonddims_and_sweeps.ipynb` |
| `qtt_multivariate` | `04_multivariate_qtts_and_layouts.ipynb` |
| `qtt_elementwise_product` | `05_operations_on_qtts.ipynb` |
| `qtt_integral` | `05_operations_on_qtts.ipynb` |
| `qtt_fourier` | `06_fourier_transforms.ipynb` |
| `qtt_partial_fourier2d` | `06_fourier_transforms.ipynb` |
| `qtt_affine` | `07_affine_transformations.ipynb` |

## Open Design Questions

Questions to decide before implementing the notebooks:

- Should notebook outputs stay committed long-term, or should we clear outputs
  once the notebooks are stable?
- Should the first prototype include a small reusable "try your own function"
  cell after the main `cosh(x)` walkthrough?

## API Level Decision

The notebooks should use the highest sensible `Tensor4all.jl` API available.
They should teach how users are meant to work with the Julia package, not expose
lower-level implementation details unless those details are necessary for
understanding the concept.

If a high-level API is missing for a planned notebook, we should record that in
the gap log and avoid inventing notebook-local replacements.

## Gap Tracking Decision

Missing `Tensor4all.jl` functionality should first be tracked in this tutorial
repository, for example in:

```text
docs/library-gap-log.md
```

GitHub issues can be created later after review. Issues should not be pushed
automatically without a separate human review step.

## Prototype Plan

The first implementation target should be:

```text
01_first_qtt_function.ipynb
```

This prototype should establish the style for:

- prose length and tone,
- CairoMakie plotting style,
- Tensor4all.jl API level,
- parameter naming,
- output policy,
- setup instructions.

After the prototype is reviewed, the same style can be used for the remaining
notebooks.

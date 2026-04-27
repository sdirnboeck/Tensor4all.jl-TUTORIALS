# Tensor4all.jl Tutorial Learning Path

This document records the current design for a Jupyter-first tutorial set for
learning QTTs with `Tensor4all.jl`.

The main goal is pedagogical: the tutorials should help Master students and
early PhD students build intuition for quantics tensor trains and learn how to
use `Tensor4all.jl` in practice. The notebooks should be useful both as a
guided learning path and as later reference material for specific topics.

## Current Status

Two notebooks now exist:

- `01_first_qtt_function_and_grid.ipynb`
- `02_accuracy_bonddims_and_sweeps.ipynb`

Notebook 01 is the main reference for:

- overall teaching tone,
- code exposure,
- representation explanations,
- baseline function and bond-dimension plots,
- print style,
- section layout.

Notebook 02 is the main reference for:

- parameter sweeps,
- playground-style comparison sections,
- sweep-specific plot choices,
- explanations of how the grid changes with `R`,
- the learner-facing explanation of `includeendpoint=false` versus
  `includeendpoint=true`.

The Rust tutorials in `../rust-Tensor4all` remain the main content source, but
the current notebook files are now the primary style reference.

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
01_first_qtt_function_and_grid.ipynb
02_accuracy_bonddims_and_sweeps.ipynb
03_multivariate_qtts_and_layouts.ipynb
04_operations_on_qtts.ipynb
05_fourier_transforms.ipynb
06_affine_transformations.ipynb
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

## Detailed Notebook Style Specification

This section records the notebook style in much more detail so the remaining
notebooks can be written consistently.

### Overall layout

Each notebook should read like a guided worksheet:

1. title
2. learning goals
3. setup reminder if needed
4. concept section
5. runnable code
6. immediate interpretation
7. deeper explanation after the student has seen the relevant output
8. experiment or variation section
9. what to notice
10. API recap

The notebook should feel like teaching material, not package documentation and
not an internal engineering note.

### Collapsible headings

Large headings must be separated from their explanatory text.

That means:

- a `#` notebook title should live in its own Markdown cell,
- every `##` section heading should live in its own Markdown cell,
- any `####` or similar subsection heading that should be collapsible should
  also live in its own Markdown cell.

The explanatory text belongs in the following Markdown cell.

This is important because students should be able to collapse a section without
still seeing the explanatory text below the folded heading.

### Tone

The tone should be calm, clear, and learner-facing.

The notebooks should:

- explain what is happening and why it matters,
- avoid sounding like tests or debug notes,
- avoid sounding like a paper draft,
- avoid hype,
- avoid unexplained jargon when a simpler phrase works,
- avoid phrases like "obviously" or "clearly".

Good sentence patterns are:

- "Here we use ..."
- "This lets us ..."
- "Before looking at one specific grid point, ..."
- "We reuse the same interpolation settings here, so ..."

The notebook should explain without patronizing the reader.

### Explanation rhythm

Each section should follow the same teaching rhythm:

1. introduce the next idea briefly,
2. run the code,
3. inspect output or plot,
4. explain why the result makes sense,
5. invite a small variation.

Do not front-load too much theory before the first result is visible.

If a concept becomes clearer only after a plot or printed output, delay the
deeper explanation until after that result.

Do not state empirical conclusions before the notebook has shown the evidence.
For example, in a sweep section it is better to say that we will check whether
one cap is sufficient than to announce the exact outcome before the sweep has
been run.

Notebook 01 already sets the preferred pattern:

- `cosh(x)` is introduced early,
- the full explanation of why it stays compact appears only after the
  bond-dimension plot.

This is the standard to keep.

### Redundancy control

Repetition is useful only when the second occurrence adds a new role.

A concept may be previewed briefly, but it should only be explained in detail
once at full length.

When reviewing future notebooks, watch specifically for:

- duplicated motivation paragraphs,
- repeated API explanations,
- repeated plot interpretation.

This also applies to empirical observations: a notebook should not first state
the exact sweep result and then repeat the same point after the figure.

### Code visibility

Pedagogically important code must remain visible in notebook cells.

Visible code includes:

- target functions,
- key parameters,
- grid construction,
- interval definitions,
- `quanticscrossinterpolate` calls,
- tensor-train conversions,
- evaluation calls,
- error calculations,
- plot code.

When a notebook introduces a new target function that is not already familiar
from an earlier notebook, add a short sentence explaining why that function is
being used in that section.

Do not hide any of those in helper files.

Small helper functions are acceptable only if they remove repetitive
boilerplate without hiding the core mathematical or API logic. Notebook 01's
`worst_case_bond_dims(...)` is the current model for an acceptable helper:
small, local, and visually supportive.

### Parameter presentation

Important parameters should be explicit, named, and placed close to the code
that uses them.

Examples:

- `R`
- `value_type`
- `tolerance`
- `maxbonddim`
- `maxiter`
- interval bounds
- sample point indices

If a visible parameter is not yet conceptually active in the example, explain
that clearly. Notebook 01 already does this for `maxbonddim = 32`: it is shown
because students should see it, but the notebook explains that it is only a
generous ceiling in that example.

### API explanation rules

If an API call contains something that looks strange to a first-time reader,
explain it immediately.

Notebook 01 establishes this rule with the explicit `Float64` argument to
`quanticscrossinterpolate`.

Future notebooks should do the same whenever they introduce:

- an explicit type argument,
- a wrapper type,
- a conversion step,
- or an indexing convention that would otherwise feel magical.

### Representation conversions

When converting between representations, always explain:

- what the current object stores,
- why the next representation is introduced,
- what concrete operation becomes possible after the conversion.

The explanation should name the concrete operations, not speak in vague terms.

For example, Notebook 01 explains that:

- the interpolation object stores the quantics grid, cached function values,
  and TCI data,
- `SimpleTT.TensorTrain(qtt.tci)` extracts the TT cores,
- `TensorNetworks.TensorTrain(simple_tt, sites)` is the representation used for
  indexed evaluation and bond-dimension inspection.

### Variable naming

Variable names should be chosen so they teach.

Preferred style:

- `target_function`
- `value_type`
- `bond_dims`
- `sample_coordinate`
- `sample_exact_value`
- `experiment_max_abs_error`

Short names are acceptable only when they are standard and already introduced,
for example `R` or `xvals`.

When comparing multiple values, use names that make the comparison explicit.
Notebook 01 already models this well with:

- `sample_qtt_value`
- `sample_indexed_tt_value`
- `sample_exact_value`

### Printed output

Printed output should be compact, informative, and sentence-like.

Use `println(...)` with explanatory text in the main teaching flow instead of
`@show`.

Good print targets are:

- parameter values,
- grid extent,
- bond dimensions,
- maximum absolute errors,
- one representative sample point.

Avoid printing:

- full tensors,
- large arrays,
- long raw object dumps,
- unreadable nested structs,
- debug-heavy output.

### Plotting standard

All plots should use `CairoMakie`.

Notebook 01 establishes the current visual grammar. Future notebooks should
reuse it unless a topic genuinely requires a different plot type.

#### Standard two-panel figure

For the common "example plus structure" layout, use:

```julia
Figure(size=(1000, 380))
```

Preferred structure:

- left panel: object in physical coordinates,
- right panel: structural information such as bond dimensions.

#### Function-value plots

For one-dimensional function comparison plots, use:

- exact/reference curve:
  - color `:black`
  - `linewidth=2`
- QTT samples:
  - color `:deepskyblue4`
  - `markersize=5` for dense sampling
  - `markersize=6` if slightly larger markers improve readability

Preferred labels:

- `xlabel="x"`
- `ylabel="value"`

Preferred legend position:

- `position=:lt`

Titles should be short and literal, for example:

- `"cosh(x) on a quantics grid"`
- `"Second experiment on [-1, 2]"`

If a smooth reference curve is helpful, it is fine to evaluate the exact
function on a denser plotting grid and overlay the QTT values on the notebook's
actual sample grid. Notebook 02 provides the main current reference for this,
especially in the `R`-sweep section.

#### Bond-dimension plots

Bond-dimension plots should follow Notebook 01 closely:

- observed bond dimensions:
  - color `:goldenrod2`
  - `linewidth=2`
- worst-case envelope:
  - color `:gray60`
  - `linewidth=2`
  - `linestyle=Linestyle([0, 10, 15])`

Preferred labels:

- `xlabel="bond link"`
- `ylabel="bond dimension"`

Preferred scaling:

- `yscale=log2`

Preferred legend position:

- `position=:rb`

This log base 2 scaling is part of the teaching design because it aligns with
the powers-of-two structure of quantics representations and makes growth easier
to read.

#### Sweep and error plots

When a notebook contains a parameter sweep over a positive error quantity, the
default error-plot style should be:

- left panel in a standard two-panel figure,
- `ylabel="max abs error"` unless another error quantity is more appropriate,
- `yscale=log10`,
- main error curve in `:deepskyblue4` with `linewidth=2`,
- matching blue scatter markers,
- optional dashed gray horizontal reference line for the requested tolerance.

When the right panel shows how a structural quantity changes across the same
sweep, the current default is:

- observed structural quantity in `:goldenrod2`,
- dashed gray comparison line for the requested cap, ceiling, or reference
  limit,
- `yscale=log2` if the structural quantity is a bond dimension.

Notebook 02 is the current reference pattern for sweep-plot layout. It also
establishes that not every sweep needs the same left-panel quantity: for an
`R` sweep it can be more instructive to show how the sample grid itself changes
than to force an error-versus-parameter curve.

#### Color semantics

Keep color meanings stable across notebooks where possible:

- black = exact or reference object,
- blue = QTT values or approximation samples,
- golden/orange = observed structural quantity,
- gray = worst-case envelope, bound, or comparison ceiling.

Students should not have to relearn the palette in each notebook.

#### Plot labeling rules

Every plot should have:

- an x-label,
- a y-label,
- a title if it helps orientation,
- a legend when more than one visual element appears.

Labels should be literal and readable, not decorative.

### Section rhythm within a notebook

Inside each conceptual block, the standard sequence is:

1. heading
2. short explanation
3. code
4. compact output or plot
5. interpretation

Avoid:

- long Markdown walls before any code,
- long runs of code without explanation,
- several figures in a row without telling the reader what changed.

Every major result block should have a nearby interpretation. In practice this
means that after a main figure or sweep figure there should usually be a short
Markdown explanation or summary, not only code and then an immediate jump to
the next section.

### Experiment sections

Each notebook should include at least one small experiment or controlled
variation.

That section should:

- reuse the main workflow,
- change one main ingredient,
- state explicitly what is held fixed,
- state explicitly what is varied,
- explicitly tell the student what they are invited to modify.

Notebook 01 provides the basic pattern:

- same interpolation workflow,
- shifted interval,
- simple second function,
- direct prompt to change `experiment_function`, interval bounds, or `R`.

For sweep sections specifically:

- name the control parameter being swept,
- state which parameters are held fixed,
- avoid claiming the exact outcome before the sweep output is shown,
- summarize the conclusion after the sweep has been run.

### Closing sections

Every notebook should end with:

- `## What to notice`
- `## API recap`

`What to notice` should summarize conceptual takeaways.

`API recap` should summarize the concrete package entry points that the student
used.

These sections should be short, scannable, and consistent across the notebook
series.

### Things to avoid

Future notebooks should avoid:

- mixing major headings and long explanatory text in the same Markdown cell,
- unexplained jargon such as "indexed chain" when a clearer phrase exists,
- hidden helper code for core logic,
- ad hoc workarounds for missing library features,
- plot styling that changes arbitrarily from notebook to notebook,
- raw large-object printing,
- feature-gap commentary inside learner-facing notebooks.

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

The first notebooks should be written in a modular way so the learning path can
be reorganized later. In practice this means:

- use clear section headings,
- avoid cross-notebook hidden dependencies,
- keep each conceptual block runnable after the setup cells,
- make repeated setup explicit enough that sections can be moved,
- do not rely on a large shared helper layer.

This keeps it easy to split `01_first_qtt_function_and_grid.ipynb` into two
notebooks later, or to merge the first two notebooks into a longer introductory
notebook if that turns out to be pedagogically better.

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

The downloaded tutorial repository should work without relying on the author's
local directory layout. Learners should not need to clone `Tensor4all.jl`
manually. The committed environment should point to a normal source for
`Tensor4all.jl`, such as the registered package once available or the GitHub
repository while the package is still unregistered.

The learner setup should be extremely small:

```bash
git clone https://github.com/sdirnboeck/Tensor4all.jl-TUTORIALS.git
cd Tensor4all.jl-TUTORIALS
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.build("Tensor4all"); Pkg.precompile()'
```

Then open the notebooks with Jupyter, VS Code, or another IDE that supports
Julia notebooks. If `Tensor4all.jl` is not registered yet, the committed
`Manifest.toml` should record the GitHub source so `Pkg.instantiate()` can fetch
it automatically.

`Tensor4all.jl` may need its Rust backend build step. The setup command should
include `Pkg.build("Tensor4all")` so users do not have to know about the backend
details. The package build script can fetch or build the required backend
according to `Tensor4all.jl`'s own installation rules.

The setup command should also run `Pkg.precompile()` before users open the
notebooks. This avoids triggering package precompilation from inside a VS Code
notebook kernel, which can fail in some VS Code / Julia extension combinations.

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
Pkg.build("Tensor4all")
Pkg.precompile()
```

The notebooks should avoid relying on local machine-specific paths inside code
cells. The local Tensor4all.jl path belongs in setup instructions for
contributors, not in every notebook and not as the only setup path.

## Proposed Learning Path

### 01_first_qtt_function_and_grid.ipynb

First contact with QTTs and quantics grids.

Content:

- build a QTT approximation of a scalar function,
- start with `cosh(x)`, because its QTT bond dimension can be explained by a
  simple hand calculation,
- introduce bit depth `R` and grid size `2^R`,
- show the connection between discrete indices and physical coordinates,
- introduce intervals such as `[0, 1]` and `[-1, 2]` at a basic level,
- evaluate the QTT on grid points,
- compare against the analytic function,
- plot the function and QTT samples,
- inspect bond dimensions once,
- include a second, more complex function as an experiment after the main
  `cosh(x)` example.

Purpose:

Give students a quick success experience and establish the basic workflow:
function to grid to QTT to values to plot.

### 02_accuracy_bonddims_and_sweeps.ipynb

Approximation quality, bond dimensions, and the practical roles of `R` and
`maxbonddim`.

Content:

- one baseline example,
- bond-dimension profile and worst-case envelope,
- sweep over `R`,
- explanation of how the sample grid changes with `R`,
- explanation of `includeendpoint=false` versus `includeendpoint=true`,
- sweep over `maxbonddim`,
- playground section for comparing target functions under fixed settings.

Purpose:

Teach students how to experiment responsibly with QTT approximations and how to
distinguish:

- grid-resolution effects from changing `R`,
- artificial rank limitation from changing `maxbonddim`,
- function-dependent complexity from changing the target function.

### 03_multivariate_qtts_and_layouts.ipynb

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

### 04_operations_on_qtts.ipynb

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

### 05_fourier_transforms.ipynb

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

### 06_affine_transformations.ipynb

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

The existing `../rust-Tensor4all` tutorials can be used as source material, but
the Julia notebook order should follow the pedagogical learning path rather
than a strict one-to-one migration order.

The Rust repo now includes an optional prelude:

```text
tt_basics
```

We are explicitly not porting that as a standalone Julia tutorial. The Julia
learning path should start directly with QTTs.

Approximate mapping:

| Rust tutorial | Julia notebook |
|---|---|
| `tt_basics` | not ported as a Julia tutorial |
| `qtt_function` | `01_first_qtt_function_and_grid.ipynb` |
| `qtt_interval` | `01_first_qtt_function_and_grid.ipynb` |
| `qtt_r_sweep` | `02_accuracy_bonddims_and_sweeps.ipynb` |
| `qtt_multivariate` | `03_multivariate_qtts_and_layouts.ipynb` |
| `qtt_elementwise_product` | `04_operations_on_qtts.ipynb` |
| `qtt_integral` | `04_operations_on_qtts.ipynb` |
| `qtt_fourier` | `05_fourier_transforms.ipynb` |
| `qtt_partial_fourier2d` | `05_fourier_transforms.ipynb` |
| `qtt_affine` | `06_affine_transformations.ipynb` |

The Rust reading order is still useful as source material, but we are not
copying it literally. In particular:

- the optional `tt_basics` prelude is excluded,
- `qtt_integral` appears earlier in Rust than in the Julia learning path,
- the Julia notebooks remain grouped by teaching topic rather than by one-file
  Rust parity.

## Deferred Decisions

No blocking format decisions remain before the implementation pause. These
decisions should be made later, after either the Rust cleanup or the first
prototype notebook:

- Notebook output policy: keep outputs committed if notebook sizes stay
  reasonable; clear large outputs if they make the repository unpleasant to
  review or clone.
- First-notebook shape: after reviewing
  `01_first_qtt_function_and_grid.ipynb`, decide whether to keep it combined,
  split it into separate function/grid notebooks, or merge it later with the
  accuracy-and-sweeps notebook.

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

Entries in that log should be written so they make sense even to someone who
has not read the notebooks. A short reminder of where the issue appeared during
tutorial writing is useful, but the main description should be package-level
and standalone.

GitHub issues can be created later after review. Issues should not be pushed
automatically without a separate human review step.

## Prototype Plan

The first implementation target should be:

```text
01_first_qtt_function_and_grid.ipynb
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

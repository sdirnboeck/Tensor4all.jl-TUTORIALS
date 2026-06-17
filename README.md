# Tensor4all.jl Tutorials

Jupyter notebooks for learning Quantics Tensor Trains (QTTs) with
`Tensor4all.jl`.

The tutorials are written for Master students and early PhD students who are
learning QTTs for the first time. The focus is interactive learning: open a
notebook, run the cells, change parameters, and inspect the plots.

## Prerequisites

You need Julia and a way to run Jupyter notebooks. If you already have both,
skip ahead to [Setup](#setup).

### 1. Install Julia (version 1.12)

The recommended way is via `juliaup`, which manages multiple Julia versions in
parallel.

- macOS / Linux:

  ```bash
  curl -fsSL https://install.julialang.org | sh
  ```

- Windows (PowerShell):

  ```powershell
  winget install julia -s msstore
  ```

After installation, restart your terminal and pin Julia 1.12 for this project:

```bash
juliaup add 1.12
juliaup default 1.12
julia --version    # should print julia version 1.12.x
```

The `Manifest.toml` in this repository was resolved with Julia 1.12.6. A
Julia 1.11 kernel can fail during package loading, so make sure you are on
1.12 before continuing.

### 2. Pick a notebook frontend

Choose one of:

- **VS Code** with the Julia and Jupyter extensions. Recommended for first-time
  users; no extra setup beyond the `Setup` step below.
- **Classic Jupyter / JupyterLab.** Then you also need the `IJulia` kernel,
  which is installed in the [Setup](#setup) step.

## Setup

Clone this repository and instantiate the Julia environment:

```bash
git clone https://github.com/sdirnboeck/Tensor4all.jl-TUTORIALS.git
cd Tensor4all.jl-TUTORIALS
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.resolve(); Pkg.build("Tensor4all"); Pkg.precompile()'
```

What the single Julia command does:

- `--project=.` tells Julia to use the `Project.toml` and `Manifest.toml` in
  the current directory, so packages are isolated to this repository.
- `Pkg.instantiate()` downloads every package listed in `Manifest.toml` at
  the exact version pinned there, including `Tensor4all.jl` (see below).
- `Pkg.resolve()` refreshes the manifest for the Julia version you are using.
- `Pkg.build("Tensor4all")` runs the build step for `Tensor4all.jl`. On the
  first run this also downloads a Rust toolchain into Julia's depot, because
  one of the internal dependencies (`RustToolChain`) compiles a small native
  component. This needs an internet connection and can take a few minutes.
- `Pkg.precompile()` precompiles all packages in advance, which avoids
  triggering precompilation later from inside the notebook kernel.

The first run can take several minutes. Subsequent runs are fast.

### About Tensor4all.jl

`Tensor4all.jl` is the package the notebooks build on. You do not need to
install it manually: it is already pinned in `Manifest.toml` and is fetched
automatically by the setup command above.

A few details that may help if something looks unfamiliar:

- `Tensor4all.jl` is **not** in the Julia General registry. It lives at
  <https://github.com/tensor4all/Tensor4all.jl> and the manifest pins a
  specific commit on its `main` branch. That is why `Pkg.add("Tensor4all")`
  by itself would not work; `Pkg.instantiate()` is the right entry point
  because it follows the `Manifest.toml`.
- The notebooks use submodules of this package, for example via
  `import Tensor4all.QuanticsGrids as QG` and
  `import Tensor4all.QuanticsTCI as QTCI`. These come with `Tensor4all.jl`
  automatically; nothing extra needs to be installed.
- To verify the install, run a quick smoke test from the repository root:

  ```bash
  julia --project=. -e 'using Tensor4all; println("Tensor4all loaded: ", pkgversion(Tensor4all))'
  ```

  Expected output: `Tensor4all loaded: 0.1.0` (or a later version) without
  any error or stack trace.

To update to a newer commit on `main` later, run:

```bash
julia --project=. -e 'using Pkg; Pkg.update("Tensor4all"); Pkg.build("Tensor4all"); Pkg.precompile()'
```

### Optional: register the IJulia kernel for classic Jupyter

If you want to open the notebooks in classic Jupyter or JupyterLab (rather
than VS Code), install the IJulia kernel once:

```bash
julia -e 'using Pkg; Pkg.add("IJulia")'
```

Then start `jupyter notebook` or `jupyter lab` from this directory and pick the
`Julia 1.12` kernel.

## Opening The Notebooks

You can open the notebooks in Jupyter, VS Code, or another IDE that supports
Julia notebooks.

Start with:

```text
01_first_qtt_function_and_grid.ipynb
```

If your editor asks you to choose a Julia kernel, pick the Julia 1.12 kernel
that matches the version you used for the setup command above.

## Troubleshooting In VS Code

If the first notebook cell fails immediately with an error that contains
`pipe_writer(::VSCodeServer.IJuliaCore.IJuliaStdio...)`, the problem is usually
not the notebook code itself. It happens when VS Code tries to trigger Julia
package precompilation from inside the notebook kernel.

Use this recovery sequence:

```bash
cd Tensor4all.jl-TUTORIALS
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.resolve(); Pkg.build("Tensor4all"); Pkg.precompile()'
```

Then in VS Code:

1. close the notebook tab,
2. run `Developer: Reload Window`,
3. reopen the notebook,
4. select the Julia kernel that matches the Julia version you used for setup,
5. run the first cell again.

If it still fails, check that the Julia version shown by the notebook kernel is
the same one used by the setup command.

## Learning Path

Read the notebooks in numerical order:

1. `01_first_qtt_function_and_grid.ipynb` introduces a one-dimensional quantics grid, builds a first QTT approximation, and shows how to read bond dimensions.
2. `02_accuracy_bonddims_and_sweeps.ipynb` explores how accuracy and bond dimensions change when `R` and `maxbonddim` are varied.
3. `03_multivariate_qtts_and_layouts.ipynb` introduces two-dimensional QTTs and compares interleaved, grouped, and fused layouts.
4. `04_operations_on_qtts.ipynb` demonstrates QTT operations: elementwise products, selected-variable products, fused-layout products, and integration.
5. `05_fourier_transforms.ipynb` applies Fourier transforms to one-dimensional QTTs and a two-dimensional partial transform.
6. `06_affine_transformations.ipynb` applies periodic and open-boundary affine pullback operators on a fused two-dimensional grid.


## Local Contributor Setup

If you are developing these tutorials together with a local checkout of
`Tensor4all.jl`, you can override the package dependency locally:

```bash
julia --project=. -e 'using Pkg; Pkg.develop(path="path-to-repo/Tensor4all.jl"); Pkg.instantiate(); Pkg.resolve(); Pkg.build("Tensor4all"); Pkg.precompile()'
```

Do not put local machine paths inside notebook cells.

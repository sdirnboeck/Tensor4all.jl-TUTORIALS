# Tensor4all.jl Tutorials

Pluto notebooks for learning Quantics Tensor Trains (QTTs) with `Tensor4all.jl`.

The notebooks are ordinary Pluto `.jl` files with embedded package environments. This repository intentionally has no root `Project.toml` or `Manifest.toml`.

## Prerequisites

- Julia (at least 1.12)
- Git, to download this repository
- Internet access for the first notebook run

On Windows, install Git from <https://git-scm.com/download/win> if `git` is not already available.

## Get the notebooks

Clone this repository and enter it:

```bash
git clone https://github.com/sdirnboeck/Tensor4all.jl-TUTORIALS.git
cd Tensor4all.jl-TUTORIALS
```

## Install Julia

Recommended installer: `juliaup`.

### macOS / Linux

```bash
curl -fsSL https://install.julialang.org | sh
```

### Windows

In PowerShell:

```powershell
winget install julia -s msstore
```

## Install and start Pluto

Install Pluto once:

```bash
julia -e "import Pkg; Pkg.add(String(:Pluto))"
```

Start Pluto from inside the cloned repository:

```bash
julia -e "import Pluto; Pluto.run()"
```

In the browser window that opens, choose a notebook file such as:

```text
01_first_qtt_function_and_grid.jl
```

On first run, Pluto downloads the notebook packages and Tensor4all will build its native backend. This can take several minutes; later runs are faster.

## Learning path

Read the notebooks in order:

1. `01_first_qtt_function_and_grid.jl` — first one-dimensional quantics grid, QTT approximation, bond dimensions, and point evaluation.
2. `02_accuracy_bonddims_and_sweeps.jl` — accuracy checks, `R` sweeps, and `maxbonddim` sweeps.
3. `03_multivariate_qtts_and_layouts.jl` — multivariate QTTs and bit-layout diagnostics.
4. `04_operations_on_qtts.jl` — QTT operations on spectral functions: products, selected-variable multiplication, and integration.
5. `05_fourier_transforms.jl` — one-dimensional Fourier transforms and a two-dimensional partial transform.
6. `06_affine_transformations.jl` — periodic and open-boundary affine pullback operators on fused grids.
7. `07_interpolative_qtts.jl` — interpolative QTT construction: single-scale, adaptive, and sparse methods.

## Troubleshooting

### Pluto cannot find packages

Open notebooks in Pluto, not with `julia notebook.jl`. Pluto reads the embedded environment at the bottom of each notebook.

### First run is slow

Expected. Pluto may download packages and Tensor4all may build its native backend.

### Reset package versions

Close Pluto and restore a fresh copy from git:

```bash
git restore .
```

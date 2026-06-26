# Tensor4all.jl Tutorials

Pluto notebooks for learning Quantics Tensor Trains (QTTs) with
`Tensor4all.jl`.

The tutorials are written for Master students and early PhD students who are
learning QTTs for the first time. Open a notebook in Pluto, run the cells,
change parameters, and inspect the plots.

## Prerequisites

You only need:

1. Julia 1.12
2. Pluto.jl
3. an internet connection for the first run

The notebooks are ordinary `.jl` files saved by Pluto. Each notebook carries its
own embedded package environment, so this repository intentionally has no root
`Project.toml` or `Manifest.toml`.

## Install Julia

The recommended installer is `juliaup`, which manages Julia versions for you.

### macOS / Linux

```bash
curl -fsSL https://install.julialang.org | sh
```

Restart your terminal, then install and select Julia 1.12:

```bash
juliaup add 1.12
juliaup default 1.12
julia --version
```

### Windows

Install Julia from the Microsoft Store:

```powershell
winget install julia -s msstore
```

Then open a new PowerShell window and check:

```powershell
julia --version
```

Use Julia 1.12.x for these notebooks.

## Install Pluto

Install Pluto once in your default Julia environment:

```bash
julia -e 'using Pkg; Pkg.add("Pluto")'
```

Start Pluto with:

```bash
julia -e 'using Pluto; Pluto.run()'
```

A browser window opens. From there, open one of the notebook files in this
repository, for example:

```text
01_first_qtt_function_and_grid.jl
```

On first run, Pluto will download the notebook's packages. The setup cell also
builds the Tensor4all native backend if it is missing. This can take several
minutes; later runs are much faster.

## Learning path

Read the notebooks in numerical order:

1. `01_first_qtt_function_and_grid.jl` — first one-dimensional quantics grid, first QTT approximation, bond dimensions, and point evaluation.
2. `02_accuracy_bonddims_and_sweeps.jl` — accuracy checks, `R` sweeps, and `maxbonddim` sweeps.
3. `03_multivariate_qtts_and_layouts.jl` — two-dimensional QTTs and interleaved, grouped, and fused layouts.
4. `04_operations_on_qtts.jl` — elementwise products, selected-variable products, fused-layout products, and integration.
5. `05_fourier_transforms.jl` — one-dimensional Fourier transforms and a two-dimensional partial transform.
6. `06_affine_transformations.jl` — periodic and open-boundary affine pullback operators on fused grids.
7. `07_interpolative_qtts.jl` — interpolative QTT construction: single-scale, adaptive, and sparse methods.

## About Tensor4all.jl

`Tensor4all.jl` is fetched automatically from the embedded notebook
environments. It is not currently installed with `Pkg.add("Tensor4all")` from
the Julia General registry.

The notebooks import Tensor4all submodules with short aliases such as:

```julia
import Tensor4all.QuanticsGrids as QG
import Tensor4all.QuanticsTCI as QTCI
import Tensor4all.TensorNetworks as TN
import Tensor4all.InterpolativeQTT as IQTT
```

You do not need to install these submodules separately.

## Troubleshooting

### Pluto cannot find packages

Open the notebook in Pluto, not by running `julia notebook.jl` directly. Pluto
recognizes the embedded environment at the bottom of each notebook and
instantiates it automatically.

### First run is slow

This is expected. Pluto may need to download Julia packages, and Tensor4all may
need to build its native backend. Keep the terminal running and wait for the
setup cell to finish.

### You changed package versions and want to reset

Use Pluto's built-in package manager for the notebook, or close Pluto and open a
fresh copy of the notebook from git.

## Contributor notes

Keep the repository Pluto-only:

- add or edit `.jl` Pluto notebooks,
- do not add `.ipynb` notebooks,
- do not add a repository-level `Project.toml` or `Manifest.toml`,
- keep notebooks self-contained with embedded Pluto environments.

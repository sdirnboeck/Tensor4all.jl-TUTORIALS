# Tensor4all.jl Tutorials

Jupyter notebooks for learning Quantics Tensor Trains (QTTs) with
`Tensor4all.jl`.

The tutorials are written for Master students and early PhD students who are
learning QTTs for the first time. The focus is interactive learning: open a
notebook, run the cells, change parameters, and inspect the plots.

## Setup

Clone this repository and instantiate the Julia environment:

```bash
git clone https://github.com/sdirnboeck/Tensor4all.jl-TUTORIALS.git
cd Tensor4all.jl-TUTORIALS
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.resolve(); Pkg.build("Tensor4all"); Pkg.precompile()'
```

The explicit `Pkg.resolve()` step refreshes the manifest for the Julia version
you are using, and `Pkg.precompile()` avoids triggering package precompilation
from inside the notebook kernel.

## Opening The Notebooks

You can open the notebooks in Jupyter, VS Code, or another IDE that supports
Julia notebooks.

Start with:

```text
01_first_qtt_function_and_grid.ipynb
```

If VS Code asks you to choose a Julia kernel, use the same Julia version that
you used for the setup command. Use a Julia 1.12 kernel for this repository;
the current `Manifest.toml` was resolved with Julia 1.12.5, so a Julia 1.11
kernel can fail during package loading.

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

All six notebooks are implemented. Notebook 06 is still the newest and should be read as the most draft-like part of the sequence.

## Local Contributor Setup

If you are developing these tutorials together with a local checkout of
`Tensor4all.jl`, you can override the package dependency locally:

```bash
julia --project=. -e 'using Pkg; Pkg.develop(path="../../code/Tensor4all/Tensor4all.jl"); Pkg.instantiate(); Pkg.resolve(); Pkg.build("Tensor4all"); Pkg.precompile()'
```

Do not put local machine paths inside notebook cells.

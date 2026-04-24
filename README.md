# Tensor4all.jl Tutorials

Jupyter notebooks for learning Quantics Tensor Trains (QTTs) with
`Tensor4all.jl`.

The tutorials are written for Master students and early PhD students who are
learning QTTs for the first time. The focus is interactive learning: open a
notebook, run the cells, change parameters, and inspect the plots.

## Setup

Install Julia 1.9 or later first.

Then clone this repository and instantiate the Julia environment:

```bash
git clone https://github.com/sdirnboeck/Tensor4all.jl-TUTORIALS.git
cd Tensor4all.jl-TUTORIALS
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.build("Tensor4all"); Pkg.precompile()'
```

The explicit `Pkg.precompile()` step is important when running notebooks in
VS Code: it avoids triggering package precompilation from inside the notebook
kernel.

## Opening The Notebooks

You can open the notebooks in Jupyter, VS Code, or another IDE that supports
Julia notebooks.

Start with:

```text
01_first_qtt_function_and_grid.ipynb
```

If VS Code asks you to choose a Julia kernel, use the same Julia version that
you used for the setup command. This notebook was last tested with Julia 1.12,
but newer Julia versions should also work as long as the environment
instantiates and imports succeed.

## Troubleshooting In VS Code

If the first notebook cell fails immediately with an error that contains
`pipe_writer(::VSCodeServer.IJuliaCore.IJuliaStdio...)`, the problem is usually
not the notebook code itself. It happens when VS Code tries to trigger Julia
package precompilation from inside the notebook kernel.

Use this recovery sequence:

```bash
cd Tensor4all.jl-TUTORIALS
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.build("Tensor4all"); Pkg.precompile()'
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

```text
01_first_qtt_function_and_grid.ipynb
02_accuracy_bonddims_and_sweeps.ipynb
03_multivariate_qtts_and_layouts.ipynb
04_operations_on_qtts.ipynb
05_fourier_transforms.ipynb
06_affine_transformations.ipynb
```

Only the first notebook is currently implemented.

## Local Contributor Setup

If you are developing these tutorials together with a local checkout of
`Tensor4all.jl`, you can override the package dependency locally:

```bash
julia --project=. -e 'using Pkg; Pkg.develop(path="../../code/Tensor4all/Tensor4all.jl"); Pkg.instantiate(); Pkg.build("Tensor4all"); Pkg.precompile()'
```

Do not put local machine paths inside notebook cells.

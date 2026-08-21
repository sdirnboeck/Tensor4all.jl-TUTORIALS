### A Pluto.jl notebook ###
# v1.0.3

#> [frontmatter]
#> order = "1"
#> site_name = "Tensor4all.jl Tutorials"
#> title = "Build your first Tensor4all QTT"
#> date = "2026-06-26"
#> tags = ["tensor4all", "qtt", "quantics-grid", "tensor-train", "tutorial"]
#> description = "Create a one-dimensional quantics grid, build a first QTT approximation, inspect bond dimensions, evaluate one grid point with TN.evaluate, and complete a checked exercise."
#> type = "article"
#> 
#>     [[frontmatter.author]]
#>     name = "Tensor4all.jl Tutorial Authors"

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 1ef31b99-117d-54d3-931c-3e1cda027d83
begin
	using Tensor4all
	import Tensor4all.QuanticsGrids as QG
	import Tensor4all.QuanticsTCI as QTCI
	import Tensor4all.TensorNetworks as TN
	import Tensor4all.SimpleTT as STT
end

# ╔═╡ d56b3fd1-6f0e-4754-a3ef-5518da05eea9
begin
	import Pkg
	if Sys.iswindows()
		script = raw"""
		$ErrorActionPreference = 'Stop'

		$winget = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe'

		& $winget install `
			--exact `
			--id Microsoft.VisualStudio.2022.BuildTools `
			--no-upgrade `
			--accept-source-agreements `
			--accept-package-agreements `
			--override '--wait --passive --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended'

		$code = $LASTEXITCODE

		# WinGet reports an already-satisfied installation as an error.
		if ($code -in @(
			-1978335189,  # No applicable update
			-1978335135   # Package already installed
		)) {
			exit 0
		}

		if ($code -ne 0) {
			throw "winget failed with exit code $code"
		}

		exit 0
		"""

		run(Cmd([
			"powershell.exe",
			"-NoProfile",
			"-NonInteractive",
			"-ExecutionPolicy", "Bypass",
			"-Command", script,
		]))
	end

	if !isfile(Tensor4all.backend_library_path())
		Pkg.build("Tensor4all")
	end
	Tensor4all.require_backend()
end;

# ╔═╡ b65f451a-0c7b-4675-a71c-9f112df76c95
begin
	using CairoMakie
	using PlutoUI
	using LaTeXStrings
	plot_fontsize = 20
end

# ╔═╡ b83dc06a-c0c9-5c30-a4c8-5ae07c1ba561
md"""
# 01. Build your first Tensor4all QTT

A short Tensor4all workflow: build a quantics grid, interpolate a QTT, inspect bond dimensions, evaluate one point, and repeat the workflow yourself.

> **Big picture**
>
> We will compress samples of `cosh(x)` into a tensor train, inspect its internal structure, and then you will build a second QTT yourself.
"""

# ╔═╡ 93c6c466-760e-5843-88bc-9266a98d9ab4
md"""
You will practice the Tensor4all workflow once with `cosh(x)`, then repeat the same sequence in a short exercise.
"""

# ╔═╡ 7f0ded6b-184b-545f-952e-b53de2cef4b5
md"""
## First run
"""

# ╔═╡ a7c0ce88-5584-5a4d-8bba-4f15fa6aeba7
md"""
The first run may take a few minutes: [`Pluto.jl`](https://plutojl.org) needs to download and compile packages, and Tensor4all needs to build its Rust backend. If you see a busy status indicator, that is expected. After the first successful run, reopening the notebook should be much faster.
"""

# ╔═╡ 0f12df16-20bf-4ac7-99af-0e13ff61b8bd
md"""
We use the Tensor4all packages below.
"""

# ╔═╡ 2862c07e-7e3f-4f8a-9076-6d3c1fd0a411
md"""
Alias map: `QG` = quantics grids, `QTCI` = quantics cross interpolation, `STT` = simple tensor trains, and `TN` = indexed tensor-network objects.
"""

# ╔═╡ 0eacff1b-6e8d-59f8-808b-a4ca2c68dc16
md"""
## Quantics grid in one dimension
"""

# ╔═╡ 88e3a383-7c83-595d-8b7b-699f6a69ccea
md"""
A one-dimensional quantics grid is controlled by a bit depth `R`. The number of sample points is

```math
N = 2^R.
```

> 🎛️ **Notebook parameters**
> Choose the bit depth `R` and one grid index to inspect throughout the walkthrough. Increasing `R` by one doubles the number of grid points.

Here we use `DiscretizedGrid{1}` with `includeendpoint=true` so the grid covers the closed interval `[0, 1]`. The helper `grididx_to_origcoord` maps a grid index back to the physical coordinate, and `grididx_to_quantics` shows the binary coordinates used by the QTT representation. The digit `1` stands for bit value `0` and `2` stands for bit value `1`, because Julia uses 1-based indexing.
"""

# ╔═╡ 5e41f526-dd86-4682-a569-3f35e49683e5
@bindname R PlutoUI.Slider(5:11; default=7, show_value=true)

# ╔═╡ 8cffdc59-2660-506d-a9e6-267dd2250e92
begin
	npoints = 2 ^ R
	grid = QG.DiscretizedGrid{1}(R, 0.0, 1.0; includeendpoint=true)
	xvals = [QG.grididx_to_origcoord(grid, i) for i in 1:npoints]
end

# ╔═╡ 80a13a91-566e-4869-b397-c290b50221c4
@bindname gridindex PlutoUI.Slider(1:npoints; default=npoints ÷ 3, show_value=true)

# ╔═╡ f4a7bc84-1e20-5638-9a52-527607fb9f83
md"""
## Main walkthrough: `cosh(x)`
"""

# ╔═╡ 10b26057-cb7b-5c69-a51a-55cb3e17ed47
md"""
Our first target function is `cosh(x)`. It is smooth and compact in QTT form.

> **Workflow**
>
> Function → quantics grid → QTT interpolation → tensor train → values and bond dimensions.

TCI (Tensor Cross Interpolation) builds the QTT by querying selected function values instead of evaluating all `2^R` grid points. We then convert the interpolation result into a `TensorNetworks.TensorTrain` so we can inspect bond dimensions and evaluate values from explicit quantics indices.
"""

# ╔═╡ 025cb26b-477e-5e12-8945-bc236f151792
target_function(x) = cosh(x)

# ╔═╡ e109293a-de41-5aff-915f-b91a96720cdf
md"""
`quanticscrossinterpolate` asks for the value type explicitly. Here we use `Float64`, because the function values in this notebook are real floating-point numbers. We also set `tolerance`, `maxbonddim`, and `maxiter`, because these are the main interpolation parameters to watch when building a QTT. In this notebook, `maxbonddim = 64` is just a generous ceiling, and the examples stay far below it.
"""

# ╔═╡ 65cf60d4-84cc-45ba-af91-d27549cd852c
begin
	value_type = Float64
	tolerance = 1e-12
	maxbonddim = 64
	maxiter = 200
end

# ╔═╡ 22e1915e-c52a-42e6-89a7-61a0f6e0bf86
qtt, _, _ = QTCI.quanticscrossinterpolate(
	value_type, target_function, grid;
	tolerance, maxbonddim, maxiter
)

# ╔═╡ 2a4aae00-32d8-43c8-adc8-6333eed52844
begin
	simple_tt = STT.TensorTrain(qtt.tci)
	sites = [Tensor4all.Index(2; tags=["x", "bit=$i"]) for i in 1:R]

	indexed_tt = TN.TensorTrain(simple_tt, sites)
	bond_dims = TN.linkdims(indexed_tt)
end

# ╔═╡ d3259e1e-5b5e-45c4-9156-6c54edd2251e
Markdown.parse("""
The tensor train has `$(length(simple_tt))` core tensors, matching `R = $R` bit sites.
Bond dimensions: `$(bond_dims)`.
""")

# ╔═╡ 36481eff-5952-5590-95f0-5d1c521f7773
md"""
The plot compares the exact values, the QTT samples, and the selected grid point. The next cell computes the arrays behind that plot: `cosh_exact` stores the exact function values, `cosh_qtt` stores the QTT values, and `cosh_max_abs_error` measures the largest pointwise difference.
"""

# ╔═╡ 960e0962-a986-5290-868c-86fcc649f051
begin
	cosh_exact = target_function.(xvals)
	cosh_qtt = qtt.(1:npoints)
	cosh_max_abs_error = maximum(abs, cosh_exact - cosh_qtt)
end;

# ╔═╡ a966cc55-b677-4907-95be-842c05ece344
Markdown.parse("Maximum absolute error on the full grid: `$(round(cosh_max_abs_error; sigdigits=3))`.")

# ╔═╡ bd147b4a-8af8-4dc6-99bb-a4669517ac7d
Markdown.parse("""
> **Compression snapshot**
>
> Grid values: `$(npoints)` · TT cores: `$(length(simple_tt))` · maximum bond dimension: `$(maximum(bond_dims))` · maximum error: `$(round(cosh_max_abs_error; sigdigits=3))`
""")

# ╔═╡ 467662a2-714f-5f5f-90e2-ea68107f8b5f
md"""
The highlighted point can also be obtained directly from the `TN.TensorTrain` object. We use the selected grid index, convert it to quantics digits, and compare the tensor-train value to the true value at the corresponding physical coordinate.
"""

# ╔═╡ 2b1b3e2c-8c17-5b6c-9e49-235fb4bab685
begin
	sample_digits = QG.grididx_to_quantics(grid, gridindex)
	sample_coordinate = QG.grididx_to_origcoord(grid, gridindex)

	sample_qtt_value = qtt(gridindex)
	sample_indexed_tt_value = real(TN.evaluate(indexed_tt, sites, sample_digits))
	sample_exact_value = target_function(sample_coordinate)
end

# ╔═╡ c7ae2e42-750b-4b0d-aa90-69c710a5496d
Markdown.parse("""
Point evaluation with `TN.evaluate`:

| quantity | value |
|:--|:--|
| grid index | `$(gridindex)` |
| coordinate | `$(sample_coordinate)` |
| quantics digits | `$(sample_digits)` |
| `qtt(i)` | `$(sample_qtt_value)` |
| `TN.evaluate(...)` | `$(sample_indexed_tt_value)` |
| exact value | `$(sample_exact_value)` |
""")

# ╔═╡ aa96fd3f-d0b0-5f0a-95f6-429d8bb949a4
details("Why this example is compact",
md"""
`cosh(x)` is compact because

```math
\cosh(x) = \frac{e^x + e^{-x}}{2}.
```

On a quantics grid, the bits contribute additively to `x`, and exponentials turn sums into products. So `exp(x)` and `exp(-x)` have very compact QTT structure, and their sum stays compact.
"""
	   )

# ╔═╡ f377507b-b7cb-5007-8506-0bde001733aa
md"""
## Exercise: build your own Tensor4all QTT

> 🧩 **Your turn**
> The next cells are intentionally incomplete. They run without errors, and soft checkpoints will guide you once you replace the placeholders.
"""

# ╔═╡ 97e5efad-4b37-5634-9534-02e0160ef250
md"""
Now use the same workflow for `f(x) = sin(6x) + 0.2x` on the interval `[-1, 2]`.

The cells below run as-is, but the important lines contain `nothing` placeholders. Replace each placeholder with real code.

For resolution, reuse the existing `R`.
"""

# ╔═╡ 07f62519-48d2-51e7-b1ec-964bc77f0d30
begin
	exercise_lower = -1.0
	exercise_upper = 2.0
	exercise_function(x) = sin(6x) + 0.2x
end

# ╔═╡ 50cac4bc-1360-4188-86b8-ee3528f0b219
md"""
Hint: You can use Pluto.jl's **Live docs** functionality (bottom right) to view docstrings.
"""

# ╔═╡ 2bb42e4e-bc70-45b4-aa5b-2dce344a48d3
md"""
### Step 1 — construct the grid and coordinates
"""

# ╔═╡ 166688ff-4bf7-566a-b9cf-1db5f10be350
begin
	exercise_npoints = 2 ^ R
	exercise_grid = nothing   # TODO: construct QG.DiscretizedGrid{1}(...) on [exercise_lower, exercise_upper]
	exercise_xvals = nothing  # TODO: compute physical coordinates for every grid index
end

# ╔═╡ 8f734d50-8f83-471f-a4c6-c9df2a2d9148
md"""
### Step 2 — interpolate the function
"""

# ╔═╡ f8d60ab7-6865-4e39-9eb5-a36e45ff724d
exercise_qtt = nothing  # TODO: call QTCI.quanticscrossinterpolate with value_type, exercise_function, and exercise_grid

# ╔═╡ 63701385-bbf1-40d1-b796-9a2f25d1960b
md"""
### Step 3 — convert to an indexed tensor train
"""

# ╔═╡ 6b8fda34-b6db-4a82-8912-741ad75f5345
begin
	exercise_simple_tt = nothing   # TODO: convert exercise_qtt.tci with STT.TensorTrain
	exercise_sites = nothing       # TODO: create one Tensor4all.Index(2; ...) per TT core
	exercise_indexed_tt = nothing  # TODO: build TN.TensorTrain(exercise_simple_tt, exercise_sites)
	exercise_bond_dims = nothing   # TODO: inspect link dimensions with TN.linkdims
end

# ╔═╡ bfd5f0b8-04fb-4f34-a3e5-32b818e418f6
md"""
### Step 4 — evaluate one grid point from the tensor train
"""

# ╔═╡ 6eb9cb0d-1900-47d0-9cdb-fb6df119822f
begin
	exercise_sample_i = min(17, exercise_npoints)  # TODO: choose a valid grid index to inspect
	exercise_sample_digits = nothing      # TODO: convert exercise_sample_i to quantics digits
	exercise_sample_coordinate = nothing  # TODO: convert exercise_sample_i to a physical coordinate
	exercise_indexed_tt_value = nothing   # TODO: evaluate exercise_indexed_tt with TN.evaluate
	exercise_exact_value = nothing        # TODO: evaluate exercise_function at exercise_sample_coordinate
end

# ╔═╡ ec091b7e-9e28-45ff-880a-3136dc3bf4e9
md"""
### Step 5 — check the full grid and plot the result
"""

# ╔═╡ f2f7f849-9f7c-468c-944e-80300b720b72
begin
	exercise_exact = nothing          # TODO: evaluate exercise_function on all exercise_xvals
	exercise_values = nothing         # TODO: evaluate exercise_qtt on every grid index
	exercise_max_abs_error = nothing  # TODO: compute the maximum absolute error
end

# ╔═╡ d7530644-a61e-4a23-9cfc-d7e236509d35
details("View hints",
md"""
#### Hints

- Reuse `value_type`, `tolerance`, `maxbonddim`, and `maxiter` from the walkthrough.
- The grid constructor in the walkthrough is the one you need, but with `exercise_lower` and `exercise_upper`.
- Build `exercise_xvals` by converting each grid index with `QG.grididx_to_origcoord`.
- The conversion path is `STT.TensorTrain(...)` followed by `TN.TensorTrain(...)`.
- To evaluate the indexed tensor train, first convert the grid index to quantics digits.
- Full-grid values can be computed with a list comprehension over `1:exercise_npoints`.
"""
)

# ╔═╡ f16fd69a-0114-4856-853f-edcb2f54605a
details("View solution",
md"""
#### Solution

```julia
exercise_grid = QG.DiscretizedGrid{1}(R, exercise_lower, exercise_upper; includeendpoint=true)
exercise_xvals = [QG.grididx_to_origcoord(exercise_grid, i) for i in 1:exercise_npoints]

exercise_qtt, _, _ = QTCI.quanticscrossinterpolate(
    value_type,
    exercise_function,
    exercise_grid;
    tolerance,
    maxbonddim,
    maxiter,
)

exercise_simple_tt = STT.TensorTrain(exercise_qtt.tci)
exercise_sites = [Tensor4all.Index(2; tags=["exercise", "bit=\$i"]) for i in 1:length(exercise_simple_tt)]
exercise_indexed_tt = TN.TensorTrain(exercise_simple_tt, exercise_sites)
exercise_bond_dims = TN.linkdims(exercise_indexed_tt)

exercise_sample_i = min(17, exercise_npoints)
exercise_sample_digits = QG.grididx_to_quantics(exercise_grid, exercise_sample_i)
exercise_sample_coordinate = QG.grididx_to_origcoord(exercise_grid, exercise_sample_i)
exercise_indexed_tt_value = real(TN.evaluate(exercise_indexed_tt, exercise_sites, exercise_sample_digits))
exercise_exact_value = exercise_function(exercise_sample_coordinate)

exercise_exact = exercise_function.(exercise_xvals)
exercise_values = [real(exercise_qtt(i)) for i in 1:exercise_npoints]
exercise_max_abs_error = maximum(abs, exercise_exact .- exercise_values)
```
""")

# ╔═╡ ec013294-94ca-5c62-8bed-689945ba19cc
md"""
## What to take away
"""

# ╔═╡ 5421cb93-e382-57e2-af6d-9997c5f6b3fc
md"""
- `R` sets the bit depth, so the grid has `2^R` points.
- `QTCI.quanticscrossinterpolate` builds the QTT from a function and quantics grid.
- `STT.TensorTrain(qtt.tci)` exposes the TT cores.
- `TN.TensorTrain(simple_tt, sites)` adds explicit site indices.
- `TN.evaluate` evaluates one quantics grid point from the indexed tensor train.
- `TN.linkdims` reports the internal bond dimensions.

Notebook 02 continues with accuracy and bond-dimension behavior.
"""

# ╔═╡ 4ed1a17d-1658-4c1e-9998-9ac909b2d5a1
PlutoUI.TableOfContents(title="Notebook map", depth=3, aside=true)

# ╔═╡ f4a31e4b-6d4d-41af-a23b-f3ed7f20b69b
begin
	worst_case_bond_dims(num_bonds; base=2) = [base^min(k, num_bonds + 1 - k) for k in 1:num_bonds]

	t4a_check(label, passed, fix="") = (; label, passed = passed === true, fix)

	function t4a_trycheck(f, label, fix)
		try
			t4a_check(label, f(), fix)
		catch
			t4a_check(label, false, fix)
		end
	end

	t4a_passed(items) = all(item -> item.passed, items)

	function t4a_checkpoint(title, items)
		lines = ["> **$title**", ">"]
		for item in items
			icon = item.passed ? "✅" : "❌"
			detail = item.passed || isempty(item.fix) ? "" : " — $(item.fix)"
			push!(lines, "> - $icon $(item.label)$detail")
		end
		Markdown.parse(join(lines, "
"))
	end

	function t4a_pending_checkpoint(title, message)
		Markdown.parse("> **$title**
>
> ⏳ $message")
	end

	function add_bond_dimension_axis!(fig, position, bond_dims; title="Bond dimensions", base=2)
		ax = Axis(
		    fig[position...],
		    xgridvisible=false,
		    ygridvisible=false,
		    xlabel="bond link",
		    ylabel="bond dimension",
		    title=title,
		    yscale=log2,
		)
		bond_index = 1:length(bond_dims)
		ax.xticks = bond_index
		lines!(ax, bond_index, bond_dims; color=:goldenrod2, linewidth=2.8, label=L"\mathrm{observed}" )
		scatter!(ax, bond_index, bond_dims;
		    color=:goldenrod2, markersize=9, strokecolor=:white, strokewidth=1)
		lines!(ax, bond_index, worst_case_bond_dims(length(bond_dims); base=base);
		    color=:gray55, linewidth=2.2, linestyle=:dash, label=L"\mathrm{worst\ case}")
		Legend(fig[position[1] + 1, position[2]], ax, orientation=:horizontal, framevisible=false)
		return ax
	end

	function quantics_grid_story(grid, xvals, R, preview_i)
		npoints = length(xvals)
		preview_x = xvals[preview_i]
		preview_digits = QG.grididx_to_quantics(grid, preview_i)

		fig = Figure(size=(1000, 300), fontsize=plot_fontsize)
		ax = Axis(
		    fig[1, 1],
		    xgridvisible=false,
		    ygridvisible=false,
		    xlabel="original coordinate x",
		)
		scatter!(ax, xvals, zeros(npoints); color=(:deepskyblue4, 0.50), markersize=6)
		scatter!(ax, [first(xvals), last(xvals)], [0, 0]; color=:goldenrod2, markersize=13, label=L"\mathrm{endpoints}")
		scatter!(ax, [preview_x], [0]; color=:tomato, marker=:star5, markersize=18, label=LaTeXString("\\mathrm{index\\ }$preview_i"))
		hideydecorations!(ax)
		hidespines!(ax, :l, :r, :t)
		ylims!(ax, -0.25, 0.25)
		axislegend(ax; position=:rt)

		Label(fig[1, 2],
		    "grid index\ni = $preview_i\n\noriginal coordinate\nxᵢ = $(round(preview_x; digits=5))\n\nquantics digits\nqᵢ = $preview_digits";
		    tellwidth=false,
		    halign=:left,
		    justification=:left,
		    fontsize=plot_fontsize,
		)
		colsize!(fig.layout, 1, Relative(0.70))
		return fig
	end
end;

# ╔═╡ cde5e86f-432e-42f8-95b8-6f948beddf4e
begin
	first_quantics_digits = QG.grididx_to_quantics(grid, 1)
	last_quantics_digits = QG.grididx_to_quantics(grid, npoints)
	grid_preview_coordinate = QG.grididx_to_origcoord(grid, gridindex)
	grid_preview_digits = QG.grididx_to_quantics(grid, gridindex)
	quantics_grid_story(grid, xvals, R, gridindex)
end

# ╔═╡ 4b5781f4-4d5f-5b54-b0bb-19b07a4c78f8
begin
	fig = Figure(size=(1180, 430), fontsize=plot_fontsize)
	qtt_marker_size = npoints <= 128 ? 11 : npoints <= 256 ? 9 : 7

	ax1 = Axis(
	    fig[1, 1],
	    xgridvisible=false,
	    ygridvisible=false,
	    xlabel=L"x",
	    ylabel="value",
	    title="cosh(x): exact values and QTT samples",
	)
	lines!(ax1, xvals, cosh_exact; color=:black, linewidth=2.5, label=L"\cosh(x)")
	scatter!(ax1, xvals, cosh_qtt;
	    color=:white, markersize=qtt_marker_size,
	    strokecolor=:deepskyblue4, strokewidth=2.0, label=L"\mathrm{QTT\ samples}")
	scatter!(ax1, [sample_coordinate], [sample_indexed_tt_value];
	    color=:tomato, marker=:star5, markersize=24,
	    strokecolor=:black, strokewidth=1.2, label=L"\mathrm{TN.evaluate\ point}")
	Legend(fig[2, 1], ax1, orientation=:horizontal, framevisible=false)

	add_bond_dimension_axis!(fig, (1, 2), bond_dims; title="Internal bond dimensions")
	colgap!(fig.layout, 28)
	rowgap!(fig.layout, 8)

	fig
end

# ╔═╡ 0c7ee121-198c-451f-ad8d-fd47d49c8bb4
if exercise_grid === nothing
	t4a_pending_checkpoint("Exercise checkpoint 1", "Replace the `exercise_grid` and `exercise_xvals` placeholders with a grid construction and its physical coordinates.")
else
	t4a_checkpoint("Exercise checkpoint 1", [
		t4a_check("grid is a one-dimensional `DiscretizedGrid`", exercise_grid isa QG.DiscretizedGrid{1}, "construct `QG.DiscretizedGrid{1}(...)`"),
		t4a_trycheck("coordinates were computed for all grid indices", "build `exercise_xvals` from every grid index") do
			exercise_xvals !== nothing && length(exercise_xvals) == exercise_npoints
		end,
		t4a_trycheck("first coordinate is `exercise_lower`", "compute `exercise_xvals` from `exercise_grid`; if it is already computed, check the lower bound") do
			isapprox(first(exercise_xvals), exercise_lower; atol=0, rtol=0)
		end,
		t4a_trycheck("last coordinate is `exercise_upper`", "compute `exercise_xvals` from `exercise_grid` with `includeendpoint=true`") do
			isapprox(last(exercise_xvals), exercise_upper; atol=0, rtol=0)
		end,
	])
end

# ╔═╡ ab1548bb-5c53-4957-a5fd-28edc8cc20d2
if exercise_qtt === nothing
	t4a_pending_checkpoint("Exercise checkpoint 2", "Build `exercise_qtt` from `exercise_function` and `exercise_grid` using the same interpolation parameters as above.")
else
	t4a_checkpoint("Exercise checkpoint 2", [
		t4a_check("result has TCI data", hasproperty(exercise_qtt, :tci), "keep the object returned by `QTCI.quanticscrossinterpolate`"),
		t4a_trycheck("QTT matches the exercise function at a sample point", "interpolate `exercise_function` on `exercise_grid`") do
			exercise_check_i = min(17, exercise_npoints)
			exercise_check_x = QG.grididx_to_origcoord(exercise_grid, exercise_check_i)
			isapprox(real(exercise_qtt(exercise_check_i)), exercise_function(exercise_check_x); atol=1e-8, rtol=1e-8)
		end,
	])
end

# ╔═╡ 7c783455-d51a-4d1e-b928-8bb0a965270b
if exercise_simple_tt === nothing || exercise_sites === nothing || exercise_indexed_tt === nothing || exercise_bond_dims === nothing
	t4a_pending_checkpoint("Exercise checkpoint 3", "Convert the QTT to an indexed tensor train and compute `exercise_bond_dims`.")
else
	t4a_checkpoint("Exercise checkpoint 3", [
		t4a_trycheck("simple tensor train has one core per bit site", "convert `exercise_qtt.tci` with `STT.TensorTrain`") do
			length(exercise_simple_tt) == R
		end,
		t4a_trycheck("one site index exists for each core", "create one `Tensor4all.Index(2; ...)` per core") do
			length(exercise_sites) == length(exercise_simple_tt)
		end,
		t4a_trycheck("indexed tensor train matches `exercise_qtt`", "build the indexed tensor train from `exercise_qtt.tci`") do
			i = min(17, exercise_npoints)
			digits = QG.grididx_to_quantics(exercise_grid, i)
			isapprox(real(TN.evaluate(exercise_indexed_tt, exercise_sites, digits)), real(exercise_qtt(i)); atol=1e-10, rtol=1e-10)
		end,
		t4a_trycheck("bond dimensions come from `TN.linkdims`", "compute `exercise_bond_dims = TN.linkdims(exercise_indexed_tt)`") do
			exercise_bond_dims == TN.linkdims(exercise_indexed_tt)
		end,
		t4a_trycheck("there are `R - 1` internal links", "check the tensor-train conversion") do
			length(exercise_bond_dims) == R - 1
		end,
		t4a_trycheck("bond dimensions stay below `maxbonddim`", "reuse the interpolation parameters from the walkthrough") do
			maximum(exercise_bond_dims) <= maxbonddim
		end,
	])
end

# ╔═╡ 8e164011-48bb-4266-970c-d2aca2cd34c9
if exercise_sample_digits === nothing || exercise_sample_coordinate === nothing || exercise_indexed_tt_value === nothing || exercise_exact_value === nothing
	t4a_pending_checkpoint("Exercise checkpoint 4", "Evaluate the indexed tensor train and compare it with the exact function value at `exercise_sample_i`.")
else
	t4a_checkpoint("Exercise checkpoint 4", [
		t4a_check("sample index is valid", 1 <= exercise_sample_i <= exercise_npoints, "choose an index between `1` and `exercise_npoints`"),
		t4a_trycheck("sample index was converted to quantics digits", "use `QG.grididx_to_quantics(exercise_grid, exercise_sample_i)`") do
			exercise_sample_digits == QG.grididx_to_quantics(exercise_grid, exercise_sample_i)
		end,
		t4a_trycheck("sample index was converted to a coordinate", "use `QG.grididx_to_origcoord(exercise_grid, exercise_sample_i)`") do
			exercise_sample_coordinate == QG.grididx_to_origcoord(exercise_grid, exercise_sample_i)
		end,
		t4a_trycheck("tensor-train value comes from `TN.evaluate`", "evaluate `exercise_indexed_tt` at `exercise_sample_digits`") do
			isapprox(exercise_indexed_tt_value, real(TN.evaluate(exercise_indexed_tt, exercise_sites, exercise_sample_digits)); atol=1e-12, rtol=1e-12)
		end,
		t4a_trycheck("exact value comes from `exercise_function`", "evaluate `exercise_function(exercise_sample_coordinate)`") do
			isapprox(exercise_exact_value, exercise_function(exercise_sample_coordinate); atol=0, rtol=0)
		end,
		t4a_trycheck("QTT value matches the exact value at this point", "check the previous items first") do
			isapprox(exercise_indexed_tt_value, exercise_exact_value; atol=1e-8, rtol=1e-8)
		end,
	])
end

# ╔═╡ e7a595ea-664c-4182-8b37-fc8c6e7913d8
if exercise_values === nothing || exercise_exact === nothing || exercise_bond_dims === nothing || exercise_max_abs_error === nothing
	exercise_step5_checks = nothing
	t4a_pending_checkpoint("Exercise checkpoint 5", "Compute exact values, QTT values, the maximum absolute error, and the bond dimensions before plotting.")
else
	exercise_step5_checks = [
		t4a_trycheck("exact values cover the whole exercise grid", "evaluate `exercise_function` on all `exercise_xvals`") do
			length(exercise_exact) == exercise_npoints
		end,
		t4a_trycheck("QTT values cover the whole exercise grid", "evaluate `exercise_qtt(i)` for every grid index") do
			length(exercise_values) == exercise_npoints
		end,
		t4a_trycheck("exact values use `exercise_function`", "set `exercise_exact = exercise_function.(exercise_xvals)`") do
			isapprox(exercise_exact, exercise_function.(exercise_xvals); atol=0, rtol=0)
		end,
		t4a_trycheck("QTT values use `exercise_qtt`", "use a list comprehension over `1:exercise_npoints`") do
			isapprox(exercise_values, [real(exercise_qtt(i)) for i in 1:exercise_npoints]; atol=1e-12, rtol=1e-12)
		end,
		t4a_trycheck("maximum error is computed correctly", "use `maximum(abs, exercise_exact .- exercise_values)`") do
			exercise_max_abs_error == maximum(abs, exercise_exact .- exercise_values)
		end,
		t4a_trycheck("full-grid error is small", "check the interpolation and full-grid values") do
			exercise_max_abs_error < 1e-8
		end,
	]
	t4a_checkpoint("Exercise checkpoint 5", exercise_step5_checks)
end

# ╔═╡ 47bbf65c-936c-4859-a409-7472bb5300fe
if exercise_step5_checks === nothing || !t4a_passed(exercise_step5_checks)
	md"""
	> Complete checkpoint 5 to show the exercise plot.
	"""
else
	begin
		fig_exercise = Figure(size=(920, 680), fontsize=plot_fontsize)
		exercise_marker_size = exercise_npoints <= 128 ? 11 : exercise_npoints <= 256 ? 9 : 7

		ax_ex1 = Axis(
		    fig_exercise[1, 1],
		    xgridvisible=false,
		    ygridvisible=false,
		    xlabel="x",
		    ylabel="value",
		    title="Exercise QTT on [-1, 2]",
		)
		lines!(ax_ex1, exercise_xvals, exercise_exact; color=:black, linewidth=2.5, label=L"\mathrm{exact\ function}")
		scatter!(ax_ex1, exercise_xvals, exercise_values;
		    color=:white, markersize=exercise_marker_size,
		    strokecolor=:deepskyblue4, strokewidth=2.0, label=L"\mathrm{QTT\ samples}")
		if exercise_sample_coordinate !== nothing && exercise_indexed_tt_value !== nothing
			scatter!(ax_ex1, [exercise_sample_coordinate], [exercise_indexed_tt_value];
			    color=:tomato, marker=:star5, markersize=24,
			    strokecolor=:black, strokewidth=1.2, label=L"\mathrm{TN.evaluate\ point}")
		end
		Legend(fig_exercise[2, 1], ax_ex1, orientation=:horizontal, framevisible=false)

		add_bond_dimension_axis!(fig_exercise, (3, 1), exercise_bond_dims; title="Exercise bond dimensions")
		rowgap!(fig_exercise.layout, 8)
		rowsize!(fig_exercise.layout, 1, Relative(0.58))
		rowsize!(fig_exercise.layout, 3, Relative(0.32))

		fig_exercise
	end
end;

# ╔═╡ 6ffb3623-3b15-4874-a399-7f1dcfa50b49
begin
	import TOML

	function t4a_notebook_files()
		files = filter(readdir(@__DIR__)) do file
			path = joinpath(@__DIR__, file)
			endswith(file, ".jl") && isfile(path) && startswith(read(path, String), "### A Pluto.jl notebook ###")
		end
		sort(files; by=file -> begin
			order = tryparse(Int, string(t4a_frontmatter(file, "order"; default="")))
			(something(order, typemax(Int)), file)
		end)
	end

	function t4a_notebook_metadata(file)
		path = joinpath(@__DIR__, file)
		metadata_lines = String[]
		for line in eachline(path)
			if startswith(line, "#> ")
				push!(metadata_lines, line[4:end])
			elseif !isempty(metadata_lines)
				break
			end
		end
		isempty(metadata_lines) && return Dict{String, Any}()
		parsed = TOML.parse(join(metadata_lines, "\n"))
		get(parsed, "frontmatter", Dict{String, Any}())
	end

	function t4a_frontmatter(file, key; default="")
		get(t4a_notebook_metadata(file), key, default)
	end

	function t4a_notebook_number(file)
		order = t4a_frontmatter(file, "order"; default="")
		!isempty(string(order)) && return lpad(string(order), 2, '0')
		m = match(r"^(\d+)_", file)
		m === nothing ? "" : only(m.captures)
	end

	function t4a_notebook_title(file)
		title = t4a_frontmatter(file, "title"; default="")
		!isempty(string(title)) && return string(title)
		stem = splitext(file)[1]
		without_number = replace(stem, r"^\d+_" => "")
		title = titlecase(replace(without_number, "_" => " "))
		replace(title, "Qtt" => "QTT", "Tci" => "TCI")
	end

	function t4a_notebook_description(file)
		string(t4a_frontmatter(file, "description"; default=file))
	end

	function t4a_escape_html(text)
		replace(string(text), "&" => "&amp;", "<" => "&lt;", ">" => "&gt;", "\"" => "&quot;")
	end

	function t4a_notebook_href(file)
		path = abspath(joinpath(@__DIR__, file))
		escaped = replace(path, "\\" => "/", " " => "%20", "#" => "%23", "?" => "%3F")
		"./open?path=$escaped"
	end

	function t4a_current_file()
		notebook_path = first(split(string(@__FILE__), "#==#"; limit=2))
		basename(notebook_path)
	end

	function t4a_nav_styles()
		"""
		<style>
		.t4a-nav { margin: 1.25rem 0; }
		.t4a-nav h2, .t4a-nav h3 { margin: 0 0 .5rem 0; }
		.t4a-grid {
			display: grid;
			grid-template-columns: 1fr;
			gap: 0;
		}
		.t4a-card {
			display: block;
			padding: .3rem .6rem;
			border-left: 2px solid transparent;
			color: inherit;
			text-decoration: none;
		}
		.t4a-card:hover { text-decoration: underline; }
		.t4a-card.current {
			border-left-color: #0284c7;
			color: #0284c7;
		}
		.t4a-num {
			display: inline-block;
			width: 2rem;
			font-variant-numeric: tabular-nums;
			opacity: .65;
		}
		.t4a-card strong { line-height: 1.2; }
		.t4a-prev-next {
			display: flex;
			justify-content: space-between;
			gap: 1rem;
			flex-wrap: wrap;
		}
		.t4a-prev-next a, .t4a-prev-next span {
			flex: 1 1 260px;
			padding: .45rem 0;
			color: inherit;
			text-decoration: none;
		}
		.t4a-prev-next a:hover { text-decoration: underline; }
		.t4a-muted { opacity: .45; }
		</style>
		"""
	end

	function t4a_tutorial_overview()
		current_file = t4a_current_file()
		cards = join(map(t4a_notebook_files()) do file
			number = t4a_escape_html(t4a_notebook_number(file))
			title = t4a_escape_html(t4a_notebook_title(file))
			if file == current_file
				"""
				<div class=\"t4a-card current\" aria-current=\"page\">
					<span class=\"t4a-num\">$number</span><strong>$title</strong>
				</div>
				"""
			else
				"""
				<a class=\"t4a-card\" href=\"$(t4a_notebook_href(file))\">
					<span class=\"t4a-num\">$number</span><strong>$title</strong>
				</a>
				"""
			end
		end, "")

		HTML("""
		<div class=\"t4a-nav\">
		$(t4a_nav_styles())
		<h2>Tutorial index</h2>
		<div class=\"t4a-grid\">$cards</div>
		</div>
		""")
	end

	function t4a_prev_next()
		files = t4a_notebook_files()
		current_file = t4a_current_file()
		idx = findfirst(==(current_file), files)
		prev = idx === nothing || idx == 1 ? nothing : files[idx - 1]
		next = idx === nothing || idx == length(files) ? nothing : files[idx + 1]

		prev_html = prev === nothing ?
			"<span class=\"t4a-muted\">← Previous notebook</span>" :
			"<a href=\"$(t4a_notebook_href(prev))\">← Previous: <strong>$(t4a_escape_html(t4a_notebook_number(prev))). $(t4a_escape_html(t4a_notebook_title(prev)))</strong></a>"

		next_html = next === nothing ?
			"<span class=\"t4a-muted\">Next notebook →</span>" :
			"<a href=\"$(t4a_notebook_href(next))\">Next: <strong>$(t4a_escape_html(t4a_notebook_number(next))). $(t4a_escape_html(t4a_notebook_title(next)))</strong> →</a>"

		HTML("""
		<div class=\"t4a-nav\">
		$(t4a_nav_styles())
		<h3>Notebook navigation</h3>
		<div class=\"t4a-prev-next\">$prev_html $next_html</div>
		</div>
		""")
	end
end;

# ╔═╡ 221e37cb-1bbc-4585-9992-7dd486c1f159
t4a_tutorial_overview()

# ╔═╡ 2d069f89-fd41-4f98-89a6-b54895c32570
t4a_prev_next()

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CairoMakie = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
LaTeXStrings = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
Pkg = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
TOML = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
Tensor4all = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

[sources]
Tensor4all = {rev = "main", url = "https://github.com/tensor4all/Tensor4all.jl.git"}

[compat]
CairoMakie = "~0.15.13"
LaTeXStrings = "~1.4.0"
PlutoUI = "~0.7.83"
Tensor4all = "~0.1.0"
julia = "1.12"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.6"
manifest_format = "2.0"
project_hash = "1e6e652134f96e52f551a62a47437507515d5d1f"

[[deps.AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "d92ad398961a3ed262d8bf04a1a2b8340f915fef"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.5.0"
weakdeps = ["ChainRulesCore", "Test"]

    [deps.AbstractFFTs.extensions]
    AbstractFFTsChainRulesCoreExt = "ChainRulesCore"
    AbstractFFTsTestExt = "Test"

[[deps.AbstractPlutoDingetjes]]
git-tree-sha1 = "6c3913f4e9bdf6ba3c08041a446fb1332716cbc2"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.4.0"

[[deps.AbstractTrees]]
git-tree-sha1 = "2d9c9a55f9c93e8887ad391fbae72f8ef55e1177"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.5"

[[deps.Accessors]]
deps = ["CompositionsBase", "ConstructionBase", "Dates", "InverseFunctions", "MacroTools"]
git-tree-sha1 = "7063ad1083578215c7c4bf410368150abe8d5524"
uuid = "7d9f7c33-5ae7-4f3b-8dc6-eff91059b697"
version = "0.1.45"

    [deps.Accessors.extensions]
    AxisKeysExt = "AxisKeys"
    IntervalSetsExt = "IntervalSets"
    LinearAlgebraExt = "LinearAlgebra"
    StaticArraysExt = "StaticArrays"
    StructArraysExt = "StructArrays"
    TestExt = "Test"
    UnitfulExt = "Unitful"

    [deps.Accessors.weakdeps]
    AxisKeys = "94b1ba4f-4ee9-5380-92f1-94cde586c3c5"
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "daa72978cd7a624246e894a4f4f067706d4e17e2"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "4.7.0"
weakdeps = ["SparseArrays", "StaticArrays"]

    [deps.Adapt.extensions]
    AdaptSparseArraysExt = "SparseArrays"
    AdaptStaticArraysExt = "StaticArrays"

[[deps.AdaptivePredicates]]
git-tree-sha1 = "7e651ea8d262d2d74ce75fdf47c4d63c07dba7a6"
uuid = "35492f91-a3bd-45ad-95db-fcad7dcfedb7"
version = "1.2.0"

[[deps.AliasTables]]
deps = ["PtrArrays", "Random"]
git-tree-sha1 = "9876e1e164b144ca45e9e3198d0b689cadfed9ff"
uuid = "66dad0bd-aa9a-41b7-9441-69ab47430ed8"
version = "1.1.3"

[[deps.Animations]]
deps = ["Colors"]
git-tree-sha1 = "e092fa223bf66a3c41f9c022bd074d916dc303e7"
uuid = "27a7e980-b3e6-11e9-2bcd-0b925532e340"
version = "0.4.2"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Automa]]
deps = ["PrecompileTools", "TranscodingStreams"]
git-tree-sha1 = "94eab0b3ccdcac361188cc661daf69d4433c1818"
uuid = "67c07d97-cdcb-5c2c-af73-a7f9c32a568b"
version = "1.2.0"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "01b8ccb13d68535d73d2b0c23e39bd23155fb712"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.1.0"

[[deps.AxisArrays]]
deps = ["Dates", "IntervalSets", "IterTools", "RangeArrays"]
git-tree-sha1 = "4126b08903b777c88edf1754288144a0492c05ad"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.8"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.BaseDirs]]
git-tree-sha1 = "8c290a1b223deaeea9aea44b235d24546da8eb98"
uuid = "18cc8868-cbac-4acf-b575-c8ff214dc66f"
version = "1.4.0"

[[deps.BitIntegers]]
deps = ["Random"]
git-tree-sha1 = "091d591a060e43df1dd35faab3ca284925c48e46"
uuid = "c3b6d118-76ef-56ca-8cc7-ebb389d030a1"
version = "0.3.7"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1b96ea4a01afe0ea4090c5c8039690672dd13f2e"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.9+0"

[[deps.CEnum]]
git-tree-sha1 = "389ad5c84de1ae7cf0e28e381131c98ea87d54fc"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.5.0"

[[deps.CRC32c]]
uuid = "8bf52ea8-c179-5cab-976a-9e18b702a9bc"
version = "1.11.0"

[[deps.CRlibm]]
deps = ["CRlibm_jll"]
git-tree-sha1 = "66188d9d103b92b6cd705214242e27f5737a1e5e"
uuid = "96374032-68de-5a5b-8d9e-752f78720389"
version = "1.0.2"

[[deps.CRlibm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e329286945d0cfc04456972ea732551869af1cfc"
uuid = "4e9b3aee-d8a1-5a3d-ad8b-7d824db253f0"
version = "1.0.1+0"

[[deps.Cairo]]
deps = ["Cairo_jll", "Colors", "Glib_jll", "Graphics", "Libdl", "Pango_jll"]
git-tree-sha1 = "71aa551c5c33f1a4415867fe06b7844faadb0ae9"
uuid = "159f3aea-2a34-519c-b102-8c37f9878175"
version = "1.1.1"

[[deps.CairoMakie]]
deps = ["CRC32c", "Cairo", "Cairo_jll", "Colors", "FileIO", "FreeType", "GeometryBasics", "LinearAlgebra", "Makie", "PrecompileTools"]
git-tree-sha1 = "47142129b1777e21da58cff265050b10d8560588"
uuid = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
version = "0.15.13"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "Libdl", "Pixman_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "1fa950ebc3e37eccd51c6a8fe1f92f7d86263522"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.18.7+0"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra"]
git-tree-sha1 = "12177ad6b3cad7fd50c8b3825ce24a99ad61c18f"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.26.1"
weakdeps = ["SparseArrays"]

    [deps.ChainRulesCore.extensions]
    ChainRulesCoreSparseArraysExt = "SparseArrays"

[[deps.CodecZstd]]
deps = ["TranscodingStreams", "Zstd_jll"]
git-tree-sha1 = "da54a6cd93c54950c15adf1d336cfd7d71f51a56"
uuid = "6b39b394-51ab-5f42-8807-6242bab2b4c2"
version = "0.8.7"

[[deps.ColorBrewer]]
deps = ["Colors", "JSON"]
git-tree-sha1 = "07da79661b919001e6863b81fc572497daa58349"
uuid = "a2cac450-b92f-5266-8821-25eda20663c8"
version = "0.4.2"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "b0fd3f56fa442f81e0a47815c92245acfaaa4e34"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.31.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "67e11ee83a43eb71ddc950302c53bf33f0690dfe"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.1"
weakdeps = ["StyledStrings"]

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "8b3b6f87ce8f65a2b4f857528fd8d70086cd72b1"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.11.0"
weakdeps = ["SpecialFunctions"]

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "37ea44092930b1811e666c3bc38065d7d87fcc74"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.13.1"

[[deps.CommonSolve]]
git-tree-sha1 = "99ee296f88c12485402e37c2fd025f95ae097637"
uuid = "38540f10-b2f7-11e9-35d8-d573e4eb0ff2"
version = "0.2.9"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "9d8a54ce4b17aa5bdce0ea5c34bc5e7c340d16ad"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.18.1"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.3.0+1"

[[deps.CompositionsBase]]
git-tree-sha1 = "802bb88cd69dfd1509f6670416bd4434015693ad"
uuid = "a33af91c-f02d-484b-be07-31d278c5ca2b"
version = "0.1.2"
weakdeps = ["InverseFunctions"]

    [deps.CompositionsBase.extensions]
    CompositionsBaseInverseFunctionsExt = "InverseFunctions"

[[deps.ComputePipeline]]
deps = ["Observables", "Preferences"]
git-tree-sha1 = "7bc84b769c1d384315e7b5c4ac03a6c303e6cf35"
uuid = "95dc2771-c249-4cd0-9c9f-1f3b4330693c"
version = "0.1.8"

[[deps.ConstructionBase]]
git-tree-sha1 = "b4b092499347b18a015186eae3042f72267106cb"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.6.0"
weakdeps = ["IntervalSets", "LinearAlgebra", "StaticArrays"]

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseLinearAlgebraExt = "LinearAlgebra"
    ConstructionBaseStaticArraysExt = "StaticArrays"

[[deps.Contour]]
git-tree-sha1 = "439e35b0b36e2e5881738abc8857bd92ad6ff9a8"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.3"

[[deps.CoreMath]]
deps = ["CoreMath_jll"]
git-tree-sha1 = "8c0480f92b1b1796239156a1b9b1bfb1b39499b4"
uuid = "b7a15901-be09-4a0e-87d2-2e66b0e09b5a"
version = "0.1.0"

[[deps.CoreMath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a692a4c1dc59a4b8bc0b6403876eb3250fde2bc3"
uuid = "a38c48d9-6df1-5ac9-9223-b6ada3b5572b"
version = "0.1.0+0"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["OrderedCollections"]
git-tree-sha1 = "6fb53a69613a0b2b68a0d12671717d307ab8b24e"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.19.5"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.DelaunayTriangulation]]
deps = ["AdaptivePredicates", "EnumX", "ExactPredicates", "Random"]
git-tree-sha1 = "c55f5a9fd67bdbc8e089b5a3111fe4292986a8e8"
uuid = "927a84f5-c5f4-47a5-9785-b46e178433df"
version = "1.6.6"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"
version = "1.11.0"

[[deps.Distributions]]
deps = ["AliasTables", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "Roots", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns"]
git-tree-sha1 = "cd3c5ac74cd3923c8945c6a81518c46abd0e73a3"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.129"

    [deps.Distributions.extensions]
    DistributionsChainRulesCoreExt = "ChainRulesCore"
    DistributionsDensityInterfaceExt = "DensityInterface"
    DistributionsSparseConnectivityTracerExt = "SparseConnectivityTracer"
    DistributionsTestExt = "Test"

    [deps.Distributions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DensityInterface = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
    SparseConnectivityTracer = "9f842d2f-2579-4b1d-911e-f412cf18a3f5"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.DocStringExtensions]]
git-tree-sha1 = "7442a5dfe1ebb773c29cc2962a8980f47221d76c"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.5"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.7.0"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e3290f2d49e661fbd94046d7e3726ffcb2d41053"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.4+0"

[[deps.EllipsisNotation]]
deps = ["PrecompileTools"]
git-tree-sha1 = "f5fe5be98d4f00cd2f94725b3ca2caa54970f314"
uuid = "da5c29d0-fa7d-589e-88eb-ea29b0a81949"
version = "1.10.1"

    [deps.EllipsisNotation.extensions]
    EllipsisNotationStaticArrayInterfaceExt = "StaticArrayInterface"

    [deps.EllipsisNotation.weakdeps]
    StaticArrayInterface = "0d7ed370-da01-4f52-bd93-41d350b8b718"

[[deps.EnumX]]
git-tree-sha1 = "c49898e8438c828577f04b92fc9368c388ac783c"
uuid = "4e289a0a-7415-4d19-859d-a7e5c4648b56"
version = "1.0.7"

[[deps.ExactPredicates]]
deps = ["IntervalArithmetic", "Random", "StaticArrays"]
git-tree-sha1 = "83231673ea4d3d6008ac74dc5079e77ab2209d8f"
uuid = "429591f6-91af-11e9-00e2-59fbe8cec110"
version = "2.2.9"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e6c4a6407a949e79a9d3f249bf49e6987c80e01f"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.8.2+0"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libva_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "7a58e45171b63ed4782f2d36fdee8713a469e6e0"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "8.1.2+0"

[[deps.FFTA]]
deps = ["AbstractFFTs", "DocStringExtensions", "LinearAlgebra", "MuladdMacro", "Primes", "Random", "Reexport"]
git-tree-sha1 = "65e55303b72f4a567a51b174dd2c47496efeb95a"
uuid = "b86e33f2-c0db-4aa1-a6e0-ab43e668529e"
version = "0.3.1"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "8e9c059d6857607253e837730dbf780b6b151acd"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.19.0"

    [deps.FileIO.extensions]
    HTTPExt = "HTTP"

    [deps.FileIO.weakdeps]
    HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"

[[deps.FilePaths]]
deps = ["FilePathsBase", "MacroTools", "Reexport"]
git-tree-sha1 = "a1b2fbfe98503f15b665ed45b3d149e5d8895e4c"
uuid = "8fc22ac5-c921-52a6-82fd-178b2807b824"
version = "0.9.0"

    [deps.FilePaths.extensions]
    FilePathsGlobExt = "Glob"
    FilePathsURIParserExt = "URIParser"
    FilePathsURIsExt = "URIs"

    [deps.FilePaths.weakdeps]
    Glob = "c27321d9-0574-5035-807b-f59d2c89b15c"
    URIParser = "30578b45-9adc-5946-b283-645ec420af67"
    URIs = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates"]
git-tree-sha1 = "3bab2c5aa25e7840a4b065805c0cdfc01f3068d2"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.24"
weakdeps = ["Mmap", "Test"]

    [deps.FilePathsBase.extensions]
    FilePathsBaseMmapExt = "Mmap"
    FilePathsBaseTestExt = "Test"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FillArrays]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "2f979084d1e13948a3352cf64a25df6bd3b4dca3"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.16.0"
weakdeps = ["PDMats", "SparseArrays", "StaticArrays", "Statistics"]

    [deps.FillArrays.extensions]
    FillArraysPDMatsExt = "PDMats"
    FillArraysSparseArraysExt = "SparseArrays"
    FillArraysStaticArraysExt = "StaticArrays"
    FillArraysStatisticsExt = "Statistics"

[[deps.FixedPointNumbers]]
deps = ["Random", "Statistics"]
git-tree-sha1 = "59af96b98217c6ef4ae0dfe065ac7c20831d1a84"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.6"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Zlib_jll"]
git-tree-sha1 = "f85dac9a96a01087df6e3a749840015a0ca3817d"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.17.1+0"

[[deps.Format]]
git-tree-sha1 = "9c68794ef81b08086aeb32eeaf33531668d5f5fc"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.7"

[[deps.FreeType]]
deps = ["CEnum", "FreeType2_jll"]
git-tree-sha1 = "907369da0f8e80728ab49c1c7e09327bf0d6d999"
uuid = "b38be410-82b0-50bf-ab77-7b57e271db43"
version = "4.1.1"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "70329abc09b886fd2c5d94ad2d9527639c421e3e"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.14.3+1"

[[deps.FreeTypeAbstraction]]
deps = ["BaseDirs", "ColorVectorSpace", "Colors", "FreeType", "GeometryBasics", "Mmap"]
git-tree-sha1 = "4ebb930ef4a43817991ba35db6317a05e59abd11"
uuid = "663a7486-cb36-511b-a19d-713bb74d65c9"
version = "0.10.8"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "7a214fdac5ed5f59a22c2d9a885a16da1c74bbc7"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.17+0"

[[deps.Gamma]]
git-tree-sha1 = "86f86b6168a016ed88e4ae4e64577b98c3b59e8e"
uuid = "a0844989-3bd2-4988-8bea-c9407ab0941b"
version = "1.1.0"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "LinearAlgebra", "PrecompileTools", "Random", "StaticArrays"]
git-tree-sha1 = "364685f5ffde25deb1bbcfd5bb278a5c6b7a9b37"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.5.11"

    [deps.GeometryBasics.extensions]
    ExtentsExt = "Extents"
    GeometryBasicsGeoInterfaceExt = "GeoInterface"
    IntervalSetsExt = "IntervalSets"

    [deps.GeometryBasics.weakdeps]
    Extents = "411431e0-e8b7-467b-b5e0-f676ba4f2910"
    GeoInterface = "cf35fbd7-0cd7-5166-be24-54bfbe79505f"
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"

[[deps.GettextRuntime_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll"]
git-tree-sha1 = "45288942190db7c5f760f59c04495064eedf9340"
uuid = "b0724c58-0f36-5564-988d-3bb0596ebc4a"
version = "0.22.4+0"

[[deps.Giflib_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6570366d757b50fabae9f4315ad74d2e40c0560a"
uuid = "59f7168a-df46-5410-90c8-f2779963d0ec"
version = "5.2.3+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "GettextRuntime_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "24f6def62397474a297bfcec22384101609142ed"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.86.3+0"

[[deps.Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "a641238db938fff9b2f60d08ed9030387daf428c"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.3"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "69ffb934a5c5b7e086a0b4fee3427db2556fba6e"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.16+0"

[[deps.GridLayoutBase]]
deps = ["GeometryBasics", "InteractiveUtils", "Observables"]
git-tree-sha1 = "93d5c27c8de51687a2c70ec0716e6e76f298416f"
uuid = "3955a311-db13-416c-9275-1d80ed98e5e9"
version = "0.11.2"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll"]
git-tree-sha1 = "f923f9a774fcf3f5cb761bfa43aeadd689714813"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "8.5.1+0"

[[deps.HashArrayMappedTries]]
git-tree-sha1 = "2eaa69a7cab70a52b9687c8bf950a5a93ec895ae"
uuid = "076d061b-32b6-4027-95e0-9a2c6f6d7e74"
version = "0.2.0"

[[deps.HypergeometricFunctions]]
deps = ["Gamma", "LinearAlgebra"]
git-tree-sha1 = "18d7deab5fb0440dc6a7b6993c5c27b25420de10"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.29"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "d1a86724f81bcd184a38fd284ce183ec067d71a0"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "1.0.0"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "0ee181ec08df7d7c911901ea38baf16f755114dc"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "1.0.0"

[[deps.ImageAxes]]
deps = ["AxisArrays", "ImageBase", "ImageCore", "Reexport", "SimpleTraits"]
git-tree-sha1 = "e12629406c6c4442539436581041d372d69c55ba"
uuid = "2803e5a7-5153-5ecf-9a86-9b4c37f5f5ac"
version = "0.6.12"

[[deps.ImageBase]]
deps = ["ImageCore", "Reexport"]
git-tree-sha1 = "eb49b82c172811fd2c86759fa0553a2221feb909"
uuid = "c817782e-172a-44cc-b673-b171935fbb9e"
version = "0.1.7"

[[deps.ImageCore]]
deps = ["ColorVectorSpace", "Colors", "FixedPointNumbers", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "PrecompileTools", "Reexport"]
git-tree-sha1 = "8c193230235bbcee22c8066b0374f63b5683c2d3"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.10.5"

[[deps.ImageIO]]
deps = ["FileIO", "IndirectArrays", "JpegTurbo", "LazyModules", "Netpbm", "OpenEXR", "PNGFiles", "QOI", "Sixel", "TiffImages", "UUIDs", "WebP"]
git-tree-sha1 = "696144904b76e1ca433b886b4e7edd067d76cbf7"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.6.9"

[[deps.ImageMetadata]]
deps = ["AxisArrays", "ImageAxes", "ImageBase", "ImageCore"]
git-tree-sha1 = "2a81c3897be6fbcde0802a0ebe6796d0562f63ec"
uuid = "bc367c6b-8a6b-528e-b4bd-a4b897500b49"
version = "0.9.10"

[[deps.Imath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "dcc8d0cd653e55213df9b75ebc6fe4a8d3254c65"
uuid = "905a6f67-0a94-5f89-b386-d35d92009cd1"
version = "3.2.2+0"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.Inflate]]
git-tree-sha1 = "d1b1b796e47d94588b3757fe84fbf65a5ec4a80d"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.5"

[[deps.IntegerMathUtils]]
git-tree-sha1 = "4c1acff2dc6b6967e7e750633c50bc3b8d83e617"
uuid = "18e54dd8-cb9d-406c-a71d-865a43cbb235"
version = "0.1.3"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "48922d06068130f87e43edef52382e6a94305ae6"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.16.3"

    [deps.Interpolations.extensions]
    InterpolationsForwardDiffExt = "ForwardDiff"
    InterpolationsUnitfulExt = "Unitful"

    [deps.Interpolations.weakdeps]
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.InterpolativeQTT]]
deps = ["LinearAlgebra", "TensorCrossInterpolation"]
git-tree-sha1 = "20f6915304ef568091166e81fed6a3434750df6c"
uuid = "87f1ea11-1d4d-47cb-b1d1-07788fc25290"
version = "0.1.3"

[[deps.IntervalArithmetic]]
deps = ["CRlibm", "CoreMath", "MacroTools", "OpenBLASConsistentFPCSR_jll", "Printf", "Random", "RoundingEmulator"]
git-tree-sha1 = "c3ee408ae340565f41699e3a3fa1053698c7626e"
uuid = "d1acc4aa-44c8-5952-acd4-ba5d80a2a253"
version = "1.0.10"

    [deps.IntervalArithmetic.extensions]
    IntervalArithmeticArblibExt = "Arblib"
    IntervalArithmeticDiffRulesExt = "DiffRules"
    IntervalArithmeticForwardDiffExt = "ForwardDiff"
    IntervalArithmeticIntervalSetsExt = "IntervalSets"
    IntervalArithmeticIrrationalConstantsExt = "IrrationalConstants"
    IntervalArithmeticLinearAlgebraExt = "LinearAlgebra"
    IntervalArithmeticRecipesBaseExt = "RecipesBase"
    IntervalArithmeticSparseArraysExt = "SparseArrays"

    [deps.IntervalArithmetic.weakdeps]
    Arblib = "fb37089c-8514-4489-9461-98f9c8763369"
    DiffRules = "b552c78f-8df3-52c6-915a-8e097449b14b"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    IrrationalConstants = "92d709cd-6900-40b7-9082-c6be49f344b6"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.IntervalSets]]
git-tree-sha1 = "79d6bd28c8d9bccc2229784f1bd637689b256377"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.14"

    [deps.IntervalSets.extensions]
    IntervalSetsRandomExt = "Random"
    IntervalSetsRecipesBaseExt = "RecipesBase"
    IntervalSetsStatisticsExt = "Statistics"

    [deps.IntervalSets.weakdeps]
    Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.InverseFunctions]]
git-tree-sha1 = "a779299d77cd080bf77b97535acecd73e1c5e5cb"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.17"
weakdeps = ["Dates", "Test"]

    [deps.InverseFunctions.extensions]
    InverseFunctionsDatesExt = "Dates"
    InverseFunctionsTestExt = "Test"

[[deps.IrrationalConstants]]
git-tree-sha1 = "b2d91fe939cae05960e760110b328288867b5758"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.6"

[[deps.Isoband]]
deps = ["isoband_jll"]
git-tree-sha1 = "f9b6d97355599074dc867318950adaa6f9946137"
uuid = "f1662d9f-8043-43de-a69a-05efc1cc6ff4"
version = "0.1.1"

[[deps.IterTools]]
git-tree-sha1 = "42d5f897009e7ff2cf88db414a389e5ed1bdd023"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.10.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7204148362dafe5fe6a273f855b8ccbe4df8173e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.8.0"

[[deps.JSON]]
deps = ["Dates", "Logging", "Parsers", "PrecompileTools", "StructUtils", "UUIDs", "Unicode"]
git-tree-sha1 = "c89d196f5ffb64bfbf80985b699ea913b0d2c211"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "1.6.1"

    [deps.JSON.extensions]
    JSONArrowExt = ["ArrowTypes"]

    [deps.JSON.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"

[[deps.JpegTurbo]]
deps = ["CEnum", "FileIO", "ImageCore", "JpegTurbo_jll", "TOML"]
git-tree-sha1 = "9496de8fb52c224a2e3f9ff403947674517317d9"
uuid = "b835a17e-a41a-41e7-81f0-2f016b05efe0"
version = "0.1.6"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1dae3057da6f2b9c857afef03177bbdc7c4afe92"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.2.0+0"

[[deps.JuliaSyntaxHighlighting]]
deps = ["StyledStrings"]
uuid = "ac6e5ff7-fb65-4e79-a425-ec3bc9c03011"
version = "1.12.0"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTA", "Interpolations", "StatsBase"]
git-tree-sha1 = "9eda8292dd3268b3b7ec9df21bbfac24e177ec52"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.12"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "059aabebaa7c82ccb853dd4a0ee9d17796f7e1bc"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.3+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "17b94ecafcfa45e8360a4fc9ca6b583b049e4e37"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "4.1.0+0"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "3ac157462e1e800777cc97d0eafd1bdb5356a470"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "21.1.8+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "dda21b8cbd6a6c40d9d02a73230f9d70fed6918c"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

[[deps.LazyModules]]
git-tree-sha1 = "a560dd966b386ac9ae60bdd3a3d3a326062d3c3e"
uuid = "8cdb02fc-e678-4876-92c5-9defec4f444e"
version = "0.3.1"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "OpenSSL_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.15.0+0"

[[deps.LibGit2]]
deps = ["LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "OpenSSL_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.9.0+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "OpenSSL_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.3+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c8da7e6a91781c41a863611c7e966098d783c57a"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.4.7+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "d36c21b9e7c172a44a10484125024495e2625ac0"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.7.1+1"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "be484f5c92fad0bd8acfef35fe017900b0b73809"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.18.0+0"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "cc3ad4faf30015a3e8094c9b5b7f19e85bdf2386"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.42.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "aebd334d06cee9f24cea70bd19a39749daf73881"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.7.3+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d620582b1f0cbe2c72dd1d5bd195a9ce73370ab1"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.42.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.12.0"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "bba2d9aa057d8f126415de240573e86a8f39d2a1"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "1.0.1"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.MacroTools]]
git-tree-sha1 = "1e0228a030642014fe5cfe68c2c0a818f9e3f522"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.16"

[[deps.Makie]]
deps = ["Animations", "Base64", "CRC32c", "ColorBrewer", "ColorSchemes", "ColorTypes", "Colors", "ComputePipeline", "Contour", "Dates", "DelaunayTriangulation", "Distributions", "DocStringExtensions", "Downloads", "FFMPEG_jll", "FileIO", "FilePaths", "FixedPointNumbers", "Format", "FreeType", "FreeTypeAbstraction", "GeometryBasics", "GridLayoutBase", "ImageBase", "ImageIO", "InteractiveUtils", "Interpolations", "IntervalSets", "InverseFunctions", "Isoband", "KernelDensity", "LaTeXStrings", "LinearAlgebra", "MacroTools", "Markdown", "MathTeXEngine", "Observables", "OffsetArrays", "PNGFiles", "Packing", "Pkg", "PlotUtils", "PolygonOps", "PrecompileTools", "Printf", "REPL", "Random", "RelocatableFolders", "Scratch", "ShaderAbstractions", "SignedDistanceFields", "SparseArrays", "Statistics", "StatsBase", "StatsFuns", "StructArrays", "TriplotBase", "UnicodeFun", "Unitful"]
git-tree-sha1 = "f2c8715d05bf10f9d4dc354e69dee30b6be53239"
uuid = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
version = "0.24.13"

    [deps.Makie.extensions]
    MakieDynamicQuantitiesExt = "DynamicQuantities"

    [deps.Makie.weakdeps]
    DynamicQuantities = "06fc5a27-2a28-4c7c-a15d-362465fb6821"

[[deps.MappedArrays]]
git-tree-sha1 = "0ee4497a4e80dbd29c058fcee6493f5219556f40"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.3"

[[deps.Markdown]]
deps = ["Base64", "JuliaSyntaxHighlighting", "StyledStrings"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MathTeXEngine]]
deps = ["AbstractTrees", "Automa", "DataStructures", "FreeTypeAbstraction", "GeometryBasics", "LaTeXStrings", "REPL", "RelocatableFolders", "UnicodeFun"]
git-tree-sha1 = "aa1078778be5a8e5259ff04fbc3d258b3e78d464"
uuid = "0a4f8689-d25c-4efe-a92b-7142dfc1aa53"
version = "0.6.9"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "7b86a5d4d70a9f5cdf2dacb3cbe6d251d1a61dbe"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.4"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2025.11.4"

[[deps.MuladdMacro]]
deps = ["PrecompileTools"]
git-tree-sha1 = "e8dcbeef032ba2f9051a44ac22b4e54e3a1a0099"
uuid = "46d2c3a1-f734-5fdb-9937-b9b9aeba4221"
version = "0.2.6"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "dbd2e8cd2c1c27f0b584f6661b4309609c5a685e"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.1.4"

[[deps.Netpbm]]
deps = ["FileIO", "ImageCore", "ImageMetadata"]
git-tree-sha1 = "d92b107dbb887293622df7697a2223f9f8176fcd"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.1.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.3.0"

[[deps.Observables]]
git-tree-sha1 = "7438a59546cf62428fc9d1bc94729146d37a7225"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.5.5"

[[deps.OffsetArrays]]
git-tree-sha1 = "117432e406b5c023f665fa73dc26e79ec3630151"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.17.0"
weakdeps = ["Adapt"]

    [deps.OffsetArrays.extensions]
    OffsetArraysAdaptExt = "Adapt"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "b6aa4566bb7ae78498a5e68943863fa8b5231b59"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.6+0"

[[deps.OpenBLASConsistentFPCSR_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "dafdaa3ff15f20ff703d909d3a6f574a5b0586f3"
uuid = "6cdc7f73-28fd-5e50-80fb-958a8875b1af"
version = "0.3.33+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.29+0"

[[deps.OpenEXR]]
deps = ["Colors", "FileIO", "OpenEXR_jll"]
git-tree-sha1 = "97db9e07fe2091882c765380ef58ec553074e9c7"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.3"

[[deps.OpenEXR_jll]]
deps = ["Artifacts", "Imath_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "0d621a4beb5e48d195f907c3c5b0bea285d9ff9d"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.4.13+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.7+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.4+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1346c9208249809840c91b26703912dff463d335"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.6+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e2bb57a313a74b8104064b7efd01406c0a50d2ff"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.6.1+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "94ba93778373a53bfd5a0caaf7d809c445292ff4"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.2"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.44.0+1"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "26766d4b5f1a410c218a19b85a672c6edb693c65"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.40"
weakdeps = ["StatsBase"]

    [deps.PDMats.extensions]
    StatsBaseExt = "StatsBase"

[[deps.PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "32b657a0d57c310a1a172bfc8c8cf68c5e674323"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.4.5"

[[deps.Packing]]
deps = ["GeometryBasics"]
git-tree-sha1 = "bc5bf2ea3d5351edf285a06b0016788a121ce92c"
uuid = "19eb6ba3-879d-56ad-ad62-d5c202156566"
version = "0.5.1"

[[deps.PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "0fac6313486baae819364c52b4f483450a9d793f"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.12"

[[deps.Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "58e5ed5e386e156bd93e86b305ebd21ac63d2d04"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.57.1+0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "32a4e09c5f29402573d673901778a0e03b0807b9"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.6"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "e4a6721aa89e62e5d4217c0b21bd714263779dda"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.46.4+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.12.1"
weakdeps = ["REPL"]

    [deps.Pkg.extensions]
    REPLExt = "REPL"

[[deps.PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "f9501cc0430a26bc3d156ae1b5b0c1b47af4d6da"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.3.3"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Random", "Reexport", "StableRNGs", "Statistics"]
git-tree-sha1 = "26ca162858917496748aad52bb5d3be4d26a228a"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.4.4"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "e189d0623e7ce9c37389bac17e80aac3b0302e75"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.83"

[[deps.PolygonOps]]
git-tree-sha1 = "77b3d3605fc1cd0b42d95eba87dfcd2bf67d5ff6"
uuid = "647866c9-e3ac-4575-94e7-e3d426903924"
version = "0.1.2"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "edbeefc7a4889f528644251bdb5fc9ab5348bc2c"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.3.4"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "8b770b60760d4451834fe79dd483e318eee709c4"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.5.2"

[[deps.Primes]]
deps = ["IntegerMathUtils"]
git-tree-sha1 = "25cdd1d20cd005b52fc12cb6be3f75faaf59bb9b"
uuid = "27ebfcd6-29c5-5fa9-bf4b-fb8fc14df3ae"
version = "0.5.7"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "fbb92c6c56b34e1a2c4c36058f68f332bec840e7"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.11.0"

[[deps.PtrArrays]]
git-tree-sha1 = "4fbbafbc6251b883f4d2705356f3641f3652a7fe"
uuid = "43287f4e-b6f4-7ad1-bb20-aadabca52c3d"
version = "1.4.0"

[[deps.QOI]]
deps = ["ColorTypes", "FileIO", "FixedPointNumbers"]
git-tree-sha1 = "472daaa816895cb7aee81658d4e7aec901fa1106"
uuid = "4b34888f-f399-49d4-9bb3-47ed5cae4e65"
version = "1.0.2"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "5e8e8b0ab68215d7a2b14b9921a946fee794749e"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.11.3"

    [deps.QuadGK.extensions]
    QuadGKEnzymeExt = "Enzyme"

    [deps.QuadGK.weakdeps]
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"

[[deps.QuanticsGrids]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae0eea18762a145ad9c10dc41f4f93cd6c88f48d"
uuid = "634c7f73-3e90-4749-a1bd-001b8efc642d"
version = "0.7.2"

[[deps.QuanticsTCI]]
deps = ["BitIntegers", "LinearAlgebra", "QuanticsGrids", "TensorCrossInterpolation"]
git-tree-sha1 = "18622427df3aa9c708fb9ddc1ce7bb8d8a816151"
uuid = "b11687fd-3a1c-4c41-97d0-998ab401d50e"
version = "0.7.3"

[[deps.REPL]]
deps = ["InteractiveUtils", "JuliaSyntaxHighlighting", "Markdown", "Sockets", "StyledStrings", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.RangeArrays]]
git-tree-sha1 = "b9039e93773ddcfc828f12aadf7115b4b4d225f5"
uuid = "b3c3ace0-ae52-54e7-9d0b-2c1406fd6b9d"
version = "0.3.2"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "1342a47bf3260ee108163042310d26f2be5ec90b"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.5"
weakdeps = ["FixedPointNumbers"]

    [deps.Ratios.extensions]
    RatiosFixedPointNumbersExt = "FixedPointNumbers"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "ffdaf70d81cf6ff22c2b6e733c900c3321cab864"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.1"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "62389eeff14780bfe55195b7204c0d8738436d64"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.1"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "5b3d50eb374cea306873b371d3f8d3915a018f0b"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.9.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "58cdd8fb2201a6267e1db87ff148dd6c1dbd8ad8"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.5.1+0"

[[deps.Roots]]
deps = ["Accessors", "CommonSolve", "Printf"]
git-tree-sha1 = "46d2af536e1afe8f04cf31a59298adadf96e99e6"
uuid = "f2b01f46-fcfa-551c-844a-d8ac1e96c665"
version = "3.0.2"

    [deps.Roots.extensions]
    RootsChainRulesCoreExt = "ChainRulesCore"
    RootsForwardDiffExt = "ForwardDiff"
    RootsIntervalRootFindingExt = "IntervalRootFinding"
    RootsSymPyExt = "SymPy"
    RootsSymPyPythonCallExt = "SymPyPythonCall"
    RootsUnitfulExt = "Unitful"

    [deps.Roots.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    IntervalRootFinding = "d2bf35a9-74e0-55ec-b149-d360ff49b807"
    SymPy = "24249f21-da20-56a4-8eb1-6a02cf4ae2e6"
    SymPyPythonCall = "bc8888f7-b21e-4b7c-a06a-5d9c9496438c"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.RoundingEmulator]]
git-tree-sha1 = "40b9edad2e5287e05bd413a38f61a8ff55b9557b"
uuid = "5eaf0fd0-dfba-4ccb-bf02-d820a40db705"
version = "0.2.1"

[[deps.RustToolChain]]
deps = ["Downloads", "Pkg", "Scratch"]
git-tree-sha1 = "7d13264778421745698ab33453032c0f7a5f137b"
uuid = "e9dc52e2-edb8-4742-9783-5e542d30dbb5"
version = "0.1.8"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SIMD]]
deps = ["PrecompileTools"]
git-tree-sha1 = "e24dc23107d426a096d3eae6c165b921e74c18e4"
uuid = "fdea26ae-647d-5447-a871-4b548cad5224"
version = "3.7.2"

[[deps.ScopedValues]]
deps = ["HashArrayMappedTries", "Logging"]
git-tree-sha1 = "67a144433c4ce877ee6d1ada69a124d6b1ecf7be"
uuid = "7e506255-f358-4e82-b7e4-beb19740aa63"
version = "1.6.2"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "9b81b8393e50b7d4e6d0a9f14e192294d3b7c109"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.3.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.ShaderAbstractions]]
deps = ["ColorTypes", "FixedPointNumbers", "GeometryBasics", "LinearAlgebra", "Observables", "StaticArrays"]
git-tree-sha1 = "818554664a2e01fc3784becb2eb3a82326a604b6"
uuid = "65257c39-d410-5151-9873-9b3e5be5013e"
version = "0.5.0"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"
version = "1.11.0"

[[deps.SignedDistanceFields]]
deps = ["Statistics"]
git-tree-sha1 = "3949ad92e1c9d2ff0cd4a1317d5ecbba682f4b92"
uuid = "73760f76-fbc4-59ce-8f25-708e95d2df96"
version = "0.4.1"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "7ddb0b49c109481b046972c0e4ab02b2127d6a75"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.6"

[[deps.Sixel]]
deps = ["Dates", "FileIO", "ImageCore", "IndirectArrays", "OffsetArrays", "REPL", "libsixel_jll"]
git-tree-sha1 = "0494aed9501e7fb65daba895fb7fd57cc38bc743"
uuid = "45858cf5-a6b0-47a3-bbea-62219f50df47"
version = "0.1.5"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "13cd91cc9be159e3f4d95b857fa2aa383b53772a"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.3"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.12.0"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "6547cbdd8ce32efba0d21c5a40fa96d1a3548f9f"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.8.0"
weakdeps = ["ChainRulesCore"]

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

[[deps.StableRNGs]]
deps = ["Random"]
git-tree-sha1 = "4f96c596b8c8258cc7d3b19797854d368f243ddc"
uuid = "860ef19b-820b-49d6-a774-d7a799459cd3"
version = "1.0.4"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "be1cf4eb0ac528d96f5115b4ed80c26a8d8ae621"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.2"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "246a8bb2e6667f832eea063c3a56aef96429a3db"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.18"
weakdeps = ["ChainRulesCore", "Statistics"]

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6ab403037779dae8c514bad259f32a447262455a"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.4"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"
weakdeps = ["SparseArrays"]

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "178ed29fd5b2a2cfc3bd31c13375ae925623ff36"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.8.0"

[[deps.StatsBase]]
deps = ["AliasTables", "DataAPI", "DataStructures", "IrrationalConstants", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "e4d7a1a0edc20af42689ea6f4f3587a2175d50ee"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.12"

[[deps.StatsFuns]]
deps = ["HypergeometricFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "770240df9a3b8888065046948f7a09b4e0f997d5"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "2.2.0"
weakdeps = ["ChainRulesCore", "InverseFunctions"]

    [deps.StatsFuns.extensions]
    StatsFunsChainRulesCoreExt = "ChainRulesCore"
    StatsFunsInverseFunctionsExt = "InverseFunctions"

[[deps.StructArrays]]
deps = ["ConstructionBase", "DataAPI", "Tables"]
git-tree-sha1 = "ad8002667372439f2e3611cfd14097e03fa4bccd"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.7.3"

    [deps.StructArrays.extensions]
    StructArraysAdaptExt = "Adapt"
    StructArraysGPUArraysCoreExt = ["GPUArraysCore", "KernelAbstractions"]
    StructArraysLinearAlgebraExt = "LinearAlgebra"
    StructArraysSparseArraysExt = "SparseArrays"
    StructArraysStaticArraysExt = "StaticArrays"

    [deps.StructArrays.weakdeps]
    Adapt = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    KernelAbstractions = "63c18a36-062a-441e-b654-da1e3ab1ce7c"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.StructUtils]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "82bee338d650aa515f31866c460cb7e3bcef90b8"
uuid = "ec057cc2-7a8d-4b58-b3b3-92acb9f63b42"
version = "2.8.2"

    [deps.StructUtils.extensions]
    StructUtilsMeasurementsExt = ["Measurements"]
    StructUtilsStaticArraysCoreExt = ["StaticArraysCore"]
    StructUtilsTablesExt = ["Tables"]

    [deps.StructUtils.weakdeps]
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    StaticArraysCore = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
    Tables = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.8.3+2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "0f38a06c83f0007bbab3cf911262841c9a0f07e0"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.13.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Tensor4all]]
deps = ["InterpolativeQTT", "Libdl", "LinearAlgebra", "QuanticsGrids", "QuanticsTCI", "Random", "RustToolChain", "ScopedValues", "TensorCrossInterpolation"]
git-tree-sha1 = "2e73e896d4969e591c5c2c8f959ea0dea9e35241"
repo-rev = "main"
repo-url = "https://github.com/tensor4all/Tensor4all.jl.git"
uuid = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
version = "0.1.0"

    [deps.Tensor4all.extensions]
    Tensor4allHDF5Ext = ["HDF5"]

    [deps.Tensor4all.weakdeps]
    HDF5 = "f67ccb44-e63f-5c2f-98bd-6dc0ccc4ba2f"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.TensorCrossInterpolation]]
deps = ["BitIntegers", "EllipsisNotation", "LinearAlgebra", "QuadGK", "Random"]
git-tree-sha1 = "8a51c1019f5d49af4a5466df971ff4325f95d789"
uuid = "b261b2ec-6378-4871-b32e-9173bb050604"
version = "0.9.19"

    [deps.TensorCrossInterpolation.extensions]
    TCIITensorConversion = ["ITensors", "ITensorMPS"]

    [deps.TensorCrossInterpolation.weakdeps]
    ITensorMPS = "0d1a4710-d33b-49a5-8f18-73bdf49b47e2"
    ITensors = "9136182c-28ba-11e9-034c-db9fb085ebd5"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.TiffImages]]
deps = ["CodecZstd", "ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "Mmap", "OffsetArrays", "PkgVersion", "PrecompileTools", "ProgressMeter", "SIMD", "UUIDs"]
git-tree-sha1 = "9ca5f1f2d42f80df4b8c9f6ab5a64f438bbd9976"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.11.9"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.Tricks]]
git-tree-sha1 = "311349fd1c93a31f783f977a71e8b062a57d4101"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.13"

[[deps.TriplotBase]]
git-tree-sha1 = "4d4ed7f294cda19382ff7de4c137d24d16adc89b"
uuid = "981d1d27-644d-49a2-9326-4793e63143c3"
version = "0.1.0"

[[deps.URIs]]
git-tree-sha1 = "bef26fb046d031353ef97a82e3fdb6afe7f21b1a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.6.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "57e1b2c9de4bd6f40ecb9de4ac1797b81970d008"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.28.0"

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    ForwardDiffExt = "ForwardDiff"
    InverseFunctionsUnitfulExt = "InverseFunctions"
    LatexifyExt = ["Latexify", "LaTeXStrings"]
    NaNMathExt = "NaNMath"
    PrintfExt = "Printf"

    [deps.Unitful.weakdeps]
    ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"
    LaTeXStrings = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
    Latexify = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
    NaNMath = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
    Printf = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.WebP]]
deps = ["CEnum", "ColorTypes", "FileIO", "FixedPointNumbers", "ImageCore", "libwebp_jll"]
git-tree-sha1 = "aa1ca3c47f119fbdae8770c29820e5e6119b83f2"
uuid = "e3aaa7dc-3e4b-44e0-be63-ffb868ccd7c1"
version = "0.1.3"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "248a7031b3da79a127f14e5dc5f417e26f9f6db7"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "1.1.0"

[[deps.XZ_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "b29c22e245d092b8b4e8d3c09ad7baa586d9f573"
uuid = "ffd25f8a-64ca-5728-b0f7-c24cf3aae800"
version = "5.8.3+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "808090ede1d41644447dd5cbafced4731c56bd2f"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.13+0"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "aa1261ebbac3ccc8d16558ae6799524c450ed16b"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.13+0"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "52858d64353db33a56e13c341d7bf44cd0d7b309"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.6+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "1a4a26870bf1e5d26cd585e38038d399d7e65706"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.8+0"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "75e00946e43621e09d431d9b95818ee751e6b2ef"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "6.0.2+0"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "7ed9347888fac59a618302ee38216dd0379c480d"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.12+0"

[[deps.Xorg_libpciaccess_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "58972370b81423fc546c56a60ed1a009450177c3"
uuid = "a65dc6b1-eb27-53a1-bb3e-dea574b5389e"
version = "0.19.0+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXau_jll", "Xorg_libXdmcp_jll"]
git-tree-sha1 = "bfcaf7ec088eaba362093393fe11aa141fa15422"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.17.1+0"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a63799ff68005991f9d9491b6e95bd3478d783cb"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.6.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.3.1+2"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "446b23e73536f84e8037f5dce465e92275f6a308"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.7+1"

[[deps.isoband_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51b5eeb3f98367157a7a12a1fb0aa5328946c03c"
uuid = "9a68df92-36a6-505f-a73e-abb412b6bfb4"
version = "0.2.3+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "850b06095ee71f0135d644ffd8a52850699581ed"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.13.3+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "125eedcb0a4a0bba65b657251ce1d27c8714e9d6"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.17.4+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.15.0+0"

[[deps.libdrm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libpciaccess_jll"]
git-tree-sha1 = "63aac0bcb0b582e11bad965cef4a689905456c03"
uuid = "8e53e030-5e6c-5a89-a30b-be5b7263a166"
version = "2.4.125+1"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "646634dd19587a56ee2f1199563ec056c5f228df"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.4+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "e51150d5ab85cee6fc36726850f0e627ad2e4aba"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.58+0"

[[deps.libsixel_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "libpng_jll"]
git-tree-sha1 = "c1733e347283df07689d71d61e14be986e49e47a"
uuid = "075b6546-f08a-558a-be8f-8157d0f608a5"
version = "1.10.5+0"

[[deps.libva_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll", "Xorg_libXext_jll", "Xorg_libXfixes_jll", "libdrm_jll"]
git-tree-sha1 = "7dbf96baae3310fe2fa0df0ccbb3c6288d5816c9"
uuid = "9a156e7d-b971-5f62-b2c9-67348b8fb97c"
version = "2.23.0+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll"]
git-tree-sha1 = "11e1772e7f3cc987e9d3de991dd4f6b2602663a5"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.8+0"

[[deps.libwebp_jll]]
deps = ["Artifacts", "Giflib_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libglvnd_jll", "Libtiff_jll", "libpng_jll"]
git-tree-sha1 = "4e4282c4d846e11dce56d74fa8040130b7a95cb3"
uuid = "c5f90fcd-3b7e-5836-afba-fc50a0988cb2"
version = "1.6.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.64.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.7.0+0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "14cc7083fc6dff3cc44f2bc435ee96d06ed79aa7"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "10164.0.1+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e7b67590c14d487e734dcb925924c5dc43ec85f3"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "4.1.0+0"
"""

# ╔═╡ Cell order:
# ╟─221e37cb-1bbc-4585-9992-7dd486c1f159
# ╟─b83dc06a-c0c9-5c30-a4c8-5ae07c1ba561
# ╟─93c6c466-760e-5843-88bc-9266a98d9ab4
# ╟─7f0ded6b-184b-545f-952e-b53de2cef4b5
# ╟─a7c0ce88-5584-5a4d-8bba-4f15fa6aeba7
# ╟─0f12df16-20bf-4ac7-99af-0e13ff61b8bd
# ╠═1ef31b99-117d-54d3-931c-3e1cda027d83
# ╟─2862c07e-7e3f-4f8a-9076-6d3c1fd0a411
# ╠═b65f451a-0c7b-4675-a71c-9f112df76c95
# ╟─0eacff1b-6e8d-59f8-808b-a4ca2c68dc16
# ╟─88e3a383-7c83-595d-8b7b-699f6a69ccea
# ╟─5e41f526-dd86-4682-a569-3f35e49683e5
# ╠═8cffdc59-2660-506d-a9e6-267dd2250e92
# ╟─80a13a91-566e-4869-b397-c290b50221c4
# ╠═cde5e86f-432e-42f8-95b8-6f948beddf4e
# ╟─f4a7bc84-1e20-5638-9a52-527607fb9f83
# ╟─10b26057-cb7b-5c69-a51a-55cb3e17ed47
# ╠═025cb26b-477e-5e12-8945-bc236f151792
# ╟─e109293a-de41-5aff-915f-b91a96720cdf
# ╠═65cf60d4-84cc-45ba-af91-d27549cd852c
# ╠═22e1915e-c52a-42e6-89a7-61a0f6e0bf86
# ╠═2a4aae00-32d8-43c8-adc8-6333eed52844
# ╟─d3259e1e-5b5e-45c4-9156-6c54edd2251e
# ╟─4b5781f4-4d5f-5b54-b0bb-19b07a4c78f8
# ╟─36481eff-5952-5590-95f0-5d1c521f7773
# ╠═960e0962-a986-5290-868c-86fcc649f051
# ╟─a966cc55-b677-4907-95be-842c05ece344
# ╟─bd147b4a-8af8-4dc6-99bb-a4669517ac7d
# ╟─467662a2-714f-5f5f-90e2-ea68107f8b5f
# ╠═2b1b3e2c-8c17-5b6c-9e49-235fb4bab685
# ╟─c7ae2e42-750b-4b0d-aa90-69c710a5496d
# ╟─aa96fd3f-d0b0-5f0a-95f6-429d8bb949a4
# ╟─f377507b-b7cb-5007-8506-0bde001733aa
# ╟─97e5efad-4b37-5634-9534-02e0160ef250
# ╠═07f62519-48d2-51e7-b1ec-964bc77f0d30
# ╟─50cac4bc-1360-4188-86b8-ee3528f0b219
# ╟─2bb42e4e-bc70-45b4-aa5b-2dce344a48d3
# ╠═166688ff-4bf7-566a-b9cf-1db5f10be350
# ╟─0c7ee121-198c-451f-ad8d-fd47d49c8bb4
# ╟─8f734d50-8f83-471f-a4c6-c9df2a2d9148
# ╠═f8d60ab7-6865-4e39-9eb5-a36e45ff724d
# ╟─ab1548bb-5c53-4957-a5fd-28edc8cc20d2
# ╟─63701385-bbf1-40d1-b796-9a2f25d1960b
# ╠═6b8fda34-b6db-4a82-8912-741ad75f5345
# ╟─7c783455-d51a-4d1e-b928-8bb0a965270b
# ╟─bfd5f0b8-04fb-4f34-a3e5-32b818e418f6
# ╠═6eb9cb0d-1900-47d0-9cdb-fb6df119822f
# ╟─8e164011-48bb-4266-970c-d2aca2cd34c9
# ╟─ec091b7e-9e28-45ff-880a-3136dc3bf4e9
# ╠═f2f7f849-9f7c-468c-944e-80300b720b72
# ╟─e7a595ea-664c-4182-8b37-fc8c6e7913d8
# ╟─47bbf65c-936c-4859-a409-7472bb5300fe
# ╟─d7530644-a61e-4a23-9cfc-d7e236509d35
# ╟─f16fd69a-0114-4856-853f-edcb2f54605a
# ╟─ec013294-94ca-5c62-8bed-689945ba19cc
# ╟─5421cb93-e382-57e2-af6d-9997c5f6b3fc
# ╟─2d069f89-fd41-4f98-89a6-b54895c32570
# ╟─4ed1a17d-1658-4c1e-9998-9ac909b2d5a1
# ╟─d56b3fd1-6f0e-4754-a3ef-5518da05eea9
# ╟─f4a31e4b-6d4d-41af-a23b-f3ed7f20b69b
# ╟─6ffb3623-3b15-4874-a399-7f1dcfa50b49
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

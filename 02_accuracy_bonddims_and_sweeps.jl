### A Pluto.jl notebook ###
# v0.20.24

#> [frontmatter]
#> order = "2"
#> site_name = "Tensor4all.jl Tutorials"
#> title = "Diagnosing QTT accuracy and rank"
#> date = "2026-06-26"
#> tags = ["tensor4all", "qtt", "diagnostics", "accuracy", "bond-dimensions"]
#> description = "Diagnose QTT runs by reading grid error, cap saturation, bond-dimension profiles, and function structure."
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

# ╔═╡ 4b569f29-57e2-55f3-9ee1-5697277378dc
begin
	using Tensor4all
	import Tensor4all.QuanticsGrids as QG
	import Tensor4all.QuanticsTCI as QTCI
	import Tensor4all.TensorNetworks as TN
	import Tensor4all.SimpleTT as STT
end

# ╔═╡ f8e364d0-2c19-4c75-8f69-f4f18d25f4d9
begin
	import Pkg
	if !isfile(Tensor4all.backend_library_path())
		Pkg.build("Tensor4all")
	end
	Tensor4all.require_backend()
end

# ╔═╡ 3c326c32-1958-4910-a06a-ebac2d48a2ed
begin
	using CairoMakie
	using PlutoUI
	using LaTeXStrings
	plot_fontsize = 20
end

# ╔═╡ 7af2bd01-e768-5d12-ae2d-f9d3bb79d7f7
md"""
# 02. Diagnosing QTT accuracy and rank

Use the Tensor4all workflow from Notebook 01 to learn how to diagnose a QTT run from a few concrete signals.

> **Big picture**
> A useful QTT diagnostic asks: did the approximation match the sampled grid, did the rank cap bind, where did the bond dimensions grow, and is the target function itself rank-demanding?
"""

# ╔═╡ dd765b4e-c03d-56b5-8937-3412c415bb15
md"""
You will build one baseline QTT, then change one thing at a time. After each run, read the same diagnostic signals and decide what you would adjust next.
"""

# ╔═╡ 10ed0dfd-bff0-4d5f-bc3f-c79f5a25670a
md"""
We use the Tensor4all packages below.
"""

# ╔═╡ 2cbcc7a1-4d2d-4787-ad19-51e2f28d0f6c
md"""
Alias map: `QG` = quantics grids, `QTCI` = quantics cross interpolation, `STT` = simple tensor trains, and `TN` = indexed tensor-network objects.
"""

# ╔═╡ f0aa6a75-e7d3-55e2-98ee-2a28c7159f48
md"""
## Baseline diagnostic run
"""

# ╔═╡ fa666941-c709-5873-a566-20b7f70db22f
md"""
We start with one structured target function and one fixed parameter set. This gives us the first diagnostic readout: measured grid error, observed rank, cap saturation, and the bond-dimension profile.
"""

# ╔═╡ dcb8301e-66bb-4e61-8c92-5d2a88d15170
md"""
```math
f(x) = \sin(250x^2 + 50x).
```

This target is a single chirp: the local frequency increases across the interval. It is simple to write down and still creates a nontrivial QTT rank.
"""

# ╔═╡ 035c29a2-1724-5eb8-8c80-859f71fc1760
begin
	chirp_quadratic_coefficient = 250
	chirp_linear_coefficient = 50
	target_function(x) = sin(chirp_quadratic_coefficient * x^2 + chirp_linear_coefficient * x)
end

# ╔═╡ d82d1c6b-dc03-566b-9c44-260c08234e49
"""
	measure_qtt(f, grid; tolerance, maxbonddim, maxiter, value_type=Float64)

Build a QTT from `f` on `grid` and measure its accuracy and bond dimensions.
Returns a named tuple with `qtt`, `bond_dims`, `values`, `xvals`, `max_abs_error`, and `max_bond_dim`.
"""
function measure_qtt(f, grid; tolerance, maxbonddim, maxiter, value_type=Float64)
    npoints = only(grid.discretegrid.maxgrididx)
    xvals = [QG.grididx_to_origcoord(grid, i) for i in 1:npoints]
    qtt, _, _ = QTCI.quanticscrossinterpolate(
        value_type, f, grid;
        tolerance, maxbonddim, maxiter,
    )
    simple_tt = STT.TensorTrain(qtt.tci)
    sites = [Tensor4all.Index(2; tags=["x", "bit=$i"]) for i in 1:length(simple_tt)]
    indexed_tt = TN.TensorTrain(simple_tt, sites)
    bond_dims = TN.linkdims(indexed_tt)
    values = [real(qtt(i)) for i in 1:npoints]
    exact = f.(xvals)
    max_abs_error = maximum(abs, exact .- values)
    (; qtt, bond_dims, values, xvals, max_abs_error, max_bond_dim=maximum(bond_dims))
end

# ╔═╡ e7a19faf-5978-4ce0-b117-6bea6fe51c61
begin
	R = 12
	grid = QG.DiscretizedGrid{1}(R, 0.0, 1.0; includeendpoint=false)

	tolerance = 1e-12
	maxbonddim = 64
	maxiter = 700
end

# ╔═╡ d166a2f5-505c-4f97-baf7-fb3b401a2493
begin
	baseline = measure_qtt(target_function, grid; tolerance, maxbonddim, maxiter)
	npoints = length(baseline.xvals)
	xvals = baseline.xvals
	qtt_values = baseline.values
	bond_dims = baseline.bond_dims
	max_abs_error = baseline.max_abs_error
end

# ╔═╡ 77eda426-95a5-4a13-8703-4aa27684201f
Markdown.parse("""
Baseline run:

| quantity | value |
|:--|:--|
| bit depth `R` | `$(R)` |
| grid points | `$(npoints)` on `[0, 1)` |
| tolerance | `$(tolerance)` |
| `maxbonddim` | `$(maxbonddim)` |
| bond dimensions | `$(bond_dims)` |
| maximum absolute error | `$(round(max_abs_error; sigdigits=3))` |
""")

# ╔═╡ ac718dfe-5596-549b-a19c-b93fe62dadc4
begin
	worst_case_bond_dims(num_bonds; base=2) =
	    [base^min(k, num_bonds + 1 - k) for k in 1:num_bonds]

	fig = Figure(size=(1050, 500), fontsize=plot_fontsize)

	ax1 = Axis(
	    fig[1, 1],
	    xgridvisible=false,
	    ygridvisible=false,
	    xlabel=L"x",
	    ylabel="value",
	    title="Target function on a quantics grid",
	)
	xs = range(first(xvals), last(xvals), length=3000)
	lines!(ax1, xs, target_function.(xs);
	    color=:black, linewidth=2, label=L"\mathrm{chirp\ target}")
	scatterlines!(ax1, xvals, qtt_values;
	    color=:deepskyblue4, linewidth=1.5, markersize=7,
	    label=L"\mathrm{QTT\ samples}")
	Legend(fig[2, 1], ax1, orientation=:horizontal, framevisible=false)

	ax2 = Axis(
	    fig[1, 2],
	    xgridvisible=false,
	    ygridvisible=false,
	    xlabel="bond link",
	    ylabel="bond dimension",
	    title="Bond dimensions at R = $R",
	    yscale=log2,
	)
	bond_index = 1:length(bond_dims)
	scatterlines!(ax2, bond_index, bond_dims;
	    color=:goldenrod2, linewidth=2, markersize=7,
	    label=L"\mathrm{bond\ dimension}")
	lines!(ax2, bond_index, worst_case_bond_dims(length(bond_dims));
	    color=:gray60, linewidth=2,
	    linestyle=Linestyle([0, 10, 15]),
	    label=L"\mathrm{worst\ case}")
	Legend(fig[2, 2], ax2, orientation=:horizontal, framevisible=false)

	fig
end

# ╔═╡ 76e2892b-5189-526a-9970-9d1dff9479f7
Markdown.parse("""
**Diagnostic readout**

| signal | observed value | diagnostic conclusion |
|:--|:--|:--|
| measured grid error | `$(round(max_abs_error; sigdigits=3))` | The QTT reproduces the sampled grid values to a small absolute error. |
| observed max bond dimension | `$(maximum(bond_dims))`, with cap `$(maxbonddim)` | The configured cap is not active in this baseline run. |
| bond profile | `$(bond_dims)` | The observed ranks are smaller than the worst-case profile shown above. |
""")

# ╔═╡ bbda78d3-5175-5ec1-b442-4b4afb0587be
md"""
## Sweep over R
"""

# ╔═╡ 19a147d7-f1fe-56cd-bc21-3169dcc24cde
md"""
Now vary only `R` for the same chirp target. This broad sweep includes very coarse sampled problems as well as well-resolved ones. A larger `R` changes the discrete problem by adding grid points and quantics sites; the diagnostic question is how the internal rank changes as that sampled problem grows.
"""

# ╔═╡ 6209b48b-a255-5520-8fe3-68a310691f21
begin
	R_values = 4:15
	R_results = map(R_values) do R
		grid_R = QG.DiscretizedGrid{1}(R, 0.0, 1.0; includeendpoint=false)
		measure_qtt(target_function, grid_R; tolerance, maxbonddim, maxiter)
	end
	R_max_bond_dims = getproperty.(R_results, :max_bond_dim)
end

# ╔═╡ 61fa8f23-c129-5a15-b711-8ba6c901badb
begin
	fig_R = Figure(size=(1050, 540), fontsize=plot_fontsize)
	line_plots = []
	palette = cgrad(:viridis, length(R_values), categorical=true)

	axR1 = Axis(
	    fig_R[1, 1],
	    xgridvisible=false,
	    ygridvisible=false,
	    xlabel=L"R",
	    ylabel="observed max bond dimension",
	    title="Peak rank versus R",
	    yscale=log2,
	    titlesize=plot_fontsize,
	)
	scatterlines!(axR1, R_values, R_max_bond_dims;
	    color=:goldenrod2, linewidth=2.5, markersize=9)

	axR2 = Axis(
	    fig_R[1, 2],
	    xgridvisible=false,
	    ygridvisible=false,
	    xlabel="bond link",
	    ylabel="bond dimension",
	    title="Bond dimension profiles for different R",
	    yscale=log2,
	    titlesize=plot_fontsize,
	)
	for (i, (R, result)) in enumerate(zip(R_values, R_results))
	    bond_profile = result.bond_dims
	    bond_idx = 1:length(bond_profile)
	    p = scatterlines!(axR2, bond_idx, bond_profile;
	        color=palette[i], linewidth=2.5, markersize=6,
	        label=L"R = %$R")
	    push!(line_plots, p)
	end
	worst = worst_case_bond_dims(length(last(R_results).bond_dims))
	p_worst_R = lines!(axR2, 1:length(worst), worst;
	    color=:gray60, linewidth=2.5,
	    linestyle=Linestyle([0, 10, 15]),
	    label=L"\mathrm{worst\ case}")
	Legend(
	    fig_R[2, :],
	    vcat(line_plots, [p_worst_R]),
	    vcat([L"R = %$R" for R in R_values], [L"\mathrm{worst\ case}"]);
	    framevisible=false,
	    orientation=:horizontal,
	    labelsize=plot_fontsize,
	    patchsize=(24, 16),
	    nbanks=2,
	)

	fig_R
end

# ╔═╡ 88abb671-c20b-4cba-82c4-a72d8a2a3cbc
md"""
## Warning: a QTT can only learn the grid you give it

A small sampled-grid error does **not** prove that the grid resolves the continuous function. To isolate that point, use a separate high-frequency cosine:

```math
f_{\mathrm{warn}}(x) = \cos(4000x).
```
"""

# ╔═╡ b03b3fc4-d81a-4980-92de-c6435f5e2d91
begin
	warning_angular_frequency = 4000
	warning_function(x) = cos(warning_angular_frequency * x)
	R_underresolved = 9
	R_resolved = 13

	underresolved_grid = QG.DiscretizedGrid{1}(R_underresolved, 0.0, 1.0; includeendpoint=true)
	resolved_grid = QG.DiscretizedGrid{1}(R_resolved, 0.0, 1.0; includeendpoint=true)

	underresolved = measure_qtt(warning_function, underresolved_grid; tolerance, maxbonddim, maxiter)
	resolved = measure_qtt(warning_function, resolved_grid; tolerance, maxbonddim, maxiter)
end

# ╔═╡ 0cd76892-2332-5d7e-a19c-936bddf2078e
md"""
## Diagnose cap saturation with `maxbonddim`
"""

# ╔═╡ d0140d2e-d183-51db-abf1-760d27bb0fe1
md"""
Now vary only `maxbonddim`, the artificial cap on the internal rank. The diagnostic question is whether the cap is preventing the QTT from reaching the rank it wants.
"""

# ╔═╡ becd693f-1553-5a3a-9e3c-0567d4c8f79f
begin
	maxbonddim_values = 1:32
	maxbonddim_results = map(maxbonddim_values) do maxbonddim
		measure_qtt(target_function, grid; tolerance, maxbonddim, maxiter)
	end
	maxbonddim_errors = getproperty.(maxbonddim_results, :max_abs_error)
	maxbonddim_observed = getproperty.(maxbonddim_results, :max_bond_dim)
	maxbonddim_saturated = maxbonddim_observed .>= collect(maxbonddim_values)
	first_nonbinding_index = findfirst(.!maxbonddim_saturated)
	first_nonbinding_cap = maxbonddim_values[first_nonbinding_index]
	plateau_rank = maxbonddim_observed[first_nonbinding_index]
end

# ╔═╡ 2abfa82d-6d8e-5813-a966-3dad448e0434
begin
	fig_mbd = Figure(size=(1050, 540), fontsize=plot_fontsize)

	axmbd1 = Axis(
	    fig_mbd[1, 1],
	    xgridvisible=false,
	    ygridvisible=false,
	    xlabel="maxbonddim",
	    ylabel="max abs error",
	    title="Error versus bond cap",
	    yscale=log10,
	    titlesize=plot_fontsize,
	)
	scatterlines!(axmbd1, maxbonddim_values, maxbonddim_errors;
	    color=:deepskyblue4, linewidth=2.5, markersize=7,
	    label=L"\mathrm{max\ abs\ error}")
	Legend(fig_mbd[2, 1], axmbd1, orientation=:horizontal, framevisible=false)

	axmbd2 = Axis(
	    fig_mbd[1, 2],
	    xgridvisible=false,
	    ygridvisible=false,
	    xlabel="maxbonddim",
	    ylabel="bond dimension",
	    title="Observed rank versus bond cap",
	    yscale=log2,
	    titlesize=plot_fontsize,
	)
	scatterlines!(axmbd2, maxbonddim_values, maxbonddim_observed;
	    color=:goldenrod2, linewidth=2.5, markersize=7,
	    label=L"\mathrm{observed\ max\ bond\ dimension}")
	lines!(axmbd2, maxbonddim_values, maxbonddim_values;
	    color=:gray60, linewidth=2,
	    linestyle=Linestyle([0, 10, 15]),
	    label=L"\mathrm{requested\ cap}")
	Legend(fig_mbd[2, 2], axmbd2, orientation=:horizontal, framevisible=false)

	fig_mbd
end

# ╔═╡ 52fc64af-8c48-5ff2-8f6a-1c250a681114
Markdown.parse("""
**Diagnostic readout**

| signal | observed value | diagnostic conclusion | next action |
|:--|:--|:--|:--|
| cap saturation with large error | small caps, such as `4`, hit the cap and have visibly large error | The rank cap is too small for this sampled function. | Increase `maxbonddim`. |
| cap saturation with small error | cap `$(plateau_rank)` still saturates, but the error has already collapsed | Saturation alone is not failure; it can mean the cap is just large enough. | Do not raise the cap unless another diagnostic requires it. |
| non-binding cap | from cap `$(first_nonbinding_cap)` onward, observed rank stays near `$(plateau_rank)` | Extra allowed rank is unused. | Stop increasing `maxbonddim` for this run. |
""")

# ╔═╡ 606bf8ca-a9ad-5aef-8f9f-25eeb1959f3c
md"""
## Compare function structure
"""

# ╔═╡ 39bd5331-1272-58ce-a601-d7a36e560712
md"""
Finally, keep the settings fixed and change the target function. This separates workflow and parameter effects from function structure: smooth slowly varying functions, oscillatory chirps, and localized peaks can require very different QTT ranks.
"""

# ╔═╡ bfaee91e-f683-5beb-8641-5a7899c1cf29
begin
	baseline_spacing = 1 / npoints
	peak_center = 0.37
	peak_half_width = 5 * baseline_spacing
	lorentzian_peak(x) = 1 / (1 + ((x - peak_center) / peak_half_width)^2)
	lorentzian_fwhm_grid_points = count(x -> abs(x - peak_center) <= peak_half_width, xvals)

	comparison_functions = [x -> cosh(x), target_function, lorentzian_peak]
	comparison_names = ["cosh(x)", "sin(250x² + 50x)", "1 / (1 + ((x - x₀) / γ)^2)"]
	comparison_structures = ["smooth, slowly varying", "single oscillatory chirp", "smooth localized peak"]
	comparison_diagnostics = [
		"low observed rank for this grid",
		"higher rank from increasing local frequency",
		"rank reflects a narrow local feature, not a failed run",
	]

	comparison_results = map(comparison_functions) do f
		measure_qtt(f, grid; tolerance, maxbonddim, maxiter)
	end
end

# ╔═╡ 2b4eb1d0-841b-47e7-9dca-c3f509f7b879
Markdown.parse("""
Function comparison summary:

The Lorentzian is

```math
f_L(x) = \\frac{1}{1 + \\left((x - x_0) / \\gamma\\right)^2}.
```

with `x₀ = $(peak_center)` and `γ = peak_half_width = 5 * baseline_spacing`. With these settings, `$(lorentzian_fwhm_grid_points)` baseline grid samples lie inside its FWHM.

| function | structure | max abs error | max bond dimension | diagnostic |
|:--|:--|--:|--:|:--|
$(join(["| `$(name)` | $(structure) | `$(round(result.max_abs_error; sigdigits=3))` | `$(result.max_bond_dim)` | $(diagnostic) |" for (name, structure, result, diagnostic) in zip(comparison_names, comparison_structures, comparison_results, comparison_diagnostics)], "
"))
""")

# ╔═╡ 514eb100-b9d2-5cc5-96ba-bf371ce002bb
begin
	fig_comp = Figure(size=(1150, 520), fontsize=plot_fontsize)

	comparison_labels = [L"\cosh(x)", L"\sin(250x^2 + 50x)", L"\frac{1}{1 + ((x - x_0) / \gamma)^2}"]
	comparison_palette = cgrad(:viridis, length(comparison_functions), categorical=true)

	axc1 = Axis(
	    fig_comp[1, 1],
	    xgridvisible=false,
	    ygridvisible=false,
	    xlabel=L"x",
	    ylabel="value",
	    title="Three target functions on [0, 1]",
	    titlesize=plot_fontsize,
	)
	xs_comp = range(0, 1, length=2000)
	function_plots = []
	for (i, (label, f)) in enumerate(zip(comparison_labels, comparison_functions))
		p = lines!(axc1, xs_comp, f.(xs_comp);
		    color=comparison_palette[i], linewidth=2.5, label=label)
		push!(function_plots, p)
	end
	Legend(fig_comp[2, 1], axc1, orientation=:horizontal, framevisible=false, nbanks=2)

	axc2 = Axis(
	    fig_comp[1, 2],
	    xgridvisible=false,
	    ygridvisible=false,
	    xlabel="bond link",
	    ylabel="bond dimension",
	    title="Bond dimensions compared",
	    yscale=log2,
	    titlesize=plot_fontsize,
	)
	profile_plots = []
	for (i, (label, result)) in enumerate(zip(comparison_labels, comparison_results))
		comparison_bond_index = 1:length(result.bond_dims)
		p = scatterlines!(axc2, comparison_bond_index, result.bond_dims;
		    color=comparison_palette[i], linewidth=2.5, markersize=7,
		    label=label)
		push!(profile_plots, p)
	end
	worst_case_profile = worst_case_bond_dims(length(comparison_results[1].bond_dims))
	worst_case_index = 1:length(worst_case_profile)
	p_worst_comp = lines!(axc2, worst_case_index, worst_case_profile;
	    color=:gray60, linewidth=2,
	    linestyle=Linestyle([0, 10, 15]),
	    label=L"\mathrm{worst\ case}")
	Legend(
		fig_comp[2, 2],
		vcat(profile_plots, [p_worst_comp]),
		vcat(comparison_labels, [L"\mathrm{worst\ case}"]);
		orientation=:horizontal,
		framevisible=false,
		nbanks=2,
	)

	fig_comp
end

# ╔═╡ ad1d4304-663c-5fa4-89a6-c780f2a64569
Markdown.parse("""
**Diagnostic readout.** All three runs have small sampled-grid error, so the rank differences are not evidence of an accuracy failure.

The same Tensor4all workflow gives max bond dimensions from `$(minimum(getproperty.(comparison_results, :max_bond_dim)))` to `$(maximum(getproperty.(comparison_results, :max_bond_dim)))` because the function structure changed. In particular, the Lorentzian has `$(lorentzian_fwhm_grid_points)` baseline grid samples inside its FWHM, so its localized feature is resolved but still rank-demanding.
""")

# ╔═╡ d1a1b14b-5349-4a31-a248-204c7f8cf7b0
md"""
## Exercise: diagnose three QTT runs

Choose the best next action for each case. Each option includes both an action and the reason for it.
"""

# ╔═╡ 77db1b36-012d-4cf7-9212-95d5834b4d99
begin
	case_1_cap = 4
	case_1_index = findfirst(==(case_1_cap), collect(maxbonddim_values))
	case_1_error = maxbonddim_errors[case_1_index]
	case_1_observed = maxbonddim_observed[case_1_index]

	case_2_cap = maxbonddim
	case_2_error = baseline.max_abs_error
	case_2_observed = baseline.max_bond_dim

	case_3_cosh_rank = comparison_results[1].max_bond_dim
	case_3_lorentzian_rank = comparison_results[3].max_bond_dim
end

# ╔═╡ 10b9079f-f143-437f-ac8a-795f07338f59
md"""
**Case 1.** A run with `maxbonddim` = $(case_1_cap) has measured grid error $(round(case_1_error; sigdigits=3)), and its observed max bond dimension is $(case_1_observed).

$(@bind case_1_choice Radio([
	:choose => "Choose an action...",
	:increase_cap => "Increase `maxbonddim`, because high error appears together with cap saturation.",
	:increase_R => "Increase `R`, because the grid is the most likely bottleneck.",
	:no_change => "Do not change anything, because the approximation already succeeded.",
]; default=:choose))
"""

# ╔═╡ 73be68b5-3a9b-4856-951b-eb74979c2a99
if case_1_choice == :increase_cap
	md"✅ Correct. High measured grid error together with cap saturation is evidence that `maxbonddim` is too small for this sampled problem."
elseif case_1_choice == :choose
	md"Pick the diagnostic action that best matches Case 1."
else
	md"Not quite. Look for the combination of high measured grid error and observed rank equal to the configured cap."
end

# ╔═╡ 7cd8a202-77a6-45a9-8c72-7ef4d69a5a30
md"""
**Case 2.** The baseline run has measured grid error $(round(case_2_error; sigdigits=3)), cap $(case_2_cap), and observed max bond dimension $(case_2_observed).

$(@bind case_2_choice Radio([
	:choose => "Choose an action...",
	:increase_cap => "Increase `maxbonddim`, because any nonzero error means the cap is too small.",
	:keep_cap => "Do not increase `maxbonddim`, because the error is small and observed rank is far below the cap.",
	:increase_R => "Increase `R`, because any nonzero grid error means the grid is too coarse.",
]; default=:choose))
"""

# ╔═╡ 630dd15a-4358-4727-b16c-a79580f6fb6f
if case_2_choice == :keep_cap
	md"✅ Correct. The run has small measured grid error and does not come close to the rank cap, so increasing `maxbonddim` is not the next diagnostic move."
elseif case_2_choice == :choose
	md"Pick the diagnostic action that best matches Case 2."
else
	md"Not quite. A tiny measured grid error by itself is not a reason to raise the rank cap, especially when the observed rank is far below the cap."
end

# ╔═╡ bf8fe6a7-90ea-4389-8a6b-70a0728ce97a
md"""
**Case 3.** Under the same settings, `cosh(x)` uses max bond dimension $(case_3_cosh_rank), while the Lorentzian peak uses max bond dimension $(case_3_lorentzian_rank).

$(@bind case_3_choice Radio([
	:choose => "Choose an action...",
	:function_structure => "Compare function structure, because the localized peak uses higher rank even though the grid error is small.",
	:lower_tolerance => "Lower `tolerance`, because the higher observed rank indicates poor accuracy.",
	:increase_R => "Increase `R`, because a higher rank always means the grid is too coarse.",
]; default=:choose))
"""

# ╔═╡ b3862368-0c93-4b71-978e-b36d0b374909
if case_3_choice == :function_structure
	md"✅ Correct. Higher observed rank is not automatically a failure: here it reflects the localized structure of the Lorentzian peak."
elseif case_3_choice == :choose
	md"Pick the diagnostic action that best matches Case 3."
else
	md"Not quite. The important signal is that the same workflow and parameters produce different ranks for different function structures."
end

# ╔═╡ 44a7a5d1-2162-5fe8-94de-fcfc0bc475dd
md"""
## What to take away
"""

# ╔═╡ f1138245-d3a8-506b-9b30-d80d85a3614f
md"""
When a QTT run looks bad or expensive, diagnose it in this order:

1. Check the measured grid error: did the QTT match the sampled grid?
2. Check cap saturation: did the observed max bond dimension hit `maxbonddim`?
3. If high error appears together with cap saturation, try increasing `maxbonddim`.
4. If grid error is small but rank is high, treat the run as accurate on the sampled grid but rank-demanding.
5. Read the whole bond-dimension profile, not only the peak rank.
6. Remember that changing `R` changes the discrete problem; grid-point accuracy is not a continuous-resolution guarantee.
7. Choose `R` from the smallest wavelength or feature width you need to resolve before interpreting QTT diagnostics.
8. Compare target-function structure before blaming the Tensor4all workflow.

Notebook 03 continues by moving from one-dimensional grids to multivariate QTT layouts.
"""

# ╔═╡ 111fd83c-14a5-4d54-9ac5-60d2cbc1853d
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
		.t4a-nav {
			border: 1px solid color-mix(in srgb, currentColor 14%, transparent);
			border-radius: 14px;
			padding: 1rem;
			margin: 1rem 0;
			background: linear-gradient(135deg, rgba(56, 189, 248, 0.10), rgba(251, 191, 36, 0.10));
		}
		.t4a-nav h2, .t4a-nav h3 { margin: 0 0 .35rem 0; }
		.t4a-nav p { margin: 0 0 .8rem 0; opacity: .78; }
		.t4a-grid {
			display: grid;
			grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
			gap: .65rem;
		}
		.t4a-card {
			display: grid;
			grid-template-columns: auto 1fr;
			gap: .25rem .7rem;
			align-items: start;
			padding: .75rem .85rem;
			border: 1px solid color-mix(in srgb, currentColor 14%, transparent);
			border-radius: 10px;
			background: color-mix(in srgb, Canvas 94%, currentColor 6%);
			color: inherit;
			text-decoration: none;
		}
		.t4a-card:hover {
			border-color: #0ea5e9;
			box-shadow: 0 4px 14px rgba(14, 165, 233, .16);
			transform: translateY(-1px);
		}
		.t4a-card.current {
			border-color: #0ea5e9;
			background: rgba(14, 165, 233, .12);
		}
		.t4a-num {
			grid-row: 1 / span 2;
			font-weight: 700;
			font-variant-numeric: tabular-nums;
			color: #0284c7;
		}
		.t4a-card strong { line-height: 1.2; }
		.t4a-card small { opacity: .68; line-height: 1.25; }
		.t4a-prev-next {
			display: flex;
			justify-content: space-between;
			gap: .75rem;
			flex-wrap: wrap;
		}
		.t4a-prev-next a, .t4a-prev-next span {
			flex: 1 1 260px;
			padding: .8rem 1rem;
			border-radius: 10px;
			border: 1px solid color-mix(in srgb, currentColor 14%, transparent);
			background: color-mix(in srgb, Canvas 94%, currentColor 6%);
			color: inherit;
			text-decoration: none;
		}
		.t4a-prev-next a:hover { border-color: #0ea5e9; box-shadow: 0 4px 14px rgba(14, 165, 233, .16); }
		.t4a-muted { opacity: .45; }
		</style>
		"""
	end

	function t4a_tutorial_overview()
		current_file = t4a_current_file()
		cards = join(map(t4a_notebook_files()) do file
			number = t4a_escape_html(t4a_notebook_number(file))
			title = t4a_escape_html(t4a_notebook_title(file))
			description = t4a_escape_html(t4a_notebook_description(file))
			if file == current_file
				"""
				<div class=\"t4a-card current\" aria-current=\"page\">
					<span class=\"t4a-num\">$number</span>
					<strong>$title</strong>
					<small>Current notebook · $description</small>
				</div>
				"""
			else
				"""
				<a class=\"t4a-card\" href=\"$(t4a_notebook_href(file))\" target=\"_blank\" rel=\"noopener\">
					<span class=\"t4a-num\">$number</span>
					<strong>$title</strong>
					<small>$description</small>
				</a>
				"""
			end
		end, "")

		HTML("""
		<div class=\"t4a-nav\">
		$(t4a_nav_styles())
		<h2>Tutorial notebooks</h2>
		<p>Open any notebook in this local Pluto tutorial series.</p>
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
			"<a href=\"$(t4a_notebook_href(prev))\" target=\"_blank\" rel=\"noopener\">← Previous: <strong>$(t4a_escape_html(t4a_notebook_number(prev))). $(t4a_escape_html(t4a_notebook_title(prev)))</strong></a>"

		next_html = next === nothing ?
			"<span class=\"t4a-muted\">Next notebook →</span>" :
			"<a href=\"$(t4a_notebook_href(next))\" target=\"_blank\" rel=\"noopener\">Next: <strong>$(t4a_escape_html(t4a_notebook_number(next))). $(t4a_escape_html(t4a_notebook_title(next)))</strong> →</a>"

		HTML("""
		<div class=\"t4a-nav\">
		$(t4a_nav_styles())
		<h3>Notebook navigation</h3>
		<div class=\"t4a-prev-next\">$prev_html $next_html</div>
		</div>
		""")
	end
end

# ╔═╡ c1de3b01-8b20-4bfd-a264-2b4c0b3ed7a7
t4a_tutorial_overview()

# ╔═╡ 32398fc2-8956-4756-9111-50c47fa99213
t4a_prev_next()

# ╔═╡ 65cbca96-2d2b-4665-9bc8-07734bd99a44
begin
	# Support for the cosine discretization-warning cells above.
	chirp_max_angular_frequency = 2 * chirp_quadratic_coefficient + chirp_linear_coefficient
	chirp_shortest_wavelength = 2pi / chirp_max_angular_frequency
	chirp_samples_per_shortest_wavelength(R) = chirp_shortest_wavelength / (1 / (2 ^ R))

	warning_shortest_wavelength = 2pi / warning_angular_frequency
	warning_samples_per_shortest_wavelength(R) = warning_shortest_wavelength / (1 / (2 ^ R))
	warning_zoom_window = 6 * warning_shortest_wavelength

	underresolved_samples_per_wavelength = warning_samples_per_shortest_wavelength(R_underresolved)
	resolved_samples_per_wavelength = warning_samples_per_shortest_wavelength(R_resolved)
	underresolved_worst_case_bond_dims = worst_case_bond_dims(length(underresolved.bond_dims))
	resolved_worst_case_bond_dims = worst_case_bond_dims(length(resolved.bond_dims))
	underresolved_worst_case_max = maximum(underresolved_worst_case_bond_dims)
	resolved_worst_case_max = maximum(resolved_worst_case_bond_dims)
end

# ╔═╡ a22c0788-9bac-5170-922a-1afee8f0ae64
Markdown.parse("""
Two cautions matter here:

- each larger `R` adds another quantics site and another bond link, so chain length changes even when peak rank is stable;
- the smallest `R` gives only about `$(round(chirp_samples_per_shortest_wavelength(first(R_values)); digits=2))` samples per shortest wavelength, so early sweep points are sampled-grid diagnostics, not continuous-resolution guarantees.
""")


# ╔═╡ d01c562c-76cc-11f1-8849-0dded6e706b6
function cosine_warning_figure()
	fig = Figure(size=(1120, 500), fontsize=plot_fontsize)
	warning_dense_xs = range(0, 1, length=30000)

	ax_values = Axis(fig[1, 1];
		xgridvisible=false,
		ygridvisible=false,
		xlabel=L"x",
		ylabel="value",
		title="Under-resolved samples of the cosine",
		limits=((0, warning_zoom_window), nothing),
	)
	lines!(ax_values, warning_dense_xs, warning_function.(warning_dense_xs);
		color=:black, linewidth=2, label=L"\cos(%$warning_angular_frequency x)")
	scatterlines!(ax_values, underresolved.xvals, underresolved.values;
		color=:tomato, linewidth=2.5, label=L"R = %$R_underresolved\ \mathrm{samples}")
	Legend(fig[2, 1], ax_values; orientation=:horizontal, framevisible=false)

	ax_bonds = Axis(fig[1, 2];
		xlabel="bond link",
		ylabel="bond dimension",
		title="Small rank does not imply continuous resolution",
		yscale=log2,
		xticks=1:length(resolved.bond_dims),
		xgridvisible=false,
		ygridvisible=false,
	)
	scatterlines!(ax_bonds, 1:length(underresolved.bond_dims), underresolved.bond_dims;
		color=:tomato, linewidth=2.5, markersize=8,
		label=L"R = %$R_underresolved")
	scatterlines!(ax_bonds, 1:length(resolved.bond_dims), resolved.bond_dims;
		color=:deepskyblue4, linewidth=2.5, markersize=8, linestyle=:dot,
		label=L"R = %$R_resolved")
	lines!(ax_bonds, 1:length(underresolved_worst_case_bond_dims), underresolved_worst_case_bond_dims;
		color=:gray50, linewidth=2.8, linestyle=:dash, label=L"R = %$R_underresolved\ \mathrm{worst\ case}")
	Legend(fig[2, 2], ax_bonds; orientation=:horizontal, framevisible=false)

	fig
end

# ╔═╡ 9a3f4232-f3e3-46c0-bd19-8d27e696e906
cosine_warning_figure()

# ╔═╡ 8b418c04-1a88-4188-8e4b-9f7d6d66f692
function cosine_warning_summary()
	Markdown.parse("""
	Discretization check:

	| run | `R` | samples/wavelength | grid error | max bond / worst max |
	|:--|--:|--:|--:|--:|
	| under-resolved | `$(R_underresolved)` | `$(round(underresolved_samples_per_wavelength; digits=2))` | `$(round(underresolved.max_abs_error; sigdigits=3))` | `$(underresolved.max_bond_dim) / $(underresolved_worst_case_max)` |
	| resolved comparison | `$(R_resolved)` | `$(round(resolved_samples_per_wavelength; digits=1))` | `$(round(resolved.max_abs_error; sigdigits=3))` | `$(resolved.max_bond_dim) / $(resolved_worst_case_max)` |

	The `R = $(R_underresolved)` QTT solves its sampled problem accurately and has tiny rank, but the grid is too coarse for the continuous cosine.
	""")
end

# ╔═╡ dbc29a18-5b22-4eef-a362-293e1afaf124
cosine_warning_summary()

# ╔═╡ 00000000-0000-0000-0000-000000000003
PlutoUI.TableOfContents(title="Notebook map", depth=3, aside=true)


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
CairoMakie = "~0.15.9"
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
project_hash = "c047dbed3135deba254f941fbdf23995d63e9623"

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

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "0761717147821d696c9470a7a86364b2fbd22fd8"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "4.5.2"
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

[[deps.ArrayInterface]]
deps = ["Adapt", "LinearAlgebra"]
git-tree-sha1 = "54f895554d05c83e3dd59f6a396671dae8999573"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "7.24.0"

    [deps.ArrayInterface.extensions]
    ArrayInterfaceAMDGPUExt = "AMDGPU"
    ArrayInterfaceBandedMatricesExt = "BandedMatrices"
    ArrayInterfaceBlockBandedMatricesExt = "BlockBandedMatrices"
    ArrayInterfaceCUDAExt = "CUDA"
    ArrayInterfaceCUDSSExt = ["CUDSS", "CUDA"]
    ArrayInterfaceChainRulesCoreExt = "ChainRulesCore"
    ArrayInterfaceChainRulesExt = "ChainRules"
    ArrayInterfaceGPUArraysCoreExt = "GPUArraysCore"
    ArrayInterfaceMetalExt = "Metal"
    ArrayInterfaceReverseDiffExt = "ReverseDiff"
    ArrayInterfaceSparseArraysExt = "SparseArrays"
    ArrayInterfaceStaticArraysCoreExt = "StaticArraysCore"
    ArrayInterfaceTrackerExt = "Tracker"

    [deps.ArrayInterface.weakdeps]
    AMDGPU = "21141c5a-9bdb-4563-92ae-f87d6854732e"
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    CUDSS = "45b445bb-4962-46a0-9369-b4df9d0f772e"
    ChainRules = "082447d4-558c-5d27-93f4-14fc19e9eca2"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    Metal = "dde4c033-4e86-420c-a63e-0dd931031962"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StaticArraysCore = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Automa]]
deps = ["PrecompileTools", "SIMD", "TranscodingStreams"]
git-tree-sha1 = "a8f503e8e1a5f583fbef15a8440c8c7e32185df2"
uuid = "67c07d97-cdcb-5c2c-af73-a7f9c32a568b"
version = "1.1.0"

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
git-tree-sha1 = "bca794632b8a9bbe159d56bf9e31c422671b35e0"
uuid = "18cc8868-cbac-4acf-b575-c8ff214dc66f"
version = "1.3.2"

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
git-tree-sha1 = "fa072933899aae6dc61dde934febed8254e66c6a"
uuid = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
version = "0.15.9"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "Libdl", "Pixman_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "d0efe2c6fdcdaa1c161d206aa8b933788397ec71"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.18.6+0"

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

[[deps.CommonWorldInvalidations]]
git-tree-sha1 = "ae52d1c52048455e85a387fbee9be553ec2b68d0"
uuid = "f70d9fcc-98c5-4d4a-abd7-e4cdeebd8ca8"
version = "1.0.0"

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

[[deps.ComputePipeline]]
deps = ["Observables", "Preferences"]
git-tree-sha1 = "3b4be73db165146d8a88e47924f464e55ab053cd"
uuid = "95dc2771-c249-4cd0-9c9f-1f3b4330693c"
version = "0.1.7"

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
git-tree-sha1 = "e86f4a2805f7f19bec5129bc9150c38208e5dc23"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.19.4"

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
deps = ["AliasTables", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns"]
git-tree-sha1 = "e421c1938fafab0165b04dc1a9dbe2a26272952c"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.125"

    [deps.Distributions.extensions]
    DistributionsChainRulesCoreExt = "ChainRulesCore"
    DistributionsDensityInterfaceExt = "DensityInterface"
    DistributionsTestExt = "Test"

    [deps.Distributions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DensityInterface = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
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
deps = ["PrecompileTools", "StaticArrayInterface"]
git-tree-sha1 = "df3c9e8000ee77c6b81955025cf18722c95c41a4"
uuid = "da5c29d0-fa7d-589e-88eb-ea29b0a81949"
version = "1.9.0"

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
git-tree-sha1 = "27af30de8b5445644e8ffe3bcb0d72049c089cf1"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.7.3+0"

[[deps.Extents]]
git-tree-sha1 = "b309b36a9e02fe7be71270dd8c0fd873625332b4"
uuid = "411431e0-e8b7-467b-b5e0-f676ba4f2910"
version = "0.1.6"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libva_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "66381d7059b5f3f6162f28831854008040a4e905"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "8.0.1+1"

[[deps.FFTA]]
deps = ["AbstractFFTs", "DocStringExtensions", "LinearAlgebra", "MuladdMacro", "Primes", "Random", "Reexport"]
git-tree-sha1 = "65e55303b72f4a567a51b174dd2c47496efeb95a"
uuid = "b86e33f2-c0db-4aa1-a6e0-ab43e668529e"
version = "0.3.1"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "6522cfb3b8fe97bec632252263057996cbd3de20"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.18.0"

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
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

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

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "Extents", "IterTools", "LinearAlgebra", "PrecompileTools", "Random", "StaticArrays"]
git-tree-sha1 = "1f5a80f4ed9f5a4aada88fc2db456e637676414b"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.5.10"

    [deps.GeometryBasics.extensions]
    GeometryBasicsGeoInterfaceExt = "GeoInterface"

    [deps.GeometryBasics.weakdeps]
    GeoInterface = "cf35fbd7-0cd7-5166-be24-54bfbe79505f"

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
git-tree-sha1 = "8a6dbda1fd736d60cc477d99f2e7a042acfa46e8"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.15+0"

[[deps.GridLayoutBase]]
deps = ["GeometryBasics", "InteractiveUtils", "Observables"]
git-tree-sha1 = "93d5c27c8de51687a2c70ec0716e6e76f298416f"
uuid = "3955a311-db13-416c-9275-1d80ed98e5e9"
version = "0.11.2"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

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
deps = ["LinearAlgebra", "OpenLibm_jll", "SpecialFunctions"]
git-tree-sha1 = "68c173f4f449de5b438ee67ed0c9c748dc31a2ec"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.28"

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

[[deps.IfElse]]
git-tree-sha1 = "debdd00ffef04665ccbb3e150747a77560e8fad1"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.1"

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
git-tree-sha1 = "65d505fa4c0d7072990d659ef3fc086eb6da8208"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.16.2"

    [deps.Interpolations.extensions]
    InterpolationsForwardDiffExt = "ForwardDiff"
    InterpolationsUnitfulExt = "Unitful"

    [deps.Interpolations.weakdeps]
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.IntervalArithmetic]]
deps = ["CRlibm", "CoreMath", "MacroTools", "OpenBLASConsistentFPCSR_jll", "Printf", "Random", "RoundingEmulator"]
git-tree-sha1 = "f1c42fcaca2d8034fe392f3e86c2e0809f75b2a1"
uuid = "d1acc4aa-44c8-5952-acd4-ba5d80a2a253"
version = "1.0.6"

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
git-tree-sha1 = "0533e564aae234aff59ab625543145446d8b6ec2"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.7.1"

[[deps.JSON]]
deps = ["Dates", "Logging", "Parsers", "PrecompileTools", "StructUtils", "UUIDs", "Unicode"]
git-tree-sha1 = "67c6f1f085cb2671c93fe34244c9cccde30f7a26"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "1.5.0"

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
git-tree-sha1 = "c0c9b76f3520863909825cbecdef58cd63de705a"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.1.5+0"

[[deps.JuliaSyntaxHighlighting]]
deps = ["StyledStrings"]
uuid = "ac6e5ff7-fb65-4e79-a425-ec3bc9c03011"
version = "1.12.0"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTA", "Interpolations", "StatsBase"]
git-tree-sha1 = "4260cfc991b8885bf747801fb60dd4503250e478"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.11"

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
git-tree-sha1 = "eb62a3deb62fc6d8822c0c4bef73e4412419c5d8"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "18.1.8+0"

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
git-tree-sha1 = "f04133fe05eff1667d2054c53d59f9122383fe05"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.7.2+0"

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
git-tree-sha1 = "13ca9e2586b89836fd20cccf56e57e2b9ae7f38f"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.29"

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
deps = ["Animations", "Base64", "CRC32c", "ColorBrewer", "ColorSchemes", "ColorTypes", "Colors", "ComputePipeline", "Contour", "Dates", "DelaunayTriangulation", "Distributions", "DocStringExtensions", "Downloads", "FFMPEG_jll", "FileIO", "FilePaths", "FixedPointNumbers", "Format", "FreeType", "FreeTypeAbstraction", "GeometryBasics", "GridLayoutBase", "ImageBase", "ImageIO", "InteractiveUtils", "Interpolations", "IntervalSets", "InverseFunctions", "Isoband", "KernelDensity", "LaTeXStrings", "LinearAlgebra", "MacroTools", "Markdown", "MathTeXEngine", "Observables", "OffsetArrays", "PNGFiles", "Packing", "Pkg", "PlotUtils", "PolygonOps", "PrecompileTools", "Printf", "REPL", "Random", "RelocatableFolders", "Scratch", "ShaderAbstractions", "Showoff", "SignedDistanceFields", "SparseArrays", "Statistics", "StatsBase", "StatsFuns", "StructArrays", "TriplotBase", "UnicodeFun", "Unitful"]
git-tree-sha1 = "68af66ec16af8b152309310251ecb4fbfe39869f"
uuid = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
version = "0.24.9"

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
git-tree-sha1 = "7eb8cdaa6f0e8081616367c10b31b9d9b34bb02a"
uuid = "0a4f8689-d25c-4efe-a92b-7142dfc1aa53"
version = "0.6.7"

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
git-tree-sha1 = "cac9cc5499c25554cba55cd3c30543cff5ca4fab"
uuid = "46d2c3a1-f734-5fdb-9937-b9b9aeba4221"
version = "0.2.4"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "9b8215b1ee9e78a293f99797cd31375471b2bcae"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.1.3"

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
git-tree-sha1 = "f2b3b9e52a5eb6a3434c8cca67ad2dde011194f4"
uuid = "6cdc7f73-28fd-5e50-80fb-958a8875b1af"
version = "0.3.30+0"

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
git-tree-sha1 = "9ac7c730c53b3b5d9a73fb900ac4b4fc263774db"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.4.9+0"

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
git-tree-sha1 = "05868e21324cede2207c6f0f466b4bfef6d5e7ee"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.1"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.44.0+1"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "e4cff168707d441cd6bf3ff7e4832bdf34278e4a"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.37"
weakdeps = ["StatsBase"]

    [deps.PDMats.extensions]
    StatsBaseExt = "StatsBase"

[[deps.PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "cf181f0b1e6a18dfeb0ee8acc4a9d1672499626c"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.4.4"

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
git-tree-sha1 = "7d2f8f21da5db6a806faf7b9b292296da42b2810"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.3"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "db76b1ecd5e9715f3d043cec13b2ec93ce015d53"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.44.2+0"

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
git-tree-sha1 = "07a921781cab75691315adc645096ed5e370cb77"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.3.3"

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

[[deps.RoundingEmulator]]
git-tree-sha1 = "40b9edad2e5287e05bd413a38f61a8ff55b9557b"
uuid = "5eaf0fd0-dfba-4ccb-bf02-d820a40db705"
version = "0.2.1"

[[deps.RustToolChain]]
deps = ["Pkg"]
git-tree-sha1 = "1390ac3e0f418bf2a7d3bd83057328a99f11e2aa"
uuid = "e9dc52e2-edb8-4742-9783-5e542d30dbb5"
version = "0.1.5"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SIMD]]
deps = ["PrecompileTools"]
git-tree-sha1 = "e24dc23107d426a096d3eae6c165b921e74c18e4"
uuid = "fdea26ae-647d-5447-a871-4b548cad5224"
version = "3.7.2"

[[deps.SciMLPublic]]
git-tree-sha1 = "0ba076dbdce87ba230fff48ca9bca62e1f345c9b"
uuid = "431bcebd-1456-4ced-9d72-93c2757fff0b"
version = "1.0.1"

[[deps.ScopedValues]]
deps = ["HashArrayMappedTries", "Logging"]
git-tree-sha1 = "ac4b837d89a58c848e85e698e2a2514e9d59d8f6"
uuid = "7e506255-f358-4e82-b7e4-beb19740aa63"
version = "1.6.0"

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

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SignedDistanceFields]]
deps = ["Statistics"]
git-tree-sha1 = "3949ad92e1c9d2ff0cd4a1317d5ecbba682f4b92"
uuid = "73760f76-fbc4-59ce-8f25-708e95d2df96"
version = "0.4.1"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "be8eeac05ec97d379347584fa9fe2f5f76795bcb"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.5"

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
git-tree-sha1 = "64d974c2e6fdf07f8155b5b2ca2ffa9069b608d9"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.2"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.12.0"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "2700b235561b0335d5bef7097a111dc513b8655e"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.7.2"
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

[[deps.Static]]
deps = ["CommonWorldInvalidations", "IfElse", "PrecompileTools", "SciMLPublic"]
git-tree-sha1 = "49440414711eddc7227724ae6e570c7d5559a086"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "1.3.1"

[[deps.StaticArrayInterface]]
deps = ["ArrayInterface", "Compat", "IfElse", "LinearAlgebra", "PrecompileTools", "SciMLPublic", "Static"]
git-tree-sha1 = "aa1ea41b3d45ac449d10477f65e2b40e3197a0d2"
uuid = "0d7ed370-da01-4f52-bd93-41d350b8b718"
version = "1.9.0"
weakdeps = ["OffsetArrays", "StaticArrays"]

    [deps.StaticArrayInterface.extensions]
    StaticArrayInterfaceOffsetArraysExt = "OffsetArrays"
    StaticArrayInterfaceStaticArraysExt = "StaticArrays"

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
git-tree-sha1 = "aceda6f4e598d331548e04cc6b2124a6148138e3"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.10"

[[deps.StatsFuns]]
deps = ["HypergeometricFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "91f091a8716a6bb38417a6e6f274602a19aaa685"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.5.2"
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
git-tree-sha1 = "86f5831495301b2a1387476cb30f86af7ab99194"
uuid = "ec057cc2-7a8d-4b58-b3b3-92acb9f63b42"
version = "2.8.0"

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
git-tree-sha1 = "f2c1efbc8f3a609aadf318094f8fc5204bdaf344"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.12.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Tensor4all]]
deps = ["Libdl", "LinearAlgebra", "QuanticsGrids", "QuanticsTCI", "Random", "RustToolChain", "ScopedValues", "TensorCrossInterpolation"]
git-tree-sha1 = "7810c39c388284930dbe2ef73805f92e571c8457"
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
git-tree-sha1 = "4909eb8f1cbf6bd4b1c30dd18b2ead9019ef2fad"
uuid = "a65dc6b1-eb27-53a1-bb3e-dea574b5389e"
version = "0.18.1+0"

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
# ╟─c1de3b01-8b20-4bfd-a264-2b4c0b3ed7a7
# ╟─7af2bd01-e768-5d12-ae2d-f9d3bb79d7f7
# ╟─dd765b4e-c03d-56b5-8937-3412c415bb15
# ╟─10ed0dfd-bff0-4d5f-bc3f-c79f5a25670a
# ╠═4b569f29-57e2-55f3-9ee1-5697277378dc
# ╟─2cbcc7a1-4d2d-4787-ad19-51e2f28d0f6c
# ╠═3c326c32-1958-4910-a06a-ebac2d48a2ed
# ╟─f0aa6a75-e7d3-55e2-98ee-2a28c7159f48
# ╟─fa666941-c709-5873-a566-20b7f70db22f
# ╟─dcb8301e-66bb-4e61-8c92-5d2a88d15170
# ╠═035c29a2-1724-5eb8-8c80-859f71fc1760
# ╠═d82d1c6b-dc03-566b-9c44-260c08234e49
# ╠═e7a19faf-5978-4ce0-b117-6bea6fe51c61
# ╠═d166a2f5-505c-4f97-baf7-fb3b401a2493
# ╟─77eda426-95a5-4a13-8703-4aa27684201f
# ╟─ac718dfe-5596-549b-a19c-b93fe62dadc4
# ╟─76e2892b-5189-526a-9970-9d1dff9479f7
# ╟─bbda78d3-5175-5ec1-b442-4b4afb0587be
# ╟─19a147d7-f1fe-56cd-bc21-3169dcc24cde
# ╠═6209b48b-a255-5520-8fe3-68a310691f21
# ╟─61fa8f23-c129-5a15-b711-8ba6c901badb
# ╟─a22c0788-9bac-5170-922a-1afee8f0ae64
# ╟─88abb671-c20b-4cba-82c4-a72d8a2a3cbc
# ╠═b03b3fc4-d81a-4980-92de-c6435f5e2d91
# ╟─9a3f4232-f3e3-46c0-bd19-8d27e696e906
# ╟─dbc29a18-5b22-4eef-a362-293e1afaf124
# ╟─0cd76892-2332-5d7e-a19c-936bddf2078e
# ╟─d0140d2e-d183-51db-abf1-760d27bb0fe1
# ╠═becd693f-1553-5a3a-9e3c-0567d4c8f79f
# ╟─2abfa82d-6d8e-5813-a966-3dad448e0434
# ╟─52fc64af-8c48-5ff2-8f6a-1c250a681114
# ╟─606bf8ca-a9ad-5aef-8f9f-25eeb1959f3c
# ╟─39bd5331-1272-58ce-a601-d7a36e560712
# ╠═bfaee91e-f683-5beb-8641-5a7899c1cf29
# ╟─2b4eb1d0-841b-47e7-9dca-c3f509f7b879
# ╟─514eb100-b9d2-5cc5-96ba-bf371ce002bb
# ╟─ad1d4304-663c-5fa4-89a6-c780f2a64569
# ╟─d1a1b14b-5349-4a31-a248-204c7f8cf7b0
# ╠═77db1b36-012d-4cf7-9212-95d5834b4d99
# ╟─10b9079f-f143-437f-ac8a-795f07338f59
# ╟─73be68b5-3a9b-4856-951b-eb74979c2a99
# ╟─7cd8a202-77a6-45a9-8c72-7ef4d69a5a30
# ╟─630dd15a-4358-4727-b16c-a79580f6fb6f
# ╟─bf8fe6a7-90ea-4389-8a6b-70a0728ce97a
# ╟─b3862368-0c93-4b71-978e-b36d0b374909
# ╟─44a7a5d1-2162-5fe8-94de-fcfc0bc475dd
# ╟─f1138245-d3a8-506b-9b30-d80d85a3614f
# ╟─32398fc2-8956-4756-9111-50c47fa99213
# ╟─f8e364d0-2c19-4c75-8f69-f4f18d25f4d9
# ╟─111fd83c-14a5-4d54-9ac5-60d2cbc1853d
# ╟─65cbca96-2d2b-4665-9bc8-07734bd99a44
# ╟─d01c562c-76cc-11f1-8849-0dded6e706b6
# ╟─8b418c04-1a88-4188-8e4b-9f7d6d66f692
# ╟─00000000-0000-0000-0000-000000000003
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

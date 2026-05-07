# Tutorial Review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the agreed tutorial-review fixes while changing only things that are necessary for beginner clarity, consistency, accessibility, and execution.

**Architecture:** Keep the tutorial notebooks notebook-first and self-contained. Do not introduce shared helper files; instead keep local helpers visible in notebooks and make duplicated helpers consistent where they matter. Use README and `docs/tutorial-learning-path.md` for sequence-level orientation rather than adding navigation footers to every notebook.

**Tech Stack:** Julia 1.12 project environment, Jupyter `.ipynb` notebooks, Tensor4all.jl, CairoMakie, FFTW, Markdown docs.

---

## Scope And Priorities

Implement these agreed decisions:

- Keep `includeendpoint` values unchanged.
- Standardize ordinary interpolation tolerances to `1e-12`.
- Set ordinary `maxbonddim` values to `64` where possible.
- Do not add a parameter convention table.
- Keep `:navia` heatmaps.
- Change only Notebook 02's 8-color R-sweep palette to a known colorblind-safe categorical palette.
- Introduce fused layout in Notebook 03.
- Keep helpers local in notebooks, but make helper naming and behavior easier to read.
- Add a README/Learning Path summary of what each notebook covers.
- In Notebook 04, keep integration in Part 3 and add a short bridge.
- In Notebook 05, add the two Fourier scaling TL;DR sentences, simplify `quantics_digits`, fix `sites2`, and import `LaTeXStrings`.
- Keep `ylabelrotation=0` in Notebook 06.

Do not implement:

- Next-footers at the end of every notebook.
- A global palette refactor across all plots.
- A shared `tutorial_helpers.jl`.
- A new orientation diagram in Notebook 05.
- Extra explanations for arbitrary parameter choices.

---

## Files To Modify

- `README.md`: add a short learning-path summary and make setup expectations clear enough that notebook setup blocks can be shorter later.
- `docs/tutorial-learning-path.md`: mirror the notebook coverage summary and record the chosen implementation decisions.
- `01_first_qtt_function_and_grid.ipynb`: set `maxbonddim = 64`.
- `02_accuracy_bonddims_and_sweeps.ipynb`: set `maxbonddim = 64`, update sweep values if needed, and replace the R-sweep palette.
- `03_multivariate_qtts_and_layouts.ipynb`: set `tolerance = 1e-12`, `maxbonddim = 64`, add fused layout after grouped layout, include fused bond dimensions in the comparison.
- `04_operations_on_qtts.ipynb`: set `maxbonddim = 64`, set selected-product tolerance to `1e-12`, add a short API explanation before `PartialContractionSpec`, add a bridge before integration.
- `05_fourier_transforms.ipynb`: add `using LaTeXStrings`, set tolerances to `1e-12`, set 1D `maxbonddim` to `64`, simplify `quantics_digits`, fix `sites2`, add TL;DR sentences.
- `06_affine_transformations.ipynb`: keep existing `tolerance = 1e-12`, `maxbonddim = 64`, and `ylabelrotation=0`; add a short API explanation before the affine matrix arrays.
- `docs/tutorial-review-2026-05-06.md`: update status notes after implementation.

---

## Verification Commands

Run these after relevant tasks:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
```

Expected: command exits with status 0.

Run all notebooks as code cells without relying on Jupyter:

```bash
for nb in 01_first_qtt_function_and_grid.ipynb 02_accuracy_bonddims_and_sweeps.ipynb 03_multivariate_qtts_and_layouts.ipynb 04_operations_on_qtts.ipynb 05_fourier_transforms.ipynb 06_affine_transformations.ipynb; do
  printf '\n===== RUN %s =====\n' "$nb"
  jq -r '.cells[] | select(.cell_type=="code") | "# %% cell\n" + (.source|join("")) + "\n"' "$nb" | julia --project=.
  rc=$?
  printf '===== EXIT %s: %s =====\n' "$nb" "$rc"
  if [ "$rc" -ne 0 ]; then exit "$rc"; fi
done
```

Expected: each notebook prints `EXIT ...: 0`.

Check only source-level notebook changes when reviewing diffs:

```bash
python3 - <<'PY'
import json, pathlib
for path in sorted(pathlib.Path('.').glob('*.ipynb')):
    nb = json.loads(path.read_text())
    print(path)
    for i, cell in enumerate(nb.get("cells", [])):
        if cell.get("cell_type") == "code":
            src = "".join(cell.get("source", []))
            if any(token in src for token in ["tolerance", "maxbonddim", "raw_colors", "quantics_digits", "PartialContractionSpec", "affine_pullback_operator_multivar", "fused"]):
                print(f"  cell {i:02d} id={cell.get('id')}")
PY
```

Expected: prints the touched cells so the reviewer can inspect them deliberately.

---

## Task 1: README And Learning Path Summary

**Files:**
- Modify: `README.md`
- Modify: `docs/tutorial-learning-path.md`

- [ ] **Step 1: Update README learning path**

Replace the plain code block under `## Learning Path` in `README.md` with this Markdown list:

```markdown
## Learning Path

Read the notebooks in numerical order:

1. `01_first_qtt_function_and_grid.ipynb` introduces a one-dimensional quantics grid, builds a first QTT approximation, and shows how to read bond dimensions.
2. `02_accuracy_bonddims_and_sweeps.ipynb` explores how accuracy and bond dimensions change when `R` and `maxbonddim` are varied.
3. `03_multivariate_qtts_and_layouts.ipynb` introduces two-dimensional QTTs and compares interleaved, grouped, and fused layouts.
4. `04_operations_on_qtts.ipynb` demonstrates QTT operations: elementwise products, selected-variable products, fused-layout products, and integration.
5. `05_fourier_transforms.ipynb` applies Fourier transforms to one-dimensional QTTs and a two-dimensional partial transform.
6. `06_affine_transformations.ipynb` applies periodic and open-boundary affine pullback operators on a fused two-dimensional grid.

All six notebooks are implemented. Notebook 06 is still the newest and should be read as the most draft-like part of the sequence.
```

- [ ] **Step 2: Update learning-path status**

In `docs/tutorial-learning-path.md`, replace the `Six notebooks now exist:` bullet list and the per-notebook reference paragraphs with this clearer summary:

```markdown
Six notebooks now exist and should be read in numerical order:

- `01_first_qtt_function_and_grid.ipynb`: first one-dimensional QTT, quantics grid indexing, and bond-dimension intuition.
- `02_accuracy_bonddims_and_sweeps.ipynb`: accuracy checks, `R` sweeps, `maxbonddim` sweeps, and simple playground comparisons.
- `03_multivariate_qtts_and_layouts.ipynb`: two-dimensional QTTs and interleaved, grouped, and fused layout comparisons.
- `04_operations_on_qtts.ipynb`: elementwise products, selected-variable products, fused-layout products, and integration.
- `05_fourier_transforms.ipynb`: one-dimensional Fourier transform and two-dimensional partial Fourier transform.
- `06_affine_transformations.ipynb`: periodic and open-boundary affine pullback transforms on fused grids.
```

Keep the remaining design notes below this summary.

- [ ] **Step 3: Verify docs wording**

Run:

```bash
rg -n "Next:|Next-Footer|All six notebooks|fused layout|Learning Path" README.md docs/tutorial-learning-path.md
```

Expected:

- No `Next:` navigation footer text appears.
- README says all six notebooks are implemented.
- README or learning path mentions fused layout in Notebook 03.

- [ ] **Step 4: Commit**

```bash
git add README.md docs/tutorial-learning-path.md
git commit -m "docs: clarify tutorial learning path"
```

---

## Task 2: Standardize Parameters Without Changing Endpoints

**Files:**
- Modify: `01_first_qtt_function_and_grid.ipynb`
- Modify: `02_accuracy_bonddims_and_sweeps.ipynb`
- Modify: `03_multivariate_qtts_and_layouts.ipynb`
- Modify: `04_operations_on_qtts.ipynb`
- Modify: `05_fourier_transforms.ipynb`

- [ ] **Step 1: Update Notebook 01**

In `01_first_qtt_function_and_grid.ipynb`, code cell id `00135c8f`, change:

```julia
maxbonddim = 32
```

to:

```julia
maxbonddim = 64
```

Do not change `includeendpoint=true` in the second experiment.

- [ ] **Step 2: Update Notebook 02 baseline**

In `02_accuracy_bonddims_and_sweeps.ipynb`, code cell id `9b868f61`, change:

```julia
maxbonddim = 32
```

to:

```julia
maxbonddim = 64
```

Do not change `includeendpoint=false`.

- [ ] **Step 3: Update Notebook 02 maxbonddim sweep**

In code cell id `6abad5c4`, change:

```julia
sweep_maxbonddim_values = [1, 2, 4, 8, 16, 32]
```

to:

```julia
sweep_maxbonddim_values = [1, 2, 4, 8, 16, 32, 64]
```

- [ ] **Step 4: Update Notebook 03 shared parameters**

In `03_multivariate_qtts_and_layouts.ipynb`, code cell id `59c08efb`, change:

```julia
tolerance = 1e-10
maxbonddim = 32
```

to:

```julia
tolerance = 1e-12
maxbonddim = 64
```

Do not change `includeendpoint=false` in grouped/interleaved/fused grids.

- [ ] **Step 5: Update Notebook 04 Part 1 parameters**

In `04_operations_on_qtts.ipynb`, code cell id `2e9bdf45`, change:

```julia
maxbonddim = 32
```

to:

```julia
maxbonddim = 64
```

- [ ] **Step 6: Update Notebook 04 selected-variable parameters**

In code cell id `selected-vars-params`, change:

```julia
selected_tolerance = 1e-10
selected_maxbonddim = 32
```

to:

```julia
selected_tolerance = 1e-12
selected_maxbonddim = 64
```

- [ ] **Step 7: Update Notebook 04 integration calls**

In code cell id `09b7f0ab`, change:

```julia
tolerance=1e-12, maxbonddim=32, maxiter=200,
```

to:

```julia
tolerance=1e-12, maxbonddim=64, maxiter=200,
```

In code cell id `b8da7df6`, make the same replacement inside the sweep loop.

- [ ] **Step 8: Update Notebook 05 Part 1**

In `05_fourier_transforms.ipynb`, code cell id `08a4aff7`, change:

```julia
tolerance=1e-10, maxbonddim=32, maxiter=200,
```

to:

```julia
tolerance=1e-12, maxbonddim=64, maxiter=200,
```

In code cell id `4ab5c9c7`, change:

```julia
op = QT.fourier_operator(R; forward=true, maxbonddim=32, tolerance=1e-10)
```

to:

```julia
op = QT.fourier_operator(R; forward=true, maxbonddim=64, tolerance=1e-12)
```

Also change the explanatory comment and truncation calls in the same cell:

```julia
#truncation can also be done in one step via: TN.apply(op, state; threshold=1e-12, maxdim=64)

result = TN.truncate(result_raw; threshold=1e-12, maxdim=64)
```

- [ ] **Step 9: Update Notebook 05 Part 2**

In code cell id `7a6a35ac`, change:

```julia
tolerance=1e-10, maxbonddim=64, maxiter=200,
```

to:

```julia
tolerance=1e-12, maxbonddim=64, maxiter=200,
```

In code cell id `6e4a2e1f`, change:

```julia
ft_qtt, _, _ = QTCI.quanticscrossinterpolate(ft_scaled; tolerance=1e-8, maxbonddim=64, maxiter=200)
```

to:

```julia
ft_qtt, _, _ = QTCI.quanticscrossinterpolate(ft_scaled; tolerance=1e-12, maxbonddim=64, maxiter=200)
```

- [ ] **Step 10: Verify parameter changes**

Run:

```bash
rg -n "tolerance = 1e-10|tolerance=1e-10|tolerance=1e-8|maxbonddim = 32|maxbonddim=32|maxdim=32" *.ipynb
```

Expected: no matches, unless a match is in a historical output blob. If matches appear in code-cell source, fix them.

- [ ] **Step 11: Run affected notebooks**

Run:

```bash
for nb in 01_first_qtt_function_and_grid.ipynb 02_accuracy_bonddims_and_sweeps.ipynb 03_multivariate_qtts_and_layouts.ipynb 04_operations_on_qtts.ipynb 05_fourier_transforms.ipynb; do
  printf '\n===== RUN %s =====\n' "$nb"
  jq -r '.cells[] | select(.cell_type=="code") | "# %% cell\n" + (.source|join("")) + "\n"' "$nb" | julia --project=.
  rc=$?
  printf '===== EXIT %s: %s =====\n' "$nb" "$rc"
  if [ "$rc" -ne 0 ]; then exit "$rc"; fi
done
```

Expected: every notebook exits with status 0.

- [ ] **Step 12: Commit**

```bash
git add 01_first_qtt_function_and_grid.ipynb 02_accuracy_bonddims_and_sweeps.ipynb 03_multivariate_qtts_and_layouts.ipynb 04_operations_on_qtts.ipynb 05_fourier_transforms.ipynb
git commit -m "chore: standardize tutorial interpolation parameters"
```

---

## Task 3: Fix The Only Required Color Accessibility Issue

**Files:**
- Modify: `02_accuracy_bonddims_and_sweeps.ipynb`

- [ ] **Step 1: Replace R-sweep categorical palette**

In code cell id `e4c4851c`, replace:

```julia
raw_colors = [:darkorange2, :dodgerblue3, :seagreen3,  :firebrick3, :slateblue3, 
    :goldenrod2, :mediumorchid3, :darkgreen]
```

with the Okabe-Ito palette:

```julia
raw_colors = [
    RGBf(0.0, 0.0, 0.0),
    RGBf(230/255, 159/255, 0.0),
    RGBf(86/255, 180/255, 233/255),
    RGBf(0.0, 158/255, 115/255),
    RGBf(240/255, 228/255, 66/255),
    RGBf(0.0, 114/255, 178/255),
    RGBf(213/255, 94/255, 0.0),
    RGBf(204/255, 121/255, 167/255),
]
```

Keep:

```julia
marker_cycle = [:circle, :rect, :diamond, :utriangle, :xcross, :star5, :dtriangle, :hexagon]
palette = [raw_colors[mod1(i, length(raw_colors))] for i in eachindex(sweep_R_values)]
markers = [marker_cycle[mod1(i, length(marker_cycle))] for i in eachindex(sweep_R_values)]
```

- [ ] **Step 2: Verify no global color refactor happened**

Run:

```bash
rg -n "colormap=:navia|raw_colors|RGBf|:darkorange2|:slateblue3|:mediumorchid3|:darkgreen" 02_accuracy_bonddims_and_sweeps.ipynb 03_multivariate_qtts_and_layouts.ipynb 04_operations_on_qtts.ipynb 05_fourier_transforms.ipynb 06_affine_transformations.ipynb
```

Expected:

- `:navia` still appears in heatmap notebooks.
- `RGBf` appears in Notebook 02 R-sweep.
- `:darkorange2`, `:slateblue3`, `:mediumorchid3`, and `:darkgreen` do not appear in live Notebook 02 source.

- [ ] **Step 3: Run Notebook 02**

Run:

```bash
jq -r '.cells[] | select(.cell_type=="code") | "# %% cell\n" + (.source|join("")) + "\n"' 02_accuracy_bonddims_and_sweeps.ipynb | julia --project=.
```

Expected: exits with status 0 and creates the R-sweep plots without color errors.

- [ ] **Step 4: Commit**

```bash
git add 02_accuracy_bonddims_and_sweeps.ipynb
git commit -m "fix: use colorblind-safe R sweep palette"
```

---

## Task 4: Introduce Fused Layout In Notebook 03

**Files:**
- Modify: `03_multivariate_qtts_and_layouts.ipynb`

- [ ] **Step 1: Add fused layout markdown after grouped layout**

Insert a new Markdown cell after grouped layout code cell id `a47dbbec` and before `## Comparing bond dimensions`:

```markdown
## Fused layout

The fused layout stores the same bit position of `x` and `y` in one tensor-train site. For two variables with binary digits, each fused site has dimension 4 instead of dimension 2.

This is useful when the local relation between variables matters more than keeping each variable's bit stream separate. A fused site is therefore not an `x` site or a `y` site; it carries one joint `(x_bit, y_bit)` state.
```

- [ ] **Step 2: Add fused layout code after the new markdown**

Insert this code cell after the new Markdown cell:

```julia
fused_grid = QG.DiscretizedGrid(
    (:x, :y), (R, R);
    lower_bound=lower,
    upper_bound=upper,
    unfoldingscheme=:fused,
    includeendpoint=false,
)

fused_qtt, _, _ = QTCI.quanticscrossinterpolate(
    value_type,
    (x, y) -> target_function(x, y),
    fused_grid;
    tolerance=tolerance,
    maxbonddim=maxbonddim,
    maxiter=maxiter,
)

fused_values = [real(fused_qtt([i, j])) for i in 1:npoints, j in 1:npoints]
fused_max_abs_error = maximum(abs.(exact_values .- fused_values))

println("Fused QTT built with $R bits per dimension.")
println("Maximum absolute error on the full grid: $fused_max_abs_error")
println("Fused site dimensions: $(fused_grid.discretegrid.sitedims)")
```

- [ ] **Step 3: Update bond-dimension preparation**

In the code cell currently preparing `interleaved_bond_dims` and `grouped_bond_dims` (cell id `2e940ae2`), add the fused state after the grouped block:

```julia
fused_simple = STT.TensorTrain(fused_qtt.tci)
fused_sites = sites_from_grid(fused_grid)
fused_indexed = TN.TensorTrain(fused_simple, fused_sites)
fused_bond_dims = TN.linkdims(fused_indexed)
```

Update the print block to show fused tags:

```julia
println("bit ordering: ")
println("interleaved ", " grouped  ", " fused")
for i in 1:length(interleaved_sites)
    site_int = interleaved_sites[i]
    site_grouped = grouped_sites[i]
    site_fused = fused_sites[i]
    println(
        "  ",
        Tensor4all.tags(site_int)[1],
        "          ",
        Tensor4all.tags(site_grouped)[1],
        "          ",
        Tensor4all.tags(site_fused),
        " dim=",
        Tensor4all.dim(site_fused),
    )
end

println("Interleaved bond dimensions: $interleaved_bond_dims")
println("Grouped bond dimensions:     $grouped_bond_dims")
println("Fused bond dimensions:       $fused_bond_dims")
```

- [ ] **Step 4: Update comparison plot**

In the plot cell id `69b8273b`, add fused lines after grouped lines:

```julia
fused_bond_index = 1:length(fused_bond_dims)
lines!(ax2, fused_bond_index, fused_bond_dims;
    color=:seagreen3, linewidth=2, linestyle=:dash, label="fused")
scatter!(ax2, fused_bond_index, fused_bond_dims;
    color=:seagreen3, markersize=6)
```

Replace the `worst_profile` line with:

```julia
worst_profile = worst_case_bond_dims(
    maximum(length.([interleaved_bond_dims, grouped_bond_dims, fused_bond_dims]));
    base=4,
)
```

Change the worst-case label to:

```julia
label="base-4 worst case"
```

- [ ] **Step 5: Update explanation markdown**

In the Markdown cell after the plot, replace the first three paragraphs with:

```markdown
The left panel shows the exact target function as a heatmap on a 2D grid. The right panel shows the internal bond-dimension profiles.

The three layouts have different profiles even though they target the same function values. Interleaving alternates the bits of `x` and `y`, grouping keeps all bits of one variable together before moving to the next, and fused layout combines the same bit level of both variables into one site.

The fused sites have dimension 4, so the worst-case envelope is shown with a base-4 ceiling. All three layouts stay far below the relevant ceiling, confirming that the QTT finds genuine structure in the target function.
```

- [ ] **Step 6: Add fused result to API recap**

In the `## API recap` section, add one bullet:

```markdown
- `unfoldingscheme=:fused` combines the same bit level of multiple variables into one higher-dimensional tensor-train site.
```

- [ ] **Step 7: Run Notebook 03**

Run:

```bash
jq -r '.cells[] | select(.cell_type=="code") | "# %% cell\n" + (.source|join("")) + "\n"' 03_multivariate_qtts_and_layouts.ipynb | julia --project=.
```

Expected: exits with status 0 and prints interleaved, grouped, and fused bond dimensions.

- [ ] **Step 8: Commit**

```bash
git add 03_multivariate_qtts_and_layouts.ipynb
git commit -m "docs: introduce fused layout in notebook 03"
```

---

## Task 5: Add API Bridges In Notebooks 04 And 06

**Files:**
- Modify: `04_operations_on_qtts.ipynb`
- Modify: `06_affine_transformations.ipynb`

- [ ] **Step 1: Add `PartialContractionSpec` explanation in Notebook 04**

Insert this Markdown cell immediately before code cell id `selected-vars-product-validation`:

```markdown
### What the partial contraction specification means

`PartialContractionSpec` tells the tensor-network contraction which indices should be paired and which indices should be identified as the same variable.

Here the first argument is empty because we do not want to contract away any full variable: the output should still be a function of both `t` and `x`.

The `t_diagonal_pairs` identify the `t` sites of `F(t, x)` with the `t` sites of `m(t)`. That makes the operation behave like pointwise multiplication in the selected variable `t`.

`output_order=full_sites` keeps the resulting tensor train in the same site order as the original two-dimensional grid, so evaluation with `QG.grididx_to_quantics(grid_tx, (i, j))` remains straightforward.
```

- [ ] **Step 2: Add affine matrix explanation in Notebook 06**

Insert this Markdown cell immediately before code cell id `304fbb09`:

```markdown
### What the affine pullback arguments mean

The affine map is written with rational entries so the grid transform can be represented exactly by integer numerators and denominators.

For a two-dimensional input and output, the flat arrays are read row by row as a `2 x 2` matrix. The periodic example uses

```julia
A = [1 0;
     1 1]
b = [0, 0]
```

encoded as `a_num`, `a_den`, `b_num`, and `b_den`.

The two positional `2` arguments tell the operator that the input and output are both two-dimensional.
```

- [ ] **Step 3: Verify Markdown cells were inserted near the code**

Run:

```bash
python3 - <<'PY'
import json
checks = {
    "04_operations_on_qtts.ipynb": "What the partial contraction specification means",
    "06_affine_transformations.ipynb": "What the affine pullback arguments mean",
}
for path, phrase in checks.items():
    nb = json.load(open(path))
    joined = "\n".join("".join(c.get("source", [])) for c in nb["cells"])
    print(path, phrase in joined)
PY
```

Expected:

```text
04_operations_on_qtts.ipynb True
06_affine_transformations.ipynb True
```

- [ ] **Step 4: Run Notebooks 04 and 06**

Run:

```bash
for nb in 04_operations_on_qtts.ipynb 06_affine_transformations.ipynb; do
  printf '\n===== RUN %s =====\n' "$nb"
  jq -r '.cells[] | select(.cell_type=="code") | "# %% cell\n" + (.source|join("")) + "\n"' "$nb" | julia --project=.
  rc=$?
  printf '===== EXIT %s: %s =====\n' "$nb" "$rc"
  if [ "$rc" -ne 0 ]; then exit "$rc"; fi
done
```

Expected: both notebooks exit with status 0.

- [ ] **Step 5: Commit**

```bash
git add 04_operations_on_qtts.ipynb 06_affine_transformations.ipynb
git commit -m "docs: explain selected contraction and affine pullback APIs"
```

---

## Task 6: Add Integration Bridge In Notebook 04

**Files:**
- Modify: `04_operations_on_qtts.ipynb`

- [ ] **Step 1: Replace Part 3 heading cell**

In Markdown cell id `71e660ae`, keep the heading and add this bridge below it:

```markdown
## Part 3: Integration of a QTT

After multiplication, we look at a second basic operation: summing or integrating values represented by a QTT.

This section returns to a one-dimensional example on purpose. The goal is to isolate the integration API before combining it with the more complex two-dimensional operations above.
```

- [ ] **Step 2: Run Notebook 04**

Run:

```bash
jq -r '.cells[] | select(.cell_type=="code") | "# %% cell\n" + (.source|join("")) + "\n"' 04_operations_on_qtts.ipynb | julia --project=.
```

Expected: exits with status 0.

- [ ] **Step 3: Commit**

```bash
git add 04_operations_on_qtts.ipynb
git commit -m "docs: bridge integration section in operations notebook"
```

---

## Task 7: Simplify Notebook 05 Fourier Helpers And Explanations

**Files:**
- Modify: `05_fourier_transforms.ipynb`

- [ ] **Step 1: Add `LaTeXStrings` import**

In setup code cell id `1ea92d8e`, add this line after `using FFTW`:

```julia
using LaTeXStrings
```

- [ ] **Step 2: Simplify `quantics_digits`**

In code cell id `72415005`, replace the helper:

```julia
function quantics_digits(i, r)
# Convert 0-based bits to 1-based quantics digits (0,bullet1, 1,bullet2)
    d = Base.digits(i - 1; base=2, pad=r)
    return [x == 0 ? 1 : 2 for x in reverse(d)]
end
```

with:

```julia
function quantics_digits(i, r)
    bits_little_endian = Base.digits(i - 1; base=2, pad=r)
    bits_big_endian = reverse(bits_little_endian)
    return [bit == 0 ? 1 : 2 for bit in bits_big_endian]
end
```

Then delete this line inside the loop:

```julia
reverse!(site_vals)
```

- [ ] **Step 3: Add TL;DR scaling sentences**

After code cell id `72415005`, insert this Markdown cell:

```markdown
The two scaling factors above have separate jobs:

- `sqrt(N)` compensates for the unitary normalization used by the discrete Fourier operator.
- `Δx` turns the discrete sum into an approximation of the continuous Fourier integral.
```

- [ ] **Step 4: Add local `sites_from_grid` helper before 2D state construction**

In Part 2, before code cell id `7a6a35ac` or at the top of that cell before `grid2 = ...`, add:

```julia
function sites_from_grid(grid)
    index_table = grid.discretegrid.indextable
    site_dims = grid.discretegrid.sitedims

    return [
        Tensor4all.Index(site_dims[site]; tags=[string(variable, "=", bit) for (variable, bit) in entries])
        for (site, entries) in pairs(index_table)
    ]
end
```

- [ ] **Step 5: Replace semantic `sites2` construction**

In code cell id `7a6a35ac`, replace:

```julia
sites2 = [Tensor4all.Index(2; tags=["x", "bit=$i"]) for i in 1:length(simple_tt2)]
```

with:

```julia
sites2 = sites_from_grid(grid2)
```

- [ ] **Step 6: Run Notebook 05**

Run:

```bash
jq -r '.cells[] | select(.cell_type=="code") | "# %% cell\n" + (.source|join("")) + "\n"' 05_fourier_transforms.ipynb | julia --project=.
```

Expected: exits with status 0 and prints Fourier reconstruction errors.

- [ ] **Step 7: Commit**

```bash
git add 05_fourier_transforms.ipynb
git commit -m "docs: simplify Fourier helper explanations"
```

---

## Task 8: Small Beginner-Clarity Polish

**Files:**
- Modify: `01_first_qtt_function_and_grid.ipynb`
- Modify: `06_affine_transformations.ipynb`

- [ ] **Step 1: Expand TCI once in Notebook 01**

Find the first Markdown occurrence of `TCI` in `01_first_qtt_function_and_grid.ipynb`. Replace the first sentence that uses `TCI` without expansion with:

```markdown
TCI (Tensor Cross Interpolation) builds the QTT by querying selected function values instead of evaluating all `2^R` grid points.
```

Keep surrounding prose intact.

- [ ] **Step 2: Remove final empty Markdown cell in Notebook 06 if it exists**

Run:

```bash
python3 - <<'PY'
import json
path = "06_affine_transformations.ipynb"
nb = json.load(open(path))
last = nb["cells"][-1]
print(last["cell_type"], "".join(last.get("source", [])).strip() == "")
PY
```

Expected: prints whether the final cell is empty.

If it prints:

```text
markdown True
```

remove only that final empty Markdown cell.

- [ ] **Step 3: Keep `ylabelrotation=0`**

Verify:

```bash
rg -n "ylabelrotation=0" 06_affine_transformations.ipynb
```

Expected: three matches in the open-boundary heatmap axes.

- [ ] **Step 4: Run Notebooks 01 and 06**

Run:

```bash
for nb in 01_first_qtt_function_and_grid.ipynb 06_affine_transformations.ipynb; do
  printf '\n===== RUN %s =====\n' "$nb"
  jq -r '.cells[] | select(.cell_type=="code") | "# %% cell\n" + (.source|join("")) + "\n"' "$nb" | julia --project=.
  rc=$?
  printf '===== EXIT %s: %s =====\n' "$nb" "$rc"
  if [ "$rc" -ne 0 ]; then exit "$rc"; fi
done
```

Expected: both notebooks exit with status 0.

- [ ] **Step 5: Commit**

```bash
git add 01_first_qtt_function_and_grid.ipynb 06_affine_transformations.ipynb
git commit -m "docs: polish beginner-facing tutorial notes"
```

---

## Task 9: Update Review Document Status

**Files:**
- Modify: `docs/tutorial-review-2026-05-06.md`

- [ ] **Step 1: Add implementation status section**

At the top of `docs/tutorial-review-2026-05-06.md`, after the introductory test note and before `## Prioritätsdefinition`, add:

```markdown
## Implementation Status

This review has been turned into an implementation plan:

- Plan file: `docs/superpowers/plans/2026-05-07-tutorial-review-implementation.md`
- Decisions are resolved; remaining work is implementation and verification.
- Color check result: no global color refactor needed; only Notebook 02's R-sweep palette needs a colorblind-safe categorical replacement.
```

- [ ] **Step 2: Mark resolved decisions**

In `## Entscheidungen Vor Umsetzung`, keep:

```markdown
Aktuell keine offenen Entscheidungen mehr. Die noch verbleibenden Punkte sind
Umsetzungsarbeit, keine Richtungsfragen.
```

- [ ] **Step 3: Verify no stale decision prompts remain**

Run:

```bash
rg -n "Offene Entscheidung|Entscheidung nötig|Bitte vor Implementierung entscheiden|Farbstrategie" docs/tutorial-review-2026-05-06.md
```

Expected: no matches.

- [ ] **Step 4: Commit**

```bash
git add docs/tutorial-review-2026-05-06.md docs/superpowers/plans/2026-05-07-tutorial-review-implementation.md
git commit -m "docs: add tutorial remediation implementation plan"
```

---

## Task 10: Full Final Verification

**Files:**
- Verify all modified files.

- [ ] **Step 1: Run all notebooks**

Run:

```bash
for nb in 01_first_qtt_function_and_grid.ipynb 02_accuracy_bonddims_and_sweeps.ipynb 03_multivariate_qtts_and_layouts.ipynb 04_operations_on_qtts.ipynb 05_fourier_transforms.ipynb 06_affine_transformations.ipynb; do
  printf '\n===== RUN %s =====\n' "$nb"
  jq -r '.cells[] | select(.cell_type=="code") | "# %% cell\n" + (.source|join("")) + "\n"' "$nb" | julia --project=.
  rc=$?
  printf '===== EXIT %s: %s =====\n' "$nb" "$rc"
  if [ "$rc" -ne 0 ]; then exit "$rc"; fi
done
```

Expected: all six notebooks exit with status 0.

- [ ] **Step 2: Check agreed constraints**

Run:

```bash
rg -n "tolerance = 1e-10|tolerance=1e-10|tolerance=1e-8|maxbonddim = 32|maxbonddim=32|maxdim=32|Next:" *.ipynb README.md docs/tutorial-learning-path.md
```

Expected:

- No live source-cell matches for the old tolerance or `maxbonddim=32`.
- No `Next:` footers.

Run:

```bash
rg -n "colormap=:navia|raw_colors|RGBf|ylabelrotation=0|using LaTeXStrings|sites2 = sites_from_grid|reverse!\\(site_vals\\)" *.ipynb
```

Expected:

- `:navia` is still present.
- `RGBf` appears in Notebook 02.
- `ylabelrotation=0` appears in Notebook 06.
- `using LaTeXStrings` appears in Notebook 05.
- `sites2 = sites_from_grid(grid2)` appears in Notebook 05.
- `reverse!(site_vals)` does not appear.

- [ ] **Step 3: Review git diff**

Run:

```bash
git status --short
git diff --stat
```

Expected: only the planned files are modified.

- [ ] **Step 4: Final commit if needed**

If Task 10 produced small verification fixes, commit them:

```bash
git add README.md docs/tutorial-learning-path.md docs/tutorial-review-2026-05-06.md docs/superpowers/plans/2026-05-07-tutorial-review-implementation.md 01_first_qtt_function_and_grid.ipynb 02_accuracy_bonddims_and_sweeps.ipynb 03_multivariate_qtts_and_layouts.ipynb 04_operations_on_qtts.ipynb 05_fourier_transforms.ipynb 06_affine_transformations.ipynb
git commit -m "test: verify tutorial remediation"
```

If there are no changes after verification, do not create an empty commit.

---

## Self-Review

Spec coverage:

- README/Learning Path summary: Task 1.
- Parameter standardization without `includeendpoint` changes: Task 2.
- Color accessibility check and minimal palette fix: Task 3.
- Fused layout in Notebook 03: Task 4.
- API bridges for `PartialContractionSpec` and affine pullback: Task 5.
- Integration bridge: Task 6.
- Notebook 05 Fourier cleanup: Task 7.
- Local helper decision: Task 7 keeps helper local; Task 4 reuses local helper style.
- Beginner polish without unnecessary churn: Task 8.
- Review document update: Task 9.
- Full verification: Task 10.

No placeholder work remains in this plan. Each task has files, exact changes, commands, expected results, and a commit point.

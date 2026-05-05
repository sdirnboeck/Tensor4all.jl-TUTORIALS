# Notebook 04 Variable-Selective Products Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a variable-selective elementwise multiplication example to `04_operations_on_qtts.ipynb`, including an unfused `:interleaved`/`:grouped` workflow and a short executable `:fused` workflow.

**Architecture:** The notebook remains a guided worksheet. The new section teaches that selected-variable multiplication is controlled by Tensor4all site indices and tags. The main workflow embeds a one-variable `m(t)` TensorTrain into a two-variable `(t, x)` site set with `TN.matchsiteinds`; the fused workflow builds `(t, x) -> m(t)` directly on a fused grid because fused sites combine variable bits.

**Tech Stack:** Jupyter notebook JSON, Julia 1.12 project environment, `Tensor4all.jl`, `QuanticsGrids`, `QuanticsTCI`, `TensorNetworks`, `SimpleTT`, `CairoMakie`, `LaTeXStrings`, `jq`.

---

## Files

- Modify: `04_operations_on_qtts.ipynb`
- Read/reference: `docs/superpowers/specs/2026-05-05-variable-selective-qtt-products-design.md`
- Read/reference: `docs/tutorial-learning-path.md`
- Read/reference: `docs/superpowers/plans/2026-04-23-tensor4all-jl-tutorial-notebooks.md`

No helper source files should be created. In the notebook, avoid local helper functions when the code is only 1-3 lines and used only 1-3 times. The only planned local helper is `sites_from_grid(grid)`, because it exposes the central layout-to-site-tag mapping.

## Task 1: Update Notebook Structure And Learning Goals

**Files:**
- Modify: `04_operations_on_qtts.ipynb`

- [ ] **Step 1: Inspect current cell order**

Run:

```bash
jq -r '.cells | to_entries[] | "CELL \(.key+1) [\(.value.cell_type)] " + ((.value.source // []) | join("") | split("\n")[0])' 04_operations_on_qtts.ipynb
```

Expected: Notebook has `Part 1: Elementwise product of two QTTs`, then `Part 2: Integration of a QTT`, then `What to notice`, then `API recap`.

- [ ] **Step 2: Update learning goals markdown**

Replace the current learning-goals body with:

```markdown
- compute the elementwise product of two QTT-represented functions
- observe how bond dimensions grow under multiplication
- multiply a multivariate QTT by a factor that acts only on selected variables
- compare how selected-variable multiplication is represented in unfused and fused layouts
- compute the definite integral of a QTT on a physical interval
- validate operations against analytic references
```

- [ ] **Step 3: Insert the new section heading before integration**

Insert these two Markdown cells before the current integration heading:

```markdown
## Part 2: Multiplying only selected variables
```

```markdown
In applications, a multivariate object may be multiplied by a factor that only depends on some of its variables. For example, a function of `(t, kx, ky, kz)` might be multiplied by a time-dependent factor `m(t)`.

Here we use a smaller two-dimensional example. The base function depends on `(t, x)`, while the modulation depends only on `t`:

$$F(t, x) = 1 + 0.3\sin(8t) + x^2 + 0.2tx,$$

$$m(t) = \exp(-3t),$$

so the product is

$$H(t, x) = F(t, x)m(t).$$

The important Tensor4all.jl idea is that the selected variable is represented through site indices. We will tag the sites from the grid, select the `t` sites, and embed the one-variable factor into the full `(t, x)` site set.
```

- [ ] **Step 4: Rename integration section heading**

Change:

```markdown
## Part 2: Integration of a QTT
```

to:

```markdown
## Part 3: Integration of a QTT
```

- [ ] **Step 5: Commit structure update**

Run:

```bash
git add 04_operations_on_qtts.ipynb
git commit -m "Update notebook 04 structure for variable-selective products"
```

Expected: One commit containing only `04_operations_on_qtts.ipynb`.

## Task 2: Add The Unfused Selected-Variable Product Workflow

**Files:**
- Modify: `04_operations_on_qtts.ipynb`

- [ ] **Step 1: Add parameters and target functions**

Add a code cell after the new Part 2 introduction:

```julia
layout = :interleaved
# Try also: :grouped

R = 7
npoints_2d = 1 << R

selected_value_type = Float64
selected_tolerance = 1e-10
selected_maxbonddim = 32
selected_maxiter = 200

base_function(t, x) = 1 + 0.3 * sin(8 * t) + x^2 + 0.2 * t * x
modulation(t) = exp(-3 * t)
selected_product(t, x) = base_function(t, x) * modulation(t);
```

- [ ] **Step 2: Add the grid and explain the layout parameter**

Add a Markdown cell:

```markdown
We start with an unfused layout. The default is `:interleaved`, where the `t` and `x` bits alternate along the tensor train. If you change `layout` to `:grouped`, all `t` bits come before all `x` bits.

The code below does not hard-code either ordering. It reads the site structure from the grid and uses tags such as `t=1`, `t=2`, ... to identify the selected variable.
```

Add a code cell:

```julia
grid_tx = QG.DiscretizedGrid(
    (:t, :x), (R, R);
    lower_bound=0.0,
    upper_bound=(1.0, 1.0),
    unfoldingscheme=layout,
    includeendpoint=false,
)

t_coords = [QG.grididx_to_origcoord(grid_tx, (i, 1))[1] for i in 1:npoints_2d]
x_coords = [QG.grididx_to_origcoord(grid_tx, (1, j))[2] for j in 1:npoints_2d]

println("Selected-variable example with layout = $layout.")
println("R = $R gives $npoints_2d grid points in each direction.")
println("Index table: $(QG.grid_indextable(grid_tx))")
```

- [ ] **Step 3: Add the only local helper**

Add a Markdown cell:

```markdown
The next small helper turns the grid index table into Tensor4all site indices. This is the only helper in this section because it carries the main idea: the grid defines which variable bits live on each tensor-train site.
```

Add a code cell:

```julia
function sites_from_grid(grid)
    return [
        Tensor4all.Index(
            QG.sitedim(grid, site);
            tags=[string(variable, "=", bit) for (variable, bit) in entries],
        )
        for (site, entries) in pairs(QG.grid_indextable(grid))
    ]
end

full_sites = sites_from_grid(grid_tx)
println("Site tags:")
for site in full_sites
    println("  ", Tensor4all.tags(site), "  dim=", Tensor4all.dim(site))
end
```

- [ ] **Step 4: Build and index `F(t, x)`**

Add a Markdown cell:

```markdown
We build the two-variable QTT for `F(t, x)` on the full `(t, x)` grid. Then we attach the site indices from the grid to the raw tensor train.
```

Add a code cell:

```julia
qtt_F, _, _ = QTCI.quanticscrossinterpolate(
    selected_value_type,
    (t, x) -> base_function(t, x),
    grid_tx;
    tolerance=selected_tolerance,
    maxbonddim=selected_maxbonddim,
    maxiter=selected_maxiter,
)

simple_F = STT.TensorTrain(qtt_F.tci)
tt_F = TN.TensorTrain(simple_F, full_sites)

t_sites = TN.findallsiteinds_by_tag(tt_F; tag="t")
println("Selected t-sites:")
for site in t_sites
    println("  ", Tensor4all.tags(site), "  dim=", Tensor4all.dim(site))
end
```

- [ ] **Step 5: Build `m(t)` and embed it into the full site set**

Add a Markdown cell:

```markdown
The modulation `m(t)` is a one-variable QTT. We attach it to the selected `t` sites, then use `TN.matchsiteinds` to insert constant-one tensors on all missing `x` sites. After this embedding, `m(t)` has the same full site structure as `F(t, x)`.
```

Add a code cell:

```julia
grid_t = QG.DiscretizedGrid(
    (:t,), (R,);
    lower_bound=0.0,
    upper_bound=(1.0,),
    unfoldingscheme=:grouped,
    includeendpoint=false,
)

qtt_m, _, _ = QTCI.quanticscrossinterpolate(
    selected_value_type,
    t -> modulation(t),
    grid_t;
    tolerance=selected_tolerance,
    maxbonddim=selected_maxbonddim,
    maxiter=selected_maxiter,
)

simple_m = STT.TensorTrain(qtt_m.tci)
tt_m_sparse = TN.TensorTrain(simple_m, t_sites)
tt_m_full = TN.matchsiteinds(tt_m_sparse, full_sites)

println("Sparse m(t) bond dimensions:   $(TN.linkdims(tt_m_sparse))")
println("Embedded m(t) bond dimensions: $(TN.linkdims(tt_m_full))")
```

- [ ] **Step 6: Multiply and validate the unfused product**

Add a Markdown cell:

```markdown
Now both tensor trains have the same site structure, so `TN.elementwise_product` multiplies them pointwise. We validate against the analytic product on the full grid.
```

Add a code cell:

```julia
tt_H_raw = TN.elementwise_product(tt_F, tt_m_full;
    threshold=selected_tolerance,
    maxdim=selected_maxbonddim,
)
tt_H = TN.truncate(tt_H_raw; threshold=selected_tolerance, maxdim=selected_maxbonddim)

exact_H = [selected_product(t_coords[i], x_coords[j]) for i in 1:npoints_2d, j in 1:npoints_2d]
H_values = [
    real(TN.evaluate(tt_H, full_sites, QG.grididx_to_quantics(grid_tx, (i, j))))
    for i in 1:npoints_2d, j in 1:npoints_2d
]
H_abs_error = abs.(exact_H .- H_values)
H_max_abs_error = maximum(H_abs_error)

println("Maximum absolute error for selected-variable product: $H_max_abs_error")
```

- [ ] **Step 7: Add the interpretation cell**

Add a Markdown cell:

```markdown
The same code works for `:interleaved` and `:grouped` because it never assumes that the selected sites are contiguous. In the interleaved layout the `t` sites are separated by `x` sites; in the grouped layout they appear together. In both cases, the tags identify the selected variable.
```

- [ ] **Step 8: Commit unfused workflow**

Run:

```bash
git add 04_operations_on_qtts.ipynb
git commit -m "Add unfused selected-variable QTT product example"
```

Expected: Commit contains the new unfused workflow cells.

## Task 3: Add Main Workflow Plot

**Files:**
- Modify: `04_operations_on_qtts.ipynb`

- [ ] **Step 1: Add bond dimension data**

Add a code cell after the unfused validation:

```julia
bond_F_selected = TN.linkdims(tt_F)
bond_m_full = TN.linkdims(tt_m_full)
bond_H_selected = TN.linkdims(tt_H)

println("Bond dimensions for selected-variable product:")
println("  F(t, x):              $bond_F_selected")
println("  embedded m(t):        $bond_m_full")
println("  product F(t, x)m(t):  $bond_H_selected")
```

- [ ] **Step 2: Add the four-panel figure**

Add a code cell:

```julia
fig_selected = Figure(size=(1050, 760))

ax_exact = Axis(
    fig_selected[1, 1],
    xlabel="t", ylabel="x",
    title="Analytic product",
)
hm_exact = heatmap!(ax_exact, t_coords, x_coords, exact_H; colormap=:navia, interpolate=false)
Colorbar(fig_selected[1, 2], hm_exact, label="value")

ax_qtt = Axis(
    fig_selected[1, 3],
    xlabel="t", ylabel="x",
    title="QTT product",
)
hm_qtt = heatmap!(ax_qtt, t_coords, x_coords, H_values; colormap=:navia, interpolate=false)
Colorbar(fig_selected[1, 4], hm_qtt, label="value")

ax_error = Axis(
    fig_selected[2, 1],
    xlabel="t", ylabel="x",
    title="Absolute error",
)
hm_error = heatmap!(ax_error, t_coords, x_coords, H_abs_error; colormap=:navia, interpolate=false)
Colorbar(fig_selected[2, 2], hm_error, label="absolute error")

ax_bonds = Axis(
    fig_selected[2, 3],
    xlabel="bond link", ylabel="bond dimension",
    title="Bond dimensions",
    yscale=log2,
)

idx_F_selected = 1:length(bond_F_selected)
lines!(ax_bonds, idx_F_selected, bond_F_selected; color=:black, linewidth=2, label=L"F(t,x)")
scatter!(ax_bonds, idx_F_selected, bond_F_selected; color=:black, markersize=6)

idx_m_full = 1:length(bond_m_full)
lines!(ax_bonds, idx_m_full, bond_m_full; color=:deepskyblue4, linewidth=2, label=L"m(t)\ \mathrm{embedded}")
scatter!(ax_bonds, idx_m_full, bond_m_full; color=:deepskyblue4, markersize=6)

idx_H_selected = 1:length(bond_H_selected)
lines!(ax_bonds, idx_H_selected, bond_H_selected; color=:goldenrod2, linewidth=2, label=L"F(t,x)m(t)")
scatter!(ax_bonds, idx_H_selected, bond_H_selected; color=:goldenrod2, markersize=6)

axislegend(ax_bonds; position=:lt)

fig_selected
```

- [ ] **Step 3: Add plot interpretation**

Add a Markdown cell:

```markdown
The first two heatmaps should be visually indistinguishable at this scale. The error plot checks the product across the whole two-dimensional grid. The bond-dimension panel shows the structural cost of carrying out the product in tensor-train form.
```

- [ ] **Step 4: Commit plot**

Run:

```bash
git add 04_operations_on_qtts.ipynb
git commit -m "Plot selected-variable QTT product validation"
```

Expected: Commit contains only the plot and interpretation cells for the main workflow.

## Task 4: Add The Fused Workflow

**Files:**
- Modify: `04_operations_on_qtts.ipynb`

- [ ] **Step 1: Add fused explanation**

Add a Markdown cell after the main workflow plot interpretation:

```markdown
### Fused layout
```

Add another Markdown cell:

```markdown
The fused layout needs a separate construction. In a fused two-variable grid, one tensor-train site can contain both `t=i` and `x=i`. There is no separate pure `t` site to embed into.

To multiply only in `t`, we build the factor on the fused `(t, x)` grid as `(t, x) -> m(t)`. The function ignores `x`, but its tensor train has the correct fused site dimensions and tags.
```

- [ ] **Step 2: Build fused grid and print site tags**

Add a code cell:

```julia
fused_grid_tx = QG.DiscretizedGrid(
    (:t, :x), (R, R);
    lower_bound=0.0,
    upper_bound=(1.0, 1.0),
    unfoldingscheme=:fused,
    includeendpoint=false,
)

fused_sites = sites_from_grid(fused_grid_tx)

println("Fused index table: $(QG.grid_indextable(fused_grid_tx))")
println("Fused site tags:")
for site in fused_sites
    println("  ", Tensor4all.tags(site), "  dim=", Tensor4all.dim(site))
end
```

- [ ] **Step 3: Build fused QTTs and multiply**

Add a code cell:

```julia
qtt_F_fused, _, _ = QTCI.quanticscrossinterpolate(
    selected_value_type,
    (t, x) -> base_function(t, x),
    fused_grid_tx;
    tolerance=selected_tolerance,
    maxbonddim=selected_maxbonddim,
    maxiter=selected_maxiter,
)

qtt_m_fused, _, _ = QTCI.quanticscrossinterpolate(
    selected_value_type,
    (t, x) -> modulation(t),
    fused_grid_tx;
    tolerance=selected_tolerance,
    maxbonddim=selected_maxbonddim,
    maxiter=selected_maxiter,
)

simple_F_fused = STT.TensorTrain(qtt_F_fused.tci)
simple_m_fused = STT.TensorTrain(qtt_m_fused.tci)
tt_F_fused = TN.TensorTrain(simple_F_fused, fused_sites)
tt_m_fused = TN.TensorTrain(simple_m_fused, fused_sites)

tt_H_fused_raw = TN.elementwise_product(tt_F_fused, tt_m_fused;
    threshold=selected_tolerance,
    maxdim=selected_maxbonddim,
)
tt_H_fused = TN.truncate(tt_H_fused_raw; threshold=selected_tolerance, maxdim=selected_maxbonddim)
```

- [ ] **Step 4: Validate fused workflow without plotting**

Add a code cell:

```julia
fused_H_values = [
    real(TN.evaluate(tt_H_fused, fused_sites, QG.grididx_to_quantics(fused_grid_tx, (i, j))))
    for i in 1:npoints_2d, j in 1:npoints_2d
]
fused_H_abs_error = abs.(exact_H .- fused_H_values)
fused_H_max_abs_error = maximum(fused_H_abs_error)

println("Maximum absolute error for fused selected-variable product: $fused_H_max_abs_error")
println("Fused F(t, x) bond dimensions:             $(TN.linkdims(tt_F_fused))")
println("Fused m(t) on (t, x) bond dimensions:      $(TN.linkdims(tt_m_fused))")
println("Fused product F(t, x)m(t) bond dimensions: $(TN.linkdims(tt_H_fused))")
```

- [ ] **Step 5: Add fused interpretation**

Add a Markdown cell:

```markdown
The fused workflow computes the same mathematical product, but the factor is constructed differently. Because each fused site can combine several variable bits, the selected-variable factor is built on the fused multivariate grid and made constant in the non-target variable.
```

- [ ] **Step 6: Commit fused workflow**

Run:

```bash
git add 04_operations_on_qtts.ipynb
git commit -m "Add fused selected-variable QTT product example"
```

Expected: Commit contains the fused subsection and no extra plot block.

## Task 5: Update Summary, API Recap, And Verify The Notebook

**Files:**
- Modify: `04_operations_on_qtts.ipynb`

- [ ] **Step 1: Update What to notice**

Replace the current `What to notice` bullet list with:

```markdown
- `TensorNetworks.elementwise_product` computes the pointwise product directly in tensor-train form.
- The product QTT can have larger bond dimensions than either factor alone. This is rank growth under multiplication.
- Variable-selective multiplication is controlled by site indices.
- Tags such as `t=1`, `t=2`, ... identify which quantics bits belong to a variable.
- For `:interleaved` and `:grouped`, `TensorNetworks.matchsiteinds` can embed a one-variable factor into a larger multivariate site set.
- For `:fused`, a selected-variable factor can be built on the fused grid as a multivariate function that ignores the non-target variables.
- `QuanticsTCI.integral` computes the definite integral of a QTT on a physical interval.
- The integral converges toward the exact analytic value as the grid resolution `R` increases.
- `x^2` is simple enough that its QTT bond dimensions stay small as `R` changes.
```

- [ ] **Step 2: Update API recap**

Replace the current `API recap` bullet list with:

```markdown
- `Tensor4all.QuanticsTCI.quanticscrossinterpolate` (building factor QTTs)
- `Tensor4all.QuanticsTCI.integral` (definite integral on a `DiscretizedGrid`)
- `Tensor4all.QuanticsGrids.DiscretizedGrid`
- `Tensor4all.QuanticsGrids.grid_indextable`
- `Tensor4all.QuanticsGrids.grididx_to_quantics`
- `Tensor4all.QuanticsGrids.sitedim`
- `Tensor4all.SimpleTT.TensorTrain`
- `Tensor4all.TensorNetworks.TensorTrain`
- `Tensor4all.TensorNetworks.elementwise_product`
- `Tensor4all.TensorNetworks.evaluate`
- `Tensor4all.TensorNetworks.findallsiteinds_by_tag`
- `Tensor4all.TensorNetworks.linkdims`
- `Tensor4all.TensorNetworks.matchsiteinds`
- `Tensor4all.TensorNetworks.truncate`
```

- [ ] **Step 3: Verify notebook JSON is valid**

Run:

```bash
jq empty 04_operations_on_qtts.ipynb
```

Expected: command exits with no output.

- [ ] **Step 4: Execute notebook in the project environment**

Run:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
jupyter nbconvert --to notebook --execute --inplace 04_operations_on_qtts.ipynb --ExecutePreprocessor.timeout=600
```

Expected: notebook executes without Julia or Jupyter errors. If the selected-variable section is too slow at `R = 7`, change only that section's `R = 7` to `R = 6`, rerun this step, and mention the change in the commit message.

- [ ] **Step 5: Check learner-facing text constraints**

Run:

```bash
rg -n "Rust|rust|missing feature|TODO|TBD|workaround|obviously|clearly" 04_operations_on_qtts.ipynb
```

Expected: no learner-facing prohibited terms. Existing words inside metadata or unrelated paths should be inspected and ignored only if they are not visible notebook prose.

- [ ] **Step 6: Check final diff**

Run:

```bash
git diff -- 04_operations_on_qtts.ipynb
```

Expected: changes are limited to:

- learning goals,
- new selected-variable product section,
- integration heading renumbering,
- updated `What to notice`,
- updated `API recap`,
- execution counts and outputs produced by notebook execution.

- [ ] **Step 7: Commit verification pass**

Run:

```bash
git add 04_operations_on_qtts.ipynb
git commit -m "Verify notebook 04 variable-selective products"
```

Expected: final notebook commit with executed outputs and summary/API updates.

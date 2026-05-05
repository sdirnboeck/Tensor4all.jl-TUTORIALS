# Variable-Selective QTT Products Design

Date: 2026-05-05

## Goal

Add a new example to `04_operations_on_qtts.ipynb` that teaches how to
multiply a multivariate QTT by a factor that acts only on selected variables.
The example should make the practical Tensor4all.jl workflow clear: variable
selection is represented through site indices and tags, not through a separate
high-level "multiply in this variable" API.

The main learner-facing operation is:

```math
H(t, x) = F(t, x) m(t)
```

where `F` is represented as a two-variable QTT and `m` is represented as a
one-variable factor that should affect only the `t` variable.

## Notebook Placement

Insert the new section after the current one-dimensional elementwise-product
section and before integration:

1. `Part 1: Elementwise product of two QTTs`
2. `Part 2: Multiplying only selected variables`
3. `Part 3: Integration of a QTT`

Update the learning goals, "What to notice", and API recap to include
variable-selective products, partial contractions, and tag-based site
selection.

## Teaching Example

Use a compact two-dimensional example:

```math
F(t, x) = 1 + 0.3 \sin(8t) + x^2 + 0.2tx
```

and

```math
m(t) = \exp(-3t).
```

The expected product is:

```math
H(t, x) = F(t, x)m(t).
```

This keeps the example easy to validate on the full grid while matching the
larger application pattern:

```math
A(t, k_x, k_y, k_z) m(t)
```

or, more generally, multiplying only over a subset of variables.

## Layout Strategy

The section should explicitly distinguish two cases:

1. Unfused layouts: `:interleaved` and `:grouped`
2. Fused layout: `:fused`

For unfused layouts, each tensor-train site contains one variable-bit pair such
as `t=1` or `x=1`. The one-dimensional factor `m(t)` can be built on fresh
site indices that mirror the selected `t` sites. A partial contraction then
diagonal-pairs only those selected `t` sites and leaves the `x` sites from
`F(t, x)` in the output.

For fused layouts, one tensor-train site can contain several variable bits at
the same bit level. For `(:t, :x)` and `R = 4`, the site structure is:

```text
site 1: (x=1, t=1)
site 2: (x=2, t=2)
site 3: (x=3, t=3)
site 4: (x=4, t=4)
```

The exact order follows the grid's stored index table at
`grid.discretegrid.indextable`; for fused layouts, QuanticsGrids stores
variables in reverse variable order inside each fused site so the first
coordinate varies fastest.

This means that a pure one-variable `m(t)` is not represented by a subset of
sites in the fused layout. Instead, the fused-compatible factor must live on
the same fused sites and be constant in the non-target variable bit within each
site.

## Helper Functions

Add small helper functions in the notebook, close to the new example. They
should stay pedagogical rather than becoming a general-purpose package layer.

### Site Construction From A Grid

Build Tensor4all site indices directly from the grid's index table:

```julia
function sites_from_grid(grid)
    index_table = grid.discretegrid.indextable
    site_dims = grid.discretegrid.sitedims
    return [
        Tensor4all.Index(
            site_dims[site];
            tags=[string(variable, "=", bit) for (variable, bit) in entries],
        )
        for (site, entries) in pairs(index_table)
    ]
end
```

This is the key teaching device. It connects the mathematical variable names
to concrete Tensor4all site tags.

Do not add a separate `qtt_to_indexed_tt` helper in this section. The
conversion is short enough that it is clearer to show it directly:

```julia
simple_F = STT.TensorTrain(qtt_F.tci)
tt_F = TN.TensorTrain(simple_F, full_sites)
```

This keeps the tutorial transparent: learners see both steps, first extracting
the raw tensor train and then attaching the site indices.

## Unfused Workflow

For `:interleaved` and `:grouped`, use a layout parameter:

```julia
layout = :interleaved
# try also: :grouped
R = 7

grid_tx = QG.DiscretizedGrid(
    (:t, :x), (R, R);
    lower_bound=0.0,
    upper_bound=(1.0, 1.0),
    unfoldingscheme=layout,
    includeendpoint=false,
)
```

Build `F(t, x)` on `grid_tx`, build `m(t)` on a one-dimensional `t` grid, then
give the one-dimensional factor fresh site indices corresponding to the
selected `t` sites from the two-dimensional QTT:

```julia
full_sites = sites_from_grid(grid_tx)
simple_F = STT.TensorTrain(qtt_F.tci)
tt_F = TN.TensorTrain(simple_F, full_sites)

t_sites = TN.findallsiteinds_by_tag(tt_F; tag="t")

grid_t = QG.DiscretizedGrid((:t,), (R,);
    lower_bound=0.0,
    upper_bound=(1.0,),
    unfoldingscheme=:grouped,
    includeendpoint=false,
)

qtt_m, _, _ = QTCI.quanticscrossinterpolate(
    value_type,
    t -> modulation(t),
    grid_t;
    tolerance=tolerance,
    maxbonddim=maxbonddim,
    maxiter=maxiter,
)

simple_m = STT.TensorTrain(qtt_m.tci)
m_sites = [Tensor4all.sim(site) for site in t_sites]
tt_m_sparse = TN.TensorTrain(simple_m, m_sites)

t_diagonal_pairs = [t_sites[i] => m_sites[i] for i in eachindex(t_sites)]
selected_product_spec = TN.PartialContractionSpec(
    Pair{Tensor4all.Index,Tensor4all.Index}[],
    t_diagonal_pairs;
    output_order=full_sites,
)

tt_H_raw = TN.partial_contract(tt_F, tt_m_sparse, selected_product_spec;
    threshold=tolerance,
    maxdim=maxbonddim,
)
tt_H = TN.truncate(tt_H_raw; threshold=tolerance, maxdim=maxbonddim)
```

The prose should explain:

- `t_sites` are the positions where `m(t)` is allowed to act.
- `m_sites` are fresh indices for the `m(t)` tensor train, with the same
  dimensions and tags as the selected `t` sites.
- `TN.PartialContractionSpec` records the diagonal pairs between selected
  `F(t, x)` sites and `m(t)` sites, and keeps `output_order=full_sites`.
- `TN.partial_contract` performs the selected-site product without changing
  the unselected `x` output sites.
- In `:grouped`, the `t` sites are contiguous.
- In `:interleaved`, the `t` sites are separated by `x` sites.
- The code stays the same because it uses tags instead of hard-coded positions.

Use `:interleaved` as the default layout. This is likely the layout many
learners will encounter first, and it makes the tag-based approach useful
immediately: the selected `t` sites are not contiguous, but the code still
finds them by tag. Mention `:grouped` as a simple parameter change and explain
that it makes the `t` sites contiguous.

## Fused Workflow

Include a short fused subsection. This should not be presented as just another
value for the same `layout` parameter, because the site meaning is different.
The fused subsection should be executable and should print a validation error,
but it should not add a second full plot block.

The fused code example should build a second two-dimensional QTT factor that
is mathematically constant in `x`:

```julia
fused_grid_tx = QG.DiscretizedGrid(
    (:t, :x), (R, R);
    lower_bound=0.0,
    upper_bound=(1.0, 1.0),
    unfoldingscheme=:fused,
    includeendpoint=false,
)

fused_sites = sites_from_grid(fused_grid_tx)

qtt_F_fused, _, _ = QTCI.quanticscrossinterpolate(
    value_type,
    (t, x) -> base_function(t, x),
    fused_grid_tx;
    tolerance=tolerance,
    maxbonddim=maxbonddim,
    maxiter=maxiter,
)

qtt_m_fused, _, _ = QTCI.quanticscrossinterpolate(
    value_type,
    (t, x) -> modulation(t),
    fused_grid_tx;
    tolerance=tolerance,
    maxbonddim=maxbonddim,
    maxiter=maxiter,
)

simple_F_fused = STT.TensorTrain(qtt_F_fused.tci)
simple_m_fused = STT.TensorTrain(qtt_m_fused.tci)
tt_F_fused = TN.TensorTrain(simple_F_fused, fused_sites)
tt_m_fused = TN.TensorTrain(simple_m_fused, fused_sites)

tt_H_fused_raw = TN.elementwise_product(tt_F_fused, tt_m_fused;
    threshold=tolerance,
    maxdim=maxbonddim,
)
tt_H_fused = TN.truncate(tt_H_fused_raw; threshold=tolerance, maxdim=maxbonddim)
```

This code is intentionally explicit: it shows that, in fused representation,
the factor must be built on the fused `(t, x)` grid even though the function
ignores `x`.

The prose should state:

- In fused layout, there is no separate list of pure `t` sites to pair in the
  same unfused way.
- A fused site may contain both `t=i` and `x=i`.
- To multiply only in `t`, build the factor as `(t, x) -> m(t)` on the fused
  grid. This makes it constant along `x` while using the correct fused site
  dimensions and tags.
- This is the same mathematical product as before, but the representation
  requires a different construction of the factor.

## Validation

Validate both workflows against the analytic product on the full grid:

```julia
exact_H = [base_function(t_coords[i], x_coords[j]) *
           modulation(t_coords[i])
           for i in 1:npoints, j in 1:npoints]
```

For unfused layouts, evaluate `tt_H` with `TN.evaluate` using
`QG.grididx_to_quantics(grid_tx, (i, j))`.

For fused layout, evaluate `tt_H_fused` using
`QG.grididx_to_quantics(fused_grid_tx, (i, j))`.

Print maximum absolute errors. The section does not need an extensive visual
comparison; one compact heatmap or a small printed validation table is enough.

## Plotting

Use one compact figure:

- left: analytic product `H(t, x)` as a heatmap,
- right: absolute error of the selected workflow.

If the notebook remains visually light, a four-panel figure is also acceptable
for the main unfused workflow:

- analytic product,
- QTT product result,
- absolute error,
- bond dimensions for `F`, sparse `m(t)`, and the product.

Do not add a second fused plot. If both unfused and fused workflows are
executed, prefer printed errors for both and one plot block for the main
workflow to avoid visual clutter.

## What To Notice

Add these points to the notebook's summary:

- Variable-selective multiplication is controlled by site indices.
- Tags such as `t=1`, `t=2`, ... identify which quantics bits belong to a
  variable.
- For `:interleaved` and `:grouped`, `TN.partial_contract` can diagonal-pair a
  one-variable factor with selected variable sites while preserving the full
  multivariate output site order.
- For `:fused`, a selected-variable factor should be built on the fused grid
  as a multivariate function that ignores the non-target variables.
- The mathematical operation can be the same while the tensor-train site
  representation changes with the layout.

## API Recap Additions

Add:

- `Tensor4all.TensorNetworks.findallsiteinds_by_tag`
- `Tensor4all.TensorNetworks.PartialContractionSpec`
- `Tensor4all.TensorNetworks.partial_contract`
- `Tensor4all.TensorNetworks.truncate`

## Open Implementation Notes

- Reuse the existing imports in Notebook 04.
- Avoid introducing a general abstraction that hides the index mechanics; the
  point of the example is to teach those mechanics.
- Start with `R = 7`, following the existing notebook style. If runtime is too
  slow during implementation or notebook verification, reduce this section to
  `R = 6`.
- If the fused workflow becomes too long in the notebook, keep the full code
  but reduce plotting to printed errors and a short explanation.

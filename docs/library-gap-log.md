# Tensor4all.jl Tutorial Gap Log

This file records missing or unclear `Tensor4all.jl` functionality and
documentation encountered while writing the tutorial notebooks.

The teaching notebooks should not contain development-backlog notes. If a
missing feature blocks a notebook section, record it here first. GitHub issues
can be created later after human review.

Each entry should be understandable on its own, even for someone who has not
read the notebooks. A short note about where the issue appeared in the tutorial
work is useful, but the main description should stand alone as a package-level
record.

## How to file

Target repo: [tensor4all/Tensor4all.jl](https://github.com/tensor4all/Tensor4all.jl)

Contribution flow (from [CONTRIBUTING.md](https://github.com/tensor4all/Tensor4all.jl/blob/main/CONTRIBUTING.md)):
1. Open issue using the Feature Request or Bug Report template
2. Maintainer reviews → label `spec_approved`
3. (Optional) Post implementation plan → label `plan_approved`
4. Implementation PR

Spec format (what goes in the issue body):
- **Summary** — what to add or change (1-2 sentences)
- **Motivation** — why needed, which use case
- **Proposed approach** — recommended design direction
- **Alternatives considered** — other approaches and why not chosen
- **Acceptance criteria** — checklist of what "done" means (e.g. `- [ ] ...`)

For features touching the C API boundary (Rust backend `tensor4all-rs`), a
linked issue must be opened on `tensor4all-rs` first.

## Entries

### 2026-04-24 - Undocumented meaning of `ranks` and `errors` from quantics cross interpolation

Status: documentation gap
Issue template: [Feature Request](https://github.com/tensor4all/Tensor4all.jl/issues/new?template=feature_request.yml)

Summary:
The function

```julia
QuanticsTCI.quanticscrossinterpolate(...)
```

returns extra values commonly bound as `ranks` and `errors`, but their meaning
is not documented clearly enough on the Julia side.

The unclear point is not that these values exist, but what they are meant to
represent semantically and how users are expected to interpret them.

Observed API shape:

```julia
qtt, ranks, errors = QuanticsTCI.quanticscrossinterpolate(...)
```

Why this matters:
- Users cannot tell whether `ranks` refers to final tensor-train bond
  dimensions, interpolation ranks, iteration history, or something else.
- Users cannot tell whether `errors` contains per-iteration diagnostics, final
  convergence data, or the recommended public error quantity.
- This makes it hard to write clear tutorials, package documentation, or user
  code that interprets these return values correctly.

Current evidence:
- `errors.last()` is treated in the Rust tutorial code as a final interpolation
  error.
- `ranks.len()` is treated in the Rust tutorial code as the number of
  interpolation steps.
- In local experiments, `ranks` and `errors` look like short iteration
  histories rather than final TT bond dimensions.
- The final QTT bond dimensions are obtained separately from the tensor-train
  representation, for example via `TensorNetworks.linkdims(...)`.

Open questions:
- A clear Julia-side explanation of what `ranks` contains.
- A clear Julia-side explanation of what `errors` contains.
- Whether these values are guaranteed to be per-iteration histories, and if so,
  which iteration or sweep they correspond to.
- Whether `errors.last()` is the recommended public convergence quantity to
  compare against the requested tolerance.

Acceptance criteria:
- [ ] `quanticscrossinterpolate` docstring describes what `ranks` contains (iteration history, bond dimensions, or otherwise)
- [ ] `quanticscrossinterpolate` docstring describes what `errors` contains and which entry is the recommended convergence quantity
- [ ] Each return value's semantics are documented clearly enough that tutorial authors and users can interpret them without reading Rust source code

Tutorial note:
This issue surfaced while writing `01_first_qtt_function_and_grid.jl`.

Current tutorial decision:
Do not explain `ranks` or `errors` in Notebook 01 for now. Keep them out of the
main pedagogical path until their meaning is documented clearly.

### 2026-04-27 - No TreeTN / `partial_contract` for elementwise QTT product

Status: feature gap
Issue template: [Feature Request](https://github.com/tensor4all/Tensor4all.jl/issues/new?template=feature_request.yml)

Summary:
The Julia frontend of `Tensor4all.jl` does not expose the TreeTN conversion and
`partial_contract` API that the Rust backend provides for elementwise (pointwise)
product of two tensor trains.

The Rust tutorial path uses:

```rust
// Convert to TreeTN, then diagonal-contract:
let (tree_f, ids_f) = tensor_train_to_treetn(&tt_f)?;
let spec = PartialContractionSpec {
    contract_pairs: vec![],
    diagonal_pairs: zip(ids_f, ids_g),
    output_order: Some(ids_f),
};
let product = partial_contract(&tree_f, &tree_g, &spec, "center", options)?;
```

The Julia side has no `partial_contract`, `PartialContractionSpec`, or
`tensor_train_to_treetn` equivalents, but it does have
`TensorNetworks.to_dense` for converting a TensorTrain to a dense array and
`QuanticsTCI.quanticscrossinterpolate` for building a QTT from array values.

Tutorial workaround in Notebook 04:
Build factor QTTs, evaluate them on the full grid, pointwise multiply the
values, and build a new QTT from the product array with
`quanticscrossinterpolate`. This teaches the same concepts (rank growth,
validation) using the available public API and avoids internal backend
dependencies.

Next step for the package:
Expose the Rust `tensor_train_to_treetn` / `partial_contract` path in the
Julia frontend, or provide a dedicated `TensorNetworks` operation for
elementwise QTT multiplication.

Cross-repo dependency:
This requires new C API functions in [tensor4all-rs](https://github.com/tensor4all/tensor4all-rs).
Per `CONTRIBUTING.md`, a linked issue must be opened on `tensor4all-rs` and its
PR merged before the Julia-side PR.

Acceptance criteria:
- [ ] Julia frontend exposes `tensor_train_to_treetn` (or equivalent) for converting `TensorNetworks.TensorTrain` to a tree tensor network
- [ ] Julia frontend exposes `partial_contract` (or equivalent) accepting a contraction specification for diagonal pairs
- [ ] An elementwise product of two QTTs can be computed via this path without converting to dense arrays
- [ ] Docstrings and/or a `TensorNetworks` manual section document the operation

Tutorial note:
This issue surfaced while writing `04_operations_on_qtts.jl`.

### 2026-05-06 - TensorTrain site-order restructuring needs tutorial-facing guidance

Status: documentation / API ergonomics gap
Issue template: [Feature Request](https://github.com/tensor4all/Tensor4all.jl/issues/new?template=feature_request.yml)

Summary:
Users need a clear, tutorial-level way to convert an indexed tensor train from
one site ordering or grouping to another, for example between grouped,
interleaved, and fused quantics layouts.

Local code search result:
This is not a missing backend feature. The relevant low-level functionality
already exists in the local `../../code/*` check:

- `Tensor4all.TensorNetworks.restructure_to`
- `Tensor4all.TensorNetworks.rearrange_siteinds`
- `Tensor4all.TensorNetworks.swap_site_indices`
- `Tensor4all.TensorNetworks.fuse_to`
- `Tensor4all.TensorNetworks.split_to`

The Julia frontend exports these functions, and the local tests include
examples such as fused-to-interleaved restructuring and mixed split / swap /
fuse restructuring. The Rust backend also exposes the corresponding TreeTN
operations through `t4a_treetn_fuse_to`, `t4a_treetn_split_to`,
`t4a_treetn_swap_site_indices`, and `t4a_treetn_restructure_to`.

Why this still matters:
- The functionality is discoverable only if the user already knows to look for
  `restructure_to` / `rearrange_siteinds`.
- A user asking "can I convert this tensor train to a different index ordering?"
  may not know whether they need `replace_siteinds`, `swap_site_indices`,
  `restructure_to`, or a fresh QTT interpolation.
- The practical input format, `target_groups::Vector{Vector{Index}}`, is clear
  to library developers but not yet beginner-friendly.
- Quantics tutorials need a direct explanation of how to express common layout
  conversions:
  - interleaved singleton sites: `[[x1], [y1], [x2], [y2], ...]`
  - grouped-by-variable sites: `[[x1], [x2], ..., [y1], [y2], ...]`
  - fused-by-bit-layer sites: `[[x1, y1], [x2, y2], ...]`
- The operation can grow bond dimensions, especially when swaps are involved,
  so tutorials should explain truncation knobs and the difference between exact
  restructuring and approximate/recompressed restructuring.

Important distinction:
`replace_siteinds` only replaces index identities/tags with dimension-compatible
indices. It does not change the tensor-train chain order or regroup site legs.
Actual site-order or site-group changes should use `rearrange_siteinds` /
`restructure_to` or the lower-level primitives.

Potential tutorial-facing API shape:

```julia
# Existing low-level pattern:
target_groups = [[x1], [y1], [x2], [y2]]
tt_interleaved = TensorNetworks.rearrange_siteinds(tt_fused, target_groups;
    split_threshold=1e-10,
    final_threshold=1e-10,
)
```

A future helper could make quantics layout conversions easier by constructing
`target_groups` from a `DiscretizedGrid` layout description or from variable
tags such as `x=1`, `y=1`, etc. That helper would be an ergonomics layer on top
of the existing restructuring API, not a replacement for it.

Acceptance criteria:
- [ ] Tensor4all.jl docs include a short guide explaining `replace_siteinds` vs `rearrange_siteinds` / `restructure_to`
- [ ] Docs or tutorials show grouped, interleaved, and fused quantics target-group construction from site tags
- [ ] The guide explains that swap-based reordering can increase bond dimensions and how `swap_rtol`, `swap_maxdim`, and final truncation controls affect the result
- [ ] Optional: provide a helper that builds common quantics `target_groups` from a grid layout or numbered variable tags

Tutorial note:
This surfaced while extending `04_operations_on_qtts.jl` with
variable-selective products and while comparing the approach to ITensors.jl's
`movesite` operation.

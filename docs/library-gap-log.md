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

## Entries

### 2026-04-24 - Undocumented meaning of `ranks` and `errors` from quantics cross interpolation

Status: documentation gap

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

Tutorial note:
This issue surfaced while writing `01_first_qtt_function_and_grid.ipynb`.

Current tutorial decision:
Do not explain `ranks` or `errors` in Notebook 01 for now. Keep them out of the
main pedagogical path until their meaning is documented clearly.

### 2026-04-27 - No TreeTN / `partial_contract` for elementwise QTT product

Status: feature gap

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

Tutorial note:
This issue surfaced while writing `04_operations_on_qtts.ipynb`.

### 2026-04-28 - `QuanticsTCI.integral` is a simple grid-based quadrature

Status: documentation gap

Summary:
The Julia-side operation

```julia
QuanticsTCI.integral(qtt)
```

computes a definite integral by summing the represented grid values and
multiplying by the grid spacing. This is a simple grid-based quadrature, not a
higher-order integration rule.

Observed implementation:

```julia
integral(qtci) = sum(qtci) * prod(grid_step(qtci.grid))
```

Why this matters:
- Users may reasonably expect the word `integral` to mean a numerically strong
  quadrature routine.
- In tutorial writing, it is easy to accidentally attribute integration error
  to the QTT approximation itself rather than to the underlying grid-based
  summation rule.
- The behavior depends visibly on the grid convention, including whether the
  endpoint is included.

Current evidence:
- For `f(x) = x^2` on `[-1, 2]`, the exact integral is `3.0`.
- With `R = 7` and `includeendpoint=false`, `QuanticsTCI.integral(qtt)` gives
  approximately `2.965118408203125`.
- With `R = 7` and `includeendpoint=true`, `QuanticsTCI.integral(qtt)` gives
  approximately `3.059334118668238`.
- In both cases, the QTT result matches the plain grid-value sum times the grid
  spacing up to floating-point roundoff, which shows that the dominant error is
  the quadrature rule rather than the tensor approximation.

Open questions:
- Whether the package should document this operation more explicitly as a
  simple grid-based quadrature.
- Whether a higher-order quadrature helper should be exposed separately.
- Whether future API naming or documentation should distinguish the current
  summation rule from more accurate integration methods.

Tutorial note:
This issue surfaced while reviewing `04_operations_on_qtts.ipynb`.

Current tutorial decision:
Do not describe `QuanticsTCI.integral` as if it were a sophisticated or
especially accurate integration routine. If the notebook keeps this section, it
should frame the operation honestly as a grid-based quadrature on the chosen
`DiscretizedGrid`.

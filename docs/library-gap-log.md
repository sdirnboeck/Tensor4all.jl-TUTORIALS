# Tensor4all.jl Tutorial Gap Log

This file records missing or unclear `Tensor4all.jl` functionality and
documentation encountered while writing the tutorial notebooks.

The teaching notebooks should not contain development-backlog notes. If a
missing feature blocks a notebook section, record it here first. GitHub issues
can be created later after human review.

## Entries

### 2026-04-24 - Undocumented meaning of `ranks` and `errors` from quantics cross interpolation

Status: documentation gap

Context:
While writing `01_first_qtt_function_and_grid.ipynb`, it was unclear what the
extra return values

```julia
qtt, ranks, errors = QuanticsTCI.quanticscrossinterpolate(...)
```

are meant to represent.

What is currently known:
- `errors.last()` is treated in the Rust tutorial code as a final interpolation
  error.
- `ranks.len()` is treated in the Rust tutorial code as the number of
  interpolation steps.
- In local experiments, `ranks` and `errors` look like short iteration
  histories rather than final TT bond dimensions.
- The final QTT bond dimensions are obtained separately from the tensor-train
  representation, for example via `TensorNetworks.linkdims(...)`.

What is missing:
- A clear Julia-side explanation of what `ranks` contains.
- A clear Julia-side explanation of what `errors` contains.
- Whether these values are guaranteed to be per-iteration histories, and if so,
  which iteration or sweep they correspond to.
- Whether `errors.last()` is the recommended public convergence quantity to
  compare against the requested tolerance.

Tutorial decision:
Do not explain `ranks` or `errors` in Notebook 01 for now. They should stay out
of the pedagogical path until their meaning is documented clearly.

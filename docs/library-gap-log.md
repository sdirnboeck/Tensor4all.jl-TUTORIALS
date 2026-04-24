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

# Notebook 05 Fourier Plan

> **Status:** active implementation plan  
> **Target notebook:** `05_fourier_transforms.ipynb`

## Purpose

This file prepares the implementation of the Fourier notebook after the first
four notebooks have established the teaching style.

Notebook 05 should keep all Fourier-related material together in one place so
that it works both as:

- a guided teaching notebook in the learning path, and
- later reference material for users who specifically want to know how Fourier
  transforms work in `Tensor4all.jl`.

## High-Level Teaching Thread

The notebook should follow this order:

1. one-dimensional Fourier transform,
2. interpretation of the transformed result,
3. bond-dimension comparison before and after the transform,
4. two-dimensional partial Fourier transform,
5. interpretation of transforming one coordinate while leaving the other
   untouched,
6. `## What to notice`,
7. `## API recap`.

The notebook should not start with the two-dimensional case. The one-dimensional
example should establish the basic idea first.

## Non-Negotiable Notebook Rules

Use the global rules from:

- `docs/superpowers/plans/2026-04-23-tensor4all-jl-tutorial-notebooks.md`
- `docs/tutorial-learning-path.md`

In particular:

- no Rust mentions in learner-facing text,
- keep pedagogically important code visible,
- use CairoMakie,
- keep output compact,
- major headings in their own Markdown cells,
- explain conclusions after the evidence is visible.

## Notebook Outcome We Want

By the end of Notebook 05, a student should understand:

- what object is being transformed,
- what the transformed object represents in this example,
- how to compare a QTT-based Fourier result to a reference result,
- how bond dimensions can change under the transform,
- how a partial Fourier transform differs from a full transform.

## Section Structure

## Title

Use:

`# 05. Fourier transforms`

## Learning goals

State that the notebook will:

- apply a Fourier transform to a one-dimensional QTT example,
- compare the QTT-based result to an analytic or dense reference,
- inspect bond dimensions before and after the transform,
- extend the idea to a two-dimensional partial Fourier transform.

## Setup reminder

Only add a short setup reminder if it is genuinely needed.

## Concept section

Keep this section short. It should:

- say that we first work in one dimension,
- state what kind of function or sampled object is being transformed,
- say that the two-dimensional case later reuses the same idea on one
  coordinate only.

Do not front-load an abstract operator explanation before any output is shown.

## Part 1: One-dimensional Fourier transform

This should be the first substantial worked example.

### Content requirements

Show:

- the original one-dimensional object,
- the transformed result obtained through the QTT workflow,
- the analytic or dense-reference transformed result.

### Plot expectations

Prefer a side-by-side visual design that keeps the comparison readable.

Good options:

1. one figure with:
   - left panel: original function,
   - right panel: transformed QTT result and transformed reference together.

2. or two stacked/simple figures if that reads more clearly with the actual
   data.

### Plot styling

Use the established notebook semantics where possible:

- exact/reference curve: black,
- QTT-produced transformed curve: blue family,
- if a second transformed reference curve is needed separately from the QTT
  curve, use a distinct named Makie color that remains readable against black
  and blue.

Legends should be explicit and polished. LaTeX labels are welcome when they
improve readability, but only if they render reliably in the notebook.

### Error reporting

Do not default to a separate error plot.

Instead:

- compute a compact error quantity,
- print it in a sentence-like `println(...)` statement,
- only add a dedicated error visualization if the transformed geometry makes
  the error field itself genuinely instructive.

### Bond dimensions

Show bond dimensions:

- before the transform,
- after the transform.

This can be done either:

- in one shared panel with clear labels, or
- in a side-by-side comparison if the lengths or structures are easier to read
  that way.

Use:

- clear labels,
- `yscale=log2` for bond dimensions,
- readable legends,
- a stable distinction between “before” and “after”.

If a worst-case envelope is available and actually helpful, it may be shown,
but it is not mandatory.

## Part 2: Two-dimensional partial Fourier transform

This should come after the one-dimensional case, not before.

### Teaching focus

The key idea is:

- one coordinate is transformed,
- the other coordinate is left in physical space.

The notebook must say this explicitly in learner-facing language.

### Content requirements

Show:

- the original two-dimensional object,
- the partially transformed QTT-based result,
- an analytic or dense-reference partially transformed result.

### Visualization expectations

For the two-dimensional case, a heatmap is preferred when it makes the
transformed structure readable.

The default expectation is:

- one heatmap for the original object,
- one heatmap for the QTT-based transformed result,
- one heatmap for the analytic or dense transformed reference,

unless that becomes too visually crowded. If three panels are too much, split
the material across two figures rather than compressing it into an unreadable
single layout.

### Error reporting

Again, do not default to a dedicated error plot.

Prefer:

- a compact printed error summary,
- optionally a heatmap of absolute error only if the spatial structure of the
  error itself is genuinely informative.

### Bond dimensions

As in the one-dimensional case, compare bond dimensions:

- before the partial transform,
- after the partial transform.

Explain the comparison after the plot or printed values are visible.

## Text style requirements specific to Notebook 05

The notebook should:

- keep the operator idea concrete,
- avoid slipping into abstract linear-operator language too early,
- repeatedly anchor the reader in what is being plotted,
- use short transitions like:
  - “We now compare the transformed QTT result against a reference.”
  - “Before moving to two dimensions, we inspect how the bond dimensions
    changed.”
  - “The next example applies the same idea to one coordinate only.”

Do not let the notebook become a long discussion of Fourier theory. It is a
usage-and-intuition notebook.

## API and verification expectations

Before finalizing Notebook 05, the worker should verify:

- which public Julia-side Fourier APIs are actually available,
- whether one-dimensional and partial two-dimensional transforms are both
  exposed cleanly enough for learner-facing use,
- what reference computation is practical and honest for each example.

If a public API is missing or too unclear:

- record the issue in `docs/library-gap-log.md`,
- do not invent a notebook-local replacement just to force the notebook
  through.

## Minimal completion bar

Notebook 05 is only “done” if it contains all of the following:

1. a one-dimensional Fourier example,
2. a visible comparison between original and transformed objects,
3. a comparison between the QTT-based transformed result and a reference,
4. bond dimensions before and after the transform,
5. a two-dimensional partial Fourier example,
6. a clear learner-facing explanation of what stays untransformed in the
   partial case,
7. `## What to notice`,
8. `## API recap`.

## Review checklist

When reviewing Notebook 05, check:

- Does it clearly start in 1D before moving to 2D?
- Are the original and transformed objects both visible?
- Is the QTT-based transformed result compared to a real reference?
- Are error quantities reported compactly instead of spawning unnecessary error
  plots?
- Are bond dimensions shown before and after the transform?
- Is the partial-transform idea stated plainly enough?
- Does the notebook read as standalone Julia teaching material with no Rust
  leakage?

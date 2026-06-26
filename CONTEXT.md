# Tensor4all Tutorial Context

This context defines learner-facing tutorial terms used in the Tensor4all.jl tutorial notebooks.

## Language

**Worked walkthrough**:
A fully provided teaching section where the notebook demonstrates a complete workflow step by step.
_Avoid_: Example when contrasting with an exercise, demo

**Implementation walkthrough**:
A worked walkthrough for learners who already know the underlying QTT concepts and need to practice the Tensor4all workflow. It should stay lean and avoid becoming a QTT theory primer.
_Avoid_: QTT primer, conceptual introduction

**Tensor4all workflow**:
The end-to-end sequence a learner practices in Tensor4all: construct a quantics grid, interpolate a QTT, convert it to an indexed tensor train, inspect bond dimensions, evaluate a point, and check full-grid error.
_Avoid_: QTT theory, internals tour

**Exercise**:
A learner-facing section where students write or replace meaningful code using material introduced earlier. It may include placeholders, hints, and a solution, but it should not provide a working baseline as the main exercise code.
_Avoid_: Second experiment, playground, variation

**Soft checkpoint**:
A learner-facing exercise check that computes pass/fail conditions and renders friendly feedback without throwing visible assertion errors. It should still clearly identify what needs fixing.
_Avoid_: Assertion checkpoint, hidden test, red error cell

**Hint**:
Guidance that points students to relevant concepts, variable names, or earlier cells without giving a copy-paste solution.
_Avoid_: Partial solution

**Solution**:
A folded, non-executing reference answer for an exercise. Students can inspect it after attempting the task, but it should not silently make the exercise work.
_Avoid_: Hidden working baseline

**Plotting backend**:
The package used to render notebook figures. For these tutorials, CairoMakie is the canonical plotting backend for polished static figures.
_Avoid_: Plot engine, graphics library

**Interactive control**:
A PlutoUI widget that lets learners change an input parameter without editing code. Interactive controls should support exploration, not replace visible teaching code.
_Avoid_: Dashboard widget

**Informative graphic**:
A visual element that teaches a concept or helps interpret a result, not merely decoration. In these tutorials, graphics should make grids, mappings, values, errors, or bond dimensions easier to understand.
_Avoid_: Decorative graphic, fancy graphic

**Learner-facing code**:
Code that students are expected to read, understand, and imitate when using Tensor4all. In these tutorials, learner-facing code should prioritize grid construction, QTT interpolation, tensor-train conversion, evaluation, error checks, and exercise TODOs.
_Avoid_: Main code, important code

**Support code**:
Code needed to make the notebook run smoothly or look good, but not intended as Tensor4all material. Plot construction, layout styling, backend setup, and guarded feedback cells are support code and can be folded when their outputs remain visible.
_Avoid_: Hidden magic, irrelevant code

## Example dialogue

Developer: Should Notebook 01 include another worked example after `cosh(x)`?
Domain expert: No, make that slot an Exercise instead.
Developer: Should the Exercise run by default?
Domain expert: Yes, with placeholders and Soft checkpoints, not with a complete working baseline or red assertion cells.
Developer: Should we include help?
Domain expert: Include both Hints and a folded Solution, but the Solution should be reference text rather than executable code.

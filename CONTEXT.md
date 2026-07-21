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

**Controlled parameter study**:
A tutorial section that changes one input while keeping the rest of the Tensor4all workflow fixed, so learners can diagnose changes in error or bond dimensions and decide what to adjust next.
_Avoid_: Playground, sweep gallery, free exploration, dashboard

**Diagnostic readout**:
A short learner-facing interpretation that turns a measured QTT signal into an explanation, conclusion, or action. It should connect observations such as grid error, cap saturation, and bond-profile shape to decisions a student could make without forcing every row to be an operational next step.
_Avoid_: Result summary, caption, observation

**Cap saturation**:
A diagnostic condition where the observed maximum bond dimension reaches the configured `maxbonddim`. It is not a proof of failure by itself, but cap saturation together with high measured grid error is evidence that the rank cap may be limiting the QTT.
_Avoid_: Rank failure, maxed out, clipping

**Function structure comparison**:
A controlled comparison where the Tensor4all workflow and parameters stay fixed while the target function changes, so learners can see how smoothness, oscillation, and localized features affect QTT compactness.
_Avoid_: Function gallery, random examples, benchmark

**Layout diagnostics**:
A multivariate QTT teaching section where the sampled function and interpolation settings stay fixed while the quantics site layout changes. It should help learners distinguish final sampled-grid accuracy from internal tensor-train structure such as site dimensions, site order, and bond profiles.
_Avoid_: Layout gallery, layout benchmark, ordering demo

**Layout-sensitive function**:
A multivariate target whose QTT bond dimensions change substantially when the quantics bit layout changes. It should demonstrate that layout choice depends on function structure rather than having a universally best ordering.
_Avoid_: Arbitrary 2D function, toy surface, layout benchmark

**Exercise**:
A learner-facing section where students write or replace meaningful code or interpret results using material introduced earlier. It may include placeholders, hints, and a solution, but it should not provide a working baseline as the main exercise code.
_Avoid_: Second experiment, playground, variation

**Diagnosis exercise**:
A learner-facing exercise where students inspect QTT diagnostic signals and choose a likely next action. It should practice interpretation rather than adding another parameter sweep.
_Avoid_: Quiz, extra sweep, puzzle

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

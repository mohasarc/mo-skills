---
name: describe-work
description: Explain completed or proposed software work so a human can understand its intent, consequential changes, design choices, and supporting evidence. Use for task handoffs, change walkthroughs, and PR or stack explanations. Select reasoning techniques appropriate to the change and audience.
---

# Describe work

Make software work understandable at the level where a human can assess its consequences and decisions. Organize the account around what the reader needs to reason about, with access to implementation detail when it helps.

## Choose the explanation the reader needs

Establish the subject, comparison, audience, and purpose from the available context. The subject may be a task, a small edit, a PR, a stack, a migration, or an existing system. Distinguish delivered behavior from proposals and future stages. If the baseline or evidence is incomplete, bound the account accordingly rather than inventing a before state.

Use the task, change, relevant surrounding implementation, recorded decisions, and observations to establish what happened. Follow supporting material when it could change the explanation. Commit structure can help recover intent and sequence; organize the explanation around meaningful concerns when that better serves the reader.

Treat the following as review activities, not required sections or a fixed sequence. Select the activities that resolve this reader's actual uncertainty. A small task may need only a few sentences; a large task may need several linked explanations.

| Activity | Reader's starting state | Understanding to enable | Explanatory focus |
| --- | --- | --- | --- |
| Establish intent | Unclear what success means or how the request was interpreted | Can assess whether this solves the intended problem | Goal, interpretation, assumptions, delivered outcome, scope boundaries |
| Orient attention | Cannot tell what deserves scrutiny | Can locate consequential changes and choose a reading route | Contributions, coherent review units, regular cases and exceptions |
| Build understanding | Can repeat the summary but cannot reason from it | Can explain the mechanism and predict relevant outcomes | Causality, structure, conditions, time, transformations, quantities |
| Exercise judgment | Understands behavior but has not assessed the commitments | Can accept or challenge choices in project context | Benefits, costs, alternatives, constraints, reversibility |
| Calibrate confidence | Has claims without knowing their support | Knows what is established and what remains uncertain | Discriminating evidence, observation boundaries, qualifications |
| Decide and intervene | Has concerns without a precise next action | Can identify what to accept, clarify, change, or investigate | Concern linked to decision, consequence, and needed resolution |

Prioritize questions whose answers could change the reader's assessment. Account for their familiarity: introduce domain concepts an unfamiliar reader needs; let a knowledgeable reader start with deltas, exceptions, and evidence. Ask for clarification only when a missing goal, comparison, or audience distinction materially affects the account and cannot be reasonably inferred.

## Match the reasoning to the change

A primitive is a compact way to expose a relationship needed for judgment. Examples include responsibility-to-owner, condition-to-outcome, event-to-state, choice-to-consequence, and claim-to-evidence. A table, diagram, narrative, simulation, or exercise can express one or several primitives. Choose the relationship first.

Consider all relevant change dimensions. These are overlapping lenses, not mutually exclusive categories or a checklist to report to the reader.

| Change dimension | Questions that often matter |
| --- | --- |
| Capabilities and experience | What can someone now do? What changes in the user journey, feedback, accessibility, or failure experience? |
| Rules and computation | Which inputs, predicates, ordering, defaults, outputs, and exceptions differ? |
| Structure and responsibility | Where do responsibilities, dependencies, instance ownership, or authority move? |
| Interfaces and representation | Which callers, schemas, stored forms, versions, or producers and consumers must agree? |
| State and coordination | What persists, resets, waits, overlaps, retries, commits, or fails together? |
| Resources and operation | What changes under scale, load, deployment, environmental variation, or resource constraints? |
| Authority and protection | Who can cause or observe which effects? Where do validation, permission, isolation, or trust boundaries change? |
| Development and assurance | How do builds, tooling, dependencies, tests, and the ability to establish confidence change? |

Use [reasoning-techniques.md](references/reasoning-techniques.md) when selecting or composing representations, especially for mixed changes or an unfamiliar change type. Its activity families provide reviewer questions, conceptual forms, and limits. Choose or adapt the relevant techniques; do not reproduce the catalog in the explanation.

For each chosen representation, determine:

- The question it answers and the consequential fact the reader should carry away.
- The entities, relationships, conditions, and comparison boundaries it must preserve.
- What the reader needs to know first, and what can remain optional detail.
- The grounding for its claims and any simplification that changes how it should be interpreted.

Prefer the simplest representation that supports the required reasoning. Use a concrete example when an abstract description is hard to predict from. Use multiple views when they answer distinct questions; remove views that merely repeat the same explanation. Interaction is useful when varying a condition, crossing a boundary, or inspecting an alternative reveals something meaningful. Do not require interaction to discover a consequential qualification.

For an ownership comparison, keep responsibilities identifiable across both states, distinguish the implementation owner from the active caller, and expose the stage where the caller switches. For a recovery example, hold request identity constant, vary whether acceptance has occurred, and show the permitted recovery paths and retained state.

## Compose a useful account

Lead with the result or consequential change and enough intent to make it meaningful. Group the work into reviewable concerns. For each concern, connect its purpose, changed behavior or responsibility, material decisions, and supporting evidence as needed.

Group regular cases and expose exceptions. A repeated migration can be explained once, with exceptional consumers called out. Distinguish core logic from integration, mechanical propagation, and evidence, but assign those roles relative to a decision: a test, adapter, or configuration line can contain the most important change.

Provide progressive depth on the same subject: consequence, mechanism, then precise implementation or evidence. Keep a qualification that could reverse the reader's judgment beside the claim it qualifies. Deeper detail may add precision without silently changing the higher-level story. Give the reader enough to stop at the level appropriate to their decision; a long inventory labeled as an overview does not reduce the reasoning burden.

Preserve distinctions that affect conclusions:

- Source location, runtime location, instance ownership, and policy authority can change independently.
- Textual relocation, equality after normalization, and behavioral equivalence are different claims.
- Compare outcomes under equivalent inputs and semantic conditions, not merely matching event numbers.
- Clearing, cancellation, execution completion, delivery, acknowledgement, and cleanup may have separate boundaries.
- Counts, size, visual prominence, and reference reach do not establish importance, severity, or correctness.
- A request, its interpretation, a disclosed choice, and the rationale for that choice are separate facts.

Ground reasons in available evidence. Mark a proposed explanation or alternative as analysis when it was not recorded as the actual rationale or rejected option. Describe missing rationale precisely; a general design goal may explain ownership without explaining a particular default or removed assertion.

Connect consequential claims to the evidence that bears on them. Distinguish an implementation reading, an illustrative model, a recorded observation, and a fresh execution. Explain coverage limits where they affect confidence. Passing checks, illustrative scenarios, and file-to-explanation mappings do not by themselves establish complete correctness or completeness. Do not turn describing the work into an unrequested full audit.

When concerns remain, make them actionable: identify the affected decision, why it matters, and the clarification, evidence, or change that would resolve it. Do not manufacture unresolved questions or acceptance decisions when the work does not call for them.

## Check explanatory sufficiency

Before finishing, assess the explanation against the activities selected for this task:

- Can the reader connect the result to the intended goal and notice material assumptions or scope gaps?
- Can they find the substantive change without reconstructing it from a file inventory?
- Does the account support a relevant prediction, structural understanding, or quantitative assessment?
- Are material commitments and their consequences available for judgment?
- Can the reader distinguish supported conclusions from models, inference, and unknowns?
- Can they express a precise intervention if one is needed?

Remove material that does not improve one of those abilities. Repair omissions that could change a decision. Treat this as an editorial check, not evidence that comprehension or review speed has been measured.

# Reasoning techniques for describing work

Use the families relevant to the reader's uncertainty. Combine, simplify, or replace techniques when another form answers the question better.

## Establish intent: connect the request to the result

The reader needs shared meaning for success before assessing the solution. This is especially useful for ambiguous requests, user-facing work, investigations, or tasks whose scope evolved.

| Technique | Reviewer question | Conceptual form | What it reveals |
| --- | --- | --- | --- |
| Goal-to-result correspondence | Did the work satisfy the important parts of the request? | Requirement paired with delivered outcome and any gap | Missing outcomes, partial completion, unnecessary scope |
| Concrete success example | What does success mean in practice? | A user or system situation, action, and observable outcome | Ambiguous terms, incompatible interpretations, unstated expectations |
| Assumption and scope boundary | What interpretation was supplied, and where does the claim stop? | Assumption connected to affected behavior; included and excluded situations | Consequential guesses, deferrals, conditions of applicability |

Use the user's domain vocabulary. A task to improve search may mean relevance, latency, typo tolerance, or discoverability; an implementation walkthrough should not silently choose the goal. Distinguish an intended outcome from one actually observed.

## Orient attention: organize significance

The reader needs to locate substance and decide where to look. This family is useful for broad migrations, mixed-purpose work, large additions, and small changes with nonlocal consequences.

| Technique | Reviewer question | Conceptual form | What it reveals |
| --- | --- | --- | --- |
| Contribution map | Where does the substantive change live? | File or coherent group paired with contribution and reason | Core decisions versus integration, mechanical propagation, and evidence |
| Review-unit decomposition | Which concerns can I assess separately? | Units organized by purpose, with dependencies between them | Independent questions and unavoidable coupling |
| Regular cases and exceptions | What repeats, and where does the pattern break? | One representative transformation plus exceptional cases | Consumer-specific behavior hidden among repetitive edits |
| Relocation and unchanged-scope lens | What is moved, copied, new, edited, or unaffected? | Counterpart mapping with comparison method and exceptions | Semantic change within structural churn |
| Structural evolution | Why are the intermediate stages necessary? | Stable entities across named revisions, with changing relationships | Staging, coexistence, cutover, sequencing dependencies |
| Impact footprint | What else may be affected? | Changed responsibility, contract, or setting connected to dependents | Reach beyond touched files and relevant review boundaries |

Line count is not significance. A test can change a guarantee; an adapter can change defaults. Editorial review units do not establish independently landable patches. A static dependency footprint is not a demonstrated runtime impact. Explain what any count or classification actually measures.

## Build understanding: expose the relevant relationships

Choose a relationship the reader needs to reason about. Familiarity with names is insufficient if the reader cannot explain their consequences.

### Causality and conditions

Useful for algorithms, parsers, validation, routing, product rules, and error handling.

| Technique | Reviewer question | Conceptual form | Preserve |
| --- | --- | --- | --- |
| Core-logic sketch | What is the essential rule? | Pseudocode, a short causal account, or a control-flow diagram | Decisive conditions, branch order, effects, waits, failure paths |
| Same-condition comparison | What happens differently in this situation? | Shared input and condition with paired outcomes | Equivalent comparison conditions and relevant outcome dimensions |
| Worked scenario | How does one concrete case reach its result? | Input through selected checkpoints to output | Causal transitions and state changes that explain the outcome |
| Ordered guards | Which condition wins, and what never runs? | Ordered predicates, decisive result, skipped operations | Precedence and effects avoided after a decision |
| Boundary cases | Where does the rule change? | Adjacent or contrasting cases around a threshold or branch | The discriminating condition rather than a mass of examples |

Choose examples that distinguish plausible interpretations. A happy path may establish orientation; an exception may carry the actual change. Mark illustrations as such instead of presenting them as executions.

### Structure, authority, and interfaces

Useful for refactors, APIs, dependency changes, permissions, and configuration consolidation.

| Technique | Reviewer question | Conceptual form | Preserve |
| --- | --- | --- | --- |
| Ownership delta | Who owns this responsibility now? | Responsibility-to-owner comparison or boundary diagram | Source ownership, instance ownership, authority, and active use as distinct relationships |
| Runtime interaction path | Where does the work run? | Components or process/thread lanes with named interactions | Actual containment, message direction, and boundary crossings |
| Contract delta | What can a caller rely on? | Before/after obligations and guarantees with caller consequences | Inputs, defaults, results, errors, side effects, completion timing |
| Value and authority lineage | Who chooses this value and who consumes it? | Source through composition and forwarding to consumers | Field identity, purpose, override precedence, and scope |
| Authority boundary | Who may cause or observe this effect? | Actor/action/resource cases or a trust-boundary diagram | Identity, permission, validation point, and denied outcomes |

Make relationship meanings explicit. An import points toward a dependency; a value may flow in the opposite direction. Shared numbers do not establish shared policy. Required shape does not prove provenance. A new package does not imply a new process or an active consumer.

### State, time, and coordination

Useful for caches, sessions, queues, transactions, concurrency, cleanup, and recovery.

| Technique | Reviewer question | Conceptual form | Preserve |
| --- | --- | --- | --- |
| State-survival view | What survives this boundary? | Event-by-state comparison or successive state snapshots | Retained, cleared, replaced, settled, and externally held state |
| Identity and reuse view | Is this the same object or merely an equal value? | Named identities or pairwise observation comparison | Identity versus equality; stored versus returned values |
| Completion gates | What must finish before the next action? | Dependency diagram, event lanes, or independently held gates | Required order, independent events, pending and failed obligations |
| Recovery scopes | What is retried and with which state? | Nested scopes or distinct loops with reset and terminal boundaries | Request identity, acceptance, budget owner, retained data, replay permission |
| Competing schedules | Can a different interleaving change the outcome? | Contrasting event orders or a controlled scheduling example | Shared state, ordering assumptions, and the observable difference |

Do not impose a total order on independent events. Resetting entries may leave handles and caller-held values alive. Retrying delivery may preserve execution identity. A numeric retry allowance does not establish that a repeated loop exists. Compare revisions at a named semantic condition such as “cleanup held pending.”

### Transformation, experience, and quantities

Useful for data migrations, serialization, user interfaces, accessibility, performance, capacity, and operational changes.

| Technique | Reviewer question | Conceptual form | Preserve |
| --- | --- | --- | --- |
| Representation mapping | How does an old form become a new one? | Paired records, schema mapping, or transformation walkthrough | Meaning, defaults, information loss, invalid inputs, reversibility |
| Compatibility transition | Which versions or participants can coexist? | Producer/consumer compatibility cases and staged transition | Read/write compatibility, mixed-version conditions, migration and rollback limits |
| Experience comparison | What will someone experience differently? | The same user task before and after, including relevant alternate states | Observable behavior, feedback, error recovery, and accessibility consequences |
| Scaling or sensitivity view | How does behavior vary with workload or parameters? | Curves, distributions, parameter comparisons, or a controlled model | Units, workload, baseline, uncertainty, bottlenecks, meaningful thresholds |
| Resource budget | Where does time, memory, cost, or capacity go? | Allocation and consumption comparison | Measured versus modeled quantities, totals, constraints, tradeoffs |
| Operational scenario | What happens in the environment where this runs? | Deployment or lifecycle walkthrough with selected failures | Configuration, rollout order, availability, recovery, environmental assumptions |

For quantitative claims, distinguish measured results from forecasts and illustrative values. A single average can hide a tail or workload-dependent regression. For experience claims, represent the actual task and relevant states; screenshots alone may omit keyboard behavior, navigation, or recovery.

## Exercise judgment: expose commitments in context

The reader understands what happens and needs to decide whether it is desirable. This family is useful for architectural boundaries, public contracts, defaults, dependencies, product policy, and maintenance obligations.

| Technique | Reviewer question | Conceptual form | What it enables |
| --- | --- | --- | --- |
| Decision with rationale | What choice am I accepting, and why was it made? | Choice, consequence, recorded reason or precise rationale gap | An explicit object for human judgment |
| Intent versus implementation | Does the delivered behavior match the promise? | Intended contract paired with supported implementation account | Scope deviations and exceptions to preservation claims |
| Tradeoff comparison | What do we gain and sacrifice? | Chosen option and plausible alternative under the same constraints | Context-sensitive design assessment |
| Counterfactual | What changes if this condition or choice changes? | A varied assumption with its consequence | Sensitivity to requirements and design alternatives |
| Reversibility and reconsideration | When would we choose differently, and what would reversal cost? | Commitment linked to future conditions and reversal constraints | Long-term ownership of the decision |

Do not manufacture an author's rationale or rejected alternatives. Label analytical alternatives. Make alternatives plausible enough to expose a real tradeoff. A component relocation model can illustrate dependency constraints without establishing a safe source change or revert.

## Calibrate confidence: connect claims to discriminating evidence

The reader needs to know how much confidence a conclusion warrants. This is useful throughout the account, especially for preservation, performance, compatibility, and protection claims.

| Technique | Reviewer question | Conceptual form | What it reveals |
| --- | --- | --- | --- |
| Claim and evidence | What supports this statement? | Claim connected to source or observation, method, scope, and limits | The basis for trusting or challenging the account |
| Discriminating witness | What would differ if this claim were false in the relevant way? | A case or observation that separates competing outcomes | Whether the evidence actually addresses the concern |
| Test-witness delta | What do tests exercise and observe now? | Before/after stimulus, apparatus, assertion, and gap | Narrowed premises, changed mocks, lost observations, moved coverage |
| Explanation coverage | What part of the change is unaccounted for? | Changed concerns or regions mapped to claims, with unmatched items | Possible omissions and deliberately bounded scope |
| Uncertainty boundary | Where does support end? | Established conclusion paired with remaining condition or unknown | What further evidence would materially change confidence |

Bounded examples do not prove universal equivalence. Moved test names do not establish preserved assertions or stimuli. File coverage does not prove semantic coverage. Successful interaction with an explanation does not establish human understanding. Keep these limits proportional and attached to the affected claims instead of repeating generic disclaimers.

## Decide and intervene: make concerns resolvable

Connect a concern to the affected decision, its consequence, and what would resolve it. Useful forms include an assumption requiring clarification, a missing observation, a proposed scope adjustment, or a specific design objection. Preserve reasons for a concern so a response can address the underlying issue.

An account might establish that a migration works in a single-version deployment while leaving mixed-version operation unexamined. The useful next question concerns whether overlap is required and what evidence addresses it. “Needs more testing” loses that precision.

Do not manufacture review ceremony or request approval merely because a decision was described. The explanation should equip the human to act when needed.

## Compose for the task

These combinations illustrate selection, not mandatory templates:

- **Small validation change:** state the intended rule, give the core logic and discriminating boundary cases, and identify the evidence. A module diagram is unlikely to add understanding.
- **User-facing workflow:** connect the goal to a concrete task, compare relevant success and failure states, and explain consequential product choices. Add implementation boundaries only where they affect the judgment.
- **Schema migration:** show representation mapping, mixed-version compatibility, rollout sequence, and information-loss or rollback constraints. Connect evidence to the relevant transition states.
- **Large refactor:** distinguish regular relocation from exceptions, show ownership and active-caller changes, then surface altered contracts and test observations. Use history when intermediate stages matter.
- **Performance optimization:** establish the workload and success criterion, explain the mechanism behind the expected improvement, compare distributions or scaling, and expose resource and maintenance tradeoffs.
- **Concurrency or recovery change:** preserve state identities, compare event order or held conditions, and show allowed recovery paths and terminal outcomes. Use observations that distinguish the relevant schedules.
- **Dependency or build update:** identify why the update is needed, separate mechanical propagation from API or operating changes, and explain effects on consumers, environments, and verification.

Combine families when the task crosses dimensions. A new feature can also change permissions, storage, and operational cost. Select according to consequential questions rather than the headline category of the task.

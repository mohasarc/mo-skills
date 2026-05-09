# AI Coding Workflow

Fuzzy idea → spec → stages → phased plan → PR → reviewed merge.

**Each skill is unaware of the others — drop into either flow at any node with whatever artifacts you already have.**

---

## Build flow

| Skill | When | What it does |
|---|---|---|
| `grill-me` | Start with a fuzzy idea | Asks clarifying questions from the **user's perspective only** (UI / external API). Ends with shared understanding. |
| `to-functional-spec` | After grilling | Dumps the conversation into `functional-spec.md`. |
| `to-stages` | After spec | Splits the spec into ordered, dependent stages. |
| `drill-down` | Per stage *(loops)* | First **technical** pass — types, interfaces, algorithms. Asks questions until aligned. |
| `to-phased-plan` | After drill-down | Writes a phased plan doc with code snippets and commit breakdown. |
| `to-implementation` | Per phase *(loops)* | Implements one phase and opens a PR (uses `stack-prs` to stack). |

### Workflow split by perspective (user vs technical), with per-stage and per-phase loops.

```mermaid
flowchart TD
    subgraph user["🗣️  User-perspective phase"]
        direction LR
        GM([grill-me]) --> FS([to-functional-spec]) --> ST([to-stages])
    end
    subgraph tech["⚙️  Technical phase"]
        direction LR
        DD([drill-down]) --> PP([to-phased-plan]) --> IMPL([to-implementation])
    end
    ST ==> DD
    IMPL ==> PR[(PR opened)]
    IMPL -. next phase .-> IMPL
    IMPL -. next stage .-> DD
```

### Effort per step, labeled by actor (you vs AI).

```mermaid
journey
    title AI coding workflow journey
    section What to build
      grill-me            : 3: You, AI
      to-functional-spec  : 5: AI
      to-stages           : 5: AI
    section How to build (per stage)
      drill-down          : 3: You, AI
      to-phased-plan      : 5: AI
    section Ship (per phase)
      to-implementation   : 5: AI
      PR opened           : 5: AI
```

<details>
<summary><b>Other build-flow diagram styles (do not open)</b></summary>

#### Original — left-to-right with explicit loop subgraphs

```mermaid
flowchart LR
    Start([any starting point]):::entry

    GM([grill-me]):::skill
    FS([to-functional-spec]):::skill
    ST([to-stages]):::skill

    subgraph perStage["for each stage"]
        direction LR
        DD([drill-down]):::skill
        PP([to-phased-plan]):::skill
        subgraph perPhase["for each phase"]
            direction LR
            IMPL([to-implementation]):::skill
        end
        DD --> PP --> IMPL
        IMPL -. next phase .-> IMPL
    end

    GM --> FS --> ST --> DD
    IMPL --> PR[(PR opened)]
    IMPL -. next stage .-> DD

    Start -.-> GM
    Start -.-> FS
    Start -.-> ST
    Start -.-> DD
    Start -.-> PP
    Start -.-> IMPL

    classDef skill fill:#e8f0ff,stroke:#3366cc,stroke-width:2px
    classDef entry fill:#fff7d6,stroke:#b58900,stroke-dasharray:4 3
```

#### Sequence diagram (you ↔ skills)

```mermaid
sequenceDiagram
    actor You
    participant GM as grill-me
    participant FS as to-functional-spec
    participant ST as to-stages
    participant DD as drill-down
    participant PP as to-phased-plan
    participant IMPL as to-implementation

    You->>GM: fuzzy idea
    GM-->>You: clarifying Qs (user POV)
    You->>FS: aligned
    FS-->>You: functional-spec.md
    You->>ST: spec
    ST-->>You: stages.md

    loop for each stage
        You->>DD: pick a stage
        DD-->>You: technical Qs
        You->>PP: aligned on tech
        PP-->>You: phased-plan.md
        loop for each phase
            You->>IMPL: phase #
            IMPL-->>You: PR opened
        end
    end
```

#### State diagram with explicit loop edges

```mermaid
stateDiagram-v2
    [*] --> grill_me
    grill_me --> to_functional_spec
    to_functional_spec --> to_stages
    to_stages --> drill_down
    drill_down --> to_phased_plan
    to_phased_plan --> to_implementation
    to_implementation --> to_implementation : next phase
    to_implementation --> drill_down : next stage
    to_implementation --> [*] : all stages done
```

#### Mindmap (taxonomy view)

```mermaid
mindmap
  root((AI coding<br/>workflow))
    User-perspective
      grill-me
      to-functional-spec
        functional-spec.md
      to-stages
        stages.md
    Technical
      drill-down
        per stage
      to-phased-plan
        phased-plan.md
      to-implementation
        per phase
        one PR each
```

#### Gantt (ordering through stages & phases)

```mermaid
gantt
    title Build flow ordering
    dateFormat  X
    axisFormat  %s
    section Spec
    grill-me                  :a1, 0, 1
    to-functional-spec        :a2, after a1, 1
    to-stages                 :a3, after a2, 1
    section Stage 1
    drill-down                :b1, after a3, 1
    to-phased-plan            :b2, after b1, 1
    to-implementation phase 1 :b3, after b2, 1
    to-implementation phase 2 :b4, after b3, 1
    section Stage 2
    drill-down                :c1, after b4, 1
    to-phased-plan            :c2, after c1, 1
    to-implementation phase 1 :c3, after c2, 1
```

#### gitGraph (PR stack as commits)

```mermaid
gitGraph
    commit id: "main"
    branch stage1-phase1
    commit id: "phase 1 PR"
    branch stage1-phase2
    commit id: "phase 2 PR"
    checkout main
    merge stage1-phase1
    merge stage1-phase2
    branch stage2-phase1
    commit id: "phase 1 PR"
    checkout main
    merge stage2-phase1
```

#### Class diagram (skills as units with I/O)

```mermaid
classDiagram
    class grill_me {
        +in: fuzzy idea
        +out: shared understanding
        +pov: user
    }
    class to_functional_spec {
        +in: conversation
        +out: functional-spec.md
    }
    class to_stages {
        +in: spec
        +out: stages.md
    }
    class drill_down {
        +in: one stage
        +out: tech alignment
        +pov: implementation
    }
    class to_phased_plan {
        +in: tech alignment
        +out: phased-plan.md
    }
    class to_implementation {
        +in: one phase
        +out: PR
    }
    grill_me --> to_functional_spec
    to_functional_spec --> to_stages
    to_stages --> drill_down
    drill_down --> to_phased_plan
    to_phased_plan --> to_implementation
    to_implementation --> drill_down : next stage
    to_implementation --> to_implementation : next phase
```

#### Timeline (phases as eras)

```mermaid
timeline
    title Build flow as timeline
    section Idea → Spec
      Talk it out  : grill-me
      Capture      : to-functional-spec
      Slice        : to-stages
    section Per stage
      Tech align   : drill-down
      Plan         : to-phased-plan
    section Per phase
      Build & PR   : to-implementation
```

#### Two-column flow with shared "any-entry" rail

```mermaid
flowchart LR
    Entry{{drop in here}}:::entry

    subgraph spec["Spec column"]
        direction TB
        S1[grill-me]
        S2[to-functional-spec]
        S3[to-stages]
        S1 --> S2 --> S3
    end
    subgraph build["Build column"]
        direction TB
        B1[drill-down]
        B2[to-phased-plan]
        B3[to-implementation]
        B1 --> B2 --> B3
        B3 -. next phase .-> B3
    end
    S3 ==> B1
    B3 -. next stage .-> B1
    B3 ==> Done[(PR)]

    Entry -.-> S1 & S2 & S3 & B1 & B2 & B3

    classDef entry fill:#fff7d6,stroke:#b58900,stroke-dasharray:4 3
```

</details>

---

## Review flow

| Skill | When | What it does |
|---|---|---|
| `architecture-review` | After PR opens | High-level review; flags issues. You paste findings as PR comments. |
| `address-review` | After comments | Reads PR comments, asks for clarifications if needed, plans, then commits each change linked to its comment. |

### Your comments and `architecture-review` comments merge into `address-review`.

```mermaid
flowchart TD
    PR[(open PR)] --> Manual[your manual review comments]
    PR --> AR([architecture-review])
    AR --> AIC[AI comments]
    Manual --> APR([address-review])
    AIC --> APR
    APR --> Clean[(clean PR)]
```

### Effort per step, labeled by actor (you vs AI).

```mermaid
journey
    title PR review journey
    section Comments land
      Your manual review   : 3: You
      architecture-review  : 5: AI
      Paste AI comments    : 3: You
    section Resolution
      address-review  : 5: AI
      Clean PR             : 5: You, AI
```

<details>
<summary><b>Other review-flow diagram styles (do not open)</b></summary>

#### Original — left-to-right with any-entry rail

```mermaid
flowchart LR
    Start([any starting point]):::entry

    AR([architecture-review]):::skill
    APR([address-review]):::skill

    PR[(open PR)] --> AR --> Comments[/your + AI comments on PR/] --> APR --> Done[(clean PR)]

    Start -.-> AR
    Start -.-> APR

    classDef skill fill:#e8f0ff,stroke:#3366cc,stroke-width:2px
    classDef entry fill:#fff7d6,stroke:#b58900,stroke-dasharray:4 3
```

#### Sequence diagram

```mermaid
sequenceDiagram
    actor You
    participant PR as Pull Request
    participant ARev as architecture-review
    participant APC as address-review

    You->>PR: open
    You->>PR: post manual review comments
    You->>ARev: run on PR
    ARev-->>You: high-level findings
    You->>PR: paste as AI comments
    You->>APC: address all comments
    opt unclear comment
      APC->>You: clarifying Qs
      You-->>APC: answers
    end
    APC->>PR: commit per comment (linked)
    PR-->>You: clean PR
```

#### State diagram

```mermaid
stateDiagram-v2
    [*] --> open
    open --> commenting
    commenting --> commenting : you add review
    commenting --> commenting : architecture-review adds findings
    commenting --> addressing : run address-review
    addressing --> addressing : clarify + commit per comment
    addressing --> clean : all resolved
    clean --> [*]
```

#### Mindmap

```mermaid
mindmap
  root((Review<br/>flow))
    Comment sources
      You
        manual review
      architecture-review
        AI comments
    Resolution
      address-review
        clarifying Qs
        commit per comment
        link to source comment
```

#### Gantt

```mermaid
gantt
    title Review flow ordering
    dateFormat  X
    axisFormat  %s
    PR opened              :a1, 0, 1
    your review comments   :a2, after a1, 1
    architecture-review    :a3, after a1, 1
    paste AI comments      :a4, after a3, 1
    address-review    :a5, after a4, 1
    clean PR               :a6, after a5, 1
```

#### gitGraph (commits per comment)

```mermaid
gitGraph
    commit id: "feature"
    commit id: "open PR"
    commit id: "fix: comment#1"
    commit id: "fix: comment#2"
    commit id: "fix: AI-flag#1"
    commit id: "fix: AI-flag#2"
    commit id: "ready to merge"
```

#### Block diagram

```mermaid
block-beta
    columns 3
    PR["open PR"]
    Comments["your + AI comments"]
    Clean["clean PR"]
    AR["architecture-review"]
    space
    APR["address-review"]
    PR --> AR
    PR --> Comments
    AR --> Comments
    Comments --> APR
    APR --> Clean
```

#### Class diagram (skill contracts)

```mermaid
classDiagram
    class architecture_review {
        +in: open PR
        +out: AI comments (high-level)
        +scope: arch / cross-cutting
    }
    class address_pr_comments {
        +in: PR + all comments
        +out: linked commits
        +may: ask clarifying Qs
        +may: skip non-applicable
    }
    architecture_review ..> address_pr_comments : feeds comments
```

#### Timeline

```mermaid
timeline
    title Review flow as timeline
    Open    : PR pushed
    Comment : your manual review
            : architecture-review run
            : AI comments pasted on PR
    Address : address-review
            : clarify if needed
            : commit per comment
    Done    : clean PR
```

</details>


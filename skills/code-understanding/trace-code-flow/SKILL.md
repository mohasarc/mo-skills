---
name: trace-code-flow
description: Produce a compact, syntax-highlighted pseudo-code gist that explains how a specific code path, class, module, feature, or subsystem works. Use when the user asks to understand code flow, generate pseudo-code documentation, create a flow-first gist, explain event-driven or async execution, or asks how a file, class, function, feature, or subsystem works with an emphasis on reading the code path rather than a prose architecture document.
---

# Trace Code Flow

## Overview

Generate a small pseudo-code artifact that lets the user follow the real execution path from entry point to exit. Preserve source-code truth: loops stay in their owning objects, event buses expand into representative subscribers, and async callbacks are shown as re-entry points.

## Workflow

1. Identify the requested target and output location.
2. Trace the source before writing.
3. Write a short syntax-highlighted pseudo-code gist.
4. Validate source ownership, event fan-out, and async re-entry.

Ask a clarifying question only when target or output location is ambiguous enough to risk writing the wrong artifact. Otherwise infer a conservative output path, usually near existing docs or beside source-related documentation.

## Investigation

Start with structure, then read bodies:

- Use symbol overview tools first when available for typed source files.
- Use `rg` to find constructors, call sites, event registrations, subscribers, emitters, timers, callbacks, and external entry points.
- Read only source ranges needed to confirm flow and ownership.
- For event-driven code, trace both sides:
  - where listeners subscribe
  - where events/actions dispatch
  - which representative listeners continue the flow
- For async code, trace where execution leaves and how it re-enters:
  - timers
  - promises/callbacks
  - socket or request handlers
  - queues/jobs
  - delayed bot or retry actions

Do not stop at a pub-sub loop like `listeners.forEach(...)`. Expand it into concrete subscriber examples so the reader knows where to jump next.

## Output Shape

Prefer a Markdown file with a fenced code block using the closest real language for syntax coloring:

````markdown
# Target Gist

```ts
// Read top to bottom.
// Event dispatch expands below, so it is not a dead end.

function mainFlow(input) {
  // 1. Entry point creates/loads runtime object.
  const runtime = createRuntime(input)

  // 2. Plugins/listeners/mechanics attach.
  attachSubscribers(runtime)

  // 3. Runtime starts and owns its loop.
  runtime.start()

  // 4. External events can re-enter later.
  runtime.handleExternalAction(action)
}
```
````

Keep the final artifact small. Aim for 50-140 lines unless the user explicitly asks for depth. Omit data fields, helper methods, validation branches, and edge cases that do not help the user follow the main flow.

## Required Content

Include:

- a clear starting function such as `mainFlow`
- numbered comments for the main path
- real owner of loops and lifecycle methods
- separate external entry points such as socket/request actions
- event dispatch boundaries expanded into representative subscribers
- async re-entry points at the bottom when they matter
- only the most important domain-specific branch examples

Do not include:

- exhaustive method lists
- long prose explanations
- every subscriber in a large event bus
- every guard clause
- full type definitions
- implementation details that do not change the mental model

## Event-Based Logic

Represent event systems as continuations, not dead ends:

```ts
gotAction(action) {
  if (!isAllowed(action)) return
  actionEngine.sendPlayerRequestedAction(action) // jump to ActionEngine
}

class ActionEngine {
  sendPlayerRequestedAction(action) {
    // Every subscriber sees it. Most return immediately.
    ImportantRule.onActionRequest(action)  // action -> next real call
    OtherRules.onActionRequest(action)
  }
}
```

Then show representative subscriber classes:

```ts
class ImportantRule {
  onActionRequest(action) {
    if (action == ImportantAction) runtime.doNextImportantThing()
  }
}
```

If subscribers can trigger more events, show the callback:

```ts
class ImportantRule {
  onActionCompletion(event) {
    if (event == TimerExpired) runtime.handleExternalAction(autoAction)
  }
}
```

## Async Logic

Mark async boundaries explicitly:

```ts
// Async re-entry points.
// socket action -> runtime.handleExternalAction(action)
// timer -> runtime.nextLoop()
// delayed bot/retry/job -> runtime.handleExternalAction(generatedAction)
```

Do not rewrite callback-driven code as a synchronous `while` loop unless the source actually owns such a loop. If the source uses `setTimeout`, promises, queues, or callbacks, show `wait(() => owner.nextLoop())` or the equivalent re-entry.

## Loyalty Rules

- Keep method names close to source names when they are important navigation anchors.
- Group unimportant collaborators under names like `OtherMechanics`, `OtherSubscribers`, or `createControllers`.
- Use comments to explain jump points, not paragraphs.
- If a source call fans out to dozens of handlers, show 2-4 representative handlers and label the rest as grouped.
- If a user says a step is confusing, refine the pseudo-code at that step instead of adding prose around it.
- If the artifact starts feeling large, delete details before adding sections.

## Final Check

Before finishing, verify:

- reader knows exactly where to start
- every jump point has a next place to go
- event dispatch expands into concrete continuations
- async callbacks have re-entry points
- loop ownership matches source
- output renders with syntax coloring
- artifact is shorter than the source explanation it replaces

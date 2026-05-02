---
name: document-feature
description: Investigate feature implementations and generate comprehensive top-down Markdown documentation with Mermaid diagrams. Use when the user asks to document a feature, investigate how something works, or generate architecture documentation.
---

# Document Feature Implementation

## Quick Start

When asked to investigate or document a feature, follow this process to generate comprehensive, top-down Markdown documentation.

### 1. Gather Requirements

Determine the following inputs (ask the user if not provided or infer from context):
- **Feature description**: What is the feature being investigated?
- **Relevant files**: Starting points for the investigation (optional).
- **Scope**: Frontend only, backend only, data layer only, or end-to-end.
- **Depth**: High-level overview vs. extremely detailed deep dive.

### 2. Investigate

Explore the codebase using the provided scope and starting files. Trace the execution flow, identify core components, and understand edge cases.

### 3. Generate Documentation

Create a new `.md` file inside the `docs/` directory at the project root (create the directory if it doesn't exist). Use a `kebab-case` filename based on the feature (e.g., `docs/podcast-generation-pipeline.md`).

Structure the documentation from high-level concepts down to specific implementation details. Adapt as necessary, but follow this general progression:

#### 1. Executive Summary
- What the feature is, why it exists, and the core problem it solves.
- High-level expected inputs and outputs.

#### 2. Architecture & System Flow
- **Visual Architecture**: Use `mermaid` code blocks (sequence diagrams for data/execution flows, flowcharts/class diagrams for structure, state diagrams where applicable).
- **Data/Execution Flow**: Step-by-step lifecycle of the feature's primary processes.
- **Interfaces & Contracts**: Key API payloads, database schemas, or boundary contracts.

#### 3. Implementation Details
- **Relevant Files**: Use ASCII trees to show ONLY the files relevant to this feature.
- **Core Components**: Breakdown of the main logic, classes, or modules. Include *minimal* code snippets highlighting critical/complex mechanics. Omit boilerplate and explain *why* the code works.

#### 4. Edge Cases, Error Handling & Limitations
- Deep-dive into what happens when things fail.
- Known bottlenecks, hardcoded workarounds, or planned future improvements.

## Output & Formatting Directives

- **Conciseness**: Zero fluff. Drop unnecessary words/articles ("the", "a", "really"). Use symbols/arrows (->, =>) instead of verbose text where possible.
- **Tone**: Scale verbosity based on requested Depth. Highly readable for humans; structured for AI context.
- **Visuals**: Always include Mermaid diagrams & ASCII file trees.
- **Code Snippets**: Minimal. Focus on business logic. Explain *why*, not *what*.

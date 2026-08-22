# v1.6.0 runtime rules and persistent context

Global rules are loaded from `~/.esattosoft-ai/rules.md`; project rules are loaded from `.esattosoft-ai-rules.md` in the selected project root. Both augment, but do not weaken, the built-in evidence-first safety rules. Use `/rules reload` after manual edits.

For PHP-generating edits/creates, do not use fractional arithmetic directly as an array offset; prefer an explicit integer key such as `intdiv($i, 2)` when that matches the requested logic.

---

# v1.5.10 edit-repair output contract

For full-file edits and repair passes:
- Return raw complete file contents only.
- Never wrap the file in `BEGIN/END UPDATED FILE` markers or Markdown fences.
- Remove every deterministic policy violation listed by the host agent.
- For CSS color repair, remove `chr(...)` and direct `array_rand(...)` pseudo-colors and use valid deterministic CSS values.
- Preserve unrelated code and requested numeric direction/exact values.
- Treat natural-language even/odd numbered items as human 1-based positions unless the user explicitly says zero-based/indexes.

# v1.5.9 Edit Discipline

For `/edit` requests, preserve the user's semantic direction and exact numeric intent. A request to make a value higher must not lower it. If the user gives an exact property value such as `font-size 60`, use that exact value unless they explicitly ask for a range, formula, offset, or variation. For CSS colors, use valid named/hex/rgb/hsl/variable values; do not generate colors from `chr(...)` or array indexes.

# Esattosoft AI Agent — Saved Prompts

## Analyze

```text
Analyze this file in strict evidence mode. Identify its verified purpose, execution/data flow, dependencies, important visible symbols, genuinely UNKNOWN items, and exact next evidence to inspect. Mention a risk only when the supplied source directly demonstrates it. Do not repeat symbols or turn inference into fact.
```

## Edit

```text
Make the smallest focused code change required by the user's instruction. Preserve architecture, naming, formatting, compatibility, and unrelated behavior. Do not rewrite unrelated sections. Return the complete updated file only.
```

## Fix

```text
Find the proven root cause from the supplied file and instruction, then make the smallest focused fix. Preserve unrelated behavior. Return the complete updated file only.
```

## Review

```text
Review this file in strict evidence mode for correctness, maintainability, security, compatibility, and obvious defects. Separate verified findings from assumptions and prioritize findings by impact.
```

## Create

```text
Create the requested file from the exact user behavior request and supplied destination evidence. Keep it minimal. Do not add strict_types, namespaces, imports/use statements, classes, function wrappers, framework wrappers, helper abstractions, packages, or extra type declarations unless requested or proven required. For direct display/output/render requests, prefer top-level executable code. Do not invent project APIs or dependencies. Use deterministic values/cycles unless randomness is explicitly requested; words such as different, varied, alternate, or unique do not authorize random APIs. Return the complete file only.
```

## Test

```text
Determine the smallest deterministic validation needed for the requested change. Prefer existing project test/build/lint commands and do not invent tooling that is not present.
```

## Reference analysis

```text
Study the supplied read-only reference evidence and identify the relevant visual, behavioral, architectural, or implementation patterns. Do not modify the reference. Separate verified reference facts from UNKNOWN items and identify what target evidence must be inspected next.
```

## Integrate reference into target

```text
Integrate the requested reference design or behavior into the target project. First inspect both target conventions and relevant read-only reference evidence. Preserve target architecture, package names, routing, data/business logic, build system, and existing conventions unless explicitly asked otherwise. Adapt rather than blindly copy. Make the smallest coherent target changes and run the smallest useful validation after approved edits.
```

## Static HTML template → existing PHP framework

```text
Study my target PHP framework and the read-only reference template. Integrate the reference visual design into the target template architecture. Preserve the target routing, database engine, template parser, backend behavior and naming conventions. Adapt the reference HTML/CSS/JS instead of replacing the framework. Ask before target edits and run the smallest useful PHP validation afterwards.
```

## Flutter UI reference

```text
Study the target Flutter project and the read-only reference. Recreate the relevant reference UI/UX inside the target while preserving target navigation, API/data models, state-management conventions, package structure and business logic. Run flutter analyze after approved changes if supported by the target.
```

## Android reference

```text
Study both Android projects. Use the read-only reference for the requested design or behavior, but preserve the target package name, Gradle/build setup, navigation, data layer and target UI architecture. Determine from evidence whether the target uses XML, Compose, Java or Kotlin and adapt the implementation rather than blindly copying incompatible reference files.
```

---


## v1.5.8 context attachments

```text
@esattosoft/core
@esattosoft/core/engine.php
@esattosoft/core/engine.php analyze routing
@tree esattosoft/core --depth 2
@file:esattosoft/core/engine.php
@folder:esattosoft/core
```

Folder attachments are **tree-only by default**. Do not assume that all files in an attached folder are loaded. Inspect only relevant files when more evidence is necessary.

For `/create`, prefer deterministic code. If the request says values should be “different” but does not explicitly ask for randomness, use a fixed array/cycle/index strategy rather than `rand()`, `mt_rand()`, `random_int()`, or `array_rand()`.

## v1.5.6 create evidence discipline

For new files, the agent should inspect a small amount of read-only evidence from the destination directory before drafting when available. Evidence is used only to prove conventions that are actually required.

Creation rules:

```text
- Use the exact requested destination and behavior.
- Prefer the smallest standalone implementation that works.
- Do not add strict_types, namespaces, imports/use statements, classes, function wrappers, framework wrappers, helper abstractions, packages or extra type declarations unless requested or proven required for this target file to work.
- Seeing optional boilerplate in a nearby file is not proof that the new file needs it.
- For direct display/output/render requests, prefer top-level executable code unless evidence proves another entry mechanism is required.
- Do not invent project classes, helpers, APIs, routes or dependencies.
- Prefer deterministic values unless randomness is explicitly requested.
```

## v1.5.5 create-path and approval UX

```text
/create @esattosoft/core/test-ai.php <instruction>
/create test-api.php into @esattosoft/core/test-ai.php <instruction>
/create test-api.php into @esattosoft/core/ <instruction>
```

For `/create`, a leading `@` is a selected-project-root alias. The explicit command auto-enables WRITE mode, but the creation approval gate remains active. Approval choices support Up/Down + Enter as well as 1/2/3 shortcuts.

---

## v1.5.4 analysis modes

### Fast analysis — default

```text
@index.php analyze
```

```text
@engine.php analyze the major subsystems and dependencies
```

### Deep analysis

```text
@index.php deep analyze the complete application entry flow and dependencies
```

```text
@engine.php deep analyze the full architecture, database layer, template engine, security-sensitive behavior and exact next evidence to inspect
```

### Reference analysis

```text
@ref1:index.html analyze the visible layout, component structure and asset dependencies
```

```text
@ref1:index.html deep analyze the complete layout architecture and how it could be adapted to the selected target without changing the reference
```


## v1.5.4 FAST output contract

Default FAST file analysis is intentionally compact so CPU-only Ollama models do not spend several minutes generating commentary.

```text
@index.php analyze
```

The built-in FAST contract targets at most six one-sentence bullets in this evidence-first order when supported:

```text
Purpose
Flow
Dependencies
Important Symbols
UNKNOWN
NEXT
```

Do not duplicate symbols, invent framework names, or add generic risk commentary. Use `deep` when the user explicitly wants a larger analysis.


### File-reference resolution

- `@filename.ext` means a project-root-aware file reference, not a literal filename beginning with `@`.
- Prefer exact relative paths when supplied.
- A bare basename may resolve project-wide when unique.
- Never silently redirect an explicit mistyped path; present close matches.
- When multiple basename matches exist, require user selection before continuing.


## v1.6.1 default-rule behavior

Global and project rules are injected into the system prompt. Generic defaults are version-aware and must never override verified project/runtime/framework constraints. When the user explicitly requests a framework, follow the verified framework/version exactly. For frontend and Android work, inspect the target stack before generating code or UI.

Large multi-line pasted prompts are sent in full even though the terminal displays only a compact `[Pasted text #N +X lines]` marker.


## v1.6.2 Telemetry Note

Normal chat now displays a pre-first-token `Thinking...` indicator and final token/speed/prompt metrics. Saved prompt semantics are unchanged.


## v1.6.3 Command Batch Paste Note

A pure multi-line paste made entirely of `/` or `@` agent commands is not a model prompt. The agent queues and executes those commands sequentially. Mixed prose/code pastes continue to be sent to the model intact.


## v1.6.5 routing note

Plain conversational prompts are handled by normal chat even when autonomous mode is ON. Use explicit project task language when autonomous project inspection/action is intended.

Examples:

```text
fix the login bug
analyze index.php
review the current project's routing
```

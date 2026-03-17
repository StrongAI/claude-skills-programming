---
name: programming
description: Use when implementing any feature or bugfix, auditing an implementation against its plan, or resolving a bug. This is the top-level programming skill that routes to the correct workflow. Triggers on any programming task that isn't purely reading or researching code.
---

# Programming

Three paths. Identify which one applies and follow it.

## Path 1: Implementing Code

A new feature, enhancement, or planned change.

1. `/think` — brainstorm the design, explore approaches, get approval
2. `/write-plan` — create a detailed implementation plan from the design
3. `/dispatching-programmers` — execute the plan, dispatching subagents per task
   - Each subagent runs `/implement` — the TDD loop with audit agent per round
4. `/wrapping-up-programming` — verify everything works, commit

Each task dispatched in step 3 MUST load the appropriate language/framework skill:

| Language/Framework | Skill | Also load |
|---|---|---|
| Swift | `/programming-swift` | `/swift-tdd` for test-driven work |
| SwiftUI | `/programming-swift-ui` | `/programming-swift` always |
| TypeScript / React / Next.js | `/programming-typescript` | |
| C++ | `/programming-cpp` | |
| PostgreSQL | `/programming-postgres` | |
| Concurrent code (any language) | `/programming-concurrency` | language skill |
| Reverse engineering / binaries | `/decompiling` | |

If the task spans multiple languages or frameworks, load all applicable skills. The language skill defines patterns, conventions, and anti-patterns that the subagent must follow.

## Path 2: Auditing an Implementation

Verifying that what was built matches what was planned.

1. `/audit-code` — clean agent reads the plan, reads every changed file, produces a findings report

This runs AFTER implementation, not during. The auditor is a separate agent with no implementation context.

## Path 3: Resolving a Bug

Something is broken and needs to be fixed.

1. `/solving-bugs` — debugger-first root cause investigation, fix the bug
2. `/wrapping-up-programming` — verify the fix works, commit

Do NOT use Path 1 for bugs. Bugs need a debugger, not a design phase.

---

## How to Choose

| Signal | Path |
|--------|------|
| "Implement", "add", "build", "create", new feature | Path 1: Implementing |
| "Audit", "verify", "check against plan", "review what was built" | Path 2: Auditing |
| "Fix", "broken", "bug", "crash", "not working", "wrong behavior" | Path 3: Bug |

If unclear, ask the user which path applies.

---
name: solving-bugs
description: Use when encountering any code behavior question — bugs, crashes, unexpected output, test failures, "why does this do X", "this isn't working", "I think the issue is", EXC_BAD_ACCESS, segfault, wrong return value, or any unexpected behavior. Triggers BEFORE reading source code to reason about behavior, BEFORE proposing fixes. Triggers when about to say "I think the problem is" or "looking at the code, it seems like" without having run anything, or when about to propose a fix without root cause investigation.
---

# Analyzing Code Problems

## Two Iron Laws

1. **NEVER reason about runtime behavior from source code alone.** Attach a debugger, set a breakpoint, observe actual state. Source code tells you what the code *says*. The debugger tells you what the code *does*.

2. **NEVER propose fixes without root cause investigation.** If you haven't observed the actual problem, you cannot fix it. Especially true when: under time pressure, "just one quick fix" seems obvious, you've already tried multiple fixes, or you don't fully understand the issue.

## When to Use

- Something crashes or produces wrong output
- A test fails and the cause isn't obvious from the assertion message
- User asks "why does X happen" or "what's the value of Y"
- You're about to say "I think the problem is..." without having run anything
- Unexpected behavior that doesn't match what the code appears to do

## When NOT to Use

- Syntax errors or compilation failures — these are static, no debugger needed
- Pure information lookup ("where is X defined") — use context-first
- The user explicitly asks you to review code without running it
- Trivial bugs visible from reading (typo in variable name, wrong operator)

---

## Phase 1: Observe

**The debugger is the first tool. Not source code. Not grep.**

1. **Reproduce consistently** — run the code and confirm the behavior. What are the exact steps? If not reproducible, gather more data — don't guess.
2. **Attach debugger and set breakpoints** at the suspected location.
3. **Observe actual state** — variables, call stack, memory, control flow.
4. **Check recent changes** — git diff, recent commits, new dependencies, config changes.

### Essential LLDB Commands

```
b file.swift:42                      # breakpoint by file:line
b MyClass.myMethod                   # breakpoint by symbol
br set -c "count > 10"              # conditional breakpoint
r                                    # run
c / n / s / finish                   # continue / step over / step into / step out
p variable                           # print value
po object                            # print object description
bt                                   # backtrace (the most important command)
thread list                          # show all threads
watchpoint set variable myVar        # break when value changes
```

The principle is the same regardless of language or debugger: set a breakpoint, run to it, inspect state, step through observing actual values.

## Phase 2: Analyze

Record observations precisely before any reasoning:

```
SYMPTOM:       [exact behavior observed]
EXPECTED:      [exact behavior expected]
REPRODUCTION:  [steps to reproduce]
CONTEXT:       [what changed — git history, config, deps, environment]
```

1. **Read error messages carefully** — don't skip past errors or warnings. Read stack traces completely. Note line numbers, file paths, error codes.
2. **Trace data flow** — where does the bad value originate? What called this with bad data? Keep tracing up until you find the source.
3. **Find working examples** — similar working code in the same codebase. Compare against references completely, not skimming. Every difference matters.
4. **In multi-component systems** — add diagnostic logging at each component boundary. Run once to see WHERE it breaks. Then investigate that specific component.

### Expert Heuristics

- **"Where does the data go wrong?"** — trace from source to symptom; find the transition point from correct to incorrect
- **"What's different?"** — compare working case to broken case; the difference identifies the variable the bug depends on
- **"What assumptions am I making?"** — list them explicitly, test each one; the wrong assumption is often the bug
- **"When did it last work?"** — temporal reasoning; git bisect, deployment logs, config changes

## Phase 3: Hypothesize and Test

**Generate at least 3 hypotheses before pursuing any.** This prevents single-hypothesis tunneling — the #1 difference between expert and novice debuggers.

For each hypothesis:

```
HYPOTHESIS:  [specific, testable claim referencing observed data]
PREDICTION:  [what would be true if this hypothesis is correct]
TEST:        [the experiment that would confirm or refute it]
RESULT:      [confirmed / refuted / inconclusive — fill in after testing]
```

**Rank hypotheses** by likelihood × ease of testing. Test the most discriminating experiment first — the one that eliminates the most hypotheses regardless of outcome.

**Binary search the search space**: if the bug could be in module A or B, test at the boundary. If it could be in commit X or Y, use `git bisect`. Halve the space with each experiment.

**Record negative results**: "I checked X and it was correct" eliminates a region of the search space. Track what's been ruled out.

### Root Cause vs. Symptom

The root cause is the **earliest point in the causal chain** where behavior diverges from correct. Use the "5 Whys":
- Why did the UI crash? → nil data
- Why nil? → API 500
- Why 500? → query timeout
- Why timeout? → missing index
- Why missing? → migration incomplete ← **root cause**

Do NOT fix downstream symptoms. Fix the root cause.

## Phase 4: Fix

1. **Create failing test case** — use test-driven-development skill.
2. **Implement single fix** — ONE change addressing the root cause. No "while I'm here" improvements.
3. **Verify fix** — test passes, no regressions, confirmed under debugger.

## When 3+ Fixes Fail

**Pattern:** each fix reveals new shared state, coupling, or problems in a different place. Fixes require "massive refactoring." Each fix creates new symptoms elsewhere.

**This is NOT a failed hypothesis — this is a wrong architecture.**

STOP and question fundamentals:
- Is this pattern fundamentally sound?
- Should we refactor architecture vs. continue fixing symptoms?
- Discuss before attempting more fixes.

---

## Red Flags — STOP

| If you're thinking this...                 | Do this instead                                                       |
| ------------------------------------------ | --------------------------------------------------------------------- |
| "Looking at the code, I think..."          | Run it and see. `p variable`. Don't think — observe.                  |
| "The issue is probably in this function"   | Set a breakpoint and know for certain.                                |
| "Let me read through the call chain"       | Let the debugger show you the actual call chain. `bt` takes 1 second. |
| "I think this variable is nil/null here"   | `p variable` at the crash site.                                       |
| "Let me search for where this is called"   | Set a breakpoint on it and look at the backtrace.                     |
| "This looks like a race condition"         | Thread sanitizer or break on both paths. Don't speculate.             |
| "Let me add some print statements"         | Use the debugger. Print debugging is inferior breakpoints.            |
| "Quick fix for now, investigate later"     | Investigate now. Systematic is faster than guess-and-check.           |
| "Just try changing X and see if it works"  | Form a hypothesis based on observed data first.                       |
| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Question the pattern.            |

## The Bottom Line

**Source code is a map. The debugger is the territory.** Fix at the source of the problem, not at the symptom. Every time you reason about runtime behavior from source alone, you risk being wrong about state, ordering, or environment — and waste time reading code that may not even execute.

Observe first. Reason second. Fix at root cause. Verify always.

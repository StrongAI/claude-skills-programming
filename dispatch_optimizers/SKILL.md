---
name: dispatch-optimizers
description: Use when optimizing code performance, reducing resource usage, or improving efficiency. Triggers on "optimize", "make it faster", "performance", "speed up", "reduce memory", "reduce latency", "dispatch optimizers", "efficiency", "latency", "throughput", "slow", "p99", "bottleneck", "too many queries", "bundle size", "cold start", "GC pressure", "allocation", "cache miss", "N+1", or when the user wants independent agents to find optimization opportunities in the same code. NOT for finding bugs (use /dispatch-auditors) or auditing against a plan (use /audit-code).
---

# Multi-Perspective Code Optimization

Dispatch multiple independent agents with overlapping scope but different optimization lenses to analyze the same codebase. Cross-validate findings by convergence — optimizations identified by N agents independently are high-confidence. Unique findings from specialized lenses surface opportunities that a single reviewer would miss.

## Gotchas

### Claude will optimize cold code instead of hot paths

Without profiling data or traffic patterns, Claude gravitates toward code that _looks_ inefficient rather than code that _runs_ often. A quadratic algorithm in a setup function that runs once is less important than an O(n) scan in a per-request middleware. Always dispatch the Hot Path Identifier (#69) first, or ask the user which code paths handle the most traffic.

### Claude will suggest caching without thinking about invalidation

When Claude finds repeated computation, its first instinct is "add a cache." But a cache without invalidation strategy creates stale data bugs that are harder to diagnose than the original performance problem. Every caching recommendation must include: TTL or invalidation trigger, max size, what happens on cache miss, and what happens when the source of truth changes.

### Claude will recommend parallelization for I/O-bound code that's actually CPU-bound

Claude sees sequential `await` calls and suggests `Promise.all`. But if the bottleneck is CPU in the handler (JSON parsing, template rendering, data transformation), parallelizing I/O won't help — it'll increase memory pressure. The optimizer must verify _where_ time is spent before recommending parallelization.

### Claude will conflate "theoretically suboptimal" with "actually slow"

An O(n log n) sort on a 20-element array is not a performance problem. Claude needs to consider data volumes when making recommendations. Every algorithmic optimization finding must include the actual or expected data size. If the data is small and won't grow, the "optimization" is noise.

### Claude will remove defensive code without verifying it's truly unnecessary

The Unnecessary Defensive Code optimizer (#59) can be dangerous. A "redundant" null check might guard against a race condition, an upstream bug, or a contract violation that hasn't manifested yet. The optimizer must prove the check is unreachable given the _entire_ call graph, not just the immediate caller.

### Claude will batch database operations without considering transaction isolation

Combining individual queries into batch operations can change transaction semantics. A loop of single-row UPDATEs has different isolation behavior than a single multi-row UPDATE. The optimizer must verify that batching doesn't change the correctness guarantees the code depends on.

## Red Flags — Thoughts That Mean Stop

If you catch yourself thinking any of these, stop and verify before proceeding:

| Thought                                  | What to do instead                                                       |
| ---------------------------------------- | ------------------------------------------------------------------------ |
| "This is obviously slow"                 | Measure. Profile. Get actual numbers before recommending changes.        |
| "Just add a cache"                       | Specify invalidation strategy, TTL, max size, and failure mode.          |
| "These can run in parallel"              | Verify independence. Check for shared state. Check if bottleneck is I/O. |
| "This data structure is wrong"           | Check actual data sizes. A "wrong" structure on 10 elements is fine.     |
| "This defensive check is unnecessary"    | Prove it's unreachable from the full call graph, not just one call site. |
| "Remove this abstraction, it's overhead" | Check if it's on a hot path. Abstraction overhead on cold paths is free. |
| "Use a more efficient algorithm"         | State the actual vs. proposed complexity AND the data volume.            |
| "This should be lazy"                    | Verify the eager path is actually reached without using the result.      |

## When to Use

- Optimizing a codebase for performance, memory, latency, or throughput
- After profiling reveals hotspots that need systematic attention
- Before a load test or production scaling event
- When efficiency debt has accumulated after rapid feature development
- When you want high confidence in findings (convergence across independent reviewers)

## When NOT to Use

- Finding bugs or correctness issues (use `/dispatch-auditors`)
- Auditing an implementation against a plan (use `/audit-code`)
- Reviewing a single function's performance (just profile it directly)
- Premature optimization without evidence of actual performance problems
- Style/convention review (use `/conventions`)

## Relationship to Dispatch-Auditors

Some auditors (#28-34) touch performance territory. The distinction:

- **Auditors** ask "is this broken?" — quadratic blowups causing _timeouts_, N+1 queries causing _outages_.
- **Optimizers** ask "can this be better?" — correct code that could be _faster, leaner, more efficient_.

Both may flag the same code. That's intentional — convergence across skill boundaries increases confidence.

## Skill Structure

```
dispatch-optimizers/
  SKILL.md                    # This file — gotchas, procedure, domain index
  references/catalog.md       # Full 77 optimizer catalog (read before dispatching)
  references/gaps.md          # Known coverage gaps
  scripts/detect-stack.sh     # Tech stack detection for tier selection
```

**Before dispatching, read `references/catalog.md`** to select the appropriate optimizers for the project.

## Optimizer Catalog Summary

77 optimizers across 9 domains + meta-optimizers. Full catalog with checks and dispatch conditions in `references/catalog.md`.

### Tiers

- **Tier 1 — Always dispatch.** 8 optimizers. Universal applicability.
- **Tier 2 — Language/framework-specific.** 15 optimizers. Dispatch based on tech stack.
- **Tier 3 — Conditional.** 30 optimizers. Dispatch based on project characteristics.
- **Tier 4 — Specialized.** 24 optimizers. Dispatch for specific concerns only.

### Domain Index

| Domain | Name                         | #   | Tier 1 | Key concern                               |
| ------ | ---------------------------- | --- | ------ | ----------------------------------------- |
|      1 | Algorithmic & Data Structure |   8 | #1-3   | Complexity, data structures               |
|      2 | Memory & Allocation          |   8 | #9     | Heap, GC, layout, pooling                 |
|      3 | Concurrency & Parallelism    |   8 | —      | Threading, locking, async, batching       |
|      4 | I/O, Network & Serialization |   8 | #29    | Buffering, compression, zero-copy         |
|      5 | Database & Query             |   8 | #33    | N+1, indexes, query patterns              |
|      6 | Caching & Result Reuse       |   6 | #41    | App cache, HTTP cache, memoization        |
|      7 | Frontend & Client            |   8 | —      | Bundle, rendering, assets                 |
|      8 | Code Elimination             |   6 | #55    | Dead code, duplication, over-abstraction  |
|      9 | Build, Deploy & Runtime      |   8 | —      | Build speed, containers, cold start       |
| Meta   | Cross-Cutting                |   9 | #69    | Hot paths, logging overhead, tail latency |

### Intentional Overlaps (Convergence Points)

These pairs examine related territory from different angles. Both are kept — the overlap is the point.

| Pair                                                         | Why both are kept                                           |
| ------------------------------------------------------------ | ----------------------------------------------------------- |
| Algorithmic Complexity (#1) + Hot Path Identifier (#69)      | Structural complexity vs runtime-measured hotspots          |
| Allocation Hotspot (#9) + GC Pressure (#10)                  | Where allocations happen vs their downstream GC impact      |
| Missing Cache Layer (#41) + Memoization Opportunity (#3)     | Application-level caching vs function-level result reuse    |
| N+1 Query Detector (#33) + Network Round-Trip (#29)          | Database-specific batching vs general network chattiness    |
| Dead Code Eliminator (#55) + Unused Dependency Pruning (#72) | Source-level dead code vs build-level unused packages       |
| Copy Elimination (#12) + Serialization Round-Trip (#27)      | In-memory copies vs I/O-boundary format round-trips         |
| Parallelization Opportunity (#17) + Async Pattern (#19)      | Thread-level parallelism vs async/event-loop concurrency    |
| Bundle Size (#47) + Tree-Shaking Failure (#48)               | Overall bundle analysis vs specific dead-export elimination |

### Recommended Merges

| Merged optimizer               | Combines                                                   |
| ------------------------------ | ---------------------------------------------------------- |
| Connection Lifecycle           | Connection Pooling (#30) + DB Connection Pool (#38)        |
| Startup & Cold Start           | Startup Optimization (#64) + Cold Start Mitigation (#65)   |
| Container & Image Optimization | Container Right-Sizing (#66) + Image Size (#67)            |
| Observability Overhead         | Logging Overhead (#70) + Metric Collection (#71) + Tracing |
| Cache Architecture             | Cache Key Design (#46) + Multi-Layer Cache (#45)           |

## Dispatch Procedure

### Step 1: Detect Tech Stack

Run `scripts/detect-stack.sh [project_root]` to identify languages, frameworks, and characteristics. The output JSON includes `recommended_domains` — which of the 9 domains are relevant.

### Step 2: Select Optimizer Tier

- **Scope: Full codebase** — Tier 1 always + Tier 2 by tech stack + Tier 3/4 by characteristics
- **Scope: Specific subsystem** — dispatchers from relevant domains only
- **Scope: Specific concern** — single domain (e.g., "memory optimization" = Domain 2)

Use the `recommended_domains` from the detection script to filter. Read `references/catalog.md` for the full optimizer list.

### Step 3: Dispatch Agents

For each selected optimizer:

1. Create an independent agent with the optimizer's analytical lens
2. Include the specific checks from the catalog entry
3. Scope the agent to the relevant files/modules
4. Request structured findings: **location**, **current pattern**, **suggested optimization**, **estimated impact** (high/medium/low), **data volume context** (actual or expected size of data affected)

**Critical: Include "data volume context" in every finding.** An optimization on 10 items is not the same as an optimization on 10 million items. Without this, findings are noise.

### Step 4: Synthesize Results

1. **Convergence detection** — Flag optimizations identified by 2+ independent optimizers. These are highest confidence.
2. **Impact ranking** — Sort by estimated impact (high > medium > low), then confidence (convergent > unique).
3. **Conflict detection** — Flag contradictions (e.g., "cache this" vs "this data changes too frequently to cache").
4. **Grouping** — Group related findings into optimization campaigns that can be implemented together.
5. **Present** — Show findings organized by domain with clear before/after patterns.

### Step 5: Validate (Not Optional)

For every high-impact finding:
- Verify the optimization is on a hot path (not cold code)
- Verify data volumes justify the complexity
- Verify correctness is preserved (especially for batching, caching, parallelization)
- Verify the before/after is testable (performance test or benchmark)

Coverage gaps are documented in `references/gaps.md`.

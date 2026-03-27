# Optimizer Catalog

77 optimizers organized into 9 domains + meta-optimizers. Each optimizer is an independent agent with a specific analytical lens, specific checks, and a dispatch condition.

---

## Domain 1: Algorithmic & Data Structure

### 1. Algorithmic Complexity Optimizer [Tier 1]

Finds code with worse-than-necessary time complexity and identifies concrete alternatives.

**Checks:**
- Linear search (`.find()`, `.includes()`, `.indexOf()`) inside loops — replace with Set/Map for O(1) lookup
- Nested loops over related collections without early termination or index-based join
- String concatenation in loops (quadratic without builder/join pattern)
- Recursive algorithms recomputing overlapping subproblems — add memoization or convert to DP
- Sort followed by linear scan where a single-pass algorithm suffices (e.g., finding top-k)

**When:** Always.

### 2. Data Structure Selection Optimizer [Tier 1]

Identifies data structures that don't match their access patterns.

**Checks:**
- Array used for membership testing — should be Set
- Array used for key-value lookup — should be Map/object
- Linked list used for random access — should be array/vector
- Tree map used where hash map suffices (no ordering needed)
- Sorted array with frequent insertions — should be balanced tree or skip list
- Large object arrays where only a few fields are accessed — consider columnar/SoA layout

**When:** Always.

### 3. Memoization & Redundant Computation [Tier 1]

Finds identical computations performed multiple times.

**Checks:**
- Pure functions called repeatedly with the same arguments in the same scope
- Derived values recomputed on every access that could be cached (computed properties, selectors)
- Expensive regex compilation inside loops or hot paths (should precompile)
- Template/format string parsing repeated per invocation instead of once at init
- Hash/checksum recomputation on unchanged data

**When:** Always.

### 4. Search & Lookup Optimization [Tier 2]

Finds linear scans where indexed/sorted lookup would be dramatically faster.

**Checks:**
- Linear search through sorted data — use binary search
- Full collection scan to find min/max when a heap or sorted structure could maintain it
- Repeated filtering of the same collection with different predicates — build an index
- String matching with naive substring search — use KMP, Boyer-Moore, or Aho-Corasick for multi-pattern
- Geographic/spatial queries using brute-force distance calculation — use spatial index (R-tree, k-d tree)

**When:** Any project processing collections of >100 elements or doing repeated lookups.

### 5. Sort & Comparison Optimization [Tier 4]

Finds suboptimal sorting and comparison patterns.

**Checks:**
- Full sort when only top-k or median is needed (use partial sort / quickselect)
- Sorting with expensive comparison function — Schwartzian transform (decorate-sort-undecorate)
- Repeated sorting of the same data — maintain sorted invariant or use insertion into sorted structure
- String comparison for enums/tags — compare numeric codes instead
- Stable sort used where stability isn't required (unstable sort can be faster)

**When:** Data processing pipelines, any code sorting user-generated content or large datasets.

### 6. Collection Pipeline Optimization [Tier 2]

Finds intermediate materialization in filter/map/reduce chains.

**Checks:**
- `.filter().map()` chains creating intermediate arrays — use lazy iteration or single-pass
- `.map().flat()` where `.flatMap()` would avoid intermediate array
- Multiple passes over same collection that could be single-pass
- Materializing entire collection when only first match is needed (`.filter()[0]` vs `.find()`)
- Stream/iterator converted to array then back to stream unnecessarily

**When:** Any project using functional collection operations.

### 7. Mathematical Simplification [Tier 4]

Finds source-level arithmetic that could be simplified or strength-reduced.

**Checks:**
- Division by power of 2 that could be right-shift (for integer arithmetic)
- Modulo by power of 2 that could be bitwise AND
- Repeated multiplication/division by same constant — precompute reciprocal
- Floating-point operations where integer arithmetic suffices
- `Math.pow(x, 2)` instead of `x * x`; `Math.sqrt` where squared comparison works

**When:** Scientific computing, game engines, graphics, financial calculations, cryptography.

### 8. Lazy Evaluation Opportunity [Tier 3]

Finds eager computation of values that may never be used.

**Checks:**
- Expensive default values computed even when the primary value exists
- All branches of a conditional computed before the condition is checked
- Entire collection transformed when only a subset will be consumed
- Module-level initialization with unconditional import-time side effects
- Configuration/feature values computed at startup but only used in rare code paths

**When:** CLI tools, serverless functions, applications with many optional features.

---

## Domain 2: Memory & Allocation

### 9. Allocation Hotspot Optimizer [Tier 1]

Finds unnecessary heap allocations in hot paths.

**Checks:**
- Object/array/closure allocation inside tight loops — pre-allocate and reuse
- Short-lived temporary objects for intermediate computation — use primitives or stack allocation
- Varargs/spread creating new arrays on every call in frequently-invoked functions
- String formatting/interpolation in hot paths — pre-build or use buffer
- Closures created per-iteration capturing outer scope when a function reference would suffice

**When:** Always.

### 10. GC Pressure Optimizer [Tier 2]

Identifies allocation patterns that cause garbage collection pauses.

**Checks:**
- High allocation rate in request-handling paths (causes frequent young-gen GC)
- Long-lived objects allocated in young generation then promoted (causes old-gen GC)
- Finalizers/weak references creating GC overhead
- Large temporary buffers allocated per-request instead of pooled
- Object graphs with complex reference patterns preventing incremental collection

**When:** Managed-language applications (JVM, .NET, Go, Node.js) with latency SLAs.

### 11. Object Pooling Opportunity [Tier 3]

Identifies frequently created/destroyed objects that could benefit from pooling.

**Checks:**
- Database connection objects created per-query instead of pooled
- Buffer/byte-array allocation per I/O operation instead of recycled
- HTTP client instances created per-request instead of reused
- Parser/formatter objects recreated on every invocation
- Thread/goroutine/fiber created per-task instead of using a pool

**When:** High-throughput servers, data processing pipelines, any code creating expensive objects frequently.

### 12. Copy Elimination [Tier 2]

Finds unnecessary data copies.

**Checks:**
- Large structs passed by value where pass-by-pointer/reference is safe
- Defensive `clone()`/`copy()` on data that won't be mutated
- `JSON.parse(JSON.stringify())` for deep clone where structured clone or spread suffices
- String copied to build another string (intermediate allocation)
- Array/slice copied before read-only iteration

**When:** Any project. Especially important in Go (value semantics) and C++ (implicit copies).

### 13. Stack vs Heap Allocation [Tier 3]

Identifies heap allocations that could be stack-allocated.

**Checks:**
- Small, short-lived objects that don't escape the function — allocate on stack
- Go: pointer returns causing heap escape when value return would work
- Java: objects eligible for scalar replacement if the JIT could prove non-escape
- Rust: unnecessary `Box` allocation for data that fits on the stack
- C/C++: `malloc` for fixed-size local buffers — use `alloca` or stack array

**When:** Go, Rust, C/C++, Java with escape analysis awareness.

### 14. Memory Layout Optimizer [Tier 3]

Finds data layout patterns that cause poor cache utilization.

**Checks:**
- Struct fields ordered randomly — reorder largest-to-smallest to minimize padding
- Array of Structures (AoS) for data processed field-by-field — convert to Structure of Arrays (SoA)
- Hot and cold fields mixed in same struct — split into hot struct + cold pointer
- Pointer-heavy data structures with poor spatial locality — flatten to arrays
- False sharing: per-thread data structures on the same cache line — add padding

**When:** Data-intensive applications, game engines, scientific computing, large dataset processing.

### 15. Interning & Deduplication [Tier 4]

Finds repeated identical immutable objects that could be shared.

**Checks:**
- Identical string values created repeatedly — use string interning/pooling
- Duplicate immutable objects created per-request — share a single instance
- Repeated construction of identical regex patterns — compile once, reuse
- Flyweight pattern opportunities: many objects sharing common state
- Enum/tagged-union values recreated instead of referencing constants

**When:** Parsers, compilers, template engines, report generators.

### 16. Memory-Mapped I/O Opportunity [Tier 4]

Finds large file reads that could benefit from memory mapping.

**Checks:**
- Large files read entirely into memory — mmap allows lazy/partial loading
- Random-access reads on large files using seek+read — mmap with OS page management is simpler
- File parsing that needs to reference multiple positions — mmap avoids multiple read calls
- Read-only file access pattern — mmap avoids buffer management

**When:** Applications processing files >10MB, databases, search engines, log analyzers.

---

## Domain 3: Concurrency & Parallelism

### 17. Parallelization Opportunity [Tier 2]

Finds independent sequential operations that could run in parallel.

**Checks:**
- Sequential network requests to independent services — parallelize with `Promise.all` / goroutine fan-out
- Sequential file processing where files are independent — parallelize across workers
- Sequential data transformations on independent partitions — use parallel map/reduce
- Sequential initialization steps with no data dependencies — run concurrently
- Loop iterations with no cross-iteration dependencies — parallelize or vectorize

**When:** Any project with independent I/O operations or CPU-bound batch processing.

### 18. Lock Contention Optimizer [Tier 2]

Finds synchronization patterns that serialize work unnecessarily.

**Checks:**
- Single global lock protecting unrelated data — split into fine-grained locks
- Read-heavy access using exclusive locks — switch to read-write locks
- Lock held during I/O operations — restructure to hold lock only during state mutation
- Contended atomic counter — use sharded/partitioned counter
- Mutex where lock-free CAS operation would suffice for simple state transitions

**When:** Multi-threaded applications, Go services with shared state.

### 19. Async Pattern Optimizer [Tier 2]

Finds blocking operations in async contexts and missed concurrency in async chains.

**Checks:**
- `await` in a loop where iterations are independent — use `Promise.all` / parallel dispatch
- Synchronous I/O in async handler (readFileSync, execSync in Node.js handler)
- Sequential `await` of independent operations — parallelize
- Async function that never actually awaits — remove async overhead
- Fire-and-forget async without error handling — at minimum, log errors

**When:** Any project using async/await, Promises, goroutines, or event-driven architecture.

### 20. Batch Accumulation Optimizer [Tier 3]

Finds per-item operations that could be batched.

**Checks:**
- Individual database writes in a loop — batch into bulk insert/update
- Per-item network requests — batch into single request
- Per-event metric emission — accumulate and flush periodically
- Per-record validation against external service — batch validation
- Per-message publish — use batch publish with flush interval

**When:** Data processing pipelines, event-driven systems, any code doing per-item I/O.

### 21. Thread Pool Sizing [Tier 3]

Identifies over or under-provisioned thread/worker pools.

**Checks:**
- CPU-bound thread pool larger than core count — excessive context switching
- I/O-bound thread pool equal to core count — should be larger to overlap I/O waits
- Single shared pool for CPU-bound and I/O-bound work — separate pools
- Unbounded thread/goroutine creation — add pool with backpressure
- Fixed pool size not adjusted for deployment environment — make configurable

**When:** Servers, background job processors, any application with explicit thread/worker pools.

### 22. Synchronization Overhead [Tier 3]

Finds unnecessary synchronization that serializes code without protecting shared state.

**Checks:**
- Lock acquired but no shared state accessed in the critical section
- Synchronized method where only a subset of the method body needs synchronization
- Thread-safe collection used where the data is only accessed by one thread
- Atomic operations on thread-local data
- Channel/queue used for SPSC where a ring buffer suffices

**When:** Multi-threaded code, especially after refactoring.

### 23. Work Distribution Optimizer [Tier 4]

Finds unbalanced work distribution across parallel workers.

**Checks:**
- Static partitioning where data is skewed — use work stealing or dynamic scheduling
- Round-robin distribution ignoring item cost — use weighted distribution
- All work dispatched to single worker due to bad hash/partition key
- Barrier synchronization where the slowest worker determines throughput
- Fork-join with highly asymmetric subtask sizes — rebalance decomposition

**When:** Parallel data processing, map-reduce pipelines, distributed computation.

### 24. Backpressure & Flow Control [Tier 3]

Finds producer-consumer patterns where the producer can overwhelm the consumer.

**Checks:**
- Unbounded queue between producer and consumer — add capacity limit
- Fast producer feeding slow consumer without rate limiting
- Event emitter with no flow control — switch to pull-based or add buffering
- Goroutine/thread spawned per incoming item without limit — use bounded worker pool
- Write-ahead log growing without checkpoint — add periodic flushing

**When:** Message processing systems, streaming pipelines, any producer-consumer architecture.

---

## Domain 4: I/O, Network & Serialization

### 25. Buffering & Batching Optimizer [Tier 2]

Finds unbuffered I/O operations and small writes that could be batched.

**Checks:**
- Individual `write()` calls for each field/line — use buffered writer, flush at end
- Per-byte or per-character I/O — read/write in blocks
- Small log entries written individually — buffer and flush periodically
- Individual `send()` calls for small messages — use Nagle's or application-level batching
- Repeated small file reads — read once, parse in memory

**When:** Any application doing file or network I/O.

### 26. Compression Opportunity [Tier 3]

Finds large data transfers that would benefit from compression.

**Checks:**
- HTTP responses without `Content-Encoding` — enable gzip/Brotli/Zstd
- Large payloads between services without compression
- Log files growing without compression — enable log rotation with compression
- Repeated similar data stored uncompressed — use dictionary compression
- Archive/backup without compression

**When:** Any application transferring or storing significant data volumes.

### 27. Serialization Round-Trip Optimizer [Tier 3]

Finds unnecessary or redundant serialization/deserialization cycles.

**Checks:**
- Data parsed from format A, serialized back to format A without transformation — pass through
- `JSON.parse(JSON.stringify())` for deep clone — use `structuredClone` or targeted copy
- Schema validation parsing entire payload when only a subset of fields is needed
- Binary data base64-encoded through systems that support binary natively
- Object serialized to JSON for logging — use structured logging

**When:** API servers with large payloads, data pipelines, multi-format projects.

### 28. Protocol Selection Optimizer [Tier 3]

Identifies suboptimal protocol choices for the communication pattern.

**Checks:**
- HTTP/1.1 with many concurrent requests — upgrade to HTTP/2 for multiplexing
- REST with high-frequency small updates — consider WebSocket or SSE
- JSON over HTTP for internal service-to-service — consider gRPC/Protobuf
- Custom text protocol — consider standard binary protocol
- TCP for fire-and-forget telemetry — consider UDP

**When:** Microservice architectures, real-time applications, high-throughput internal services.

### 29. Network Round-Trip Optimizer [Tier 1]

Finds chatty network patterns — sequential requests, redundant fetches, missing batching.

**Checks:**
- Sequential HTTP requests to independent endpoints — parallelize
- Same endpoint called multiple times with identical parameters — deduplicate
- Multiple small requests where a single batch endpoint exists
- Client-side joins (fetch A, then for each A fetch B) — use server-side join or GraphQL
- DNS resolution on every request — cache DNS results

**When:** Always.

### 30. Connection Management Optimizer [Tier 3]

Finds connection churn and missing connection reuse.

**Checks:**
- New TCP/HTTP connection per request — use connection pooling and keep-alive
- TLS handshake on every connection — enable session resumption / 0-RTT
- Connection pool sized too small or too large
- Connections held open during idle periods — implement idle timeout
- Missing connection draining during graceful shutdown

**When:** Any application making outbound network connections.

### 31. Zero-Copy Opportunity [Tier 4]

Finds unnecessary data copies in I/O paths.

**Checks:**
- File-to-socket transfer using read+write — use `sendfile()` / `TransmitFile()`
- Pipe-to-pipe data movement through user space — use `splice()` / `tee()`
- Buffer copied between layers — use shared buffer/view
- Deserialization creating new objects — use zero-copy formats (FlatBuffers, Cap'n Proto)
- Data copied to format for logging/tracing — use lazy serialization

**When:** High-throughput data transfer, performance-sensitive I/O paths.

### 32. Response Streaming Opportunity [Tier 4]

Finds responses that wait for complete computation before sending.

**Checks:**
- HTTP response buffered entirely before sending — stream rows/chunks as ready
- Report generation that computes everything then writes — stream as computed
- Database query results fully materialized before processing — use cursor/streaming
- API that returns array after all computed — use streaming JSON or SSE
- File upload/download proxied through full buffering — stream through

**When:** APIs returning large responses, report generators, proxies.

---

## Domain 5: Database & Query

### 33. N+1 Query Detector [Tier 1]

Finds query-in-a-loop patterns where a single batched query would suffice.

**Checks:**
- Loop fetching related records one at a time — use JOIN or WHERE IN
- ORM lazy loading triggered per-item in a loop — use eager loading / include
- Recursive parent lookup in a loop — use recursive CTE or materialized path
- Multiple queries checking existence — batch into single EXISTS with IN clause
- Per-item permission check query — batch permission check

**When:** Always.

### 34. Missing Index Optimizer [Tier 2]

Identifies queries performing full table scans on filterable/sortable columns.

**Checks:**
- WHERE clause on unindexed column in tables with >1000 rows
- ORDER BY on unindexed column causing filesort
- JOIN on unindexed foreign key column
- Frequent range queries on unindexed columns
- Compound query patterns that would benefit from composite indexes

**When:** Any project with a relational database.

### 35. Query Pattern Optimizer [Tier 2]

Finds suboptimal query construction patterns.

**Checks:**
- `SELECT *` when only specific columns are needed
- Correlated subquery where JOIN would be faster
- `DISTINCT` used to mask a join that produces duplicates — fix the join
- `UNION` where `UNION ALL` suffices (unnecessary deduplication sort)
- Functions in WHERE clause preventing index use

**When:** Any project with a database. Especially important for ORMs.

### 36. Denormalization Opportunity [Tier 3]

Finds expensive multi-table joins on read-heavy paths.

**Checks:**
- Multi-table JOIN executed on every page load — materialize or cache
- Frequently computed aggregates (counts, sums) — maintain running totals
- Deeply nested parent lookups — add denormalized path column
- Display data requiring 3+ JOINs — create read-optimized view
- Slowly changing dimension lookup on every query — cache or snapshot

**When:** Read-heavy applications with stable write patterns.

### 37. Batch Operation Optimizer [Tier 2]

Finds individual database operations that should be batched.

**Checks:**
- Individual INSERT in a loop — batch into multi-row INSERT or COPY
- Individual UPDATE in a loop — batch with UPDATE ... FROM or CASE expression
- Individual DELETE in a loop — batch with DELETE ... WHERE IN
- Multiple schema DDL statements — combine into single transaction
- Sequential queries that could use multi-statement or pipelining

**When:** Any code performing bulk data modifications.

### 38. Database Connection Pool Optimizer [Tier 3]

Identifies connection pool misconfiguration.

**Checks:**
- No connection pooling — add pgBouncer, HikariCP, or language-level pool
- Pool size not matching workload
- Connections not returned to pool after use (leak)
- Pool health check overhead — use test-on-idle instead of test-on-borrow
- Long-running transactions holding connections

**When:** Any application with a database.

### 39. Read Replica & Query Routing [Tier 3]

Finds read queries hitting the primary that could be routed to replicas.

**Checks:**
- Read-only queries hitting the primary when replicas exist
- Report/analytics queries competing with transactional queries
- Full-text search queries hitting the primary — offload to search index
- Historical data queries hitting the primary — archive to read-optimized store
- Aggregation queries that could run on a replica with acceptable staleness

**When:** Applications with read replicas or read/write ratio exceeding 10:1.

### 40. Materialized View / Precomputation [Tier 3]

Finds expensive computations that could be precomputed at the data layer.

**Checks:**
- Dashboard queries recomputing same aggregates on every page load
- Leaderboard/ranking recalculated on every request — precompute on schedule
- Search results rebuilt on every query — build search index
- Report data joining many tables — precompute into reporting table
- Count queries on large tables — maintain counter cache

**When:** Applications with expensive read queries that don't need real-time freshness.

---

## Domain 6: Caching & Result Reuse

### 41. Missing Cache Layer [Tier 1]

Identifies expensive repeated computations or lookups that lack any caching.

**Checks:**
- External API calls with stable responses called on every request — add cache with TTL
- Database lookups for rarely-changing reference data — cache in-memory
- Template rendering with same data on every request — cache rendered output
- Configuration reloaded from file/service on every use — cache and watch for changes
- Permission/ACL checks repeated per-request for same user — cache per-session

**When:** Always.

### 42. HTTP Cache Header Optimizer [Tier 3]

Finds responses missing cache headers.

**Checks:**
- Static assets without `Cache-Control: max-age` or `immutable`
- API responses for stable data without `ETag` or `Last-Modified`
- Responses with `no-cache` that could use `stale-while-revalidate`
- CDN-cacheable responses not marked as `public`
- Missing `Vary` header causing cache pollution

**When:** Web applications, APIs.

### 43. Computed Value Caching [Tier 2]

Finds derived values recomputed on every access.

**Checks:**
- Getter/property performing computation on every call — cache with invalidation
- React `useMemo`/`useCallback` missing for expensive computations in render
- Derived state recalculated on every store update — use memoized selectors
- Regular expression compiled on every function call — compile once at module level
- Computed CSS/layout values recalculated per-frame

**When:** Any project with derived/computed values. Especially frontends.

### 44. Cache Invalidation Strategy [Tier 3]

Finds caches without proper invalidation.

**Checks:**
- Cache without TTL or explicit invalidation
- Write path that mutates source of truth but doesn't invalidate cache
- Cache key too broad or too narrow
- LRU cache without size limit
- Memoization on mutable inputs

**When:** Any project with caching.

### 45. Multi-Layer Cache Coordination [Tier 4]

Finds inconsistent caching across layers.

**Checks:**
- L1/L2 caches with different TTLs causing inconsistency
- CDN caching responses the origin considers stale
- Browser cache and API cache with no coordinated invalidation
- Multiple services caching same data independently
- Write-through to L2 but not L1

**When:** Applications with multiple caching layers. Microservice architectures.

### 46. Cache Key Design Optimizer [Tier 4]

Finds cache key patterns that reduce hit rate or cause collisions.

**Checks:**
- Cache key missing a discriminating parameter
- Cache key including unnecessary parameters — reducing hit rate
- Cache key using object reference instead of value-based hash
- High-cardinality cache keys causing cache bloat
- Cache key not including user/tenant — cross-tenant leakage risk

**When:** Multi-tenant applications. Personalized content caching.

---

## Domain 7: Frontend & Client Performance

### 47. Bundle Size Optimizer [Tier 2]

Finds opportunities to reduce JavaScript/CSS bundle size.

**Checks:**
- Large dependency imported for a single utility function
- Moment.js/Lodash (full) where lighter alternatives exist
- Polyfills included for browsers no longer supported
- Duplicate packages in bundle (same library at different versions)
- Development-only code in production bundle

**When:** Web applications with JavaScript bundles.

### 48. Tree-Shaking Failure Optimizer [Tier 3]

Finds code patterns that prevent tree-shaking.

**Checks:**
- CommonJS `require()` where ESM `import` would enable tree-shaking
- Barrel files re-exporting everything
- Side effects in module top-level code
- Dynamic `import()` of entire modules when one export is needed
- `sideEffects: false` missing in `package.json` for pure packages

**When:** Frontend applications with bundlers.

### 49. Render Performance Optimizer [Tier 2]

Finds unnecessary re-renders, layout thrashing, paint overhead.

**Checks:**
- Components re-rendering on every parent render — add `React.memo`
- State updates triggering re-render of unrelated subtrees
- Inline object/array/function creation in JSX props (referential inequality)
- Forced synchronous layout (reading then writing in same frame)
- CSS animations using layout-triggering properties — use transform/opacity

**When:** Web applications with interactive UIs.

### 50. Virtual List / Windowing Optimizer [Tier 3]

Finds large lists rendered in full.

**Checks:**
- Rendering >100 DOM elements for a scrollable list — use virtualization
- Large HTML table rendered in full — use virtual scrolling
- Infinite scroll loading all items into DOM — recycle DOM nodes
- Grid/gallery rendering all thumbnails — lazy-render on scroll
- Tree view expanding all nodes into DOM — virtualize

**When:** Applications displaying large data sets.

### 51. Asset Optimization [Tier 2]

Finds unoptimized images, fonts, and media.

**Checks:**
- Images in PNG/JPEG where WebP/AVIF would be 30-50% smaller
- Images at full resolution regardless of display size — use `srcset`
- Images loaded eagerly below the fold — add `loading="lazy"`
- Web fonts loading entire character set — subset to used glyphs
- Font loading blocking first paint — use `font-display: swap`

**When:** Any web application serving images, fonts, or media.

### 52. Critical Rendering Path Optimizer [Tier 3]

Finds resources that block first paint unnecessarily.

**Checks:**
- Render-blocking CSS in `<head>` for below-fold styles — extract critical CSS
- Synchronous `<script>` in `<head>` — add `defer` or `async`
- Large third-party scripts loaded synchronously
- Web fonts blocking text rendering — preload critical fonts
- Missing `<link rel="preconnect">` for third-party origins

**When:** Web applications targeting fast TTFP and LCP.

### 53. Web Worker Offloading [Tier 4]

Finds CPU-intensive work on the main thread.

**Checks:**
- JSON parsing of large payloads on main thread — offload to worker
- Image/video processing on main thread — use OffscreenCanvas in worker
- Complex data transformation blocking UI — move to worker
- Markdown/text rendering of large documents — offload parsing

**When:** SPAs with heavy computation targeting <100ms input latency.

### 54. Prefetch & Preload Optimizer [Tier 3]

Finds predictable navigation patterns where resources could be loaded speculatively.

**Checks:**
- Next-page resources loaded only on navigation — add `prefetch`
- Critical resources discovered late — add `preload`
- API data for likely next view not prefetched — trigger on hover/focus
- DNS resolution for third-party domains delayed — add `dns-prefetch`
- Module chunks loaded only on route change — prefetch on idle

**When:** Multi-page applications, SPAs with route-based code splitting.

---

## Domain 8: Code Elimination & Simplification

### 55. Dead Code Eliminator [Tier 1]

Finds code that can never execute and symbols never referenced.

**Checks:**
- Functions/methods defined but never called from any code path
- Variables assigned but never read
- Code after unconditional return/throw/break/continue
- Exported symbols that nothing imports
- Conditional branches guarded by impossible conditions

**When:** Always.

### 56. Over-Abstraction Detector [Tier 3]

Finds unnecessary indirection that doesn't earn its complexity cost.

**Checks:**
- Wrapper/facade delegating every call to a single inner object without adding behavior
- Interface with exactly one implementation and no planned extension
- Abstract class with one concrete subclass
- Factory function that always creates the same type
- Strategy pattern with one strategy

**When:** Any codebase, especially after speculative refactoring.

### 57. Code Duplication Consolidation [Tier 2]

Finds duplicated logic that could be extracted into shared functions.

**Checks:**
- Near-identical functions differing only in one parameter
- Repeated error handling blocks
- Copy-pasted setup/teardown in tests
- Identical validation logic across multiple endpoints
- Parallel data transformation pipelines

**When:** Any codebase after rapid feature development.

### 58. Unused Feature Removal [Tier 3]

Finds features that are no longer active.

**Checks:**
- Feature flags permanently set to one state
- Configuration options never set to non-default
- Code paths guarded by always-true/false conditions
- API endpoints with zero traffic
- Dependencies only used by dead feature code

**When:** Any project with feature flags or gradual rollout infrastructure.

### 59. Unnecessary Defensive Code [Tier 3]

Finds redundant validation and error handling at internal boundaries.

**Checks:**
- Null/nil check on a value the type system guarantees is non-null
- Input validation duplicated across multiple layers for the same data
- Error handling for structurally impossible conditions
- Defensive copy of data just constructed and not shared
- Try-catch around code that provably cannot throw

**When:** Projects with strict type systems where the compiler already enforces safety.

### 60. Abstraction Inlining [Tier 4]

Finds trivial abstractions where inlining would be clearer and faster.

**Checks:**
- Single-line wrapper functions called in only one place
- Utility class with one static method
- Constants defined for values used exactly once
- Variable assigned then immediately returned
- Method that just calls `super` with same arguments

**When:** Any codebase, especially after refactoring.

---

## Domain 9: Build, Deploy & Runtime

### 61. Incremental Build Optimizer [Tier 3]

Finds build configurations that prevent incremental compilation.

**Checks:**
- Generated files invalidating entire build graph
- Global header/config changes triggering full recompilation
- Build tool not using content-based change detection
- Test suite running all tests when only a subset is affected
- CI rebuilding everything on every commit

**When:** Projects with >30s build times. Monorepos.

### 62. Build Parallelism Optimizer [Tier 3]

Finds serial build steps that could be parallelized.

**Checks:**
- Sequential compilation of independent modules — enable parallel compilation
- Sequential lint then compile then test — parallelize independent stages
- Single-threaded TypeScript compilation — use `--incremental` or project references
- Docker layers built sequentially when independent
- CI jobs in serial that have no dependencies

**When:** Projects with >1 minute build times.

### 63. Dependency Pruning Optimizer [Tier 3]

Finds unused or unnecessarily heavy dependencies.

**Checks:**
- Packages in `dependencies` but never imported — remove
- Heavy package used for one small feature — replace or inline
- Multiple packages providing overlapping functionality — consolidate
- `devDependencies` accidentally in `dependencies`
- Transitive dependency pulling in massive subtree

**When:** Any project with package management.

### 64. Startup Optimization [Tier 2]

Finds unnecessary work during application initialization.

**Checks:**
- Synchronous file/network I/O during startup — defer or parallelize
- Loading all plugins/modules eagerly — lazy-load on first use
- Database schema validation on every startup — run only in CI
- Large configuration parsed eagerly when most fields unused
- Connection pools fully warmed at startup — warm incrementally

**When:** Serverless functions, CLI tools, microservices.

### 65. Cold Start Mitigation [Tier 3]

Finds patterns specific to serverless/FaaS that increase cold start latency.

**Checks:**
- Large deployment package — minimize dependencies, use layers
- JVM without CDS/AppCDS or GraalVM native-image
- Top-level initialization loading unused resources
- Connection established on every cold start
- Provisioned concurrency not evaluated for latency-sensitive functions

**When:** AWS Lambda, Google Cloud Functions, Azure Functions.

### 66. Container Right-Sizing [Tier 3]

Finds over or under-provisioned container resource limits.

**Checks:**
- CPU limit far above actual usage — reduce to save cost
- Memory limit at actual usage (no headroom) — add buffer
- CPU request equal to limit — prevents bursting
- No resource limits set — risks noisy-neighbor and OOM kills
- JVM heap not matching container memory limit

**When:** Kubernetes/container deployments.

### 67. Image Size Optimizer [Tier 4]

Finds opportunities to reduce container image size.

**Checks:**
- Build tools/compilers in runtime image — use multi-stage build
- Package manager cache left in image — clean in same layer
- Large base image where Alpine or distroless suffices
- Debug symbols, test files, docs in production image
- Multiple `RUN` commands creating unnecessary layers

**When:** Container-based deployments.

### 68. Runtime Configuration Optimizer [Tier 3]

Finds suboptimal runtime configuration that limits performance.

**Checks:**
- JVM heap too small (excessive GC) or too large (long GC pauses)
- Node.js `--max-old-space-size` not set for memory-intensive workloads
- Go `GOMAXPROCS` not matching available cores in container
- Database connection pool size not matching workload
- HTTP server timeout/keep-alive/max-connections not tuned

**When:** Any deployed application.

---

## Meta-Optimizers (Cross-Cutting)

### 69. Hot Path Identifier [Tier 1]

Uses profiling data or static analysis to identify code paths that consume the most resources.

**Checks:**
- Functions consuming >10% of CPU time — flag as primary targets
- Endpoints with highest p99 latency — trace and identify bottleneck
- Code paths executed on every request vs. rare paths — optimize the common path
- Middleware/interceptors doing unnecessary work on every request
- Inner loops with high iteration counts — prioritize for algorithmic optimization

**When:** Always. Without hot path identification, optimization may target cold code.

### 70. Logging & String Formatting Overhead [Tier 2]

Finds expensive string formatting in log statements that execute even when log level is disabled.

**Checks:**
- String interpolation/concatenation in log calls regardless of level — use lazy formatting
- JSON serialization for log context at debug level — guard with level check
- `.toString()` / `fmt.Sprintf` on complex objects for disabled log levels
- Logging inside tight loops — add sampling or move outside loop
- Stack trace capture for non-error log levels

**When:** Any application with logging. Critical for high-throughput services.

### 71. Metric & Tracing Overhead [Tier 3]

Finds observability instrumentation that adds measurable overhead.

**Checks:**
- High-cardinality metric labels causing metric explosion
- Trace span created for every loop iteration — span per batch instead
- Metrics collected synchronously in the hot path — buffer and flush async
- Histogram bucket boundaries poorly chosen
- Full request/response body captured in traces — capture summary only

**When:** High-throughput services where observability overhead is measurable.

### 72. Unused Dependency Pruning [Tier 3]

Finds imported but unused packages.

**Checks:**
- Import statements for packages not referenced in the importing file
- Packages in manifest but not imported by any source file
- Test-only dependencies included in production builds
- Transitive dependencies eliminable by choosing a lighter direct dependency
- Native/binary dependencies adding compilation overhead when pure alternatives exist

**When:** Any project with dependency management.

### 73. Latency Tail Optimizer [Tier 3]

Finds patterns that cause p99/p999 spikes while p50 appears healthy.

**Checks:**
- GC pauses during request handling — tune GC or reduce allocation rate
- Lock contention under load — only manifests at high concurrency
- Timeout cascades: one slow downstream causing upstream timeouts
- Connection pool exhaustion causing queuing
- Retry storms: multiple layers retrying, amplifying load

**When:** Any service with latency SLAs. Microservice architectures.

### 74. Regex Optimization [Tier 4]

Finds regex patterns that are inefficient or have catastrophic backtracking.

**Checks:**
- Nested quantifiers (`(a+)+`, `(a*)*`) causing exponential backtracking
- Unnecessary capturing groups — use non-capturing `(?:...)`
- Regex compiled inside loop — compile once outside loop
- Greedy quantifier where possessive or atomic group would prevent backtracking
- Complex regex where simple string operations would suffice

**When:** Applications using regex for validation, parsing, or routing.

### 75. Configuration-as-Optimization [Tier 3]

Finds default configurations that leave performance on the table.

**Checks:**
- HTTP keep-alive disabled or with too-short timeout
- TCP_NODELAY not set for latency-sensitive connections
- DNS caching not configured
- OS-level limits too low (file descriptors, socket buffers, TCP backlog)
- Compiler optimization level not set for release builds

**When:** Any deployed application.

### 76. API Design Efficiency [Tier 3]

Finds API patterns that force clients into inefficient usage.

**Checks:**
- No batch endpoint — clients forced to make N individual requests
- No field selection — clients over-fetch
- No pagination — clients must fetch entire collections
- No conditional request support (ETag/If-Modified-Since) — clients re-fetch unchanged data
- No webhook/push support — clients must poll

**When:** APIs consumed by multiple clients. Public APIs.

### 77. Energy Efficiency [Tier 4]

Finds wasteful computation patterns that increase power consumption without proportional benefit.

**Checks:**
- Polling loops with short intervals where event-driven notification is available
- Background tasks running continuously instead of on-demand
- Full data reprocessing where incremental processing would suffice
- Idle resources kept warm unnecessarily — implement scale-to-zero
- Busy-wait loops instead of OS-level blocking/notification

**When:** Cloud deployments (cost), mobile applications (battery), embedded systems.

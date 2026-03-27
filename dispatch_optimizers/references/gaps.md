# Known Coverage Gaps

The 77 optimizers have partial or no coverage for these areas. Consider adding specialized checks when these apply.

## High Value

| Gap                               | Description                                                  | When it matters                          |
| --------------------------------- | ------------------------------------------------------------ | ---------------------------------------- |
| GPU offloading                    | Moving computation to GPU via CUDA/OpenCL/Metal/WebGPU       | ML inference, graphics, scientific       |
| SIMD vectorization                | Manual or auto-vectorization for data-parallel loops         | Image processing, codecs, numerical      |
| Profile-guided optimization (PGO) | Using runtime profiles to guide compiler optimization        | Performance-critical binaries            |
| Link-time optimization (LTO)      | Cross-module inlining and dead code elimination at link time | C/C++/Rust release builds                |
| NUMA-aware allocation             | Allocating memory near the processor that will use it        | Multi-socket servers                     |
| Kernel bypass (DPDK, io_uring)    | Avoiding kernel overhead for I/O                             | Network appliances, storage engines      |
| Write-ahead log optimization      | Batching/grouping WAL entries for throughput                 | Databases, event stores                  |
| Query plan pinning/hinting        | Preventing optimizer regressions with plan guides            | Production databases with critical paths |
| SSR/SSG/ISR optimization          | Server rendering strategy selection per page                 | Content-heavy web applications           |
| Service mesh overhead             | Sidecar proxy latency and resource consumption               | Kubernetes with Istio/Linkerd            |

## Medium Value

| Gap                                | Description                                                         | When it matters                          |
| ---------------------------------- | ------------------------------------------------------------------- | ---------------------------------------- |
| Autovacuum tuning (PostgreSQL)     | Table-level vacuum settings for high-churn tables                   | PostgreSQL databases                     |
| JIT compilation tuning             | JVM JIT tier configuration, Node.js TurboFan heuristics             | Long-running JVM/Node processes          |
| Memory-mapped data structures      | Using mmap for on-disk B-trees, hash tables                         | Databases, search engines                |
| Speculative execution awareness    | Avoiding patterns vulnerable to speculative execution side channels | Cryptographic and security code          |
| Network topology optimization      | Reducing cross-AZ/cross-region calls                                | Multi-region deployments                 |
| Compression algorithm selection    | Choosing algorithm based on data characteristics and latency budget | Storage engines, data pipelines          |
| Lock-free data structure selection | Replacing locked structures with lock-free alternatives             | Ultra-low-latency systems                |
| Branch prediction optimization     | Reorganizing code for better branch prediction                      | Inner loops of performance-critical code |
| Syscall reduction                  | Minimizing kernel transitions in hot paths                          | High-frequency I/O operations            |
| Custom allocator selection         | jemalloc, tcmalloc, mimalloc based on allocation pattern            | Memory-allocation-heavy applications     |

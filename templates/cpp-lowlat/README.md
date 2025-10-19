# C++ Low-Latency Development Environment

High-performance C++ environment for systems requiring minimal latency and maximum throughput.

## Usage

```bash
# Initialize environment
nix flake init -t github:dlond/system-flakes#cpp-lowlat
nix develop

# Setup Conan profile
conan profile detect --force

# Install dependencies with Conan
conan install . --build=missing -pr:b=default

# Build with CMake presets + Ninja
cmake --preset conan-release
cmake --build --preset conan-release

# Or for debug build
cmake --preset conan-debug
cmake --build --preset conan-debug

# Run tests
ctest --preset conan-release

# Run benchmarks
./build/conan-release/bench_orderbook

# Profile (Linux only)
perf record -g ./build/conan-release/app
perf report
```

## Key Concepts for Low-Latency Systems

### 1. Lock-Free Data Structures

```cpp
template<typename T, size_t Size>
class LockFreeQueue {
    alignas(64) std::atomic<size_t> head_{0};  // Cache line aligned
    alignas(64) std::atomic<size_t> tail_{0};
    std::array<T, Size> buffer_;

public:
    bool try_push(const T& item) noexcept {
        const auto current_tail = tail_.load(std::memory_order_relaxed);
        const auto next_tail = (current_tail + 1) % Size;

        if (next_tail == head_.load(std::memory_order_acquire)) {
            return false; // Queue full
        }

        buffer_[current_tail] = item;
        tail_.store(next_tail, std::memory_order_release);
        return true;
    }

    std::optional<T> try_pop() noexcept {
        const auto current_head = head_.load(std::memory_order_relaxed);

        if (current_head == tail_.load(std::memory_order_acquire)) {
            return std::nullopt; // Queue empty
        }

        T item = buffer_[current_head];
        head_.store((current_head + 1) % Size, std::memory_order_release);
        return item;
    }
};
```

### 2. Memory Pool Allocator

```cpp
template<typename T, size_t PoolSize>
class MemoryPool {
    alignas(alignof(T)) char buffer_[PoolSize * sizeof(T)];
    std::array<T*, PoolSize> free_list_;
    std::atomic<size_t> free_count_{PoolSize};

public:
    MemoryPool() {
        for (size_t i = 0; i < PoolSize; ++i) {
            free_list_[i] = reinterpret_cast<T*>(&buffer_[i * sizeof(T)]);
        }
    }

    [[nodiscard]] T* allocate() noexcept {
        const auto idx = free_count_.fetch_sub(1, std::memory_order_acq_rel);
        if (idx == 0) return nullptr;
        return free_list_[idx - 1];
    }

    void deallocate(T* ptr) noexcept {
        const auto idx = free_count_.fetch_add(1, std::memory_order_acq_rel);
        free_list_[idx] = ptr;
    }
};
```

### 3. High-Performance Event Processing

```cpp
struct Event {
    uint64_t id;
    uint64_t timestamp;
    int32_t value;  // Use integers for precision
    uint32_t type;
};

class EventProcessor {
    // Separate queues for different priorities
    LockFreeQueue<Event, 10000> high_priority_;
    LockFreeQueue<Event, 50000> normal_priority_;

    // Pre-allocated memory pools
    MemoryPool<Event, 100000> event_pool_;

public:
    void process_event(Event event) noexcept;
    void batch_process() noexcept;
};
```

## Performance Optimization Checklist

### CPU Optimizations
- [ ] Cache line alignment (64 bytes)
- [ ] False sharing prevention
- [ ] Branch prediction hints (`[[likely]]`, `[[unlikely]]`)
- [ ] SIMD instructions for batch operations
- [ ] CPU affinity and core isolation

### Memory Optimizations
- [ ] Custom allocators (pools, arenas)
- [ ] Minimize allocations in hot path
- [ ] Huge pages for large data structures
- [ ] NUMA awareness (multi-socket systems)

### Compiler Optimizations
- [ ] Profile-guided optimization (PGO)
- [ ] Link-time optimization (LTO)
- [ ] Function inlining hints
- [ ] Loop unrolling

### Network Optimizations (Linux)
- [ ] Kernel bypass (io_uring)
- [ ] Zero-copy techniques
- [ ] TCP_NODELAY for low latency
- [ ] Batch packet processing

## Benchmarking with Google Benchmark

```cpp
#include <benchmark/benchmark.h>

static void BM_LockFreeQueue(benchmark::State& state) {
    LockFreeQueue<int, 1000> queue;

    for (auto _ : state) {
        queue.try_push(42);
        auto val = queue.try_pop();
        benchmark::DoNotOptimize(val);
    }

    state.SetItemsProcessed(state.iterations());
}
BENCHMARK(BM_LockFreeQueue);

static void BM_MemoryPool(benchmark::State& state) {
    MemoryPool<Event, 10000> pool;

    for (auto _ : state) {
        auto* ptr = pool.allocate();
        benchmark::DoNotOptimize(ptr);
        pool.deallocate(ptr);
    }

    state.SetItemsProcessed(state.iterations());
}
BENCHMARK(BM_MemoryPool);

BENCHMARK_MAIN();
```

## Profiling and Analysis

### Linux Tools
```bash
# CPU profiling
perf record -g ./app
perf report

# Cache analysis
valgrind --tool=cachegrind ./app
cg_annotate cachegrind.out.<pid>

# Memory profiling
valgrind --tool=massif ./app
ms_print massif.out.<pid>
```

### Cross-Platform
```bash
# LLDB for debugging
lldb ./app
(lldb) breakpoint set --name main
(lldb) run
(lldb) thread backtrace

# Time measurement
time ./app

# Google Benchmark
./bench_app --benchmark_format=json > results.json
```

## Best Practices

1. **Measure First**: Profile before optimizing
2. **Minimize Allocations**: Use pools and pre-allocation
3. **Data Locality**: Keep hot data together
4. **Avoid Contention**: Use lock-free where possible
5. **Batch Operations**: Process multiple items together

## Project Structure

```
low_latency_project/
├── CMakeLists.txt
├── CMakePresets.json     # Generated by Conan
├── conanfile.txt         # Dependencies
├── include/
│   ├── lock_free/
│   ├── memory/
│   └── utils/
├── src/
│   └── main.cpp
├── tests/
│   └── test_performance.cpp
└── benchmarks/
    └── bench_all.cpp
```

## Resources

- [C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/)
- [Lock-Free Programming](https://www.1024cores.net/)
- [Mechanical Sympathy](https://mechanical-sympathy.blogspot.com/)
- [CppCon Talks on Performance](https://www.youtube.com/user/CppCon)
- [Google Benchmark Documentation](https://github.com/google/benchmark)
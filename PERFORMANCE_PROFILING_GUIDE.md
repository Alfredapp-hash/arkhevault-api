# App Performance Profiling Guide

## Overview

This document provides comprehensive guidance on profiling and optimizing the performance of the Forged In Fire Client Manager macOS application.

**Project Location:** `/Users/purduelaw/Desktop/ArkheApps/StudentTracker/ForgedInFireClientManager/`

---

## Table of Contents

1. [Performance Goals](#performance-goals)
2. [Profiling Tools](#profiling-tools)
3. [Profiling Techniques](#profiling-techniques)
4. [Common Performance Issues](#common-performance-issues)
5. [Optimization Strategies](#optimization-strategies)
6. [Monitoring](#monitoring)
7. [Best Practices](#best-practices)

---

## Performance Goals

### Target Metrics

| Metric | Target | Current Status |
|--------|--------|----------------|
| App Launch Time | < 2 seconds | TBD |
| View Load Time | < 0.5 seconds | TBD |
| Core Data Fetch | < 0.2 seconds | TBD |
| API Response Time | < 1 second | TBD |
| Memory Usage | < 200 MB | TBD |
| CPU Usage (Idle) | < 5% | TBD |
| CPU Usage (Active) | < 30% | TBD |
| Battery Impact | Low | TBD |

### Performance Benchmarks

#### Launch Performance
- Cold start: < 2 seconds
- Warm start: < 0.5 seconds
- Background launch: < 1 second

#### View Performance
- Dashboard load: < 0.5 seconds
- Client list load: < 0.3 seconds
- Client detail load: < 0.5 seconds
- Calendar view load: < 0.3 seconds

#### Data Operations
- Client fetch (single): < 0.1 seconds
- Client fetch (list): < 0.2 seconds
- Client save: < 0.2 seconds
- Search query: < 0.3 seconds

---

## Profiling Tools

### Xcode Instruments

#### 1. Time Profiler
**Purpose:** Identify CPU-intensive operations

**Usage:**
1. Open Xcode
2. Product → Profile (Cmd+I)
3. Select "Time Profiler"
4. Click Record
5. Perform actions to profile
6. Stop recording
7. Analyze results

**Key Metrics:**
- Total CPU time
- Self time (time in function)
- Call tree analysis
- Flame graph visualization

#### 2. Allocations
**Purpose:** Track memory allocations and leaks

**Usage:**
1. Product → Profile
2. Select "Allocations"
3. Click Record
4. Perform actions
5. Stop recording
6. Analyze memory growth

**Key Metrics:**
- Total bytes allocated
- Number of allocations
- Persistent vs. transient allocations
- Memory leaks detection

#### 3. Leaks
**Purpose:** Detect memory leaks

**Usage:**
1. Product → Profile
2. Select "Leaks"
3. Click Record
4. Perform actions
5. Stop recording
6. Review leaks

**Key Metrics:**
- Number of leaks
- Leaked objects
- Leak backtrace

#### 4. Core Data
**Purpose:** Profile Core Data operations

**Usage:**
1. Product → Profile
2. Select "Core Data"
3. Click Record
4. Perform database operations
5. Stop recording
6. Analyze queries

**Key Metrics:**
- Fetch time
- Save time
- Query count
- Fault count

#### 5. Energy Log
**Purpose:** Monitor energy impact

**Usage:**
1. Product → Profile
2. Select "Energy Log"
3. Click Record
4. Use app normally
5. Stop recording
6. Review energy impact

**Key Metrics:**
- Energy impact (Low/High)
- CPU usage
- Network usage
- Location usage

### Command Line Tools

#### 1. `sample`
```bash
# Sample CPU usage
sample <pid> -duration 10 -file sample.txt

# Sample specific process
sample ForgedInFireClientManager -duration 30
```

#### 2. `leaks`
```bash
# Check for memory leaks
leaks <pid>

# Generate leaks report
leaks --atExit -- <app_path>
```

#### 3. `heap`
```bash
# Analyze heap allocations
heap <pid>

# Find specific allocations
heap <pid> --summary
```

#### 4. `instruments` (CLI)
```bash
# Run instruments from command line
instruments -t "Time Profiler" /path/to/app.app

# Run with template
xcrun xctrace record --template "Time Profiler" --launch /path/to/app.app
```

---

## Profiling Techniques

### 1. Launch Performance Profiling

**Steps:**
1. Close the app completely
2. Open Instruments → Time Profiler
3. Click Record and launch the app
4. Wait for launch to complete
5. Stop recording
6. Analyze the launch timeline

**What to Look For:**
- Long-running initialization code
- Synchronous network calls during launch
- Heavy Core Data operations on main thread
- Large image loading

**Optimization Targets:**
- Move initialization to background
- Cache frequently used data
- Lazy load non-critical components
- Preload critical data

### 2. View Transition Profiling

**Steps:**
1. Open Instruments → Time Profiler
2. Start recording
3. Navigate between views
4. Stop recording
5. Analyze view transition times

**What to Look For:**
- Expensive view body calculations
- Large data fetches
- Complex SwiftUI view hierarchies
- Unnecessary re-renders

**Optimization Targets:**
- Use `@State` and `@Binding` efficiently
- Implement view caching
- Break down complex views
- Use `Equatable` views to prevent unnecessary re-renders

### 3. Core Data Profiling

**Steps:**
1. Open Instruments → Core Data
2. Start recording
3. Perform database operations
4. Stop recording
5. Analyze query performance

**What to Look For:**
- Slow fetch requests
- N+1 query problems
- Unnecessary faulting
- Missing indexes

**Optimization Targets:**
- Add indexes to frequently queried attributes
- Use fetch limits
- Batch fetch operations
- Use predicates efficiently
- Implement relationship faulting

### 4. Memory Profiling

**Steps:**
1. Open Instruments → Allocations
2. Start recording
3. Use the app extensively
4. Stop recording
5. Analyze memory growth

**What to Look For:**
- Memory leaks
- Retain cycles
- Unnecessary allocations
- Large object retention

**Optimization Targets:**
- Use `weak` and `unowned` references
- Implement proper deinit
- Use value types where appropriate
- Release unnecessary references
- Implement object pooling

### 5. Network Profiling

**Steps:**
1. Open Instruments → Network
2. Start recording
3. Make network requests
4. Stop recording
5. Analyze network activity

**What to Look For:**
- Slow API responses
- Unnecessary requests
- Large payload sizes
- No caching

**Optimization Targets:**
- Implement request caching
- Use pagination
- Compress payloads
- Optimize API endpoints
- Implement request batching

---

## Common Performance Issues

### 1. Main Thread Blocking

**Symptoms:**
- UI freezes during operations
- Slow scrolling
- Unresponsive interface

**Causes:**
- Synchronous network calls
- Heavy Core Data operations on main thread
- Complex calculations on main thread
- Large image processing

**Solutions:**
```swift
// Bad: Blocking main thread
let clients = context.fetch(clientsFetchRequest)

// Good: Background thread
Task.detached(priority: .userInitiated) {
    let clients = await context.fetch(clientsFetchRequest)
    await MainActor.run {
        self.clients = clients
    }
}
```

### 2. Memory Leaks

**Symptoms:**
- Memory usage grows over time
- App crashes after extended use
- Slow performance

**Causes:**
- Retain cycles in closures
- Strong references to delegates
- Unreleased observers
- Cyclic dependencies

**Solutions:**
```swift
// Bad: Retain cycle
class MyView {
    let closure: () -> Void
    
    init() {
        closure = {
            self.doSomething() // Retain cycle
        }
    }
}

// Good: Weak self
class MyView {
    let closure: () -> Void
    
    init() {
        closure = { [weak self] in
            self?.doSomething()
        }
    }
}
```

### 3. Inefficient Core Data Queries

**Symptoms:**
- Slow data loading
- High CPU usage during fetch
- Battery drain

**Causes:**
- Fetching too much data
- Missing indexes
- N+1 query problem
- Unnecessary relationship faulting

**Solutions:**
```swift
// Bad: Fetching everything
let fetchRequest = NSFetchRequest<Client>(entityName: "Client")
let clients = try? context.fetch(fetchRequest)

// Good: Fetching with predicate and limit
let fetchRequest = NSFetchRequest<Client>(entityName: "Client")
fetchRequest.predicate = NSPredicate(format: "isActive == YES")
fetchRequest.fetchLimit = 50
fetchRequest.includesSubentities = false
let clients = try? context.fetch(fetchRequest)
```

### 4. SwiftUI Re-render Issues

**Symptoms:**
- Slow view updates
- High CPU usage
- Laggy interface

**Causes:**
- Unnecessary view re-renders
- Complex view hierarchies
- Expensive view body calculations

**Solutions:**
```swift
// Bad: Always re-renders
struct MyView: View {
    var data: [Item]
    
    var body: some View {
        List(data) { item in
            Text(item.name)
        }
    }
}

// Good: Equatable view
struct MyView: View {
    var data: [Item]
    
    var body: some View {
        List(data, id: \.id) { item in
            Text(item.name)
        }
        .equatable()
    }
}
```

### 5. Image Performance Issues

**Symptoms:**
- Slow image loading
- High memory usage
- Laggy scrolling

**Causes:**
- Loading full-resolution images
- Not caching images
- Synchronous image loading
- Unnecessary image processing

**Solutions:**
```swift
// Bad: Loading full image
Image(nsImage: NSImage(contentsOf: url)!)

// Good: Async loading with caching
AsyncImage(url: url) { phase in
    if let image = phase.image {
        image.resizable()
    } else if phase.error != nil {
        Image(systemName: "photo")
    } else {
        ProgressView()
    }
}
```

---

## Optimization Strategies

### 1. SwiftUI Optimizations

#### Use `@State` and `@Binding` Efficiently
```swift
// Minimize @State variables
struct MyView: View {
    @State private var isExpanded = false
    
    var body: some View {
        // Only mark as @State what needs to trigger re-renders
    }
}
```

#### Implement View Caching
```swift
// Use @StateObject for view models
struct MyView: View {
    @StateObject private var viewModel = MyViewModel()
    
    var body: some View {
        // ViewModel persists across view updates
    }
}
```

#### Use Lazy Loading
```swift
// LazyVStack for long lists
LazyVStack {
    ForEach(items) { item in
        ItemView(item: item)
    }
}
```

### 2. Core Data Optimizations

#### Add Indexes
```swift
// In Core Data model, add indexes to frequently queried attributes
// Add index to: firstName, lastName, email, status
```

#### Use Fetch Limits
```swift
fetchRequest.fetchLimit = 50
fetchRequest.fetchOffset = 0
```

#### Batch Operations
```swift
// Use NSBatchDeleteRequest for bulk deletes
let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
try? context.execute(batchDelete)
```

#### Implement Relationship Faulting
```swift
// Set relationship to lazy loading
// This prevents unnecessary data loading
```

### 3. Network Optimizations

#### Implement Caching
```swift
// Use URLSession with caching
let config = URLSessionConfiguration.default
config.requestCachePolicy = .returnCacheDataElseLoad
let session = URLSession(configuration: config)
```

#### Use Pagination
```swift
// Fetch data in pages
func fetchClients(page: Int, limit: Int) {
    let offset = (page - 1) * limit
    fetchRequest.fetchOffset = offset
    fetchRequest.fetchLimit = limit
}
```

#### Compress Payloads
```swift
// Use gzip compression
let session = URLSession(configuration: .default)
session.configuration.requestCachePolicy = .returnCacheDataElseLoad
```

### 4. Memory Optimizations

#### Use Value Types
```swift
// Use structs instead of classes where possible
struct ClientData {
    let id: UUID
    let name: String
    // Structs are more memory-efficient
}
```

#### Release Unused References
```swift
// Set references to nil when done
var largeData: [Data]?
// ... use data ...
largeData = nil // Release memory
```

#### Implement Object Pooling
```swift
// Reuse objects instead of creating new ones
class ObjectPool<T> {
    private var pool: [T] = []
    
    func acquire() -> T? {
        return pool.popLast()
    }
    
    func release(_ object: T) {
        pool.append(object)
    }
}
```

---

## Monitoring

### Performance Monitoring in Production

#### 1. Implement Performance Metrics

```swift
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    func measure<T>(_ label: String, operation: () -> T) -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = operation()
        let end = CFAbsoluteTimeGetCurrent()
        let duration = end - start
        
        print("[Performance] \(label): \(duration)s")
        
        // Log to analytics in production
        // Analytics.logEvent("performance_metric", parameters: [
        //     "label": label,
        //     "duration": duration
        // ])
        
        return result
    }
}

// Usage
let result = PerformanceMonitor.shared.measure("Fetch Clients") {
    try context.fetch(clientsFetchRequest)
}
```

#### 2. Track App Launch Time

```swift
class AppDelegate {
    var launchStartTime: Date?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        launchStartTime = Date()
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        if let startTime = launchStartTime {
            let launchTime = Date().timeIntervalSince(startTime)
            print("App launch time: \(launchTime)s")
        }
    }
}
```

#### 3. Monitor Memory Usage

```swift
func getMemoryUsage() -> UInt64 {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }
    
    if kerr == KERN_SUCCESS {
        return info.resident_size
    }
    
    return 0
}
```

#### 4. Monitor CPU Usage

```swift
func getCpuUsage() -> Double {
    var cpuInfo: processor_info_array_t?
    var numCpuInfo: mach_msg_type_number_t = 0
    var numCpus: natural_t = 0
    
    let result = host_processor_info(
        mach_host_self(),
        PROCESSOR_CPU_LOAD_INFO,
        &numCpus,
        &cpuInfo,
        &numCpuInfo
    )
    
    if result == KERN_SUCCESS {
        // Calculate CPU usage
        // Implementation details...
    }
    
    return 0.0
}
```

---

## Best Practices

### 1. Development Phase

- **Profile Early and Often**
  - Profile during development, not just before release
  - Set performance budgets for key operations
  - Use Instruments regularly

- **Write Performance Tests**
  - Add performance tests to your test suite
  - Monitor performance regressions
  - Set performance thresholds

- **Use Debug Build for Development**
  - Debug builds include more debugging info
  - Optimize builds for production

### 2. Code Reviews

- **Review for Performance**
  - Check for main thread blocking
  - Look for memory leaks
  - Verify efficient data access

- **Use Performance Checklist**
  - [ ] No main thread blocking
  - [ ] No memory leaks
  - [ ] Efficient Core Data queries
  - [ ] Proper caching
  - [ ] Efficient SwiftUI views

### 3. Release Phase

- **Profile Release Builds**
  - Profile optimized release builds
  - Test with production data
  - Verify performance targets met

- **Monitor Production**
  - Track performance metrics
  - Monitor crash rates
  - Collect user feedback

### 4. Ongoing Maintenance

- **Regular Performance Audits**
  - Quarterly performance reviews
  - Update performance budgets
  - Address performance regressions

- **Stay Updated**
  - Keep up with SwiftUI best practices
  - Monitor Core Data updates
  - Review Apple performance guidelines

---

## Performance Checklist

### Pre-Release Checklist

- [ ] App launch time < 2 seconds
- [ ] View load times < 0.5 seconds
- [ ] Core Data fetches < 0.2 seconds
- [ ] No memory leaks detected
- [ ] No main thread blocking
- [ ] Memory usage < 200 MB
- [ ] CPU usage < 30% during normal use
- [ ] Energy impact is Low
- [ ] Performance tests passing
- [ ] Instruments profiling completed

### Ongoing Monitoring Checklist

- [ ] Performance metrics collected
- [ ] Crash rate monitored
- [ ] User feedback reviewed
- [ ] Performance budgets maintained
- [ ] Performance regressions addressed

---

## Troubleshooting

### Issue: App is slow to launch

**Steps:**
1. Profile launch with Time Profiler
2. Identify slow initialization code
3. Move to background threads
4. Implement lazy loading
5. Cache frequently used data

### Issue: UI is laggy

**Steps:**
1. Profile with Time Profiler
2. Check for main thread blocking
3. Review SwiftUI view hierarchy
4. Implement view caching
5. Optimize data fetching

### Issue: High memory usage

**Steps:**
1. Profile with Allocations
2. Check for memory leaks
3. Review large object retention
4. Implement proper cleanup
5. Use value types where appropriate

### Issue: Battery drain

**Steps:**
1. Profile with Energy Log
2. Check CPU usage
3. Review network activity
4. Optimize background operations
5. Implement efficient polling

---

## Resources

### Apple Documentation
- [Instruments User Guide](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/InstrumentsUserGuide/)
- [Performance Best Practices](https://developer.apple.com/documentation/xcode/improving-your-app-s-performance)
- [SwiftUI Performance](https://developer.apple.com/documentation/swiftui/performance)

### Tools
- Xcode Instruments
- SwiftLint (code quality)
- Periphery (unused code detection)

### Articles
- [Optimizing SwiftUI Performance](https://developer.apple.com/videos/play/wwdc2023/10162/)
- [Core Data Performance](https://developer.apple.com/videos/play/wwdc2020/10017/)

---

**Document Version:** 1.0
**Last Updated:** 2024
**Status:** Performance Profiling Guide Complete
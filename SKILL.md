---
name: programming
description: Use when implementing any feature or bugfix in Swift, before writing implementation code. Use when writing Swift tests with @Test, #expect, #require, Swift Testing framework, or when testing async/await, actors, @MainActor code. Use when choosing between XCTest and Swift Testing, setting up test suites, parameterized tests, or dependency injection for testability. Use when identifying test cases, edge cases, boundary values, equivalence classes, coverage gaps. Triggers on swift test, xcodebuild test, test target, test suite, mock, stub, parameterized test, what to test, which tests to write, snapshot, XCUITest, Page Object, ViewInspector, assertSnapshot. DO NOT trigger on source code review or debugging of code the user wrote.
---

# Test-Driven Development

TDD in Swift: identify test cases via boundary value analysis, then red-green-refactor through them. Heavy reference material is in `references/`.

## When to Use

- Implementing any feature or bugfix in a Swift project
- Writing new tests (use Swift Testing, not XCTest)
- Identifying what to test / edge cases / coverage gaps
- Testing async/await, actors, @MainActor code
- Dependency injection for testability
- Snapshot or XCUITest for UI features

## When NOT to Use

- Performance benchmarks (use XCTest `measure {}`)
- Objective-C test code (use XCTest)
- Source code review or debugging

---

# Phase 1: Boundary Value Analysis

Run BEFORE writing tests. Produces a prioritized test case list for TDD's RED phase.

## BVA Algorithm

### Step 1: Enumerate Inputs

Everything the function reads: explicit parameters, `self` properties, closure captures, globals, environment, external data. Do not skip implicit inputs.

### Step 2: Classify Input Types

Numeric, String, Collection, Nullable, Boolean, Enum/Union, Date/Time, Float, Composite. Each type class has specific boundary values — see `references/boundary-catalog.md`.

### Step 3: Scan for Decision Points

Every code construct that partitions input space: comparisons, switch/match, loop conditions, guard clauses, try/catch, type narrowing, null checks, `.count` comparisons, ternaries.

### Step 4: Extract Boundary Values

For each decision point, select three test points: on-boundary, off-below, off-above. See `references/boundary-catalog.md` for the operator table and increment rules.

### Step 5: Handle Compound Conditions

**AND** (`A && B`): Use MC/DC — N+1 tests where each condition independently flips the outcome.
**OR** (`A || B`): Same MC/DC approach.
**Nested/complex**: Decompose into decision table.

### Step 6: Derived and State-Dependent Boundaries

- Derived: `if (a + b > limit)` → boundary is `a + b = limit`, test at limit±1
- State-dependent: identify distinct states, test each state × boundary combination

### Step 7: Produce Test Case List

Order by priority: degenerate/empty → minimal valid → nominal → upper boundaries → invalid → type-specific edges → compound interactions → state × boundary.

Output format per case:
```
N. test_name: description
   Input: { param1: value, param2: value }
   Expected: outcome
   Boundary: which boundary this tests
```

---

# Phase 2: TDD Cycle (Swift)

### RED: Write the Failing Test

```swift
import Testing

@Suite("Cart")
struct CartTests {
    let sut: Cart

    init() {
        sut = Cart(catalog: MockCatalog())
    }

    @Test("Rejects negative quantity")
    func rejectNegativeQuantity() throws {
        #expect(throws: CartError.invalidQuantity) {
            try sut.add(item: .widget, quantity: -1)
        }
    }
}
```

Rules: `@Test` with display name. One behavior per test. `#expect` for soft assertions, `#require` for preconditions. Struct suite with `init()`. Inject dependencies via initializer.

### Verify RED

```bash
swift test --filter "CartTests/rejectNegativeQuantity"           # SPM
xcodebuild test -scheme MyApp -destination 'platform=macOS' \
  -only-testing 'MyAppTests/CartTests/rejectNegativeQuantity'    # Xcode
```

Confirm: test **fails** (not errors), failure matches expected behavior, fails because feature is missing.

### GREEN: Minimal Implementation

Simplest code that makes the test pass. Don't add features or refactor.

### Verify GREEN

```bash
swift test                           # SPM: all tests
xcodebuild test -scheme MyApp ...    # Xcode: all tests
```

All tests pass, no warnings.

### REFACTOR

After green only. Remove duplication, improve names. Keep all tests green. Don't add behavior.

### Repeat

Next failing test from the BVA list.

---

# Testing Async, Actors, @MainActor

```swift
@Test func fetchUser() async throws {
    let user = try await api.fetchUser(id: "123")
    #expect(user.name == "Alex")
}

@Test func counterIncrements() async {
    let counter = Counter()  // actor
    await counter.increment()
    #expect(await counter.value == 1)
}

@Test @MainActor func viewModelLoads() async {
    let vm = ViewModel()
    await vm.loadData()
    #expect(vm.title == "Loaded")
}
```

Mock objects in concurrent tests must be `Sendable` — use actor mocks. Swift Testing runs tests in parallel by default. Use `.serialized` only when tests share external state that cannot be isolated.

---

# Dependency Injection

Swift has no runtime mock generation. Every seam must be explicit.

**Protocol-based** (primary): define protocol, implement live + mock versions, inject via init.
**Closure injection** (lighter): `var fetchUser: (String) async throws -> User = LiveAPI().fetchUser`
**Default parameter**: `init(api: APIClient = LiveAPIClient())`

Test data factories: `extension User { static func fixture(name: String = "Test") -> User { ... } }`

---

# XCTest Migration

| XCTest                 | Swift Testing             |
| ---------------------- | ------------------------- |
| `XCTAssertEqual(a, b)` | `#expect(a == b)`         |
| `XCTAssertNil(x)`      | `#expect(x == nil)`       |
| `try XCTUnwrap(x)`     | `try #require(x)`         |
| `setUpWithError()`     | `init() throws`           |
| `XCTestExpectation`    | `await confirmation(...)` |
| `func testFoo()`       | `@Test func foo()`        |
| `XCTSkip`              | `.disabled("reason")`     |

Both frameworks coexist. Do not subclass `XCTestCase` for Swift Testing tests.

---

# Swift TDD: What's Different

- **Value types reduce mocking**: pure functions on structs need no mocks
- **Type system replaces tests**: don't test what the compiler enforces (type mismatch, exhaustive switch, non-optional, Sendable)
- **Parallel by default**: fix shared state, don't reach for `.serialized`
- **No runtime mocking**: every dep needs protocol/closure seam. Code-gen tools (Mockolo, Sourcery) generate mocks at build time

---

# Layered Testing

All units must be tested, and all runtime paths tested from unit outward. N layers between unit and user behavior = N layers of tests.

| Layer | Proves                                        | Test type        |
| ----- | --------------------------------------------- | ---------------- |
|     1 | Evaluator produces correct output             | Unit test        |
|     2 | Model delivers result to display state        | Integration test |
|     3 | View receives and renders                     | Snapshot/UI test |

Rules: passing unit test proves the unit works, NOT the feature. Each layer tests real composition (not mocks of the layer below). No untested layer boundaries.

---

# UI Feature TDD (Outside-In Double Loop)

Outer acceptance test (snapshot/XCUITest) stays red while inner unit tests drive implementation.

1. Write outer test (RED) — snapshot or XCUITest for completed feature
2. Identify components (VM properties, model methods, view elements)
3. Inner loop: unit test → implement → refactor for each VM behavior
4. Implement view last (GREEN outer)

**Testing pyramid**: ~70% unit / ~20% snapshot / ~10% XCUITest

| Question                               | Test Type     |
| -------------------------------------- | ------------- |
| Logic with no UI dependency?          | Unit          |
| View renders correct elements?        | Snapshot      |
| Dark mode / large text correct?       | Snapshot      |
| Multi-screen flow works end-to-end?   | XCUITest      |
| System permissions/alerts work?       | XCUITest      |

---

# Snapshot Testing

```swift
import Testing
import SnapshotTesting

@Test func lightAndDark() {
    let view = ItemListView(viewModel: .init(items: Item.samples))
    assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
    assertSnapshot(of: view, as: .image(
        layout: .device(config: .iPhone13),
        traits: UITraitCollection(userInterfaceStyle: .dark)
    ), named: "dark")
}
```

Determinism: pin Xcode + simulator in CI, `perceptualPrecision: 0.98`, disable animations, fix locale/timezone.

---

# XCUITest

Reserve for 5-10 critical journeys. Page Object pattern mandatory.

```swift
struct LoginScreen {
    let app: XCUIApplication
    var emailField: XCUIElement { app.textFields["emailField"] }
    var loginButton: XCUIElement { app.buttons["loginButton"] }

    @discardableResult
    func login(email: String, password: String) -> HomeScreen {
        emailField.tap(); emailField.typeText(email)
        loginButton.tap()
        return HomeScreen(app: app)
    }
}
```

Rules: `.accessibilityIdentifier()` for element identification. `waitForExistence(timeout:)` for waits — never `sleep()`. Each test resets state via launch arguments.

---

# Common Mistakes

| Mistake                                   | Fix                                                        |
| ----------------------------------------- | ---------------------------------------------------------- |
| Using XCTest for new unit tests           | Swift Testing (`@Test`, `#expect`)                         |
| Missing `await` on actor assertions       | `#expect(await counter.value == 1)`                        |
| Non-Sendable mock in concurrent tests     | Actor mock or `@unchecked Sendable` with lock              |
| Tests depend on execution order           | Make independent, or `.serialized`                         |
| `#expect` where `#require` needed         | Preconditions need `#require`                              |
| Modifying test to match buggy output      | Fix the implementation, not the test                       |
| 2-3 test cases for function with branches | Run BVA algorithm — almost certainly incomplete            |
| Only testing explicit parameters          | Check implicit state, closures, globals                    |
| Skipping derived boundaries               | `a + b > limit` has boundary even if no single param does |

# Red Flags

- Writing `import XCTest` for a new unit test
- Test passes immediately (testing existing behavior)
- Mock type isn't `Sendable` but tests run in parallel
- "This function is too simple to analyze" — it has boundaries
- "I'll just test happy path and one error" — that's not BVA
- Using `accessibilityIdentifier` without verifying it exists in view source

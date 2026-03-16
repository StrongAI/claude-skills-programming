# Swift Testing Quick Reference

## Assertions

```swift
#expect(a == b)                                    // equality (any expression)
#expect(list.contains(x))                          // membership
#expect(throws: ErrorType.self) { try riskyCall() } // error type
let err = try #require(throws: MyError.self) { try parse(bad) }  // capture error
let val = try #require(optionalValue)              // unwrap-or-fail (replaces XCTUnwrap)
```

`#expect` = soft (continues on failure). `#require` = hard (throws, stops test). Use `#require` for preconditions where continuing is pointless.

## Parameterized Tests

```swift
@Test("Validates email", arguments: [
    ("valid@example.com", true),
    ("no-at-sign", false),
    ("", false),
])
func emailValidation(_ email: String, _ expected: Bool) {
    #expect(isValid(email) == expected)
}

@Test(arguments: Theme.allCases)           // CaseIterable: auto-covers all cases
func themeRenders(_ theme: Theme) { ... }

@Test(arguments: zip(inputs, outputs))     // paired: parallel iteration
func transform(_ input: String, _ expected: String) { ... }
```

Each argument tuple runs as an independent test case. Max two argument collections (cartesian product unless zipped).

## Tags and Traits

```swift
extension Tag {
    @Tag static var networking: Self
    @Tag static var critical: Self
}

@Suite(.tags(.networking), .serialized)
struct APITests {
    @Test(.tags(.critical), .bug("APP-1234", "Crash on retry"))
    func retryOnFailure() async throws { ... }
}
```

| Trait                     | Purpose                      |
| ------------------------- | ---------------------------- |
| `.tags(...)`              | Categorization and filtering |
| `.bug("ID", "desc")`      | Links to issue tracker       |
| `.enabled(if: expr)`      | Conditional execution        |
| `.disabled("reason")`     | Skip with explanation        |
| `.timeLimit(.minutes(n))` | Execution timeout            |
| `.serialized`             | No parallel for this suite   |

CLI filtering: `swift test --filter .networking` / `swift test --skip .slow`.

## Async Event Verification

```swift
// Assert callback fires exactly N times
await confirmation("didUpdate", expectedCount: 3) { confirm in
    let delegate = MockDelegate(onUpdate: { confirm() })
    sut.delegate = delegate
    sut.performAction()
}

// Assert something does NOT happen
await confirmation("no side effect", expectedCount: 0) { confirm in
    sut.logout()
}
```

All confirmations must fire before the closure returns. For callback APIs, use `withCheckedContinuation` inside the closure.

## Known Issues and Exit Tests

```swift
// Known bug: test runs, failure expected, alerts when fixed
withKnownIssue("Parser fails on nested tags") {
    #expect(parse(complexInput).count > 0)
}

// Exit tests (Swift 6.2+): verify precondition/fatalError
await #expect(processExitsWith: .failure) {
    precondition(false, "boom")
}
```

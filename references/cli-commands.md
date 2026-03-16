# CLI Test Commands

## SPM

```bash
swift test                                     # all tests
swift test --filter "SuiteTests/testName"      # single test
swift test --filter .networking                # by tag
swift test --skip .slow                        # exclude tag
swift test -l                                  # list (dry run)
swift test --enable-code-coverage              # coverage
```

## Xcode Projects

```bash
xcodebuild test -scheme MyApp -destination 'platform=macOS'
xcodebuild test -scheme MyApp -destination 'platform=macOS' \
  -only-testing 'MyAppTests/AuthTests/loginSucceeds'
xcodebuild test -scheme MyApp -destination 'platform=macOS' \
  -skip-testing 'MyAppTests/SlowTests'
# CI optimization: build once, run many
xcodebuild build-for-testing -scheme MyApp -destination 'platform=macOS'
xcodebuild test-without-building -scheme MyApp -destination 'platform=macOS'
```

`-only-testing` format: `TestTarget[/Suite[/TestMethod]]`.

Exit code 0 = all passed. Pipe through `xcbeautify` for readable output.

## XCUITest Parallel Execution

```bash
xcodebuild test \
  -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -parallel-testing-enabled YES \
  -parallel-testing-worker-count 4 \
  -resultBundlePath TestResults.xcresult
```

Xcode distributes test classes (not individual methods) across worker simulator clones.

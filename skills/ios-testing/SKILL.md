---
name: ios-testing
description: Rules for writing and planning iOS tests (XCTest unit tests, XCUITest UI tests, Swift Testing) that keep the suite small, fast and readable by humans. Use whenever writing, changing, debugging or planning tests for an iOS or Swift app - a feature plan's test section, unit tests, UI or end-to-end tests, snapshot tests, a failing test for a bug, a flaky test - and before running the app in the simulator to check a change (simctl, AXe). Activates for "add a test", "write tests", "test this", "test plan", "what should we test", "UI test", "XCUITest", "XCTest", "end-to-end test", "smoke test", "verify in the simulator", and when editing files in a *Tests or *UITests target.
---

# iOS testing

## Problem

Each test adds its run time to every local run, every CI run and every agent
iteration for as long as the project lives. A suite reaches 30 or 60 minutes
through many small additions that each looked reasonable. There is no fixed time
budget: each new test is a decision whose cost the agent can state and justify.

Assertions are cheap, so use as many as the behavior needs. Tests are
expensive, and tests that launch the app in the simulator cost the most.

## The goal

Keep the iOS test suite fast enough that people run it on every change, and
readable enough that a human can review it.

## Cost and value

Orders of magnitude. Measure when the choice depends on it.

| Kind | Cost per test |
|------|---------------|
| Logic test in a Swift package (`swift test` on the Mac) | milliseconds, no simulator |
| Unit test in the app's test target | milliseconds plus any network or disk I/O, after one app launch per run |
| UI test (XCUITest) | seconds to tens of seconds; each test usually launches the app in `setUp` |
| Smoke check by the agent (simctl, AXe) | minutes: build, install, launch, tap through |

Tests also cost maintenance. UI tests break when copy or layout changes, and a
flaky test costs everyone who reruns a red build.

Before adding a test, answer these. If the agent can't name the regression, or
a cheaper level catches it, add assertions to an existing test or add nothing.

- Which regression does it catch that no current test catches? Name it in one
  sentence.
- What is the cheapest level in the table that can catch it?
- Can it be assertions in a test that already runs this code?
- How likely is this code to break? Branching logic, parsing, money and date
  maths, and code that changes often earn tests. Wiring, constants, generated
  code and Apple's frameworks don't.

In a plan's test section, list each test as new or extended, with its kind and
rough cost: "extend `SignUpUITests` (+3 assertions)", "new
`EmailValidationTests` (12 inputs, ms)". A new UI test also gets one sentence on
why no existing test can take its assertions. The reviewer sees the cost before
the code exists.

## Assert behavior, not declarations

Assertions are cheap to run, but one that repeats a declaration protects
nothing: it passes while the declaration is unchanged, and whoever changes the
value on purpose has to change the test too. Don't assert:

- Constants and configuration: a timeout, a retry count, a base URL, a feature
  flag's default, an animation duration, a color or font constant.
- Declarations: protocol conformance (`XCTAssertTrue(sut is UITableViewDataSource)`),
  an enum's cases, `CodingKeys`, a Realm object's `primaryKey()` or properties.
- Wiring: an outlet is connected, a delegate is set, an observer or a
  dependency is registered.
- Project settings: Info.plist keys, entitlements, the bundle ID.
- Apple's frameworks: that `JSONDecoder` decodes or `UserDefaults` stores.

Exercise the code that uses the value and assert its result instead: decode a
sample response and assert the model, load the view controller and assert what
it shows, or, when the retry behavior matters, fail the stubbed request and
count the attempts. A change that only tunes a value, such as a timeout or a
color, needs no new test.

An exact value is worth asserting when a contract outside the code fixes it:
raw values persisted on disk (Realm, `UserDefaults` or Keychain keys), JSON
field names the API expects, URL schemes other apps open. Name the contract in
the test name, and assert the persisted or encoded output rather than the
declaration. Repeating a declaration, or freezing a value someone may tune, is
not a contract.

## Pick the cheapest level

- Edge cases go in unit tests, never in a UI test per case. When a view decides
  something (is this email valid, how is this amount formatted, is this button
  enabled), extract the decision into a plain type named after it
  (`EmailValidation`) that takes plain values (a `String`, a `Date`, a model) and
  returns a result. Unit test that type with every input the product cares
  about, not every rule in the RFC. That is fast, and we cover scenarios without
  needing several e2e tests.
- Logic with no UIKit or app dependency can live in a local Swift package when
  the project has one that fits; `swift test` runs it without a simulator.
  Don't create a package only to make code testable.
- Aim for one or two UI tests per big feature, maybe three. The first covers the
  happy path. Extra ones cover failures that need the full app, such as a server
  error or navigating back (e.g validation errors show up in the UI).
- A UI test walks the whole flow and asserts at each step: the screen appeared,
  the field took the input, the button became enabled, the final screen shows
  the result. Within one test, don't reset or relaunch between steps. Don't
  split one flow into a test per step, since each split pays for another app
  launch.
- Visual properties can be unit tested when the test doesn't take seconds:
  build the view or view controller in the test and assert the color, font,
  constraint or bar appearance. Assert styling that depends on state or on an
  iOS behavior (a disabled button's color, the bar color when scrolled to the
  top), not a single assignment. Don't add UI tests for visual checks such as a
  border or spacing.
- Add snapshot tests only where the project already uses a snapshot library.
  Each reference image is a file someone re-records and triages.

```swift
// SignUpViewController asks EmailValidation; the edge cases are tested here.
func testValidatesEmails() {
  let cases: [(email: String, valid: Bool)] = [
    ("ana@example.com", true),
    (" ana@example.com ", true),
    ("ana@example", false),
    ("ana@@example.com", false),
    ("", false),
  ]
  for (email, valid) in cases {
    XCTAssertEqual(EmailValidation().isValid(email), valid, "'\(email)'")
  }
}
```

## Extend before adding

- Before writing a UI test, search the UI test target for the screen's labels,
  identifiers and view names to find tests that already pass through that
  screen, button or flow. Add the new assertions there.
- Example: a name field added to sign-up is typed into and asserted in the
  existing sign-up test. It gets no test of its own.
- A new case for an existing type goes into its existing test class, and into
  its input table when it has one.
- When two slow tests that the change touches cover the same path, propose
  merging them. Don't delete tests without asking.

## Readable tests

- Follow the codebase: framework, folders, file names, class and method names,
  helpers, fixtures and assertion style. Read two or three neighbouring tests
  before writing one. Deviate slightly only when the codebase is old or has few
  examples, and say so in the plan or PR.
- Use the framework the target already uses, and ask before adding Swift
  Testing to an XCTest-only target. UI tests need XCTest: Swift Testing has no
  UI automation.
- Name test classes after the type or flow under test (`EmailValidationTests`,
  `SignUpUITests`), and test methods after the behavior
  (`testRejectsEmailWithoutDomain`, not `testEmail2` or `testValidate`). A unit
  test checks one behavior.
- Keep the inputs visible in the test or in a small named helper in the same
  file, so a reader sees what was tested without opening other files.
- For input tables, Swift Testing's `@Test(arguments:)` reports each input on
  its own. In XCTest, loop over the table and put the input in the assertion
  message so a failure names the case.

## Where test code lives

- Code only tests use lives in the test targets: stubs, fakes, fixtures,
  factories and shared helpers go in the target's support folder (such as
  `<App>Tests/helpers`), as `spec/support` holds them in Rails. Use the folder
  the project already has.
- A helper two test targets need goes in a folder or support target that only
  test targets compile. Code that imports XCTest or Testing never goes in the
  app or in a library the app links; the app crashes at launch.
- Exception: XCUITest runs the app in a separate process and can only pass
  launch arguments and environment, so a hook that changes the app for a UI test
  (reset state, stop animations, stub the network, start signed in) has to be in
  the app target. Keep these hooks in one folder named for the job (such as
  `UITestSupport`), run them only when their launch argument is present, and
  wrap them in `#if DEBUG` so Release builds don't contain them.
- Define each launch argument and accessibility identifier once, in a file
  compiled into both the app and the UI test target.

## Reliable tests

- Never `sleep` or wait a fixed time. Wait for a condition
  (`waitForExistence(timeout:)`, `XCTNSPredicateExpectation`,
  `await fulfillment(of:)`). A fixed wait is too long when the app is fast and
  too short when it is slow.
- Stub the network in new tests: a `URLProtocol` stub, an injected client, or
  launch arguments that switch a UI test to stubs. A real server, even a local
  one, adds time and fails for reasons outside the code. Where the project's
  tests at that layer only use a local server, follow that and note the cost in
  the plan. Where neighbouring tests do both, stub.
- Inject what changes between runs: clock, date, locale, time zone, storage.
  Each test sets up its own state, so it passes alone and in random order.
- Fix a flaky test, or ask to delete it. Don't turn on retry-on-failure to make
  it pass. Run a new or extended UI test several times before committing
  (`xcodebuild test ... -test-iterations 5 -run-tests-until-failure`).
- In UI tests, find elements the way the project does. Where it has no pattern
  yet, prefer accessibility identifiers to labels, which change with copy and
  localization.

## Smoke checks in the simulator

A smoke check is the agent running the app in the simulator (simctl, AXe) to
see a change work. It's QA'ing.

- Do one pass through the changed flow's happy path, and check each step with a
  screenshot or the element tree.
- Don't repeat the pass for each edge case; unit tests cover those.
- A smoke check doesn't replace a committed test. When it finds a bug, write a
  failing test at the cheapest level that reproduces it, then fix the bug.

## Debugging tests

Throwaway tests that help debug are fine; they are not part of the suite.
Delete them before committing, unless one catches a regression no other test
catches, follows the codebase's conventions and passes the cost questions above.
In that case, refactor the test to respect the rules above.

## Safety

When relying on a backend API schema, prefer to stub the network using some kind
of contract defined by the backend. That way, we don't need to call the backend,
which is slow, but the stub will break if the backend changes, making the test
contracts safe and fast.

## Before finishing

- Run the tests the change added or touched: their whole unit test target, and
  for UI tests only the changed test classes.
- Report which tests were added or extended, their kind, and how long each UI
  test took. Pass `-resultBundlePath <path>` to `xcodebuild test`, then read
  `durationInSeconds` per test from
  `xcrun xcresulttool get test-results tests --path <path>`.

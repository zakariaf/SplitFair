<!-- Thanks for contributing! Please fill this out so review is quick. -->

## What & why

<!-- What does this PR change, and why? Link any related issue: e.g. "Closes #12". -->

## Type of change

- [ ] Bug fix
- [ ] New feature
- [ ] Docs / tests / tooling
- [ ] Refactor (no behavior change)

## Checklist

- [ ] `swift test --package-path Packages/BillCore` is green (the **$97.20** gate included)
- [ ] `swiftformat .` and `swiftlint --strict` pass with no changes/violations
- [ ] I added or updated tests for any money-math or model change
- [ ] The four non-negotiables still hold (exact-cent math · offline/no-account · one `@Observable` store · money is ink-on-paper)
- [ ] No new third-party dependency, network call, analytics, or account was introduced
- [ ] One focused change; clear, imperative commit messages

## Notes for the reviewer

<!-- Anything worth calling out: tradeoffs, screenshots for UI changes, follow-ups. -->

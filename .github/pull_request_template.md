<!-- Title format: <type>(<scope>): <subject> — see .github/CONTRIBUTING.md -->
<!-- Types: feat | fix | chore | docs | refactor | perf | ci -->

## What

<!-- One or two sentences. What does this PR change? -->

## Why

<!-- The motivation. Don't restate the diff — explain the problem this solves. -->

## Test plan

<!-- How did you verify this works? Tick what applies; add specifics. -->

- [ ] `shellcheck -x -S style install.sh bin/*` exits 0
- [ ] `plutil -lint launchd/*.plist nas/*.inetloc` all OK (if plists touched)
- [ ] `brew bundle check` clean for any modified Brewfile
- [ ] Ran on a clean shell / fresh terminal session
- [ ] No hardcoded `/Users/<username>/` paths introduced

## Notes for the reviewer

<!-- Anything non-obvious. Tradeoffs, alternatives ruled out, follow-ups. Delete if not needed. -->

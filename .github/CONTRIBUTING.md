# Contributing

Thanks for your interest. These dotfiles are primarily a personal setup, but if you've found a portability bug, want to add a feature, or improve the docs site — PRs and issues are welcome.

## Before you start

1. **Open an issue first** for anything non-trivial. A 5-line description saves both of us from a rejected PR.
2. **Read `CLAUDE.md`** in the repo root. It documents the design decisions (AeroSpace dual-config, portability rules, script quality standards) and saves you re-deriving them.
3. **Read the relevant docs page** at [dotfiles.rafay99.com](https://dotfiles.rafay99.com) — most behaviour is explained there in more detail than the commit history.

## The bar for changes

Every shell script, plist, and Brewfile in this repo is checked in CI. Before pushing:

```bash
# Shell scripts — must exit 0 (warnings + info-level fail too)
shellcheck -x -S style install.sh bin/*

# Plists — every file must print OK
for f in launchd/*.plist nas/*.inetloc; do plutil -lint "$f"; done

# Brewfiles — entries must resolve via Homebrew
for bf in Brewfile Brewfile.aerospace Brewfile.omniwm; do
  brew bundle check --file="$bf" --verbose
done
```

CI runs the same three commands. A red check is a release blocker.

### Inline lint disables

Only use `# shellcheck disable=SCxxxx` when the lint is genuinely wrong for your case, and **include a one-line comment justifying why** on the same line. See `install.sh:930` for the pattern.

## Commit style

Conventional Commits. The autolabeler and `git-cliff` both depend on this:

- `feat: …` — new feature → Features in changelog, minor version bump
- `fix: …` — bug fix → Fixes, patch bump
- `chore: …` — tooling, deps, CI, refactor with no behaviour change → Maintenance, patch bump
- `docs: …` — docs-only changes → Docs, patch bump
- `refactor: …` — code restructure with no behaviour change → Refactor

Scope is optional: `feat(nas-mount): …` is fine, `feat: …` is also fine.

Keep the subject under 72 chars. Use the body to explain *why*, not *what* — the diff already shows the *what*.

## Portability rule

**No hardcoded `/Users/<username>/` paths anywhere.** Use `$HOME` / `~` / `fish_add_path $HOME/...`. The repo is cloned across machines with different usernames and a hardcoded path silently breaks on a fresh install. See the **Cross-machine portability** section in `CLAUDE.md` for the full rationale and the launchd plist `__HOME__` templating pattern.

## Releasing

Direct-commit to `main` is fine — CI handles the release notes:

```bash
git tag v0.2.0
git push --tags
```

`.github/workflows/release.yml` invokes `git-cliff` to group commits between `v0.1.0..v0.2.0` by Conventional Commits prefix and publishes the GitHub Release.

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). Be excellent to each other.

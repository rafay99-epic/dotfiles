# Security Policy

## Supported versions

This is a personal dotfiles repository — the only supported version is the latest commit on `main`. Older tagged releases are kept for changelog purposes but are not patched.

## Reporting a vulnerability

If you find a security issue — credentials accidentally committed, a script that's exploitable by a local attacker, a supply-chain risk in a Brewfile pin, an XSS hole in the docs site — **please do not open a public issue.**

Email **99marafay@gmail.com** with:

- A description of the issue and where it lives (file + line)
- Steps to reproduce
- Your assessment of impact (local-only? remote? requires NAS access?)

Expect a reply within 7 days. Fixes for confirmed issues are usually pushed within 30 days; severe issues sooner.

## Out of scope

- Anything that requires already having a shell on the user's machine (the threat model here doesn't include local attackers — this is dotfiles, not server software).
- Findings against third-party tools installed via `Brewfile` (`brew`, `aerospace`, `ghostty`, etc.) — report those upstream.
- Reports based on running the install script as `root` (it's not designed to and shouldn't be).

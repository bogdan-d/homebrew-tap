## AI / contributor guidelines — BogdanD Homebrew Tap

This file provides targeted guidance for contributors (including AI agents) working on casks in this repository. Keep changes small and incremental and follow the established patterns.

Repository layout
- `Casks/` — the Ruby cask files. Each file is a single cask recipe.
- `WIP/` — work-in-progress files or temporary artifacts for testing and must be ignored.
- `dev-cask.sh` — local testing and validation helper (see below).
- `scripts/finish.sh` — required end-of-session formatting and validation command.

Key patterns to follow
- Follow the Homebrew cask DSL: `cask "name" do ... end`. Include `version`, `sha256`, `url`, `desc`, `homepage` where applicable.
- Multi-arch support: use `arch arm: "arm64", intel: "x64"` and `on_arm`/`on_intel` conditionals where needed.
- Desktop assets: use `artifact` for `.desktop` files and icons; apply `preflight` for any Exec or icon path rewrites.
- Wallpapers and DE-specific artifacts: handle GNOME, KDE, and other DEs by adapting metadata and XML preprocessing as necessary.

Validation and CI
- Before finishing any editing session, run:

```bash
./scripts/finish.sh
```

- This applies Homebrew's `brew style --fix` formatting, including its `shfmt` and ShellCheck rules, verifies repository style, runs the `dev-cask.sh` tests, and audits changed casks.
- Use focused commands while developing when useful:

```bash
./dev-cask.sh style <cask_name>
./dev-cask.sh audit <cask_name>
./dev-cask.sh bump <cask_name>
```

- Use `brew bump-cask-pr` to create version bump PRs and ensure `version` and `sha256` are updated together.

Local testing scripts
- `dev-cask.sh <command> <cask_name> [options]` — Run `install`, `audit`, `livecheck`, or `bump` in a unique scratch tap containing only the requested cask; `style` checks the local file directly. `--keep` prints the owned tap name and exact cleanup command. The helper refuses to replace or remove a cask that was already installed.

Note: The local testing script is meant to be used on a developer machine (it requires Homebrew). It’s helpful for validating local changes without publishing. Always use `--keep` when you need to debug an install by leaving the cask installed and the tap present.

Agent behavior (rules)
- Do not alter published values (`version`, `sha256`, `url`) unless deliberately bumping the version with a testable install.
- Create focused PRs (one cask per PR where practical).
- Mirror existing patterns (see `visual-studio-code-linux.rb` for desktop transformations and multi-arch patterns).
- Add `zap trash:` entries for user-level files when necessary and verify prefix paths (e.g., `~/.local/`).

Useful examples
- `Casks/visual-studio-code-linux.rb` — multi-arch handling and desktop transformations
- `Casks/framework-tool.rb` — minimal-binary cask example

If you need more specifics (example diffs, lint outputs, or a PR template), open a discussion or leave a draft PR and request feedback.

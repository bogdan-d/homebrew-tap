## AI / contributor guidelines — BogdanD Homebrew Tap

This file provides targeted guidance for contributors (including AI agents) working on casks in this repository. Keep changes small and incremental and follow the established patterns.

Repository layout
- `Casks/` — the Ruby cask files. Each file is a single cask recipe.
- `WIP/` — work-in-progress files or temporary artifacts for testing and must be ignored.
- `dev-cask.sh` — local testing and validation helper (see below).

Key patterns to follow
- Follow the Homebrew cask DSL: `cask "name" do ... end`. Include `version`, `sha256`, `url`, `desc`, `homepage` where applicable.
- Multi-arch support: use `arch arm: "arm64", intel: "x64"` and `on_arm`/`on_intel` conditionals where needed.
- Desktop assets: use `artifact` for `.desktop` files and icons; apply `preflight` for any Exec or icon path rewrites.
- Wallpapers and DE-specific artifacts: handle GNOME, KDE, and other DEs by adapting metadata and XML preprocessing as necessary.

Validation and CI
- Run local checks before creating PRs:

```bash
./dev-cask.sh style <cask_name>
./dev-cask.sh audit <cask_name>
```

- Use `brew bump-cask-pr` to create version bump PRs and ensure `version` and `sha256` are updated together.

Local testing scripts
- `dev-cask.sh <command> <cask_name> [options]` — Create a temporary local tap (`bogdan-d/local-test`), copy the specified cask into it, and run one of the supported Homebrew commands (`install`, `audit`, `livecheck`, `style`, `cleanup`, `untap`). Offers `--keep` to skip cleanup, `--debug` for debug output, and `--verbose` to pass to brew commands. For `install`, defaults to cleanup after unless `--keep` is used.

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

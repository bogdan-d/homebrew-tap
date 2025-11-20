## AI / contributor guidelines — BogdanD Homebrew Tap

This file provides targeted guidance for contributors (including AI agents) working on casks in this repository. Keep changes small and incremental and follow the established patterns.

Repository layout
- `Casks/` — the Ruby cask files. Each file is a single cask recipe.
- `dev-cask.sh`, `test-cask.sh` — local testing and validation helpers (see below).
- scripts: utility scripts such as `audit.sh` and `style.sh` are in the repo root.

Key patterns to follow
- Follow the Homebrew cask DSL: `cask "name" do ... end`. Include `version`, `sha256`, `url`, `desc`, `homepage` where applicable.
- Multi-arch support: use `arch arm: "arm64", intel: "x64"` and `on_arm`/`on_intel` conditionals where needed.
- Desktop assets: use `artifact` for `.desktop` files and icons; apply `preflight` for any Exec or icon path rewrites.
- Wallpapers and DE-specific artifacts: handle GNOME, KDE, and other DEs by adapting metadata and XML preprocessing as necessary.

Validation and CI
- Run local checks before creating PRs:

```bash
./style.sh Casks/<cask-file>.rb
./audit.sh Casks/<cask-file>.rb
```

- Use `brew bump-cask-pr` to create version bump PRs and ensure `version` and `sha256` are updated together.

Local testing scripts
- `dev-cask.sh <command> <cask_name> [options]` — Create a temporary local tap (`bogdan-d/local-test`), copy the specified cask into it, and run one of the supported Homebrew commands (`install`, `audit`, `livecheck`, `style`, `cleanup`, `untap`). Offers `--keep` to skip cleanup.
- `test-cask.sh <cask_name> [--keep] [--cleanup] [--untap]` — A direct install test harness. It adds/commits local changes into the temporary tap, runs `brew install --cask --verbose`, and optionally cleans up the install and the tap.

Note: Both local testing scripts are meant to be used on a developer machine (they require Homebrew). They’re helpful for validating local changes without publishing. Always use `--keep` when you need to debug an install by leaving the cask installed and the tap present.

Agent behavior (rules)
- Do not alter published values (`version`, `sha256`, `url`) unless deliberately bumping the version with a testable install.
- Create focused PRs (one cask per PR where practical).
- Mirror existing patterns (see `visual-studio-code-linux.rb` for desktop transformations and multi-arch patterns).
- Add `zap trash:` entries for user-level files when necessary and verify prefix paths (e.g., `~/.local/`).

Useful examples
- `Casks/visual-studio-code-linux.rb` — multi-arch handling and desktop transformations
- `Casks/bluefin-wallpapers.rb` — wallpaper cask pattern
- `Casks/framework-tool.rb` — minimal-binary cask example

If you need more specifics (example diffs, lint outputs, or a PR template), open a discussion or leave a draft PR and request feedback.

# Universal Blue Homebrew Tap Guidelines

## Project Overview
This is a Homebrew tap for Universal Blue (Fedora-based distros like Bluefin, Aurora, Bazzite). It provides Linux casks for applications unsuitable for Flatpak, such as IDEs, OEM tools, and wallpapers. The tap serves as a staging area for testing Linux cask builds before potential upstreaming.

# Universal Blue Homebrew Tap Guidelines

Purpose: give AI coding agents the essential, discoverable knowledge to be productive in this repo.

Core idea
- This repository is a Homebrew "tap" that provides Linux casks (Ruby DSL files) in `Casks/`.
- Casks install user-space artifacts (binaries to `~/.local/bin`, icons/desktop files to `~/.local/share/`) and are intended for Fedora-based derivatives (Bluefin/Aurora/Bazzite).

What to focus on (high-value patterns)
- Casks are single-file recipes: `cask "name" do ... end`. Look for `version`, `sha256`, `url`, `name`, `desc`, `homepage`.
- Multi-arch pattern: `arch arm: "arm64", intel: "x64"` with `on_arm`/`on_intel` conditionals appears in `visual-studio-code-linux.rb`.
- Desktop integration: many casks use `artifact` for `.desktop` files and `preflight` blocks to edit `.desktop` or move icons (see `visual-studio-code-linux.rb` and `bluefin-wallpapers.rb`).
- Wallpapers: wallpaper casks include DE detection and XML preprocessing; `bluefin-wallpapers.rb` and `aurora-wallpapers.rb` are canonical examples.

Critical developer workflows (commands)
- Install a cask locally (verbose for debugging):
```pwsh
brew install --cask <cask-name> --verbose
```
- Audit and style-check a cask before PR:
```pwsh
brew audit --cask --online Casks/<cask-file>.rb
brew style Casks/<cask-file>.rb
```
- Create a version bump PR (renovate or manual):
```pwsh
brew bump-cask-pr Casks/<cask-file>.rb
```

Common, discoverable conventions
- Prefer deterministic URLs (GitHub releases) and explicit `sha256`. When updating, update both `version` and `sha256`.
- Use `livecheck` blocks where appropriate (see `visual-studio-code-linux.rb`) to enable automated version detection.
- Use `artifact` for `.desktop` and icons; apply `preflight` to change Exec paths or desktop categories.
- Provide `zap trash:` entries for user-space cleanup where installed files are under `~/.local/`.

Examples to reference
- `Casks/visual-studio-code-linux.rb` — multi-arch, completions, desktop file tweaks.
- `Casks/bluefin-wallpapers.rb` — DE-specific artifacts and XML preprocessing.
- `Casks/framework-tool.rb` — minimal binary cask pattern.

Agent guidance (how AI should modify files here)
- Preserve user-facing semantics: do not change `version`, `sha256`, or published URLs without a clear version bump and testable install.
- Small, focused patches: change only one cask per PR where possible.
- When adding features (livecheck, livecheck regex), run `brew style` and `brew audit` locally and include output in PR description.
- When editing desktop files or preflight logic, mirror patterns from `visual-studio-code-linux.rb` to keep behavior consistent.

If anything is unclear or you'd like more detail (example diffs, lint outputs, or a short PR template), tell me which parts to expand.

# BogdanD - Homebrew Linux Tap

This repository is a Homebrew "tap" providing Linux casks and user-space packages for Fedora Atomic (and related Fedora-based derivatives). It contains casks for applications and assets that are better installed in user-space than as system packages—IDEs, developer tools, OEM utilities, and wallpapers.

Quick start
1. Tap the repository (replace <user>/<repo> as appropriate):

```bash
brew tap bogdan-d/tap
```

2. Install a cask:

```bash
brew install --cask visual-studio-code-linux
brew install --cask vscodium-linux
```

What’s included
- IDEs and developer editors: VS Code, VSCodium, Zed, LM Studio
- OEM or hardware tools: Framework System Tool
- Wallpapers and desktop assets (Bluefin, Aurora, Bazzite, etc.)

Working with this repo
- Casks are located in `Casks/` — each cask is a single Ruby DSL file. Follow conventions already used in this repo: `version`, `sha256`, `url`, `artifact`, and `preflight` blocks.
- Use `arch` and `on_arm`/`on_intel` conditionals for multi-arch builds.
- For painting desktop files/icons or replacing Exec paths, prefer `artifact` and `preflight` transformations.

Checks & automation
- Audit and style-check casks before opening a PR:

```bash
./audit.sh Casks/<cask-file>.rb
./style.sh Casks/<cask-file>.rb
```

- When updating a cask’s version, update both `version` and `sha256`, and create a bump PR using `brew bump-cask-pr` if applicable.

Contributing
- Open a PR with a clear description and check CI output. Small, focused PRs are preferred (one cask per PR when possible).
- If a cask is experimental or preview, prefer `version :latest` and `sha256 :no_check`, but document the reasoning.

License & notice
- This repository is a personal/homebrew tap. Use the casks responsibly and follow upstream licenses for included software.

Developer scripts

This repository includes helper scripts to speed up development and local testing of casks:

- `./style.sh [cask-name|path ...]`: Run `brew style` on one or more casks (supports `--fix`).
- `./audit.sh [cask-name|path ...]`: Run `brew audit --cask` on one or more casks.
- `./dev-cask.sh <command> <cask_name> [options]`: Local testing wrapper. It creates a temporary local tap at `bogdan-d/local-test`, copies the cask file into the tap, and runs the specified command:
	- Commands: `install`, `audit`, `livecheck`, `style`, `cleanup`, `untap`.
	- Options: `--keep` to skip cleanup (keep the temporary tap and the installed cask for manual inspection).
	- Example: `./dev-cask.sh install antigravity-linux --keep`

- `./test-cask.sh <cask_name> [--keep] [--cleanup] [--untap]`: A lightweight test harness which will commit or copy your local cask into the temporary tap, install it using `brew install --cask --verbose`, and optionally keep or clean up the install.
	- Example: `./test-cask.sh antigravity-linux`

Both dev/test scripts require Homebrew to be installed and accessible in your PATH. They help you validate casks against a local tap without publishing changes upstream.

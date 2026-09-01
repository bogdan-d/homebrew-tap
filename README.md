# BogdanD - Homebrew Linux Tap

This repository is a Homebrew "tap" providing Linux casks and user-space packages for Fedora Atomic (and related Fedora-based derivatives). It contains casks for applications and assets that are better installed in user-space than as system packages: IDEs, developer tools, OEM utilities, and wallpapers.

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

What's included
- IDEs and developer editors: VS Code, VSCodium, Zed, LM Studio
- OEM or hardware tools: Framework System Tool

Working with this repo
- Casks are located in `Casks/` - each cask is a single Ruby DSL file. Follow conventions already used in this repo: `version`, `sha256`, `url`, `artifact`, and `preflight` blocks.
- Use `arch` (and `os linux: "linux"` where appropriate) for multi-arch builds; avoid `on_arm`/`on_intel` inside `livecheck` (unsupported there).
- For painting desktop files/icons or replacing Exec paths, prefer `artifact` and `preflight` transformations.

Checks & automation
- Run the repository finisher before opening a PR:

```bash
./scripts/finish.sh
```

It applies Homebrew's `brew style --fix` formatting (including `shfmt` and ShellCheck), verifies repository style, runs helper tests, and audits changed casks.

- Use focused cask commands while developing:

```bash
./dev-cask.sh style visual-studio-code-linux --fix
./dev-cask.sh audit visual-studio-code-linux
./dev-cask.sh livecheck visual-studio-code-linux
./dev-cask.sh bump visual-studio-code-linux
./dev-cask.sh install --keep --verbose visual-studio-code-linux
```

`--keep` prints the unique scratch tap name and the exact cleanup command to run later.

- When updating a cask's version, update both `version` and `sha256`, and create a bump PR using `brew bump-cask-pr` if applicable.
- **Auto-merge note:** The scheduled `brew bump` workflow may attempt to enable auto-merge on PRs it creates. To allow this, enable **Allow auto-merge** in the repository Settings and ensure branch protection rules permit auto-merge on the target branch. If not enabled, the workflow will log a warning and continue.

Contributing
- Open a PR with a clear description and check CI output. Small, focused PRs are preferred (one cask per PR when possible).
- If a cask is experimental or preview, prefer `version :latest` and `sha256 :no_check`, but document the reasoning.

License & notice
- This repository is a personal/homebrew tap. Use the casks responsibly and follow upstream licenses for included software.

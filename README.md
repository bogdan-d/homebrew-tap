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
- Use `arch` and `on_arm`/`on_intel` conditionals for multi-arch builds.
- For painting desktop files/icons or replacing Exec paths, prefer `artifact` and `preflight` transformations.

Checks & automation
- Audit and style-check casks before opening a PR:

```bash
./dev-cask.sh style visual-studio-code-linux --fix
./dev-cask.sh audit visual-studio-code-linux
./dev-cask.sh livecheck visual-studio-code-linux
./dev-cask.sh install --keep --verbose visual-studio-code-linux
./dev-cask.sh cleanup --debug --verbose visual-studio-code-linux
```

- When updating a cask's version, update both `version` and `sha256`, and create a bump PR using `brew bump-cask-pr` if applicable.

Contributing
- Open a PR with a clear description and check CI output. Small, focused PRs are preferred (one cask per PR when possible).
- If a cask is experimental or preview, prefer `version :latest` and `sha256 :no_check`, but document the reasoning.

License & notice
- This repository is a personal/homebrew tap. Use the casks responsibly and follow upstream licenses for included software.

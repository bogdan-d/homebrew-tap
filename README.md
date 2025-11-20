# My personal Homebrew Tap

This is a _staging area_ to test Linux casks builds of things I want. It is intended to show that homebrew casks on linux work great. This repository's metric of success is when the applications in here are deleted. This also ships artwork and OEM tools that are better managed in userspace than on an image.

Homebrew has asked us to run this as a tap as opposed to PRing these into individual projects, and that will take some work so in the meantime we can test.

### Experimental Tap

We have some in-progress, but not quite finished formulas and casks in an [experimental tap](https://github.com/bogdan-d/experimental-tap). If you wish to experiment or provide feedback, check it out. Please send pull requests first, this is the production tap!

## This is useful for

IDEs like Jetbrains and VSCode. They don't run well out of flatpaks so we put them on their own images. This lets the user also opt-into vscode instead of having it on a -dx image even if you don't use it.

```shell
brew tap bogdan-d/tap
brew install --cask visual-studio-code-linux
brew install --cask visual-studio-code-insiders-linux
brew install --cask vscodium-linux
brew install --cask zed-linux
brew install --cask lm-studio-linux

brew install --cask bluefin-wallpapers
brew install --cask bluefin-wallpapers-extra
brew install --cask aurora-wallpapers
brew install --cask bazzite-wallpapers
brew install --cask framework-wallpapers
```

## Includes

- LM Studio - Local LLM discovery, download, and runtime
- Visual Studio Code - Microsoft's code editor
- Visual Studio Code Insiders - Preview/Insiders channel of VS Code
- Zed - High-performance, multiplayer code editor
- VSCodium - Open-source build of VS Code
- Framework System Tool - Hardware management for Framework laptops

### Wallpapers

Metadata for GNOME is usually there.

If you are on KDE then [follow these instructions](https://github.com/renner0e/bluefin-wallpapers-plasma).

- Bluefin Wallpapers - Wallpapers for Bluefin
- Bluefin Extra Wallpapers - Additional wallpapers for Bluefin
- Aurora Wallpapers - Art made for Aurora
- Bazzite Wallpapers - Wallpapers made for Bazzite
- Framework Wallpapers

## Checks & QA

Before opening a PR or publishing a cask, please run the following checks locally. These are the same commands used in our agent guidance and help keep casks consistent:

```pwsh
# Audit and style checks
brew audit --cask --online Casks/<cask-file>.rb
brew style Casks/<cask-file>.rb

# Optional: run livecheck for casks that expose a version
brew livecheck --cask Casks/<cask-file>.rb

# When updating a cask's version, create a bump PR
brew bump-cask-pr Casks/<cask-file>.rb
```

Notes:
- Rolling/preview/insiders casks often use `version :latest` and `sha256 :no_check` — check the cask source if you need strict checksums.
- Follow existing patterns: use `arch` multi-arch declarations where applicable, `artifact` for desktop files/icons, and `preflight` blocks to rewrite Exec/Icon paths when needed (see `Casks/visual-studio-code-linux.rb`).

## Developer scripts

This repository includes a couple of helper scripts you can use while working on the
tap:

	./style.sh [cask-name|path ...]  # Run `brew style --fix` on a cask or all casks
	./audit.sh [cask-name|path ...]  # Run `brew audit --cask` on a cask or all casks

Both scripts accept either a cask name (e.g., `antigravity-linux`) or a path
(`Casks/antigravity-linux.rb`). Use `-h` or `--help` to view help text.

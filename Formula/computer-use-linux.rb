class ComputerUseLinux < Formula
  desc "MCP server and CLI that lets AI agents observe and control the Linux desktop"
  homepage "https://github.com/agent-sh/computer-use-linux"
  url "https://github.com/agent-sh/computer-use-linux/archive/refs/tags/v0.7.62.tar.gz"
  sha256 "7d26bb7bb4402319b23a2bc5976336331b7681a0756f9b9b5b91138b0467d0cd"
  license "MIT"
  head "https://github.com/agent-sh/computer-use-linux.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/bogdan-d/homebrew-tap/releases/download/computer-use-linux-0.7.62"
    sha256 cellar: :any, x86_64_linux: "412bfe5dc11bef1a7bace52fc1b24c45b67973cdb9086dd90e14b6be368264a7"
  end

  depends_on "rust" => :build
  depends_on :linux
  depends_on "ydotool"

  def fetch
    system "cargo", "fetch", *std_cargo_fetch_args
  end

  def install
    # Installs computer-use-linux plus its COSMIC helper and on-screen indicator, which it finds next to itself.
    system "cargo", "install", *std_cargo_args
    pkgshare.install "skills"
  end

  def caveats
    skill = opt_pkgshare/"skills/computer-use-linux"
    <<~EOS
      Host pieces for KDE Plasma on Wayland come from the distribution, not Homebrew
      (AT-SPI bus, RemoteDesktop/Screenshot portals, Klipper for typing text):
        sudo pacman -S --needed at-spi2-core xdg-desktop-portal-kde plasma-workspace
      /dev/uinput must be readable and writable by your user. If it is not, grant only
      your user access rather than joining the broad "input" group:
        sudo setfacl -m u:$USER:rw /dev/uinput    # lasts until reboot

      Enable AT-SPI accessibility, then restart the apps you want to drive:
        computer-use-linux setup

      Optional ydotool keyboard fallback daemon (runs as your user, socket mode 0600):
        brew services start ydotool

      Check readiness:
        computer-use-linux doctor | jq .readiness

      Link the bundled skill:
        mkdir -p ~/.claude/skills ~/.codex/skills
        ln -sfn #{skill} ~/.claude/skills/computer-use-linux
        ln -sfn #{skill} ~/.codex/skills/computer-use-linux

      Register the MCP server for Claude Code:
        claude mcp add --scope user computer-use-linux -- #{opt_bin}/computer-use-linux mcp

      Register it for Codex by adding this to ~/.codex/config.toml (Codex only forwards
      the listed desktop session variables to MCP servers):
        [mcp_servers.computer-use-linux]
        command = "#{opt_bin}/computer-use-linux"
        args = ["mcp"]
        env_vars = ["DBUS_SESSION_BUS_ADDRESS", "DESKTOP_SESSION", "DISPLAY", "WAYLAND_DISPLAY", "XAUTHORITY", "XDG_CURRENT_DESKTOP", "XDG_SESSION_DESKTOP", "XDG_SESSION_TYPE", "XDG_RUNTIME_DIR", "XDG_DATA_DIRS", "XDG_CONFIG_HOME", "XDG_CACHE_HOME", "XDG_DATA_HOME", "XDG_STATE_HOME", "YDOTOOL_SOCKET"]

      Do not also install the upstream Claude Code or Codex plugin: its launcher downloads
      its own release binaries into ~/.cache/computer-use-linux.
    EOS
  end

  test do
    assert_match "Usage", shell_output("#{bin}/computer-use-linux --help")
    assert_match "Usage", shell_output("#{bin}/computer-use-linux-indicator --help")
    assert_match "Usage", shell_output("#{bin}/computer-use-linux-cosmic --help")
    assert_path_exists pkgshare/"skills/computer-use-linux/SKILL.md"
  end
end

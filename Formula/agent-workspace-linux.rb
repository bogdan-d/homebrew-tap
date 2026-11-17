class AgentWorkspaceLinux < Formula
  desc "MCP server that gives AI agents a private hidden Linux desktop"
  homepage "https://github.com/agent-sh/agent-workspace-linux"
  url "https://github.com/agent-sh/agent-workspace-linux/archive/refs/tags/v0.6.4.tar.gz"
  sha256 "fa7ab9640445fcb84a7e5f3e2ae4b8f6ebd6b047a13b24f3075686770948e385"
  license "MIT"
  head "https://github.com/agent-sh/agent-workspace-linux.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/bogdan-d/homebrew-tap/releases/download/agent-workspace-linux-0.6.4"
    rebuild 1
    sha256 cellar: :any, x86_64_linux: "fafbf837bbdc465b6071ffce1a2398bd45c2e9ebc4d06b2b4d84975e0cdc9b3d"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  # The font crates probe fontconfig and freetype through pkg-config at build time.
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "libxcb"
  depends_on "libxkbcommon"
  depends_on :linux
  depends_on "wayland"
  # The KWin backend refuses to start without wl-copy and wl-paste.
  depends_on "wl-clipboard"

  def fetch
    system "cargo", "fetch", *std_cargo_fetch_args
  end

  def install
    system "cargo", "install", *std_cargo_args
    pkgshare.install "skills"
  end

  def caveats
    skill = opt_pkgshare/"skills/agent-workspace-linux"
    <<~EOS
      The KWin backend (--session kwin) needs these from the distribution, not Homebrew:
        sudo pacman -S --needed kwin xorg-xwayland kservice libkscreen dbus coreutils
      and read/write access to a DRM render node (/dev/dri/renderD*).

      The default X11 backend additionally needs:
        sudo pacman -S --needed xorg-server-xvfb xorg-xauth xorg-xdpyinfo xorg-xprop xorg-xwininfo openbox xdotool imagemagick xclip

      Check readiness (see ready_for_kwin_workspace):
        agent-workspace-linux doctor

      Link the bundled skill:
        mkdir -p ~/.claude/skills ~/.codex/skills
        ln -sfn #{skill} ~/.claude/skills/agent-workspace-linux
        ln -sfn #{skill} ~/.codex/skills/agent-workspace-linux

      Register the MCP server for Claude Code:
        claude mcp add --scope user agent-workspace-linux -- #{opt_bin}/agent-workspace-linux mcp

      Register it for Codex by adding this to ~/.codex/config.toml (Codex only forwards
      the listed desktop session variables to MCP servers):
        [mcp_servers.agent-workspace-linux]
        command = "#{opt_bin}/agent-workspace-linux"
        args = ["mcp"]
        env_vars = ["DBUS_SESSION_BUS_ADDRESS", "DISPLAY", "WAYLAND_DISPLAY", "XAUTHORITY", "XDG_RUNTIME_DIR", "XDG_CURRENT_DESKTOP", "XDG_SESSION_TYPE", "XDG_DATA_DIRS"]
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/agent-workspace-linux --version")
    assert_path_exists pkgshare/"skills/agent-workspace-linux/SKILL.md"
  end
end

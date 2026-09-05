cask "opencode-desktop-linux" do
  os linux: "linux"

  version "1.18.29"
  sha256 "98775713346fbc4afcfbd94076557b20af79700ebe7347e7ba838c4f44e61882"

  url "https://github.com/anomalyco/opencode/releases/download/v#{version}/opencode-desktop-linux-x86_64.rpm"
  name "OpenCode"
  desc "Open source AI coding agent desktop client"
  homepage "https://opencode.ai/"

  livecheck do
    url "https://github.com/anomalyco/opencode/releases/latest/download/latest.json"
    strategy :json do |json|
      json["version"]
    end
  end

  depends_on :linux
  depends_on arch: :x86_64
  depends_on formula: "gtk+3"
  depends_on formula: "webkitgtk"
  depends_on formula: "rpm2cpio"
  depends_on formula: "cpio"

  binary "usr/bin/OpenCode", target: "opencode-desktop"
  binary "usr/bin/opencode-cli", target: "opencode-cli"
  artifact "usr/share/icons/hicolor/32x32/apps/OpenCode.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/32x32/apps/OpenCode.png"
  artifact "usr/share/icons/hicolor/128x128/apps/OpenCode.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/128x128/apps/OpenCode.png"
  artifact "usr/share/icons/hicolor/256x256@2/apps/OpenCode.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/256x256@2/apps/OpenCode.png"
  artifact "usr/share/applications/OpenCode.desktop",
           target: "#{Dir.home}/.local/share/applications/OpenCode.desktop"

  preflight_steps do
    run "{{HOMEBREW_PREFIX}}/opt/rpm2cpio/bin/rpm2cpio",
        args: ["{{staged_path}}/opencode-desktop-linux-x86_64.rpm"], stdout_path: "opencode-desktop.cpio"
    run "{{HOMEBREW_PREFIX}}/opt/cpio/bin/cpio",
        args: ["-idm", "--quiet"], stdin_path: "opencode-desktop.cpio", chdir: "{{staged_path}}"
    remove "opencode-desktop.cpio"
    inreplace "usr/share/applications/OpenCode.desktop", /^Exec=.*/,
              "Exec={{HOMEBREW_PREFIX}}/bin/opencode-desktop %U"
  end

  zap trash: [
    "~/.cache/ai.opencode.desktop",
    "~/.config/ai.opencode.desktop",
    "~/.local/share/ai.opencode.desktop",
  ]
end

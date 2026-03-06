cask "opencode-desktop-linux" do
  arch arm: "aarch64", intel: "x86_64"

  version "1.2.20"
  sha256 arm64_linux:  "f2466cc2415c2cd700209e11a8244dc8fdf89222eeecc3dd9674745814797a48",
         x86_64_linux: "e0131ff86ce6b5e07064bb1e58c7238b966a3c4b450deec4485a44ba6284dfa7"

  url "https://github.com/anomalyco/opencode/releases/download/v#{version}/opencode-desktop-linux-#{arch}.rpm",
      verified: "github.com/anomalyco/opencode/"
  name "OpenCode"
  desc "Open source AI coding agent desktop client"
  homepage "https://opencode.ai/"

  livecheck do
    url "https://github.com/anomalyco/opencode/releases/latest/download/latest.json"
    strategy :json do |json|
      json["version"]
    end
  end

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

  preflight do
    rpm2cpio = Formula["rpm2cpio"].bin/"rpm2cpio"
    cpio = Formula["cpio"].bin/"cpio"
    system "sh", "-c", "'#{rpm2cpio}' '#{staged_path}/opencode-desktop-linux-#{arch}.rpm' | '#{cpio}' -idm --quiet",
           chdir: staged_path

    desktop_file = "#{staged_path}/usr/share/applications/OpenCode.desktop"
    content = File.read(desktop_file)
    content.gsub!(/^Exec=.*/, "Exec=#{HOMEBREW_PREFIX}/bin/opencode-desktop %U")
    File.write(desktop_file, content)
  end

  zap trash: [
    "~/.cache/ai.opencode.desktop",
    "~/.config/ai.opencode.desktop",
    "~/.local/share/ai.opencode.desktop",
  ]
end

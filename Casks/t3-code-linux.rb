cask "t3-code-linux" do
  os linux: "linux"

  version "0.1.5"
  sha256 "933ff9dc4c650a75aa4087c98f2ae6c6540c233f0e2feb32ebff950b09be849d"

  url "https://github.com/pingdotgg/t3code/releases/download/v#{version}/T3-Code-#{version}-x86_64.AppImage"
  name "T3 Code"
  desc "Desktop GUI for coding agents"
  homepage "https://t3.codes/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :x86_64
  depends_on formula: "squashfs"
  depends_on :linux

  binary "squashfs-root/t3code"
  artifact "squashfs-root/usr/share/icons/hicolor/512x512/apps/t3code.png",
           target: "#{Dir.home}/.local/share/icons/t3code.png"
  artifact "squashfs-root/t3code.desktop",
           target: "#{Dir.home}/.local/share/applications/t3code.desktop"

  preflight_steps do
    set_permissions "T3-Code-{{version}}-x86_64.AppImage", "a+x", recursive: false
    run "{{staged_path}}/T3-Code-{{version}}-x86_64.AppImage",
        args: ["--appimage-extract"], chdir: "{{staged_path}}"
    remove "T3-Code-{{version}}-x86_64.AppImage"
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home
    inreplace "squashfs-root/t3code.desktop", /^Exec=.*/,
              "Exec={{HOMEBREW_PREFIX}}/bin/t3code %U"
  end

  zap trash: [
    "~/.cache/t3code-updater",
    "~/.config/t3code-v2",
    "~/.t3",
  ]
end

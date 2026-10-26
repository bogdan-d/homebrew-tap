cask "paseo-linux" do
  os linux: "linux"

  version "0.13.1"
  sha256 "8b8abe4d4e33538ea45a4e6ca254b66eb1836613da2e7918dc928e44849a851b"

  url "https://github.com/getpaseo/paseo/releases/download/v#{version}/Paseo-#{version}-x64.tar.gz"
  name "Paseo"
  desc "Desktop app for orchestrating coding agents"
  homepage "https://paseo.sh/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :x86_64
  depends_on :linux

  binary "Paseo-#{version}-x64/Paseo", target: "paseo-desktop"
  binary "Paseo-#{version}-x64/resources/bin/paseo"
  artifact "paseo.desktop",
           target: "#{Dir.home}/.local/share/applications/paseo.desktop"
  artifact "Paseo-#{version}-x64/resources/app-dist/pwa-icon-512.png",
           target: "#{Dir.home}/.local/share/icons/paseo.png"

  preflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home

    write_file("paseo.desktop", <<~EOS)
      [Desktop Entry]
      Name=Paseo
      Comment=Desktop app for orchestrating coding agents
      Exec={{HOMEBREW_PREFIX}}/bin/paseo-desktop %U
      Icon=paseo
      Terminal=false
      Type=Application
      StartupWMClass=Paseo
      Categories=Development;
      MimeType=x-scheme-handler/paseo;
    EOS
  end

  zap trash: [
    "~/.cache/@getpaseodesktop-updater",
    "~/.config/Paseo",
    "~/.paseo",
  ]
end

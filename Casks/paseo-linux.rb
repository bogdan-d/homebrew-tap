cask "paseo-linux" do
  os linux: "linux"

  version "0.15.0"
  sha256 "65a206038396e792ef605039a602e90a6ffb45a59493d661f9bf6c7ec7589ff3"

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

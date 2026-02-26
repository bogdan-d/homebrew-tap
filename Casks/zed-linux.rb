cask "zed-linux" do
  arch arm: "aarch64", intel: "x86_64"
  os linux: "linux"

  version :latest
  sha256 :no_check

  url "https://zed.dev/api/releases/stable/latest/zed-linux-#{arch}.tar.gz"
  name "Zed"
  name "Zed Editor"
  desc "High-performance, multiplayer code editor"
  homepage "https://zed.dev/"

  livecheck do
    skip "Uses version :latest"
  end

  # Zed publishes .desktop inside the tarball, but we generate one to match our bin path
  binary "zed.app/bin/zed"
  artifact "zed.app/share/icons/hicolor/512x512/apps/zed.png",
           target: "#{Dir.home}/.local/share/icons/zed.png"
  artifact "zed.desktop",
           target: "#{Dir.home}/.local/share/applications/dev.zed.Zed.desktop"

  preflight do
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    File.write("#{staged_path}/zed.desktop", <<~EOS)
      [Desktop Entry]
      Name=Zed
      Comment=High-performance, multiplayer code editor
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/zed %F
      Icon=#{Dir.home}/.local/share/icons/zed.png
      Type=Application
      StartupNotify=true
      StartupWMClass=dev.zed.Zed
      Categories=TextEditor;Development;IDE;
      MimeType=inode/directory;application/octet-stream;text/plain;text/x-python;text/x-shellscript;text/x-c++;text/x-java;text/x-ruby;text/x-php;text/x-perl;text/x-go;text/x-javascript;application/x-sh;application/json;application/xml;
      Keywords=zed;editor;code;ide;
      Terminal=false
    EOS
  end

  zap trash: [
    "~/.cache/zed",
    "~/.config/zed",
    "~/.local/share/zed",
  ]
end

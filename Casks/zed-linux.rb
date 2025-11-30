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

  # Zed publishes .desktop inside the tarball, but we generate one to match our bin path
  binary "zed.app/bin/zed"

  # NOTE: Using preflight to install desktop/icon files instead of `artifact` stanza
  # to work around Homebrew bug with OS::Linux::Pathname type signature.
  # See: https://github.com/Homebrew/brew/issues (Sorbet type mismatch in add_altname_metadata)

  preflight do
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons"

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

    # Copy desktop file and icon (workaround for Homebrew artifact bug)
    FileUtils.cp("#{staged_path}/zed.desktop",
                 "#{Dir.home}/.local/share/applications/dev.zed.Zed.desktop")
    FileUtils.cp("#{staged_path}/zed.app/share/icons/hicolor/512x512/apps/zed.png",
                 "#{Dir.home}/.local/share/icons/zed.png")
  end

  postflight do
    # Create symlinks back to staged path for uninstall tracking
    # (mimics what artifact stanza would do)
    source_desktop = "#{staged_path}/zed.desktop"
    source_icon = "#{staged_path}/zed.app/share/icons/hicolor/512x512/apps/zed.png"
    target_desktop = "#{Dir.home}/.local/share/applications/dev.zed.Zed.desktop"
    target_icon = "#{Dir.home}/.local/share/icons/zed.png"

    FileUtils.ln_sf(target_desktop, source_desktop) if File.exist?(source_desktop)
    FileUtils.ln_sf(target_icon, source_icon) if File.exist?(source_icon)
  end

  uninstall_preflight do
    # Remove the installed files that we copied in preflight
    FileUtils.rm("#{Dir.home}/.local/share/applications/dev.zed.Zed.desktop", force: true)
    FileUtils.rm("#{Dir.home}/.local/share/icons/zed.png", force: true)
  end

  # ! NO zapping !
  # zap trash: [
  #   "~/.config/zed",
  #   "~/.local/share/zed",
  #   "~/.cache/zed",
  # ]
end

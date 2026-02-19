cask "antigravity-linux" do
  arch arm: "arm", intel: "x64"
  os linux: "linux"

  version "1.18.3-4739469533380608"
  sha256 arm64_linux:  "258778041c502e7ce74b39959e9b93d28f5c1d8154e553863f58a365e5a9fca5",
         x86_64_linux: "4c7fe48c954e4d255c5d3ea4c74f168a4a7187fd2beedb223423cb57481c9638"

  url "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/#{version}/#{os}-#{arch}/Antigravity.tar.gz",
      verified: "edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/"
  name "Google Antigravity"
  desc "Google Antigravity - Experience liftoff"
  homepage "https://antigravity.google/"

  livecheck do
    url "https://antigravity-auto-updater-974169037036.us-central1.run.app/api/update/linux-x64/stable/latest"
    regex(%r{/stable/([^/]+)/}i)
    strategy :json do |json, regex|
      match = json["url"]&.match(regex)
      next if match.blank?

      match[1]
    end
  end

  binary "#{staged_path}/Antigravity/bin/antigravity"
  bash_completion "#{staged_path}/Antigravity/resources/completions/bash/antigravity"
  zsh_completion  "#{staged_path}/Antigravity/resources/completions/zsh/_antigravity"
  artifact "Antigravity/antigravity.desktop",
           target: "#{Dir.home}/.local/share/applications/antigravity.desktop"
  artifact "Antigravity/antigravity-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/antigravity-url-handler.desktop"
  artifact "antigravity.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/512x512/apps/antigravity.png"

  preflight do
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons/hicolor/512x512/apps"

    # Copy icon from extracted archive
    icon_path = "Antigravity/resources/app/out/vs/workbench/contrib/antigravityCustomAppIcon"
    icon_source = "#{staged_path}/#{icon_path}/browser/media/antigravity/antigravity.png"
    FileUtils.cp icon_source, "#{staged_path}/antigravity.png" if File.exist?(icon_source)

    File.write("#{staged_path}/Antigravity/antigravity.desktop", <<~EOS)
      [Desktop Entry]
      Name=Antigravity
      Comment=Experience liftoff
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/antigravity %F
      Icon=#{Dir.home}/.local/share/icons/hicolor/512x512/apps/antigravity.png
      Type=Application
      StartupNotify=false
      StartupWMClass=Antigravity
      Categories=TextEditor;Development;IDE;
      MimeType=inode/directory;application/octet-stream;text/plain;text/x-python;text/x-shellscript;text/x-c++;text/x-java;text/x-ruby;text/x-php;text/x-perl;text/x-go;text/x-javascript;application/x-sh;application/json;application/xml;application/x-antigravity-workspace;
      Actions=new-empty-window;
      Keywords=vscode;antigravity;code;editor;ai;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Exec=#{HOMEBREW_PREFIX}/bin/antigravity --new-window %F
      Icon=#{Dir.home}/.local/share/icons/hicolor/512x512/apps/antigravity.png
    EOS
    File.write("#{staged_path}/Antigravity/antigravity-url-handler.desktop", <<~EOS)
      [Desktop Entry]
      Name=Antigravity - URL Handler
      Comment=Experience liftoff
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/antigravity --open-url %U
      Icon=#{Dir.home}/.local/share/icons/antigravity.png
      Type=Application
      NoDisplay=true
      StartupNotify=true
      Categories=Utility;TextEditor;Development;IDE;
      MimeType=x-scheme-handler/antigravity;
      Keywords=vscode;antigravity;
    EOS

    # Create a placeholder icon if extraction fails
    FileUtils.touch "#{staged_path}/antigravity.png" unless File.exist?("#{staged_path}/antigravity.png")
  end

  zap trash: [
    "~/.antigravity",
    "~/.config/Antigravity",
    "~/.gemini",
  ]
end

cask "antigravity-linux" do
  arch arm: "arm", intel: "x64"
  os linux: "linux"

  version "1.11.5-5234145629700096"
  sha256 arm64_linux:  "e154dc745c51c7aadc33becee985188c92246a36a16ee0ba545c422172f8d0c2",
         x86_64_linux: "4e03151a55743cf30fac595abb343c9eb5a3b6a80d2540136d75b4ead8072112"

  url "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/#{version}/linux-#{arch}/Antigravity.tar.gz",
      verified: "edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/"
  name "Google Antigravity"
  desc "Google Antigravity - Experience liftoff"
  homepage "https://antigravity.google/"

  livecheck do
    arch_for_livecheck = on_arch_conditional arm: "arm64", intel: "x64"
    url "https://antigravity-auto-updater-974169037036.us-central1.run.app/api/update/#{os}-#{arch_for_livecheck}/stable/latest"
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
  artifact "Antigravity/resources/app/resources/linux/code.png",
           target: "#{Dir.home}/.local/share/icons/antigravity.png"

  preflight do
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"

    File.write("#{staged_path}/Antigravity/antigravity.desktop", <<~EOS)
      [Desktop Entry]
      Name=Antigravity
      Comment=Experience liftoff
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/antigravity %F
      Icon=#{Dir.home}/.local/share/icons/antigravity.png
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
      Icon=#{Dir.home}/.local/share/icons/antigravity.png
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
  end

  # ! NO zapping !
  # zap trash: [
  #   "~/.antigravity",
  #   "~/.config/Antigravity",
  #   "~/.gemini",
  # ]
end

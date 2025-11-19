cask "antigravity-linux" do
  version "1.11.3"
  sha256 "025da512f9799a7154e2cc75bc0908201382c1acf2e8378f9da235cb84a5615b"

  url "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/1.11.3-6583016683339776/linux-x64/Antigravity.tar.gz"
  name "Google Antigravity"
  desc "Agentic Development Platform"
  homepage "https://antigravity.google/"

  livecheck do
    url "https://antigravity.google/download/linux"
    regex(%r{antigravity/stable/([\d.]+-\d+)/linux[._-]x64}i)
  end

  binary "Antigravity/bin/antigravity"
  bash_completion "Antigravity/resources/completions/bash/antigravity"
  zsh_completion "Antigravity/resources/completions/zsh/_antigravity"
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
      Name=Google Antigravity
      Comment=Agentic Development Platform
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/antigravity %F
      Icon=#{Dir.home}/.local/share/icons/antigravity.png
      Type=Application
      StartupNotify=false
      StartupWMClass=Antigravity
      Categories=TextEditor;Development;IDE;
      MimeType=inode/directory;application/octet-stream;text/plain;text/x-python;text/x-shellscript;text/x-c++;text/x-java;text/x-ruby;text/x-php;text/x-perl;text/x-go;text/x-javascript;application/x-sh;application/json;application/xml;application/x-code-workspace;
      Actions=open-antigravity;
      Keywords=antigravity;

      [Desktop Action open-antigravity]
      Name=Open Antigravity
      Exec=#{HOMEBREW_PREFIX}/bin/antigravity %F
      Icon=#{Dir.home}/.local/share/icons/antigravity.png
    EOS
    File.write("#{staged_path}/Antigravity/antigravity-url-handler.desktop", <<~EOS)
      [Desktop Entry]
      Name=Google Antigravity - URL Handler
      Comment=Agentic Development Platform
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/antigravity --open-url %U
      Icon=#{Dir.home}/.local/share/icons/antigravity.png
      Type=Application
      NoDisplay=true
      StartupNotify=true
      Categories=Utility;TextEditor;Development;IDE;
      MimeType=x-scheme-handler/antigravity;
      Keywords=antigravity;
    EOS
  end

  # ! NO zapping !
  # zap trash: [
  #   "~/.config/Antigravity",
  #   "~/.antigravity",
  # ]
end

cask "visual-studio-code-insiders-linux" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version :latest
  sha256 :no_check

  url "https://update.code.visualstudio.com/latest/#{os}-#{arch}/insider"
  name "Microsoft Visual Studio Code - Insiders"
  name "VS Code Insiders"
  desc "Insiders build of the VS Code editor"
  homepage "https://code.visualstudio.com/insiders/"

  # livecheck do
  #   url "https://update.code.visualstudio.com/api/update/#{os}-#{arch}/insider/latest"
  #   strategy :json do |json|
  #     json["productVersion"]
  #   end
  # end

  binary "VSCode-linux-#{arch}/bin/code-insiders"
  binary "VSCode-linux-#{arch}/bin/code-tunnel-insiders"
  bash_completion "#{staged_path}/VSCode-linux-#{arch}/resources/completions/bash/code-insiders"
  zsh_completion  "#{staged_path}/VSCode-linux-#{arch}/resources/completions/zsh/_code-insiders"

  # NOTE: Using preflight to install desktop/icon files instead of `artifact` stanza
  # to work around Homebrew bug with OS::Linux::Pathname type signature.
  # See: https://github.com/Homebrew/brew/issues (Sorbet type mismatch in add_altname_metadata)

  preflight do
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons"

    File.write("#{staged_path}/VSCode-linux-#{arch}/code-insiders.desktop", <<~EOS)
      [Desktop Entry]
      Name=Visual Studio Code - Insiders
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/code-insiders %F
      Icon=#{Dir.home}/.local/share/icons/vscode-insiders.png
      Type=Application
      StartupNotify=false
      StartupWMClass=code-insiders
      Categories=TextEditor;Development;IDE;
      MimeType=inode/directory;application/octet-stream;text/plain;text/x-python;text/x-shellscript;text/x-c++;text/x-java;text/x-ruby;text/x-php;text/x-perl;text/x-go;text/x-javascript;application/x-sh;application/json;application/xml;application/x-code-workspace;
      Actions=new-empty-window;
      Keywords=vscode;insiders;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Exec=#{HOMEBREW_PREFIX}/bin/code-insiders --new-window %F
      Icon=#{Dir.home}/.local/share/icons/vscode-insiders.png
    EOS
    File.write("#{staged_path}/VSCode-linux-#{arch}/code-insiders-url-handler.desktop", <<~EOS)
      [Desktop Entry]
      Name=Visual Studio Code Insiders - URL Handler
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/code-insiders --open-url %U
      Icon=#{Dir.home}/.local/share/icons/vscode-insiders.png
      Type=Application
      NoDisplay=true
      StartupNotify=true
      Categories=Utility;TextEditor;Development;IDE;
      MimeType=x-scheme-handler/vscode;
      Keywords=vscode;insiders;
    EOS

    # Copy desktop files and icon (workaround for Homebrew artifact bug)
    FileUtils.cp("#{staged_path}/VSCode-linux-#{arch}/code-insiders.desktop",
                 "#{Dir.home}/.local/share/applications/code-insiders.desktop")
    FileUtils.cp("#{staged_path}/VSCode-linux-#{arch}/code-insiders-url-handler.desktop",
                 "#{Dir.home}/.local/share/applications/code-insiders-url-handler.desktop")
    FileUtils.cp("#{staged_path}/VSCode-linux-#{arch}/resources/app/resources/linux/code.png",
                 "#{Dir.home}/.local/share/icons/vscode-insiders.png")
  end

  postflight do
    # Create symlinks back to staged path for uninstall tracking
    # (mimics what artifact stanza would do)
    source_desktop = "#{staged_path}/VSCode-linux-#{arch}/code-insiders.desktop"
    source_url_handler = "#{staged_path}/VSCode-linux-#{arch}/code-insiders-url-handler.desktop"
    source_icon = "#{staged_path}/VSCode-linux-#{arch}/resources/app/resources/linux/code.png"

    FileUtils.ln_sf("#{Dir.home}/.local/share/applications/code-insiders.desktop", source_desktop) if File.exist?(source_desktop)
    FileUtils.ln_sf("#{Dir.home}/.local/share/applications/code-insiders-url-handler.desktop", source_url_handler) if File.exist?(source_url_handler)
    FileUtils.ln_sf("#{Dir.home}/.local/share/icons/vscode-insiders.png", source_icon) if File.exist?(source_icon)
  end

  uninstall_preflight do
    # Remove the installed files that we copied in preflight
    desktop = "#{Dir.home}/.local/share/applications/code-insiders.desktop"
    url_handler = "#{Dir.home}/.local/share/applications/code-insiders-url-handler.desktop"
    icon = "#{Dir.home}/.local/share/icons/vscode-insiders.png"

    FileUtils.rm_f(desktop) if File.exist?(desktop)
    FileUtils.rm_f(url_handler) if File.exist?(url_handler)
    FileUtils.rm_f(icon) if File.exist?(icon)
  end

  # ! NO zapping !
  # zap trash: [
  #   "~/.config/Code - Insiders",
  #   "~/.vscode-insiders",
  # ]
end

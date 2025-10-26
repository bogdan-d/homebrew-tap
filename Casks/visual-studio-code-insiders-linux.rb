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

  livecheck do
    url "https://update.code.visualstudio.com/api/update/#{os}-#{arch}/insider/latest"
    strategy :json do |json|
      json["productVersion"]
    end
  end

  binary "VSCode-linux-#{arch}/bin/code-insiders"

  artifact "VSCode-linux-#{arch}/code-insiders.desktop",
           target: "#{Dir.home}/.local/share/applications/code-insiders.desktop"
  artifact "VSCode-linux-#{arch}/code-insiders-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/code-insiders-url-handler.desktop"
  artifact "VSCode-linux-#{arch}/resources/app/resources/linux/code.png",
           target: "#{Dir.home}/.local/share/icons/vscode-insiders.png"

  preflight do
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    # Capture the user's login/interactive shell PATH so desktop-launched apps
    # (launched by the DE) inherit the same PATH the user has in their shell.
    # Fall back to the current process PATH if capturing fails.
    shell = ENV['SHELL'] || '/bin/bash'
    user_path = `#{shell} -lc 'printf "%s" "$PATH"'`.to_s.strip
    user_path = ENV['PATH'] if user_path.empty?
    # Escape double quotes so the PATH can be embedded safely in the .desktop Exec
    user_path_escaped = user_path.gsub('"', '\\"')

    File.write("#{staged_path}/VSCode-linux-#{arch}/code-insiders.desktop", <<~EOS)
      [Desktop Entry]
      Name=Visual Studio Code - Insiders
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec=env PATH="#{user_path_escaped}:$PATH" #{HOMEBREW_PREFIX}/bin/code-insiders %F
      Icon=#{Dir.home}/.local/share/icons/vscode-insiders.png
      Type=Application
      StartupNotify=false
      StartupWMClass=code-insiders
      Categories=TextEditor;Development;IDE;
      MimeType=inode/directory;application/octet-stream;text/plain;text/x-python;text/x-shellscript;text/x-c++;text/x-java;text/x-ruby;text/x-php;text/x-perl;text/x-go;text/x-javascript;application/x-sh;application/json;application/xml;application/x-code-workspace;
      Actions=open-code-insiders;
      Keywords=vscode;insiders;

      [Desktop Action open-code-insiders]
      Name=Open Code Insiders
      Exec=env PATH="#{user_path_escaped}:$PATH" #{HOMEBREW_PREFIX}/bin/code-insiders %F
      Icon=#{Dir.home}/.local/share/icons/vscode-insiders.png
    EOS
    File.write("#{staged_path}/VSCode-linux-#{arch}/code-insiders-url-handler.desktop", <<~EOS)
      [Desktop Entry]
      Name=Visual Studio Code Insiders - URL Handler
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec=env PATH="#{user_path_escaped}:$PATH" #{HOMEBREW_PREFIX}/bin/code-insiders --open-url %U
      Icon=#{Dir.home}/.local/share/icons/vscode-insiders.png
      Type=Application
      NoDisplay=true
      StartupNotify=true
      Categories=Utility;TextEditor;Development;IDE;
      MimeType=x-scheme-handler/vscode;
      Keywords=vscode;insiders;
    EOS
  end

	# ! NO zapping !
  # zap trash: [
  #   "~/.config/Code - Insiders",
  #   "~/.vscode-insiders",
  # ]
end

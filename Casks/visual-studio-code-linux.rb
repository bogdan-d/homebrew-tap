cask "visual-studio-code-linux" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version "1.124.2"
  sha256 arm:          "dc206b7a7a99b37e60316995b48fffe30d0919228ff1c6eeddc247d783f86845",
         intel:        "2f4a3dfafc5f0249ad38726f99fd06f1621ba776d78c0bae200b53b45bdbc234",
         arm64_linux:  "dc206b7a7a99b37e60316995b48fffe30d0919228ff1c6eeddc247d783f86845",
         x86_64_linux: "2f4a3dfafc5f0249ad38726f99fd06f1621ba776d78c0bae200b53b45bdbc234"

  url "https://update.code.visualstudio.com/#{version}/linux-#{arch}/stable"
  name "Microsoft Visual Studio Code"
  name "VS Code"
  desc "Open-source code editor"
  homepage "https://code.visualstudio.com/"

  livecheck do
    url "https://update.code.visualstudio.com/api/update/linux-#{arch}/stable/latest"
    strategy :json do |json|
      json["productVersion"]
    end
  end

  depends_on :linux

  binary "VSCode-linux-#{arch}/bin/code"
  binary "VSCode-linux-#{arch}/bin/code-tunnel"
  bash_completion "#{staged_path}/VSCode-linux-#{arch}/resources/completions/bash/code"
  zsh_completion  "#{staged_path}/VSCode-linux-#{arch}/resources/completions/zsh/_code"
  artifact "VSCode-linux-#{arch}/code.desktop",
           target: "#{Dir.home}/.local/share/applications/code.desktop"
  artifact "VSCode-linux-#{arch}/code-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/code-url-handler.desktop"
  artifact "VSCode-linux-#{arch}/resources/app/resources/linux/code.png",
           target: "#{Dir.home}/.local/share/icons/vscode.png"

  preflight do
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    File.write("#{staged_path}/VSCode-linux-#{arch}/code.desktop", <<~EOS)
      [Desktop Entry]
      Name=Visual Studio Code
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/code %F
      Icon=#{Dir.home}/.local/share/icons/vscode.png
      Type=Application
      StartupNotify=false
      StartupWMClass=Code
      Categories=TextEditor;Development;IDE;
      MimeType=inode/directory;application/octet-stream;text/plain;text/x-python;text/x-shellscript;text/x-c++;text/x-java;text/x-ruby;text/x-php;text/x-perl;text/x-go;text/x-javascript;application/x-sh;application/json;application/xml;application/x-code-workspace;
      Actions=new-empty-window;
      Keywords=vscode;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Exec=#{HOMEBREW_PREFIX}/bin/code --new-window %F
      Icon=#{Dir.home}/.local/share/icons/vscode.png
    EOS
    File.write("#{staged_path}/VSCode-linux-#{arch}/code-url-handler.desktop", <<~EOS)
      [Desktop Entry]
      Name=Visual Studio Code - URL Handler
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/code --open-url %U
      Icon=#{Dir.home}/.local/share/icons/vscode.png
      Type=Application
      NoDisplay=true
      StartupNotify=true
      Categories=Utility;TextEditor;Development;IDE;
      MimeType=x-scheme-handler/vscode;
      Keywords=vscode;
    EOS
  end

  zap trash: [
    "~/.config/Code",
    "~/.vscode",
  ]
end

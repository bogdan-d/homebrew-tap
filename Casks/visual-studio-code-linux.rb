cask "visual-studio-code-linux" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version "1.141.0"
  sha256 arm:          "3b6ea238a2aa9000bab0137c19f06d4e8edcb5587438a3afc9dc9739e793e934",
         intel:        "d77d588f0454cbaaa71e723497de4160d15b95fba4988abe177b1432e6bd570a",
         arm64_linux:  "3b6ea238a2aa9000bab0137c19f06d4e8edcb5587438a3afc9dc9739e793e934",
         x86_64_linux: "d77d588f0454cbaaa71e723497de4160d15b95fba4988abe177b1432e6bd570a"

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
  artifact "code.desktop",
           target: "#{Dir.home}/.local/share/applications/code.desktop"
  artifact "code-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/code-url-handler.desktop"
  artifact "VSCode-linux-#{arch}/resources/app/resources/linux/code.png",
           target: "#{Dir.home}/.local/share/icons/vscode.png"

  preflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home

    write_file("code.desktop", <<~EOS)
      [Desktop Entry]
      Name=Visual Studio Code
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec={{HOMEBREW_PREFIX}}/bin/code %F
      Icon=vscode
      Type=Application
      StartupNotify=false
      StartupWMClass=Code
      Categories=TextEditor;Development;IDE;
      MimeType=inode/directory;application/octet-stream;text/plain;text/x-python;text/x-shellscript;text/x-c++;text/x-java;text/x-ruby;text/x-php;text/x-perl;text/x-go;text/x-javascript;application/x-sh;application/json;application/xml;application/x-code-workspace;
      Actions=new-empty-window;
      Keywords=vscode;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Exec={{HOMEBREW_PREFIX}}/bin/code --new-window %F
      Icon=vscode
    EOS
    write_file("code-url-handler.desktop", <<~EOS)
      [Desktop Entry]
      Name=Visual Studio Code - URL Handler
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec={{HOMEBREW_PREFIX}}/bin/code --open-url %U
      Icon=vscode
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

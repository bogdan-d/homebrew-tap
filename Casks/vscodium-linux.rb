cask "vscodium-linux" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version "1.143.17183"
  sha256 arm:          "570fd1947f957bbdc11b164b69a0a6d8bb1173e447faeac0dba5d01cc9bfea06",
         intel:        "b113c7cc55624f0779fe194169bb6c049785bfaac2033c84b8a4da68445d72af",
         arm64_linux:  "570fd1947f957bbdc11b164b69a0a6d8bb1173e447faeac0dba5d01cc9bfea06",
         x86_64_linux: "b113c7cc55624f0779fe194169bb6c049785bfaac2033c84b8a4da68445d72af"

  url "https://github.com/VSCodium/vscodium/releases/download/#{version}/VSCodium-linux-#{arch}-#{version}.tar.gz"
  name "VSCodium"
  desc "Open-source code editor"
  homepage "https://vscodium.com/"

  livecheck do
    url :url
    regex(/^VSCodium-linux-#{arch}-v?(\d+(?:\.\d+)+)\.tar\.gz$/i)
    # Releases are published before their Linux assets are uploaded.
    strategy :github_releases do |json, regex|
      json.map do |release|
        next if release["draft"] || release["prerelease"]

        release["assets"]&.map do |asset|
          asset["name"]&.[](regex, 1)
        end
      end.flatten
    end
  end

  depends_on :linux

  binary "bin/codium"
  binary "bin/codium-tunnel"
  bash_completion "resources/completions/bash/codium"
  zsh_completion  "resources/completions/zsh/_codium"
  artifact "codium.desktop",
           target: "#{Dir.home}/.local/share/applications/codium.desktop"
  artifact "codium-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/codium-url-handler.desktop"
  artifact "resources/app/resources/linux/code.png",
           target: "#{Dir.home}/.local/share/icons/vscodium.png"

  preflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home

    write_file("codium.desktop", <<~EOS)
      [Desktop Entry]
      Name=VSCodium
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec={{HOMEBREW_PREFIX}}/bin/codium %F
      Icon=vscodium
      Type=Application
      StartupNotify=false
      StartupWMClass=VSCodium
      Categories=TextEditor;Development;IDE;
      MimeType=inode/directory;application/octet-stream;text/plain;text/x-python;text/x-shellscript;text/x-c++;text/x-java;text/x-ruby;text/x-php;text/x-perl;text/x-go;text/x-javascript;application/x-sh;application/json;application/xml;application/x-codium-workspace;
      Actions=new-empty-window;
      Keywords=vscodium;codium;vscode;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Exec={{HOMEBREW_PREFIX}}/bin/codium --new-window %F
      Icon=vscodium
    EOS
    write_file("codium-url-handler.desktop", <<~EOS)
      [Desktop Entry]
      Name=VSCodium - URL Handler
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec={{HOMEBREW_PREFIX}}/bin/codium --open-url %U
      Icon=vscodium
      Type=Application
      NoDisplay=true
      StartupNotify=true
      Categories=Utility;TextEditor;Development;IDE;
      MimeType=x-scheme-handler/vscodium;
      Keywords=vscodium;codium;vscode;
    EOS
  end

  zap trash: [
    "#{Dir.home}/.config/Codium",
    "#{Dir.home}/.vscodium",
  ]
end

cask "antigravity-linux" do
  version "1.11.3,6583016683339776"
  sha256 "025da512f9799a7154e2cc75bc0908201382c1acf2e8378f9da235cb84a5615b"

  url "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/#{version.csv.first}-#{version.csv.second}/linux-x64/Antigravity.tar.gz"
  name "Google Antigravity"
  desc "Google Antigravity - Experience liftoff"
  homepage "https://antigravity.google/"

  livecheck do
    url "https://antigravity.google/"
    regex(/pkgver=(\d+(?:\.\d+)+).*?_buildid=(\d+)/m)
    strategy :page_match do |_page, regex|
      # The AUR repository is sometimes unreliable, so we use curl with retries
      aur_url = "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=google-antigravity-bin"
      headers = [
        "-H", "User-Agent: Homebrew/4.4.5 (Linux; x64; Ubuntu 22.04.4 LTS) curl/7.81.0",
        "-H", "Accept: text/plain"
      ]

      # Retry 4 times with a 2 second delay
      cmd = [
        "curl", "--fail", "--silent", "--show-error", "--location",
        "--retry", "4", "--retry-delay", "2", *headers, aur_url
      ]

      stdout, _, status = Open3.capture3(*cmd)
      next if !status.success? || stdout.blank?

      match = stdout.match(regex)
      next if match.blank?

      "#{match[1]},#{match[2]}"
    end
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
      Keywords=vscode;antigravity;

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
      Keywords=antigravity;
    EOS
  end

  # ! NO zapping !
  # zap trash: [
  #   "~/.config/Antigravity",
  #   "~/.antigravity",
  # ]
end

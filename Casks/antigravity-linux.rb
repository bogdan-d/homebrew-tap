cask "antigravity-linux" do
  # version format is "<pkgver>,<buildid>" - AUR PKGBUILD provides both
  version "1.11.5,5234145629700096"
  sha256 "4e03151a55743cf30fac595abb343c9eb5a3b6a80d2540136d75b4ead8072112"

  url "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/#{version.csv.first}-#{version.csv.second}/linux-x64/Antigravity.tar.gz"
  name "Google Antigravity"
  desc "Google Antigravity - Experience liftoff"
  homepage "https://antigravity.google/"

  livecheck do
    # Use the AUR PKGBUILD for version and buildid detection. AUR can be
    # flaky with 502s/503s, so fetch it with curl and retries and fall back
    # gracefully when the upstream is unavailable.
    url "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=antigravity-bin"
    regex(/pkgver=(\d+(?:\.\d+)+).*?_buildid=(\d+)/m)
    strategy :page_match do |_page, regex|
      aur_url = "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=antigravity-bin"
      headers = [
        "-H", "User-Agent: Homebrew/4.4.5 (Linux; x64; Ubuntu 22.04.4 LTS) curl/7.81.0",
        "-H", "Accept: text/plain"
      ]

      # Retry 4 times with a 2 second delay to handle transient AUR failures
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

  # The upstream tarball sometimes contains the binary as: "Antigravity",
  # "antigravity", or under "Antigravity/bin/antigravity". We normalize
  # the install by creating a consistent "Antigravity/bin/antigravity" symlink
  # during the preflight stage and then using the binary stanza below.
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
    # Ensure there is a stable path for the binary regardless of actual file name
    begin
      bin_dir = "#{staged_path}/Antigravity/bin"
      FileUtils.mkdir_p bin_dir

      candidates = [
        "#{staged_path}/Antigravity/Antigravity",
        "#{staged_path}/Antigravity/antigravity",
        "#{staged_path}/Antigravity/bin/antigravity",
      ]

      candidate = candidates.find { |f| File.exist?(f) }
      FileUtils.ln_s(candidate, "#{bin_dir}/antigravity") if candidate && !File.exist?("#{bin_dir}/antigravity")
    rescue => e
      # Don't abort install if something goes wrong here; fall back to default behavior.
      odie "Failed to create Antigravity binary symlink: #{e}" if defined?(odie)
    end

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

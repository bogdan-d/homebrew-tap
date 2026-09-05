cask "goose-linux" do
  os linux: "linux"

  version "1.49.0"
  sha256 "ea6bd89fa552529b1dda18ecc9a278dc2f2a0ca40b9deddce96c9d4252f77e5f"

  url "https://github.com/block/goose/releases/download/v#{version}/Goose-#{version}-1.x86_64.rpm"
  name "Goose"
  desc "Open source, extensible AI agent that goes beyond code suggestions"
  homepage "https://block.github.io/goose/"

  livecheck do
    url "https://github.com/block/goose/releases"
    regex(%r{/v?(\d+(?:\.\d+)+)/Goose[._-]v?\d+(?:\.\d+)+-\d+\.x86_64\.rpm}i)
    strategy :github_releases do |json, regex|
      json.map do |release|
        next if release["draft"] || release["prerelease"]

        release["assets"]&.map do |asset|
          match = asset["browser_download_url"]&.match(regex)
          next if match.blank?

          match[1]
        end
      end.flatten
    end
  end

  depends_on :linux
  depends_on arch: :x86_64
  depends_on formula: "libarchive"

  binary "Goose/Goose", target: "goose-desktop"
  artifact "Goose.desktop",
           target: "#{Dir.home}/.local/share/applications/Goose.desktop"
  artifact "Goose/resources/images/icon.png",
           target: "#{Dir.home}/.local/share/icons/Goose.png"

  preflight_steps do
    # Extract usr/lib/* directly to staged_path (stripping the usr/lib prefix)
    run "{{HOMEBREW_PREFIX}}/opt/libarchive/bin/bsdtar",
        args: ["-xvf", "{{staged_path}}/Goose-{{version}}-1.x86_64.rpm", "-C", "{{staged_path}}",
               "--strip-components=3", "usr/lib/Goose"], print_stdout: true

    # Remove the RPM artifact after extraction
    remove "Goose-{{version}}-1.x86_64.rpm"

    run "/usr/bin/test", args: ["-f", "{{staged_path}}/Goose/Goose"]
    run "/usr/bin/test", args: ["-f", "{{staged_path}}/Goose/resources/images/icon.png"]

    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home

    write_file("Goose.desktop", <<~EOS)
      [Desktop Entry]
      Name=Goose
      Comment=Open source, extensible AI agent that goes beyond code suggestions
      Exec={{HOMEBREW_PREFIX}}/bin/goose-desktop %U
      Icon=Goose
      Terminal=false
      Type=Application
      Categories=Development;
      MimeType=x-scheme-handler/goose;
      StartupWMClass=Goose
      Keywords=goose;
    EOS
  end

  zap trash: [
    "~/.config/Goose",
    "~/.local/share/Goose",
  ]
end

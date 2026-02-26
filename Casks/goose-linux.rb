cask "goose-linux" do
  version "1.25.1"
  sha256 "3e020fa2e650fe7e1df77d7908413ee83475514c4f9ad868a64d4f57bd1fdb5c"

  url "https://github.com/block/goose/releases/download/v#{version}/Goose-#{version}-1.x86_64.rpm",
      verified: "github.com/block/goose/"
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

  depends_on formula: "libarchive"

  binary "Goose/Goose", target: "goose-desktop"
  artifact "Goose.desktop",
           target: "#{Dir.home}/.local/share/applications/Goose.desktop"
  artifact "Goose/resources/images/icon.png",
           target: "#{Dir.home}/.local/share/icons/Goose.png"

  preflight do
    # Extract only usr/lib from the RPM to staged_path
    rpm_path = Dir["#{staged_path}/*.rpm"].first
    raise "RPM not found in staged_path" if rpm_path.blank?

    # Extract usr/lib/* directly to staged_path (stripping the usr/lib prefix)
    # Using -v for verbose output to debug extraction
    bsdtar = "#{HOMEBREW_PREFIX}/bin/bsdtar"
    system "sh", "-c", "#{bsdtar} -xvf '#{staged_path}/Goose-#{version}-1.x86_64.rpm' -C '#{staged_path}' --strip-components=3 usr/lib/Goose",
           chdir: staged_path

    # Remove the RPM artifact after extraction
    FileUtils.rm(rpm_path)
    puts "Removed RPM artifact: #{File.basename(rpm_path)}\n"

    raise "RPM extraction failed: missing Goose/Goose binary" unless File.exist?("#{staged_path}/Goose/Goose")
    unless File.exist?("#{staged_path}/Goose/resources/images/icon.png")
      raise "RPM extraction failed: missing app icon"
    end

    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons"

    File.write("#{staged_path}/Goose.desktop", <<~EOS)
      [Desktop Entry]
      Name=Goose
      Comment=Open source, extensible AI agent that goes beyond code suggestions
      Exec=#{HOMEBREW_PREFIX}/bin/goose-desktop %U
      Icon=#{Dir.home}/.local/share/icons/Goose.png
      Type=Application
      Categories=Development;Utility;
      MimeType=x-scheme-handler/goose;
      StartupWMClass=Goose
      Keywords=goose;
      Terminal=false
    EOS
  end

  zap trash: [
    "~/.config/Goose",
    "~/.local/share/Goose",
  ]
end

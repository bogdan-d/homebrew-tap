cask "block-goose-linux" do
  version "1.19.0-1"
  sha256 "6be2804758b28661bd66e757ca77c6de56828e45aa550b1ca01da63dba3d614b"

  url "https://github.com/block/goose/releases/download/v#{version.split("-").first}/Goose-#{version}.x86_64.rpm",
      verified: "github.com/block/goose/"
  name "Goose"
  desc "Open source, extensible AI agent that goes beyond code suggestions"
  homepage "https://block.github.io/goose/"

  # Some releases don't provide assets for Goose Desktop,
  # so we have to check multiple releases to identify the newest version.
  livecheck do
    url :url
    regex(%r{/v?(\d+(?:\.\d+)+)/Goose-(\d+(?:\.\d+)+-\d+)\.x86_64\.rpm}i)
    strategy :github_releases do |json, regex|
      json.map do |release|
        next if release["draft"] || release["prerelease"]

        release["assets"]&.map do |asset|
          match = asset["browser_download_url"]&.match(regex)
          next if match.blank?

          match[2]
        end
      end.flatten
    end
  end

  depends_on arch: :x86_64
  depends_on formula: "libarchive"

  binary "Goose/Goose", target: "Goose"
  artifact "block-goose.desktop",
           target: "#{Dir.home}/.local/share/applications/block-goose.desktop"
  artifact "Goose/resources/images/icon.png",
           target: "#{Dir.home}/.local/share/icons/block-goose.png"

  preflight do
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons"

    # Extract only usr/lib from the RPM to staged_path
    rpm_path = Dir["#{staged_path}/*.rpm"].first
    raise "RPM not found in staged_path" if rpm_path.blank?

    bsdtar = "#{HOMEBREW_PREFIX}/bin/bsdtar"
    # Extract usr/lib/* directly to staged_path (stripping the usr/lib prefix)
    # Using -v for verbose output to debug extraction
    system_command bsdtar,
                   args:         [
                     "-xvf",
                     rpm_path,
                     "-C",
                     staged_path,
                     "--strip-components=3",
                     "usr/lib/Goose",
                   ],
                   must_succeed: true

    # Remove the RPM artifact after extraction
    FileUtils.rm(rpm_path)
    puts "Removed RPM artifact: #{File.basename(rpm_path)}\n"

    raise "RPM extraction failed: missing Goose/Goose binary" unless File.exist?("#{staged_path}/Goose/Goose")
    unless File.exist?("#{staged_path}/Goose/resources/images/icon.png")
      raise "RPM extraction failed: missing app icon"
    end

    File.write("#{staged_path}/block-goose.desktop", <<~EOS)
      [Desktop Entry]
      Name=Goose
      Comment=Open source, extensible AI agent that goes beyond code suggestions
      Exec=#{HOMEBREW_PREFIX}/bin/Goose %U
      Icon=#{Dir.home}/.local/share/icons/block-goose.png
      Type=Application
      StartupNotify=false
      StartupWMClass=Goose
      Categories=Development;Utility;
      MimeType=x-scheme-handler/goose;
      Keywords=goose;
      Terminal=false
    EOS
  end

  zap trash: "~/.cache/goose"
  # zap trash: [
  #   "~/.cache/goose",
  #   "~/.config/goose",
  #   "~/.local/share/goose",
  # ]
end

cask "antigravity-cli-linux" do
  arch arm: "arm", intel: "x64"
  file_arch = on_arch_conditional arm: "arm64", intel: "x64"
  livecheck_arch = on_arch_conditional arm: "arm64", intel: "amd64"
  os linux: "linux"

  version "1.5.3,6604829099950080"
  sha256 arm:          "2d50060c7b1327995e5c81ec58829c91c2564ebb9fec165d3f9f1325ec188675",
         intel:        "1b4850599cce73a17f94ffb422df3bf9531531b77dbddc40c1a435e0c2c16807",
         arm64_linux:  "2d50060c7b1327995e5c81ec58829c91c2564ebb9fec165d3f9f1325ec188675",
         x86_64_linux: "1b4850599cce73a17f94ffb422df3bf9531531b77dbddc40c1a435e0c2c16807"

  url "https://storage.googleapis.com/antigravity-public/antigravity-cli/#{version.csv.first}-#{version.csv.second}/linux-#{arch}/cli_linux_#{file_arch}.tar.gz"
  name "Google Antigravity CLI"
  desc "Terminal interface for Antigravity agents"
  homepage "https://antigravity.google/product/antigravity-cli"

  livecheck do
    url "https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_#{livecheck_arch}.json"
    regex(%r{/antigravity-cli/([^/]+)/}i)
    strategy :json do |json, regex|
      match = json["url"]&.match(regex)
      next if match.blank?

      match[1]&.tr("-", ",").to_s
    end
  end

  depends_on :linux

  binary "agy.wrapper.sh", target: "agy"

  preflight_steps do
    write_file("agy.wrapper.sh", <<~EOS)
      #!/bin/sh
      if [ "$1" = "update" ]; then
        echo "Antigravity CLI is managed by Homebrew. Use 'brew upgrade --cask antigravity-cli-linux' instead." >&2
        exit 1
      fi

      exec "{{staged_path}}/antigravity" "$@"
    EOS
    set_permissions "agy.wrapper.sh", "0755", recursive: false
  end

  zap trash: "~/.gemini/antigravity-cli"
end

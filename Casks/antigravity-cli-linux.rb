cask "antigravity-cli-linux" do
  arch arm: "arm", intel: "x64"
  file_arch = on_arch_conditional arm: "arm64", intel: "x64"
  livecheck_arch = on_arch_conditional arm: "arm64", intel: "amd64"
  os linux: "linux"

  version "1.4.12,4768735748292608"
  sha256 arm:          "30dd61ebe1f0a8829057ea2de29dad08c710dd972ce4c02949f51e632135a86b",
         intel:        "3368d1923fc869f21ec8fce83252a8c96c89283aac9393958ac91fbf7a3949e4",
         arm64_linux:  "30dd61ebe1f0a8829057ea2de29dad08c710dd972ce4c02949f51e632135a86b",
         x86_64_linux: "3368d1923fc869f21ec8fce83252a8c96c89283aac9393958ac91fbf7a3949e4"

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

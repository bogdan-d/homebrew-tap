cask "antigravity-cli-linux" do
  arch arm: "arm", intel: "x64"
  file_arch = on_arch_conditional arm: "arm64", intel: "x64"
  livecheck_arch = on_arch_conditional arm: "arm64", intel: "amd64"
  os linux: "linux"

  version "1.2.9,5905287731871744"
  sha256 arm:          "8a63cf4c4f559e2ff91bd46fbdf015ca7937415805d0cff82015b9cb9dbbdfcd",
         intel:        "d9850373f3df866011024a961fa9740cc4adaac060eebe9c70fbf263ac6b2624",
         arm64_linux:  "8a63cf4c4f559e2ff91bd46fbdf015ca7937415805d0cff82015b9cb9dbbdfcd",
         x86_64_linux: "d9850373f3df866011024a961fa9740cc4adaac060eebe9c70fbf263ac6b2624"

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

cask "antigravity-cli-linux" do
  arch arm: "arm", intel: "x64"
  file_arch = on_arch_conditional arm: "arm64", intel: "x64"
  livecheck_arch = on_arch_conditional arm: "arm64", intel: "amd64"
  os linux: "linux"

  version "1.0.13,5758107482193920"
  sha256 arm:          "e2f062ff8a573d2da54c03c8f0b66e130a563a08c87b6db174953a9afdd21235",
         intel:        "6bf990458c114af3b3173dcbc1b0fb9ab93bea91c53b605fdd69aedd29a21cd9",
         arm64_linux:  "e2f062ff8a573d2da54c03c8f0b66e130a563a08c87b6db174953a9afdd21235",
         x86_64_linux: "6bf990458c114af3b3173dcbc1b0fb9ab93bea91c53b605fdd69aedd29a21cd9"

  url "https://storage.googleapis.com/antigravity-public/antigravity-cli/#{version.csv.first}-#{version.csv.second}/linux-#{arch}/cli_linux_#{file_arch}.tar.gz",
      verified: "storage.googleapis.com/antigravity-public/antigravity-cli/"
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

  preflight do
    File.write("#{staged_path}/agy.wrapper.sh", <<~EOS)
      #!/bin/sh
      if [ "$1" = "update" ]; then
        echo "Antigravity CLI is managed by Homebrew. Use 'brew upgrade --cask antigravity-cli-linux' instead." >&2
        exit 1
      fi

      exec "#{staged_path}/antigravity" "$@"
    EOS
    FileUtils.chmod 0755, "#{staged_path}/agy.wrapper.sh"
  end

  zap trash: "~/.gemini/antigravity-cli"
end

cask "antigravity-cli-linux" do
  arch arm: "arm", intel: "x64"
  file_arch = on_arch_conditional arm: "arm64", intel: "x64"
  livecheck_arch = on_arch_conditional arm: "arm64", intel: "amd64"
  os linux: "linux"

  version "1.5.11,6132547114106880"
  sha256 arm:          "de4fea15f83f40685cb30374b58337318d58340efcc8779a2eb1461b620b69f4",
         intel:        "df652c98fdf519a87c017b4e1d92f3fdb66c344de16e5e685c596637bbd28334",
         arm64_linux:  "de4fea15f83f40685cb30374b58337318d58340efcc8779a2eb1461b620b69f4",
         x86_64_linux: "df652c98fdf519a87c017b4e1d92f3fdb66c344de16e5e685c596637bbd28334"

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

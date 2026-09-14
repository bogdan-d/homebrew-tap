cask "codex-desktop-linux" do
  arch arm: "aarch64", intel: "x86_64"
  os linux: "linux"

  version :latest
  sha256 :no_check

  url "https://persistent.oaistatic.com/codex-app-prod/linux/rpm/latest/chatgpt.#{arch}.rpm"
  name "Codex"
  desc "AI coding desktop app from OpenAI"
  homepage "https://openai.com/codex/"

  livecheck do
    skip "Uses version :latest"
  end

  depends_on formula: "libarchive"
  depends_on :linux

  binary "chatgpt/codex-launcher", target: "codex-desktop"
  artifact "codex-desktop.desktop",
           target: "#{Dir.home}/.local/share/applications/codex-desktop.desktop"
  artifact "chatgpt/resources/icon-chatgpt.png",
           target: "#{Dir.home}/.local/share/icons/codex-desktop.png"

  preflight_steps do
    # Keep the launcher beside ChatGPT and its resources, without installing RPM system files.
    run "{{HOMEBREW_PREFIX}}/opt/libarchive/bin/bsdtar",
        args: ["-xf", "{{staged_path}}/chatgpt.#{arch}.rpm", "-C", "{{staged_path}}",
               "--strip-components=3", "./usr/lib/chatgpt"]
    remove "chatgpt.#{arch}.rpm"

    run "/usr/bin/test", args: ["-x", "{{staged_path}}/chatgpt/ChatGPT"]
    run "/usr/bin/test", args: ["-x", "{{staged_path}}/chatgpt/codex-launcher"]
    run "/usr/bin/test", args: ["-f", "{{staged_path}}/chatgpt/resources/icon-chatgpt.png"]

    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home

    write_file("codex-desktop.desktop", <<~EOS)
      [Desktop Entry]
      Name=Codex
      Comment=AI coding desktop app from OpenAI
      Exec={{HOMEBREW_PREFIX}}/bin/codex-desktop %U
      Icon=codex-desktop
      Terminal=false
      Type=Application
      StartupNotify=true
      Categories=Development;
      MimeType=x-scheme-handler/codex;
    EOS
  end
end

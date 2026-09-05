cask "antigravity-linux" do
  arch arm: "arm", intel: "x64"
  livecheck_arch = on_arch_conditional arm: "arm64", intel: "x64"
  os linux: "linux"

  version "2.0.6,5413878570549248"
  sha256 arm:          "02fc7f47650582ac72b845853b514de6c83ea7a4cd8a8d739e1a8688db2f45a9",
         intel:        "ad1e04535149b07c27030eb1ead40f4efda388cb39020bcbb9accdfb49e44cc5",
         arm64_linux:  "02fc7f47650582ac72b845853b514de6c83ea7a4cd8a8d739e1a8688db2f45a9",
         x86_64_linux: "ad1e04535149b07c27030eb1ead40f4efda388cb39020bcbb9accdfb49e44cc5"

  url "https://storage.googleapis.com/antigravity-public/antigravity-hub/#{version.csv.first}-#{version.csv.second}/linux-#{arch}/Antigravity.tar.gz"
  name "Google Antigravity"
  desc "Agent orchestration platform"
  homepage "https://antigravity.google/product/antigravity-2"

  livecheck do
    url "https://antigravity-auto-updater-974169037036.us-central1.run.app/api/update/linux-#{livecheck_arch}/stable/latest"
    regex(%r{/antigravity-hub/([^/]+)/}i)
    strategy :json do |json, regex|
      match = json["url"]&.match(regex)
      next if match.blank?

      match[1]&.tr("-", ",").to_s
    end
  end

  depends_on :linux
  depends_on formula: "python@3.14"

  binary "#{staged_path}/Antigravity-#{arch}/antigravity"
  artifact "antigravity.desktop",
           target: "#{Dir.home}/.local/share/applications/antigravity.desktop"
  artifact "antigravity-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/antigravity-url-handler.desktop"
  artifact "antigravity.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/512x512/apps/antigravity.png"

  preflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons/hicolor/512x512/apps", base: :home

    # Disable Electron auto-update checks; Homebrew manages this install.
    remove "Antigravity-*/resources/app-update.yml"

    write_file("antigravity.desktop", <<~EOS)
      [Desktop Entry]
      Name=Antigravity
      Comment=Agent orchestration platform
      GenericName=AI Agent Platform
      Exec="{{HOMEBREW_PREFIX}}/bin/antigravity" %F
      Icon=antigravity
      Type=Application
      StartupNotify=false
      StartupWMClass=Antigravity
      Categories=Development;Utility;
      Keywords=antigravity;agent;ai;
    EOS

    write_file("antigravity-url-handler.desktop", <<~EOS)
      [Desktop Entry]
      Name=Antigravity - URL Handler
      Comment=Agent orchestration platform
      GenericName=AI Agent Platform
      Exec="{{HOMEBREW_PREFIX}}/bin/antigravity" "%U"
      Icon=antigravity
      Type=Application
      NoDisplay=true
      Terminal=false
      StartupNotify=true
      StartupWMClass=Antigravity
      Categories=Utility;Development;
      MimeType=x-scheme-handler/antigravity;
      Keywords=antigravity;
    EOS

    run "{{HOMEBREW_PREFIX}}/opt/python@3.14/bin/python3.14", args: ["-c", <<~PYTHON, "{{staged_path}}"]
      import json
      import struct
      import sys
      from pathlib import Path

      staged_path = Path(sys.argv[1])
      app_root = next(staged_path.glob("Antigravity-*"))
      asar_path = app_root / "resources/app.asar"

      if asar_path.exists():
          with asar_path.open("rb") as asar:
              asar.seek(8)
              header_size = struct.unpack("<I", asar.read(4))[0] - 4
              asar.seek(16)
              icon_entry = json.loads(asar.read(header_size)).get("files", {}).get("icon.png")

              if icon_entry:
                  asar.seek(16 + header_size + int(icon_entry["offset"]))
                  (staged_path / "antigravity.png").write_bytes(asar.read(icon_entry["size"]))
    PYTHON

    # Create a placeholder icon if extraction fails.
    unless_path_exists "antigravity.png" do
      touch "antigravity.png"
    end
  end

  zap trash: [
    "~/.antigravity",
    "~/.config/Antigravity",
    "~/.config/antigravity",
    "~/.gemini/antigravity",
  ]

  caveats <<~EOS
    If authentication fails or the browser doesn't open Antigravity, try running:
      xdg-mime default antigravity-url-handler.desktop x-scheme-handler/antigravity
      update-desktop-database ~/.local/share/applications
  EOS
end

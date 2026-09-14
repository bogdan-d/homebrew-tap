cask "rancher-desktop-linux" do
  os linux: "linux"

  version :latest
  sha256 :no_check

  url "https://download.opensuse.org/repositories/isv:/Rancher:/stable/AppImage/rancher-desktop-latest-x86_64.AppImage"
  name "Rancher Desktop"
  desc "Container management and Kubernetes on the desktop"
  homepage "https://rancherdesktop.io/"

  livecheck do
    skip "Uses version :latest"
  end

  depends_on arch: :x86_64
  depends_on formula: "squashfs"
  depends_on :linux

  binary "squashfs-root/AppRun", target: "rancher-desktop"

  preflight_steps do
    set_permissions "rancher-desktop-latest-x86_64.AppImage", "a+x", recursive: false
    run "{{staged_path}}/rancher-desktop-latest-x86_64.AppImage",
        args: ["--appimage-extract"], chdir: "{{staged_path}}"
    remove "rancher-desktop-latest-x86_64.AppImage"
  end

  postflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons/hicolor/512x512/apps", base: :home

    if_path_exists "squashfs-root/rancher-desktop.png" do
      copy "squashfs-root/rancher-desktop.png",
           ".local/share/icons/hicolor/512x512/apps/rancher-desktop.png",
           target_base: :home
    end

    if_path_exists "squashfs-root/rancher-desktop.desktop" do
      inreplace "squashfs-root/rancher-desktop.desktop", /^Exec=.*/,
                "Exec={{HOMEBREW_PREFIX}}/bin/rancher-desktop"
      inreplace "squashfs-root/rancher-desktop.desktop", /^Icon=.*/, "Icon=rancher-desktop"
      copy "squashfs-root/rancher-desktop.desktop", ".local/share/applications/rancher-desktop.desktop",
           target_base: :home
    end
  end

  uninstall_postflight_steps do
    remove [".local/share/icons/hicolor/512x512/apps/rancher-desktop.png",
            ".local/share/applications/rancher-desktop.desktop"], base: :home
  end

  zap trash: [
    "~/.config/rancher-desktop",
    "~/.local/share/rancher-desktop",
  ]
end

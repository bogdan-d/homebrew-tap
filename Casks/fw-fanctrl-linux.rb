cask "fw-fanctrl-linux" do
  os linux: "linux"

  version "1.0.4,2"
  sha256 "d716bf48c72504264a06cd58aa2865d533485a504921f99f9e2587f769606855"

  release_tag = "fw-fanctrl-#{version.csv.first}-#{version.csv.second}"
  release_root = "fw-fanctrl-#{version.csv.first}-x86_64"

  url "https://github.com/ublue-os/homebrew-experimental-tap/releases/download/#{release_tag}/#{release_root}.tar.gz"
  name "fw-fanctrl"
  desc "Framework laptop fan controller daemon and CLI"
  homepage "https://github.com/TamtamHero/fw-fanctrl"

  livecheck do
    url "https://api.github.com/repos/ublue-os/homebrew-experimental-tap/releases"
    strategy :json do |json|
      json.filter_map do |rel|
        match = rel["tag_name"].to_s.match(/^fw-fanctrl-(\d+(?:\.\d+)+)-(\d+)$/)
        next if match.nil?

        "#{match[1]},#{match[2]}"
      end.max
    end
  end

  depends_on :linux
  depends_on arch: :x86_64

  binary "#{release_root}/usr/bin/fw-fanctrl"
  binary "#{release_root}/usr/bin/ectool"

  postflight_steps do
    run "sh", args: ["-c", <<~SH], sudo: true
      set -e

      find_executable() {
        for path in "$@"; do
          [ -x "$path" ] && { printf '%s\\n' "$path"; return; }
        done
        return 0
      }

      release_dir=$(find "{{staged_path}}" -maxdepth 1 -type d -name 'fw-fanctrl-*-x86_64' -print -quit)
      root_prefix="/opt/ublue-fw-fanctrl"
      root_bin_dir="$root_prefix/bin"
      systemd_dir="/etc/systemd/system"
      sleep_dir="/etc/systemd/system-sleep"
      config_dir="/etc/fw-fanctrl"

      install -d "$root_bin_dir" "$systemd_dir" "$sleep_dir" "$config_dir"
      install -Dm0755 "$release_dir/usr/bin/fw-fanctrl" "$root_bin_dir/fw-fanctrl"
      install -Dm0755 "$release_dir/usr/bin/ectool" "$root_bin_dir/ectool"
      install -Dm0644 "$release_dir/usr/lib/systemd/system/fw-fanctrl.service" "$systemd_dir/fw-fanctrl.service"
      install -Dm0755 "$release_dir/usr/lib/systemd/system-sleep/fw-fanctrl-suspend" "$sleep_dir/fw-fanctrl-suspend"
      install -Dm0644 "$release_dir/usr/share/fw-fanctrl/config.schema.json" "$config_dir/config.schema.json"
      [ -e "$config_dir/config.json" ] ||
        install -Dm0644 "$release_dir/usr/share/fw-fanctrl/config.json" "$config_dir/config.json"

      getenforce=$(find_executable /usr/sbin/getenforce /usr/bin/getenforce /bin/getenforce)
      restorecon=$(find_executable /usr/sbin/restorecon /usr/bin/restorecon /bin/restorecon)
      semanage=$(find_executable /usr/sbin/semanage /usr/bin/semanage /bin/semanage)
      chcon=$(find_executable /usr/sbin/chcon /usr/bin/chcon /bin/chcon)
      systemctl=$(find_executable /usr/bin/systemctl /bin/systemctl)
      selinux_mode="Disabled"
      [ -z "$getenforce" ] || selinux_mode=$("$getenforce")

      if [ "$selinux_mode" != "Disabled" ]; then
        resolved_root_bin=$(realpath "$root_bin_dir" 2>/dev/null || printf '%s\\n' "$root_bin_dir")
        bin_pattern="$resolved_root_bin(/.*)?"

        if [ -n "$semanage" ]; then
          "$semanage" fcontext -a -t bin_t "$bin_pattern" ||
            "$semanage" fcontext -m -t bin_t "$bin_pattern"
        elif [ -n "$chcon" ]; then
          "$chcon" -R -t bin_t "$resolved_root_bin"
        fi

        if [ -n "$restorecon" ]; then
          for path in "$root_prefix" "$systemd_dir" "$sleep_dir" "$config_dir"; do
            [ -e "$path" ] && "$restorecon" -RFv "$path"
          done
        fi
      fi

      [ -z "$systemctl" ] || "$systemctl" daemon-reload
    SH
  end

  uninstall_preflight_steps do
    run "sh", args: ["-c", <<~SH], sudo: true
      find_executable() {
        for path in "$@"; do
          [ -x "$path" ] && { printf '%s\\n' "$path"; return; }
        done
      }

      root_prefix="/opt/ublue-fw-fanctrl"
      root_bin_dir="$root_prefix/bin"
      systemd_dir="/etc/systemd/system"
      sleep_dir="/etc/systemd/system-sleep"
      config_dir="/etc/fw-fanctrl"
      getenforce=$(find_executable /usr/sbin/getenforce /usr/bin/getenforce /bin/getenforce)
      restorecon=$(find_executable /usr/sbin/restorecon /usr/bin/restorecon /bin/restorecon)
      semanage=$(find_executable /usr/sbin/semanage /usr/bin/semanage /bin/semanage)
      systemctl=$(find_executable /usr/bin/systemctl /bin/systemctl)

      [ -z "$systemctl" ] || "$systemctl" disable --now fw-fanctrl.service

      selinux_mode="Disabled"
      [ -z "$getenforce" ] || selinux_mode=$("$getenforce")
      if [ "$selinux_mode" != "Disabled" ] && [ -n "$semanage" ]; then
        resolved_root_bin=$(realpath "$root_bin_dir" 2>/dev/null || printf '%s\\n' "$root_bin_dir")
        "$semanage" fcontext -d "$resolved_root_bin(/.*)?"
      fi

      rm -f "$systemd_dir/fw-fanctrl.service"
      rm -f "$sleep_dir/fw-fanctrl-suspend"
      rm -f "$config_dir/config.schema.json"
      rm -rf "$root_prefix"
      if [ -d "$config_dir" ] && [ -z "$(find "$config_dir" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
        rmdir "$config_dir"
      fi

      [ -z "$systemctl" ] || "$systemctl" daemon-reload
      [ -z "$restorecon" ] || [ "$selinux_mode" = "Disabled" ] || "$restorecon" -RFv /opt /var/opt
    SH
  end

  caveats <<~EOS
    fw-fanctrl is installed under:
      /opt/ublue-fw-fanctrl/bin/{fw-fanctrl,ectool}
      /etc/systemd/system/fw-fanctrl.service
      /etc/systemd/system-sleep/fw-fanctrl-suspend
      /etc/fw-fanctrl/config.json (default; not overwritten on upgrade)
      /etc/fw-fanctrl/config.schema.json

    To activate the daemon:
      sudo systemctl enable --now fw-fanctrl.service

    To change fan curves, edit /etc/fw-fanctrl/config.json, then:
      sudo fw-fanctrl reload

    Requires Python 3.12+ on the system (default on Bluefin and Bazzite).
    Framework laptops only; upstream: https://github.com/TamtamHero/fw-fanctrl
  EOS
end

cask "docker-rootless-linux" do
  arch intel: "x86_64"
  os linux: "linux"

  version "29.8.1"
  sha256 "d8db66739d2e28d4933786d73e918d9be643a67fbd835db1bf740d650a259e70"

  url "https://download.docker.com/linux/static/stable/#{arch}/docker-#{version}.tgz"
  name "Docker Rootless"
  desc "Docker static binaries with rootless extras"
  homepage "https://docs.docker.com/engine/security/rootless/"

  livecheck do
    url "https://download.docker.com/linux/static/stable/#{arch}/"
    regex(/href=.*?docker[._-]v?(\d+(?:\.\d+)+)\.tgz/i)
  end

  depends_on arch: :x86_64
  depends_on formula: "docker"
  depends_on formula: "fuse-overlayfs"
  depends_on formula: "iproute2"
  depends_on formula: "slirp4netns"
  depends_on :linux

  # Binaries from the main tgz
  # The docker cli is aleady in brew
  binary "docker/dockerd"
  binary "docker/docker-init"
  binary "docker/docker-proxy"
  binary "docker/containerd"
  binary "docker/containerd-shim-runc-v2"
  binary "docker/ctr"
  binary "docker/runc"
  # Docker rootless extras
  binary "docker-rootless-extras/dockerd-rootless.sh", target: "dockerd-rootless"
  binary "docker-rootless-extras/rootlesskit"
  binary "docker-rootless-extras/vpnkit"

  preflight_steps do
    run "curl",
        args:           ["-L", "https://download.docker.com/linux/static/stable/x86_64/docker-rootless-extras-{{version}}.tgz",
                         "-o", "{{staged_path}}/extras.tgz"],
        network_access: true
    run "tar", args: ["-xzf", "{{staged_path}}/extras.tgz", "-C", "{{staged_path}}"]
    remove "extras.tgz"
  end

  postflight_steps do
    mkdir_p ".config/systemd/user", base: :home

    write_file ".config/systemd/user/dockerd-rootless.service", <<~SERVICE, base: :home
      [Unit]
      Description=Docker Application Container Engine (Rootless)
      Documentation=https://docs.docker.com/go/rootless/

      [Service]
      Environment=PATH={{HOMEBREW_PREFIX}}/bin:{{HOMEBREW_PREFIX}}/sbin:/usr/bin:/usr/sbin:/bin
      Environment=XDG_RUNTIME_DIR=/run/user/%U
      ExecStart={{HOMEBREW_PREFIX}}/bin/dockerd-rootless --iptables=false
      ExecReload=/bin/kill -s HUP $MAINPID
      TimeoutSec=0
      RestartSec=2
      Restart=always
      StartLimitBurst=3
      StartLimitInterval=60s
      LimitNOFILE=infinity
      LimitNPROC=infinity
      LimitCORE=infinity
      TasksMax=infinity
      Delegate=yes
      Type=notify
      NotifyAccess=all
      KillMode=mixed

      [Install]
      WantedBy=default.target
    SERVICE
    set_permissions ".config/systemd/user/dockerd-rootless.service", "0644", base: :home, recursive: false
  end

  # Does not seem work...
  zap trash: "~/.config/systemd/user/dockerd-rootless.service"

  caveats <<~EOS
    Use 'dockerd-rootless --iptables=false' to start

    To enable and start the systemd service:
      systemctl --user daemon-reload
      systemctl --user enable --now dockerd-rootless

    A "rootless" docker context is not created automatically. To create and select it:
      docker context create rootless --docker host=unix:///run/user/$(id -u)/docker.sock
      docker context use rootless
  EOS
end

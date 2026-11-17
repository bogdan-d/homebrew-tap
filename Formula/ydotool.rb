class Ydotool < Formula
  desc "Generic command-line automation tool (no X!)"
  homepage "https://github.com/ReimuNotMoe/ydotool"
  url "https://github.com/ReimuNotMoe/ydotool/archive/708e96ff27e381a8c549418a9d34cdde12305317.tar.gz"
  version "1.0.4.20251222"
  sha256 "0ddbb2694fbb25657a8b0fdb7db783f6ba0f166b10959d6496de9faef93679cf"
  license "AGPL-3.0-only"
  head "https://github.com/ReimuNotMoe/ydotool.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/bogdan-d/homebrew-tap/releases/download/ydotool-1.0.4.20251222"
    sha256 cellar: :any, x86_64_linux: "0267ca93011252cb6b8e5081f6e92828278ea135d848917c51a7ca174e6239ec"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "scdoc" => :build
  depends_on :linux

  def install
    system "cmake", "-S", ".", "-B", "build",
           "-DSYSTEMD_USER_SERVICE=OFF",
           *std_cmake_args
    system "cmake", "--build", "build", "-j#{ENV.make_jobs}"
    system "cmake", "--install", "build"
  end

  service do
    run [opt_bin/"ydotoold", "--socket-path=/run/user/#{Process.uid}/.ydotool_socket"]
    keep_alive true
    error_log_path var/"log/ydotoold.log"
    log_path var/"log/ydotoold.log"
    environment_variables PATH: std_service_path_env
  end

  def caveats
    <<~EOS
      ydotool requires the ydotoold daemon to be running.

      The socket will be created at: /run/user/#{Process.uid}/.ydotool_socket

      Start the service with:
        brew services start ydotool

      Or run manually:
        ydotoold --socket-path=/run/user/#{Process.uid}/.ydotool_socket

      You may need to add your user to the input group:
        sudo usermod -a -G input $USER

      Then log out and back in for the changes to take effect.
    EOS
  end

  test do
    assert_match "Usage: ydotool <cmd> <args>", shell_output("#{bin}/ydotool --help")
    assert_match "ydotool Daemon", shell_output("#{bin}/ydotoold --help")
  end
end

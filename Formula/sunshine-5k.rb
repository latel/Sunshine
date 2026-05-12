require "language/node"

class Sunshine5k < Formula
  GCC_VERSION = "14".freeze
  GCC_FORMULA = "gcc@#{GCC_VERSION}".freeze

  desc "Self-hosted game stream host for Moonlight with local macOS 5K VideoToolbox patch"
  homepage "https://app.lizardbyte.dev/Sunshine"
  url "https://github.com/LizardByte/Sunshine.git",
    tag:      "v2025.924.154138",
    revision: "86188d47a7463b0f73b35de18a628353adeaa20e"
  version "2025.924.154138-5k.1"
  license all_of: ["GPL-3.0-only"]

  patch do
    url "https://raw.githubusercontent.com/latel/Sunshine/macos-vt-5k-hevc/patches/macos-vt-5k-hevc.patch"
    sha256 "b80ef60e8e4a92002e58558ef9b58b70b90d9ed5f458b9595eaac069cc1a3341"
  end

  option "with-docs", "Enable docs"
  option "with-static-boost", "Enable static link of Boost libraries"
  option "without-static-boost", "Disable static link of Boost libraries"

  depends_on "cmake" => :build
  depends_on "doxygen" => :build
  depends_on "graphviz" => :build
  depends_on "node" => :build
  depends_on "pkgconf" => :build
  depends_on "curl"
  depends_on "icu4c@78"
  depends_on "miniupnpc"
  depends_on "openssl@3"
  depends_on "opus"

  on_linux do
    depends_on GCC_FORMULA => [:build, :test]
    depends_on "at-spi2-core"
    depends_on "avahi"
    depends_on "ayatana-ido"
    depends_on "cairo"
    depends_on "gdk-pixbuf"
    depends_on "glib"
    depends_on "gnu-which"
    depends_on "gtk+3"
    depends_on "harfbuzz"
    depends_on "libayatana-appindicator"
    depends_on "libayatana-indicator"
    depends_on "libcap"
    depends_on "libdbusmenu"
    depends_on "libdrm"
    depends_on "libice"
    depends_on "libnotify"
    depends_on "libsm"
    depends_on "libva"
    depends_on "libx11"
    depends_on "libxcb"
    depends_on "libxcursor"
    depends_on "libxext"
    depends_on "libxfixes"
    depends_on "libxi"
    depends_on "libxinerama"
    depends_on "libxrandr"
    depends_on "libxtst"
    depends_on "mesa"
    depends_on "numactl"
    depends_on "pango"
    depends_on "pulseaudio"
    depends_on "systemd"
    depends_on "wayland"
  end

  conflicts_with "sunshine", because: "sunshine-5k installs the Sunshine binary name"
  conflicts_with "sunshine-beta", because: "sunshine-5k installs the Sunshine binary name"

  fails_with :clang do
    build 1400
    cause "Requires C++23 support"
  end

  fails_with :gcc do
    version "12"
    cause "Requires C++23 support"
  end

  def install
    ENV["BRANCH"] = "macos-vt-5k-hevc"
    ENV["BUILD_VERSION"] = "2025.924.154138-5k.1"
    ENV["COMMIT"] = "86188d47a7463b0f73b35de18a628353adeaa20e-local-hevc-idr-fps-patch"

    if OS.linux?
      gcc_path = Formula[GCC_FORMULA]
      ENV["CC"] = "#{gcc_path.opt_bin}/gcc-#{GCC_VERSION}"
      ENV["CXX"] = "#{gcc_path.opt_bin}/g++-#{GCC_VERSION}"
      ENV.append "LDFLAGS", "-static-libgcc -static-libstdc++"
    end

    args = %W[
      -DBUILD_WERROR=ON
      -DCMAKE_CXX_STANDARD=23
      -DCMAKE_INSTALL_PREFIX=#{prefix}
      -DHOMEBREW_ALLOW_FETCHCONTENT=ON
      -DOPENSSL_ROOT_DIR=#{Formula["openssl"].opt_prefix}
      -DSUNSHINE_ASSETS_DIR=sunshine/assets
      -DSUNSHINE_BUILD_HOMEBREW=ON
      -DSUNSHINE_PUBLISHER_NAME='LizardByte'
      -DSUNSHINE_PUBLISHER_WEBSITE='https://app.lizardbyte.dev'
      -DSUNSHINE_PUBLISHER_ISSUE_URL='https://app.lizardbyte.dev/support'
      -DBUILD_TESTS=OFF
    ]

    if build.with? "docs"
      args << "-DBUILD_DOCS=ON"
    else
      args << "-DBUILD_DOCS=OFF"
    end

    if build.without? "static-boost"
      args << "-DBOOST_USE_STATIC=OFF"
    else
      args << "-DBOOST_USE_STATIC=ON"
      unless Formula["icu4c"].any_version_installed?
        odie <<~EOS
          icu4c must be installed to link against static Boost libraries,
          either install icu4c or use brew install sunshine-5k --with-static-boost instead
        EOS
      end
      ENV.append "CXXFLAGS", "-I#{Formula["icu4c"].opt_include}"
      icu4c_lib_path = Formula["icu4c"].opt_lib.to_s
      ENV.append "LDFLAGS", "-L#{icu4c_lib_path}"
      ENV["LIBRARY_PATH"] = icu4c_lib_path
    end

    if OS.linux?
      args << "-DCUDA_FAIL_ON_MISSING=OFF"
      args << "-DCMAKE_EXE_LINKER_FLAGS=-static-libgcc -static-libstdc++"
      args << "-DCMAKE_SHARED_LINKER_FLAGS=-static-libgcc -static-libstdc++"
    end

    system "cmake", "-S", ".", "-B", "build", "-G", "Unix Makefiles", *std_cmake_args, *args
    system "make", "-C", "build"
    system "make", "-C", "build", "install"

    system "codesign", "-s", "-", "--force", "--deep", bin/"sunshine" if OS.mac?
    bin.install "src_assets/linux/misc/postinst" if OS.linux?
  end

  service do
    run [opt_bin/"sunshine", "~/.config/sunshine/sunshine.conf"]
  end

  def post_install
    if OS.linux?
      opoo <<~EOS
        ATTENTION: To complete installation, you must run the following command:
        `sudo #{bin}/postinst`
      EOS
    end

    if OS.mac?
      opoo <<~EOS
        This build includes the local macOS VideoToolbox 5K HEVC patch.
        Keep Moonlight on the client using the Metal renderer for best pointer/display feel.
      EOS
    end
  end

  def caveats
    <<~EOS
      Installed Sunshine with the local macOS 5K HEVC patch.

      Start manually:
        #{opt_bin}/sunshine ~/.config/sunshine/sunshine.conf

      Or as a service:
        brew services start sunshine-5k
    EOS
  end

  test do
    system bin/"sunshine", "--version"
  end
end

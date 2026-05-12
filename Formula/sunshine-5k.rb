require "language/node"

class Sunshine5k < Formula
  GCC_VERSION = "14".freeze
  GCC_FORMULA = "gcc@#{GCC_VERSION}".freeze

  desc "Game stream host with local macOS 5K VideoToolbox patch"
  homepage "https://app.lizardbyte.dev/Sunshine"
  url "https://github.com/LizardByte/Sunshine.git",
    tag:      "v2025.924.154138",
    revision: "86188d47a7463b0f73b35de18a628353adeaa20e"
  version "2025.924.154138-5k.1"
  license all_of: ["GPL-3.0-only"]

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

  patch :DATA

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

    args << if build.with? "docs"
      "-DBUILD_DOCS=ON"
    else
      "-DBUILD_DOCS=OFF"
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

__END__
diff --git a/src/cbs.cpp b/src/cbs.cpp
index 67cda0c..4b15d35 100644
--- a/src/cbs.cpp
+++ b/src/cbs.cpp
@@ -247,4 +247,91 @@ namespace cbs {
 
     return ((CodedBitstreamH265Context *) ctx->priv_data)->active_sps->vui_parameters_present_flag;
   }
+
+  bool packet_contains_idr(const AVPacket *packet, int codec_id) {
+    if (!packet || !packet->data || packet->size <= 0) {
+      return false;
+    }
+
+    const auto is_idr_nal = [codec_id](const std::uint8_t *nal, int size) {
+      if (size <= 0) {
+        return false;
+      }
+
+      if (codec_id == AV_CODEC_ID_H264) {
+        const auto nal_type = nal[0] & 0x1F;
+        return nal_type == 5;
+      }
+
+      if (codec_id == AV_CODEC_ID_H265 && size >= 2) {
+        const auto nal_type = (nal[0] >> 1) & 0x3F;
+        return nal_type >= 16 && nal_type <= 21;
+      }
+
+      return false;
+    };
+
+    const auto data = packet->data;
+    const auto size = packet->size;
+
+    for (int i = 0; i + 4 <= size;) {
+      int start_code_len = 0;
+      if (i + 3 <= size && data[i] == 0 && data[i + 1] == 0 && data[i + 2] == 1) {
+        start_code_len = 3;
+      } else if (data[i] == 0 && data[i + 1] == 0 && data[i + 2] == 0 && data[i + 3] == 1) {
+        start_code_len = 4;
+      }
+
+      if (!start_code_len) {
+        ++i;
+        continue;
+      }
+
+      const auto nal_start = i + start_code_len;
+      auto nal_end = nal_start;
+      while (nal_end + 3 <= size) {
+        if (data[nal_end] == 0 && data[nal_end + 1] == 0 && (data[nal_end + 2] == 1 || (nal_end + 4 <= size && data[nal_end + 2] == 0 && data[nal_end + 3] == 1))) {
+          break;
+        }
+        ++nal_end;
+      }
+
+      if (is_idr_nal(data + nal_start, nal_end - nal_start)) {
+        return true;
+      }
+
+      i = nal_end;
+    }
+
+    for (const auto length_size : {4, 3, 2, 1}) {
+      for (int offset = 0; offset < length_size && offset + length_size < size; ++offset) {
+        auto parsed_any = false;
+
+        for (int i = offset; i + length_size <= size;) {
+          auto nal_size = 0;
+          for (int j = 0; j < length_size; ++j) {
+            nal_size = (nal_size << 8) | static_cast<int>(data[i + j]);
+          }
+
+          if (nal_size <= 0 || i + length_size + nal_size > size) {
+            break;
+          }
+
+          parsed_any = true;
+
+          if (is_idr_nal(data + i + length_size, nal_size)) {
+            return true;
+          }
+
+          i += length_size + nal_size;
+        }
+
+        if (parsed_any) {
+          break;
+        }
+      }
+    }
+
+    return false;
+  }
 }  // namespace cbs
diff --git a/src/cbs.h b/src/cbs.h
index 5dfddab..b7c58cb 100644
--- a/src/cbs.h
+++ b/src/cbs.h
@@ -36,4 +36,6 @@ namespace cbs {
    * @return True if the SPS->VUI is present in the active SPS of the packet, false otherwise.
    */
   bool validate_sps(const AVPacket *packet, int codec_id);
+
+  bool packet_contains_idr(const AVPacket *packet, int codec_id);
 }  // namespace cbs
diff --git a/src/video.cpp b/src/video.cpp
index 8f6b69c..8337180 100644
--- a/src/video.cpp
+++ b/src/video.cpp
@@ -5,6 +5,7 @@
 // standard includes
 #include <atomic>
 #include <bitset>
+#include <chrono>
 #include <list>
 #include <thread>
 
@@ -1400,11 +1401,14 @@ namespace video {
         return ret;
       }
 
-      if (av_packet->flags & AV_PKT_FLAG_KEY) {
-        BOOST_LOG(debug) << "Frame "sv << frame_nr << ": IDR Keyframe (AV_FRAME_FLAG_KEY)"sv;
+      packet->idr = cbs::packet_contains_idr(av_packet, ctx->codec_id) ||
+            ((frame->flags & AV_FRAME_FLAG_KEY) && ctx->codec_id == AV_CODEC_ID_H265);
+
+      if (packet->is_idr()) {
+        BOOST_LOG(debug) << "Frame "sv << frame_nr << ": IDR Keyframe"sv;
       }
 
-      if ((frame->flags & AV_FRAME_FLAG_KEY) && !(av_packet->flags & AV_PKT_FLAG_KEY)) {
+      if ((frame->flags & AV_FRAME_FLAG_KEY) && !packet->is_idr()) {
         BOOST_LOG(error) << "Encoder did not produce IDR frame when requested!"sv;
       }
 
@@ -1565,6 +1569,11 @@ namespace video {
                         std::numeric_limits<int>::max();
 
       ctx->keyint_min = std::numeric_limits<int>::max();
+    #ifdef __APPLE__
+      if (encoder.name == "videotoolbox") {
+        ctx->keyint_min = 0;
+      }
+    #endif
 
       // Some client decoders have limits on the number of reference frames
       if (config.numRefFrames) {
@@ -1580,6 +1589,12 @@ namespace video {
       ctx->flags |= AV_CODEC_FLAG_CLOSED_GOP | AV_CODEC_FLAG_LOW_DELAY;
 
       ctx->flags2 |= AV_CODEC_FLAG2_FAST;
+    #ifdef __APPLE__
+      if (encoder.name == "videotoolbox") {
+        ctx->flags = 0;
+        ctx->flags2 = 0;
+      }
+    #endif
 
       auto avcodec_colorspace = avcodec_colorspace_from_sunshine_colorspace(colorspace);
 
@@ -1660,6 +1675,12 @@ namespace video {
 
       ctx->thread_type = FF_THREAD_SLICE;
       ctx->thread_count = ctx->slices;
+    #ifdef __APPLE__
+      if (encoder.name == "videotoolbox") {
+        ctx->thread_type = 0;
+        ctx->thread_count = 0;
+      }
+    #endif
 
       AVDictionary *options {nullptr};
       auto handle_option = [&options, &config](const encoder_t::option_t &option) {
diff --git a/src/video.h b/src/video.h
index a966c53..15ad294 100644
--- a/src/video.h
+++ b/src/video.h
@@ -268,7 +268,7 @@ namespace video {
     }
 
     bool is_idr() override {
-      return av_packet->flags & AV_PKT_FLAG_KEY;
+      return idr || (av_packet->flags & AV_PKT_FLAG_KEY);
     }
 
     int64_t frame_index() override {
@@ -284,6 +284,7 @@ namespace video {
     }
 
     AVPacket *av_packet;
+    bool idr = false;
   };
 
   struct packet_raw_generic: packet_raw_t {

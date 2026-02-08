{
  description = "Avodah - Super Productivity Flutter Migration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Linux desktop dependencies
      linuxDeps = pkgs: with pkgs; [
        gtk3
        glib
        pcre2
        libepoxy
        cairo
        pango
        gdk-pixbuf
        atk
        harfbuzz
        xorg.libX11
        xorg.libXcursor
        xorg.libXinerama
        xorg.libXrandr
        libGL
        libxkbcommon
        sqlite  # For Drift database tests
      ];

      mkPackage = pkgs:
        let
          flutter = pkgs.flutter;
          deps = linuxDeps pkgs;
        in
        pkgs.stdenv.mkDerivation rec {
          pname = "avodah";
          version = "0.1.0";

          src = pkgs.lib.cleanSource ./.;

          nativeBuildInputs = with pkgs; [
            flutter
            dart
            cmake
            ninja
            pkg-config
            clang
            makeWrapper
          ] ++ deps;

          buildInputs = deps;

          configurePhase = ''
            export HOME=$(mktemp -d)
            export PUB_CACHE=$HOME/.pub-cache
            flutter config --no-analytics
            flutter pub get
          '';

          buildPhase = ''
            flutter build linux --release
          '';

          installPhase = ''
            mkdir -p $out/bin $out/share/avodah
            cp -r build/linux/x64/release/bundle/* $out/share/avodah/
            makeWrapper $out/share/avodah/avodah $out/bin/avodah \
              --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath deps}"
          '';

          meta = with pkgs.lib; {
            description = "Avodah - Time Tracking & Task Management";
            homepage = "https://github.com/sinh-x/avodah";
            license = licenses.mit;
            platforms = platforms.linux;
            mainProgram = "avodah";
          };
        };
    in
    {
      # Overlay for NixOS integration
      overlays.default = final: prev: {
        avodah = mkPackage final;
      };

      # Packages
      packages = forAllSystems (system: {
        default = mkPackage nixpkgs.legacyPackages.${system};
        avodah = mkPackage nixpkgs.legacyPackages.${system};
      });

      # Development shells
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              android_sdk.accept_license = true;
            };
          };

          # Android SDK configuration
          androidComposition = pkgs.androidenv.composeAndroidPackages {
            cmdLineToolsVersion = "11.0";
            platformToolsVersion = "35.0.2";
            buildToolsVersions = [ "35.0.0" ];
            platformVersions = [ "35" "34" ];
            includeEmulator = false;
            includeSources = false;
            includeSystemImages = false;
            includeNDK = false;
          };
          androidSdk = androidComposition.androidsdk;

          flutter = pkgs.flutter;
          deps = linuxDeps pkgs;

          # Dev command scripts
          av-run = pkgs.writeShellScriptBin "av-run" "flutter run -d linux";
          av-run-android = pkgs.writeShellScriptBin "av-run-android" "flutter run -d android";
          av-build = pkgs.writeShellScriptBin "av-build" "flutter build linux --release";
          av-build-android = pkgs.writeShellScriptBin "av-build-android" "flutter build apk --release";
          av-test = pkgs.writeShellScriptBin "av-test" "flutter test";
          av-analyze = pkgs.writeShellScriptBin "av-analyze" "flutter analyze";
          av-clean = pkgs.writeShellScriptBin "av-clean" "flutter clean && flutter pub get";
        in
        {
          default = pkgs.mkShell {
            packages = [
              flutter
              pkgs.dart
              androidSdk
              pkgs.jdk17
              pkgs.git
              pkgs.cmake
              pkgs.ninja
              pkgs.pkg-config
              pkgs.clang
              # Dev commands
              av-run
              av-run-android
              av-build
              av-build-android
              av-test
              av-analyze
              av-clean
            ] ++ deps;

            env = {
              ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
              ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
              JAVA_HOME = "${pkgs.jdk17}";
              CHROME_EXECUTABLE = "${pkgs.chromium}/bin/chromium";
            };

            shellHook = ''
              echo "Avodah Development Environment"
              echo ""
              echo "Flutter: $(flutter --version --machine 2>/dev/null | grep -o '"frameworkVersion":"[^"]*"' | cut -d'"' -f4)"
              echo "Dart: $(dart --version 2>&1 | head -1)"
              echo ""
              echo "Commands:"
              echo "  av-run           - Run on Linux desktop"
              echo "  av-run-android   - Run on Android device/emulator"
              echo "  av-build         - Build Linux release"
              echo "  av-build-android - Build Android APK"
              echo "  av-test          - Run tests"
              echo "  av-analyze       - Run analyzer"
              echo "  av-clean         - Clean and get deps"
              echo ""
            '';

            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath deps;
          };
        });
    };
}

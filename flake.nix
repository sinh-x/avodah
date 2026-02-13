{
  description = "Avodah - Time Tracking & Task Management";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Linux desktop dependencies (for Flutter app & devShell)
      linuxDeps =
        pkgs: with pkgs; [
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
          sqlite # For Drift database tests
        ];

      # CLI package (avo) — pure Dart, built with buildDartApplication
      mkAvoPackage =
        pkgs:
        pkgs.buildDartApplication {
          pname = "avo";
          version = "0.1.0";

          src = pkgs.lib.cleanSource ./.;
          sourceRoot = "source/mcp";

          pubspecLock = pkgs.lib.importJSON ./mcp/pubspec.lock.json;

          # sqlite3 Dart package needs system sqlite — handled automatically
          # by nixpkgs' package-source-builders/sqlite3

          postInstall = ''
            # Fish completions
            installShellCompletion --fish --name avo.fish \
              $NIX_BUILD_TOP/source/completions/avo.fish
          '';

          nativeBuildInputs = [ pkgs.installShellFiles ];

          meta = with pkgs.lib; {
            description = "Avodah CLI - Time Tracking & Task Management";
            homepage = "https://github.com/sinh-x/avodah";
            license = licenses.mit;
            platforms = platforms.linux;
            mainProgram = "avo";
          };
        };
    in
    {
      # Overlay for NixOS integration
      overlays.default = final: prev: {
        avo = mkAvoPackage final;
      };

      # Packages
      packages = forAllSystems (system: {
        default = mkAvoPackage nixpkgs.legacyPackages.${system};
        avo = mkAvoPackage nixpkgs.legacyPackages.${system};
      });

      # Development shells
      devShells = forAllSystems (
        system:
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
            platformVersions = [
              "35"
              "34"
            ];
            includeEmulator = false;
            includeSources = false;
            includeSystemImages = false;
            includeNDK = false;
          };
          androidSdk = androidComposition.androidsdk;

          flutter = pkgs.flutter;
          deps = linuxDeps pkgs;

          # Dev command scripts
          avo-run = pkgs.writeShellScriptBin "avo-run" "flutter run -d linux";
          avo-run-android = pkgs.writeShellScriptBin "avo-run-android" "flutter run -d android";
          avo-build = pkgs.writeShellScriptBin "avo-build" "flutter build linux --release";
          avo-build-android = pkgs.writeShellScriptBin "avo-build-android" "flutter build apk --release";
          avo-test = pkgs.writeShellScriptBin "avo-test" "flutter test";
          avo-analyze = pkgs.writeShellScriptBin "avo-analyze" "flutter analyze";
          avo-clean = pkgs.writeShellScriptBin "avo-clean" "flutter clean && flutter pub get";
          avo-build-cli = pkgs.writeShellScriptBin "avo-build-cli" ''
            cd "$(git rev-parse --show-toplevel)/mcp" && dart compile exe bin/avo.dart -o bin/avo
          '';
          avo = pkgs.writeShellScriptBin "avo" ''
            MCP_DIR="$(git rev-parse --show-toplevel)/mcp"
            BIN="$MCP_DIR/bin/avo"

            # Recompile if binary is missing or any dart source is newer
            if [ ! -f "$BIN" ] || [ -n "$(find "$MCP_DIR/lib" "$MCP_DIR/bin/avo.dart" -newer "$BIN" 2>/dev/null | head -1)" ]; then
              echo "Compiling avo..." >&2
              (cd "$MCP_DIR" && dart compile exe bin/avo.dart -o bin/avo) >&2
            fi

            exec "$BIN" "$@"
          '';
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
              avo-run
              avo-run-android
              avo-build
              avo-build-android
              avo-test
              avo-analyze
              avo-clean
              avo-build-cli
              avo
            ]
            ++ deps;

            env = {
              ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
              ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
              JAVA_HOME = "${pkgs.jdk17}";
              CHROME_EXECUTABLE = "${pkgs.chromium}/bin/chromium";
              # Prevent starship/termbg from sending OSC 11 terminal query
              # (response leaks into fish's input buffer via direnv timing race)
              COLORFGBG = "15;0";
            };

            shellHook = ''
              echo "Avodah Development Environment"
              echo ""
              echo "Flutter: $(TERM=dumb flutter --version --machine </dev/null 2>/dev/null | ${pkgs.jq}/bin/jq -r '.frameworkVersion // "unknown"')"
              echo "Dart:    $(TERM=dumb dart --version </dev/null 2>&1 | head -1)"
              echo ""
              echo "Commands:"
              echo "  avo-run           - Run on Linux desktop"
              echo "  avo-run-android   - Run on Android device/emulator"
              echo "  avo-build         - Build Linux release"
              echo "  avo-build-android - Build Android APK"
              echo "  avo-test          - Run tests"
              echo "  avo-analyze       - Run analyzer"
              echo "  avo-clean         - Clean and get deps"
              echo "  avo-build-cli     - Compile native avo binary"
              echo ""
              echo "  avo <command>     - Run Avodah CLI (native, auto-compiles)"
              echo ""

              # Reset terminal line discipline — flutter/dart can corrupt stty settings
              # (e.g. disabling icrnl, causing Enter to show ^M instead of newline)
              stty sane 2>/dev/null
            '';

            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath deps;
          };
        }
      );
    };
}

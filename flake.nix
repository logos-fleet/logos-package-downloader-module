{
  description = "Logos Package Downloader Module - Online package catalog and download service";

  inputs = {
    logos-module-builder.url = "github:logos-co/logos-module-builder";
    logos-package-downloader.url = "github:logos-co/logos-package-downloader";
  };

  outputs = inputs@{ logos-module-builder, ... }:
    logos-module-builder.lib.mkLogosModule {
      src = ./.;
      configFile = ./metadata.json;
      flakeInputs = inputs;
      externalLibInputs = {
        # Use the `lib` package of logos-package-downloader (it ships
        # libpackage_downloader_lib.{so,dylib,dll} + headers under that
        # output, not under `default`).
        #
        # This mapping is resolved per TARGET, not per name: mkLogosModule
        # reads `input.packages.${system}.lib` for whatever system it is
        # building. So the x86_64-windows target this module advertises is
        # only real because logos-package-downloader itself publishes
        # packages.x86_64-windows.lib -- it has since its own #24, which is
        # the rev this lock already pinned, so enabling Windows here needed
        # no re-pin of it. Pin it back one commit (4f2b684) and the eval
        # fails loudly with
        #   External lib "package_downloader": flake input does not provide
        #   packages.x86_64-windows.lib
        # rather than quietly dropping the target -- so the two pins must
        # not be allowed to drift apart.
        package_downloader = {
          input = inputs.logos-package-downloader;
          packages.default = "lib";
          # THE SAME LIBRARY, FOR A PHONE. `generate` stages a BUILD-platform
          # image into lib/ and nothing in logos-module-builder can recompile it
          # -- it comes from its own flake -- so the mobile Bare build asks here,
          # per target.
          #
          # `legacyPackages.<buildSystem>.mobile.<target>.lib`: an iOS
          # derivation's `system` is its BUILD platform, so the archive cannot
          # live under `packages.<target>`. It is ONE self-contained archive
          # (curl, OpenSSL and lgx folded in by logos-package-downloader), which
          # is why EXTERNAL_LIBS below still names one library.
          #
          # Only the two iOS targets exist; aarch64-android resolves to null and
          # logos-module-builder refuses THAT target by name.
          mobilePackages = { system, buildSystem, ... }:
            ((inputs.logos-package-downloader.legacyPackages.${buildSystem} or { }).mobile
              or { }).${system}.lib or null;
        };
      };
      tests = {
        dir = ./tests;
        # Link-time-mock the package_downloader external lib: the real
        # network/disk-backed PackageDownloaderLib is replaced by
        # tests/mocks/mock_package_downloader_lib.cpp. Key matches the
        # externalLibInputs entry above.
        mockCLibs = [ "package_downloader" ];
      };
    };
}

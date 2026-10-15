{
  description = "Minecraft client and server jars";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      data = lib.importJSON ./versions.json;

      mkJars =
        pkgs:
        let
          jars = lib.mapAttrs (
            version:
            lib.mapAttrs (
              kind: sha1:
              pkgs.fetchurl {
                name = "minecraft-${kind}-${version}.jar";
                url = "https://piston-data.mojang.com/v1/objects/${sha1}/${kind}.jar";
                inherit sha1;
              }
            )
          ) data.versions;
        in
        jars // { latest = jars.${data.latest}; };
    in
    {
      lib = {
        inherit (data) latest versions;
        inherit mkJars;
      };

      overlays.default = final: _prev: { minecraftJars = mkJars final; };

      legacyPackages = forAllSystems mkJars;

      checks = forAllSystems (pkgs: {
        inherit ((mkJars pkgs).latest) client server;
      });
    };
}

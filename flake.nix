{
  description = "Friday Night Funkin packaged for Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fu.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, fu, ... }: (with fu.lib; eachSystem [ system.x86_64-linux ]) (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};

      haxePackages = pkgs.haxePackages // pkgs.callPackage ./pkgs/haxelibs { };

      callPackage = pkgs.newScope {
        inherit haxePackages;
      };
    in
    {
      packages = {
        funkin = callPackage ./pkgs/funkin { };
        kade-engine = callPackage ./pkgs/kade-engine { };
        trickster = callPackage ./pkgs/trickster { };
      };

      legacyPackages = {
        inherit haxePackages;
      };
    }
  );
}

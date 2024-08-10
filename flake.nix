{
  description = "Provides a reproducible python3 env to run the simulations";

  nixConfig = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://cache.nixos.org"
    ];
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
  };
  outputs =
    inputs@{ self
    , nixpkgs
    , nixpkgs-stable
    , ...
    }:
    let
      inherit (builtins)
        map
        mapAttrs
        foldl'
        hasAttr
        head
        ;

      defaultSystems = [
        "x86_64-linux"
      ];

      forSystems =
        (systems: nixpkgs-channel:
          let
            systemOutputs = (map
              (system: createSystemOutput system nixpkgs-channel)
              systems);
          in
          foldl'
            (
              output: acc:
                (mapAttrs
                  (name: value:
                    if (hasAttr name acc)
                    then value // acc.${name}
                    else value)
                  output
                )
            )
            (
              if (systemOutputs == [ ])
              then { }
              else (head systemOutputs)
            )
            systemOutputs
        );

      createSystemOutput =
        (system: nixpkgs-channel:
          let
            pkgs = nixpkgs-channel.legacyPackages.${system};

            python3 = pkgs.python311Full;
            python3Deps = (python3Pkgs: with python3Pkgs; [
              pip
              virtualenv
            ]);

            buildInputs = [
              python3
            ] ++ (python3Deps pkgs.python311Packages);

            tabbyPackage = pkgs.stdenv.mkDerivation {
              pname = "tabbyAPI";
              version = "0.0.1";
              src = ./.;

              inherit buildInputs;
              buildPhase = ''
                mkdir -p $src
              '';

              installPhase = ''
                mkdir -p $out
                cp -R -T $src $out
              '';
            };

            flakeOutput = {
              devShells.default = pkgs.mkShell {
                packages = [ tabbyPackage ];
                inputsFrom = [ tabbyPackage ];
              };

              packages.default = tabbyPackage;
            };
          in
          mapAttrs
            (name: value: { "${system}" = value; })
            flakeOutput
        );

    in
    forSystems defaultSystems nixpkgs-stable;
}

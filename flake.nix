{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-python.url = "github:cachix/nixpkgs-python";
    nixpkgs-python.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { 
    self
    , nixpkgs
    , nixpkgs-python
  }: let 
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    pythonPkgs = nixpkgs-python.packages.x86_64-linux."3.11";
  in {

    devShells.${system}.default = pkgs.mkShell {
      LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";
      buildInputs = [
        pythonPkgs
        pkgs.stdenv
        pkgs.ffmpeg
      ];
    };

  };
}

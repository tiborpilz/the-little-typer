{
  description = "Pie — the dependently-typed language from *The Little Typer* — packaged for Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # The Pie source itself. `flake = false` means we just want the source tree;
    # the flake.lock records its hash automatically, so there is no manual sha256
    # to maintain. Pinned to a known-good revision (Pie is "finished" per upstream,
    # so this rarely needs bumping).
    pie-src = {
      url = "github:the-little-typer/pie/2c89553a693ac6688b16d722f416914f2e9aa4c3";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, pie-src }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      # ---- Package: the Pie build ----------------------------------------
      # `pie` is a REPL launcher plus pie-aware `racket`/`raco` wrappers. Editor
      # integration (Emacs/Neovim) lives with the consumer's config, not here.
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          pie = pkgs.callPackage ./nix/pie.nix { inherit pie-src; };
        in
        {
          inherit pie;
          default = pie;
        });

      # ---- Runnable app: `nix run .#pie` ---------------------------------
      apps = forAllSystems (system:
        let
          p = self.packages.${system};
        in
        {
          default = self.apps.${system}.pie;
          pie = { type = "app"; program = "${p.pie}/bin/pie"; };
        });

      # ---- Dev shell: `nix develop` --------------------------------------
      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          p = self.packages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [ p.pie ];
            shellHook = ''
              echo ""
              echo "  Pie dev shell"
              echo "  ────────────────────────────────────────────"
              echo "  pie              start a Pie REPL (racket -l pie -i)"
              echo "  racket foo.pie   run a #lang pie file"
              echo ""
            '';
          };
        });

      # Overlay for other flakes: adds `pkgs.pie`.
      overlays.default = final: prev: {
        pie = final.callPackage ./nix/pie.nix { inherit pie-src; };
      };
    };
}

{
  description = "Pie — the dependently-typed language from *The Little Typer* — packaged for Nix, with Emacs & Neovim setups";

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
      # ---- Packages -------------------------------------------------------
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          pie = pkgs.callPackage ./nix/pie.nix { inherit pie-src; };
          pie-emacs = pkgs.callPackage ./nix/emacs.nix { inherit pie; };
          pie-neovim = pkgs.callPackage ./nix/neovim.nix { inherit pie; };
        in
        {
          inherit pie pie-emacs pie-neovim;
          default = pie;
        });

      # ---- Runnable apps: `nix run .#pie`, `.#emacs`, `.#neovim` ----------
      apps = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          p = self.packages.${system};
        in
        {
          default = self.apps.${system}.pie;
          pie = { type = "app"; program = "${p.pie}/bin/pie"; };
          emacs = { type = "app"; program = "${p.pie-emacs}/bin/pie-emacs"; };
          neovim = { type = "app"; program = "${p.pie-neovim}/bin/pie-nvim"; };
        });

      # ---- Dev shell: `nix develop` --------------------------------------
      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          p = self.packages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [ p.pie p.pie-emacs p.pie-neovim ];
            shellHook = ''
              echo ""
              echo "  Pie dev shell"
              echo "  ────────────────────────────────────────────"
              echo "  pie          start a Pie REPL (racket -l pie -i)"
              echo "  racket foo.pie   run a #lang pie file"
              echo "  pie-emacs foo.pie   open in Emacs (racket-mode)"
              echo "  pie-nvim  foo.pie   open in Neovim"
              echo ""
            '';
          };
        });

      # ---- Home Manager module -------------------------------------------
      # Usage in your HM config:
      #   imports = [ pie.homeManagerModules.default ];
      #   programs.pie = { enable = true; emacs.enable = true; neovim.enable = true; };
      homeManagerModules.default = import ./nix/hm-module.nix self;
      homeManagerModules.pie = self.homeManagerModules.default;

      # Convenience: `nix fmt`-friendly and overlay for other flakes.
      overlays.default = final: prev: {
        pie = final.callPackage ./nix/pie.nix { inherit pie-src; };
      };
    };
}

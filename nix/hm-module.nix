self:
{ config, lib, pkgs, ... }:

# Home Manager module for Pie.
#
#   imports = [ inputs.pie.homeManagerModules.default ];
#   programs.pie = {
#     enable = true;
#     emacs.enable  = true;   # racket-mode integration
#     neovim.enable = true;   # ftdetect + syntax + :PieRun / :PieRepl
#   };
#
# By default the editor options install the self-contained `pie-emacs` /
# `pie-nvim` launchers. If you already manage Emacs/Neovim through Home Manager
# (`programs.emacs` / `programs.neovim`), set `integrate = true` on that editor
# to weave Pie support into your existing configuration instead.

let
  inherit (lib) mkEnableOption mkOption mkIf types mkMerge optionals;
  system = pkgs.stdenv.hostPlatform.system;
  piePkgs = self.packages.${system};
in
{
  options.programs.pie = {
    enable = mkEnableOption "the Pie language (from The Little Typer)";

    package = mkOption {
      type = types.package;
      default = piePkgs.pie;
      description = "The Pie package to install (provides `pie`, and pie-aware `racket`/`raco`).";
    };

    emacs = {
      enable = mkEnableOption "Emacs support for Pie (racket-mode)";
      integrate = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Weave Pie into your existing Home Manager `programs.emacs`
          (adds racket-mode + `#lang pie` wiring) instead of installing the
          standalone `pie-emacs` launcher.
        '';
      };
    };

    neovim = {
      enable = mkEnableOption "Neovim support for Pie";
      integrate = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Weave Pie into your existing Home Manager `programs.neovim`
          (adds the Pie filetype/syntax plugin + :PieRun / :PieRepl) instead of
          installing the standalone `pie-nvim` launcher.
        '';
      };
    };
  };

  config = mkIf config.programs.pie.enable (mkMerge [
    # Always install the core Pie package.
    { home.packages = [ config.programs.pie.package ]; }

    # ---- Emacs ---------------------------------------------------------
    (mkIf (config.programs.pie.emacs.enable && !config.programs.pie.emacs.integrate) {
      home.packages = [ piePkgs.pie-emacs ];
    })
    (mkIf (config.programs.pie.emacs.enable && config.programs.pie.emacs.integrate) {
      programs.emacs.extraPackages = epkgs: [ epkgs.racket-mode ];
      programs.emacs.extraConfig = ''
        ;; --- Pie support (added by programs.pie) ---
        (with-eval-after-load 'racket-mode
          (setq racket-program "${config.programs.pie.package}/bin/racket"))
        (add-to-list 'auto-mode-alist '("\\.pie\\'" . racket-mode))
      '';
    })

    # ---- Neovim --------------------------------------------------------
    (mkIf (config.programs.pie.neovim.enable && !config.programs.pie.neovim.integrate) {
      home.packages = [ piePkgs.pie-neovim ];
    })
    (mkIf (config.programs.pie.neovim.enable && config.programs.pie.neovim.integrate) {
      programs.neovim.plugins = [
        (pkgs.vimUtils.buildVimPlugin {
          pname = "pie-nvim";
          version = "0.1";
          src = self + "/editors/nvim";
        })
      ];
      programs.neovim.extraLuaConfig = ''
        vim.g.pie_racket = "${config.programs.pie.package}/bin/racket"
      '';
    })
  ]);
}

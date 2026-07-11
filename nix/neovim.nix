{ lib
, neovim
, vimUtils
, makeWrapper
, runCommand
, pie
}:

# Neovim configured for Pie: filetype detection for *.pie, syntax highlighting,
# and :PieRun / :PieRepl commands wired to the pie-aware Racket. Exposed as
# `pie-nvim`, which starts an isolated Neovim (its own config dir) so it doesn't
# touch the user's own setup.

let
  # Package the editors/nvim runtime dir as a Vim plugin so ftdetect/syntax/
  # ftplugin all land on the runtimepath.
  piePlugin = vimUtils.buildVimPlugin {
    pname = "pie-nvim";
    version = "0.1";
    src = ../editors/nvim;
  };

  # Minimal init that loads the plugin and pins the Racket path.
  initLua = ''
    vim.g.mapleader = " "
    vim.g.maplocalleader = ","
    vim.g.pie_racket = "${pie}/bin/racket"
    vim.opt.runtimepath:prepend("${piePlugin}")
    vim.cmd("syntax on")
    vim.cmd("filetype plugin indent on")
  '';

  customNeovim = neovim.override {
    configure = {
      customRC = ''
        lua << EOF
        ${initLua}
        EOF
      '';
      packages.pie.start = [ piePlugin ];
    };
  };
in
runCommand "pie-nvim"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      description = "Neovim preconfigured for the Pie language";
      mainProgram = "pie-nvim";
    };
  }
  ''
    mkdir -p "$out/bin"
    makeWrapper ${customNeovim}/bin/nvim "$out/bin/pie-nvim" \
      --prefix PATH : "${pie}/bin"
  ''

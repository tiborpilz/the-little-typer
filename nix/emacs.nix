{ lib
, emacsPackagesFor
, emacs
, makeWrapper
, runCommand
, pie
}:

# A self-contained Emacs preloaded with racket-mode and a Pie init file.
# Exposes `pie-emacs`, which launches an isolated Emacs (emacs -Q) so it never
# interferes with the user's own configuration. `racket-program` is pinned to
# the pie-aware Racket wrapper from the `pie` package, so `racket-run` can load
# `#lang pie` immediately.

let
  emacsWithRacket = (emacsPackagesFor emacs).emacsWithPackages
    (epkgs: [ epkgs.racket-mode ]);

  initEl = ../editors/pie-init.el;
in
runCommand "pie-emacs"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      description = "Emacs preconfigured with racket-mode for the Pie language";
      mainProgram = "pie-emacs";
    };
  }
  ''
    mkdir -p "$out/bin" "$out/share/pie-emacs"
    cp ${initEl} "$out/share/pie-emacs/pie-init.el"

    # Bake the pie-aware racket path into the init so racket-run always finds pie.
    cat >> "$out/share/pie-emacs/pie-init.el" <<EOF

;; Injected by Nix: use the pie-aware Racket so #lang pie resolves anywhere.
(setq racket-program "${pie}/bin/racket")
EOF

    makeWrapper ${emacsWithRacket}/bin/emacs "$out/bin/pie-emacs" \
      --add-flags "-Q -l $out/share/pie-emacs/pie-init.el" \
      --prefix PATH : "${pie}/bin"
  ''

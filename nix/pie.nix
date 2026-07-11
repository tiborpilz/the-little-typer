{ lib
, stdenv
, racket        # full Racket distribution — pie needs gui-lib, slideshow, typed-racket, etc.
, makeWrapper
, pie-src
}:

# Pie is a Racket *collection* package (its info.rkt declares
# `(define collection "pie")`). Every one of its runtime dependencies
# (data-lib, gui-lib, slideshow-lib, pict-lib, typed-racket, parser-tools,
# syntax-color, rackunit) ships inside the full `racket` distribution, so we
# don't need any package-server access at all.
#
# The build simply:
#   1. copies the source into a private collection root ($out/share/pie-collects/pie)
#   2. compiles it to bytecode with `raco setup` (offline, no network)
#   3. installs `racket` / `raco` wrappers that put that collection root on
#      PLTCOLLECTS, plus a `pie` launcher = `racket -l pie -i`.
#
# The trailing colon in PLTCOLLECTS ("<root>:") is load-bearing: an empty entry
# tells Racket to *also* include its built-in collections. Without it, Racket
# would see only Pie and nothing else.

stdenv.mkDerivation (finalAttrs: {
  pname = "pie";
  version = "0.01-unstable-2021-07-07";

  src = pie-src;

  nativeBuildInputs = [ racket makeWrapper ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    collects="$out/share/pie-collects"
    mkdir -p "$collects/pie"
    cp -r ./. "$collects/pie/"
    # In case the source tree carried any stale build artifacts:
    find "$collects/pie" -type d -name compiled -exec rm -rf {} + 2>/dev/null || true

    # Compile to bytecode. Use throwaway HOME/addon dirs so nothing tries to
    # touch the real user profile during the build.
    export HOME="$TMPDIR/pie-build-home"
    export PLTADDONDIR="$TMPDIR/pie-build-addon"
    mkdir -p "$HOME" "$PLTADDONDIR"
    export PLTCOLLECTS="$collects:"
    raco setup --no-docs -l pie

    mkdir -p "$out/bin"

    # Pie-aware racket / raco: they behave exactly like upstream but can also
    # load `#lang pie`. Safe to put on PATH in a dev shell.
    # PLT_COMPILED_FILE_CHECK=exists tells Racket to trust the bytecode we
    # already compiled into the (read-only) store, instead of comparing
    # timestamps and trying to recompile into a path it can't write to.
    makeWrapper ${racket}/bin/racket "$out/bin/racket" \
      --prefix PLTCOLLECTS : "$collects:" \
      --set-default PLT_COMPILED_FILE_CHECK exists
    makeWrapper ${racket}/bin/raco "$out/bin/raco" \
      --prefix PLTCOLLECTS : "$collects:" \
      --set-default PLT_COMPILED_FILE_CHECK exists

    # `pie` — drop straight into a Pie REPL.
    makeWrapper "$out/bin/racket" "$out/bin/pie" \
      --add-flags "-l pie -i"

    runHook postInstall
  '';

  # Smoke test baked into the build: prove the REPL loads and normalizes.
  doInstallCheck = true;
  installCheckPhase = ''
    echo '(the Nat (add1 (add1 zero)))' | "$out/bin/pie" | grep -q 'the Nat 2' \
      && echo "pie REPL OK"
  '';

  passthru = {
    # Where the compiled collection lives, in case another derivation wants to
    # add it to its own PLTCOLLECTS.
    collectionRoot = "${finalAttrs.finalPackage}/share/pie-collects";
  };

  meta = with lib; {
    description = "A little dependently-typed language to accompany *The Little Typer*";
    longDescription = ''
      Pie is the companion language for the book *The Little Typer* by Daniel P.
      Friedman and David Thrane Christiansen. It is implemented as a Racket
      `#lang`, so any file beginning with `#lang pie` is interpreted as a Pie
      program. This package provides a `pie` REPL launcher and pie-aware
      `racket`/`raco` wrappers.
    '';
    homepage = "https://github.com/the-little-typer/pie";
    license = licenses.agpl3Plus; # upstream COPYING is GNU AGPL v3
    mainProgram = "pie";
    platforms = platforms.unix;
  };
})

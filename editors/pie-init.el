;;; pie-init.el --- Minimal Emacs setup for the Pie language -*- lexical-binding: t; -*-
;;
;; Loaded by the `pie-emacs` launcher (emacs -Q -l pie-init.el).  It wires up
;; racket-mode — the most mature editor integration for Racket `#lang`s — so
;; that `#lang pie` files get syntax highlighting, indentation, and a live REPL.
;;
;; Key bindings (from racket-mode):
;;   C-c C-c / C-c C-k   racket-run          — load the buffer into a Pie REPL
;;   C-c C-z             racket-repl          — jump to / from the REPL
;;   C-c C-d             racket-xp-documentation (when racket-xp-mode is on)
;;
;; The `racket-program' is pinned at build time to the pie-aware Racket wrapper,
;; so `racket-run' can resolve `#lang pie' even outside a dev shell.

;;; Code:

(require 'racket-mode)

;; Open .pie files in racket-mode.
(add-to-list 'auto-mode-alist '("\\.pie\\'" . racket-mode))

;; Treat `#lang pie` buffers as racket-mode too (belt and suspenders).
(add-hook 'racket-mode-hook
          (lambda ()
            ;; Extra background analysis: identifier highlighting, docs, jumps.
            (racket-xp-mode 1)
            (setq-local tab-width 2)))

;; A couple of quality-of-life defaults for a demo editor.
(setq inhibit-startup-screen t)
(show-paren-mode 1)
(electric-pair-mode 1)
(column-number-mode 1)

;; Friendly scratch message so first-time users know what to do.
(setq initial-scratch-message
      ";; Pie + Emacs (racket-mode)\n\
;; Open a .pie file, then C-c C-c to run it in a Pie REPL.\n\n")

(provide 'pie-init)
;;; pie-init.el ends here

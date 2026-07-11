" Filetype settings for Pie.
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

setlocal lisp
setlocal commentstring=;\ %s
setlocal comments=:;
setlocal expandtab
setlocal shiftwidth=2
setlocal softtabstop=2

" Which racket to use. The Nix-built `pie-nvim` sets g:pie_racket to the
" pie-aware Racket wrapper; otherwise we fall back to whatever's on $PATH.
if !exists("g:pie_racket")
  let g:pie_racket = "racket"
endif

" :PieRun — run the current file with #lang pie.
command! -buffer PieRun  execute "split | terminal " . g:pie_racket . " " . shellescape(expand("%:p"))

" :PieRepl — open an interactive Pie REPL in a terminal split.
command! -buffer PieRepl execute "split | terminal " . g:pie_racket . " -l pie -i"

" Handy local mappings (only in Pie buffers).
nnoremap <buffer> <localleader>r :PieRun<CR>
nnoremap <buffer> <localleader>i :PieRepl<CR>

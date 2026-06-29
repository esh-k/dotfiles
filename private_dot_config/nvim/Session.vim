let SessionLoad = 1
let s:so_save = &g:so | let s:siso_save = &g:siso | setg so=0 siso=0 | setl so=-1 siso=-1
let v:this_session=expand("<sfile>:p")
doautoall SessionLoadPre
let NvimTreeSetup =  1 
let NvimTreeRequired =  1 
silent only
silent tabonly
cd ~/.config/nvim_test
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
let s:shortmess_save = &shortmess
set shortmess+=aoO
badd +1 lua/plugins/dap.lua
badd +29 requirements.md
badd +149 progress.md
badd +23 init.lua
badd +1 ~/.config/nvim_test/lua/plugins/lsp.lua
badd +18 lua/configs/search_history.lua
badd +92 lua/plugins/telescope.lua
badd +8 lua/options.lua
badd +33 lua/mappings.lua
badd +59 lua/plugins/nvimtree.lua
badd +105 lua/plugins/init.lua
badd +10 lua/configs/lga_quote.lua
badd +45 lua/configs/conform.lua
badd +12 lua/configs/lazy.lua
badd +1786 /opt/homebrew/Cellar/neovim/0.12.3/share/nvim/runtime/lua/vim/lsp/util.lua
badd +3 Grug\ FAR\ -\ 1:\ number
badd +8 Grug\ FAR\ -\ 2:\ number
badd +3 Grug\ FAR\ -\ 3
badd +1 Grug\ FAR\ -\ 4:\ sdlkf
badd +84 lua/plugins/jupyter.lua
argglobal
%argdel
edit lua/plugins/init.lua
argglobal
balt requirements.md
setlocal foldmethod=manual
setlocal foldexpr=v:lua.vim.treesitter.foldexpr()
setlocal foldmarker={{{,}}}
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldenable
silent! normal! zE
let &fdl = &fdl
let s:l = 105 - ((18 * winheight(0) + 32) / 65)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 105
normal! 09|
tabnext 1
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0 && getbufvar(s:wipebuf, '&buftype') isnot# 'terminal'
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20
let &shortmess = s:shortmess_save
let s:sx = expand("<sfile>:p:r")."x.vim"
if filereadable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &g:so = s:so_save | let &g:siso = s:siso_save
set hlsearch
nohlsearch
let g:this_session = v:this_session
let g:this_obsession = v:this_session
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :

syntax on
set nu
set autoindent
set smartindent
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4

" STATUSLINE
" http://stackoverflow.com/questions/5375240/a-more-useful-statusline-in-vim
" http://got-ravings.blogspot.com/2008/08/vim-pr0n-making-statuslines-that-own.html
" https://github.com/scrooloose/vimfiles/blob/master/vimrc
" http://vimdoc.sourceforge.net/htmldoc/options.html#'statusline'
set laststatus=2         " always show status line

set statusline=%t        " filename
set statusline+=%r       " read only flag
set statusline+=%m       " modified flag ('+' if modified)

set statusline+=[%{strlen(&fenc)?&fenc:'none'}, "file encoding (utf-8)
set statusline+=%{&ff}]  " file format (unix)

set statusline+=%y       " file type (python)
set statusline+=%=       " right align the rest
set statusline+=%l,      " cursor line
set statusline+=%c       " cursor column
set statusline+=/%L      " total lines in file
set statusline+=(%p%%)   " percent through file at cursor
" END STATUSLINE

function Load_if_readable(file)
	" echo 'Loading machine specific config: '.a:file
	if filereadable(a:file)
		exec 'source '.fnameescape(a:file)
		" echo 'Successfully loaded '.a:file
	else
		" echo a:file.' not found'
	endif
endfunction

call Load_if_readable($HOME.'/.config/machine_specific/.vimrc')

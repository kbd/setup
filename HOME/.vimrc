syntax on
set nu
set autoindent
set smartindent
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4

function Load_if_readable(file)
	" echo 'Loading machine specific config: '.a:file
	if filereadable(a:file)
	    exec 'source '.fnameescape(a:file)
	    " echo 'Successfully loaded '.a:file
	else
	    " echo a:file.' not found'
	endif
endfunction

call Load_if_readable($HOME.'/.vimrc_machine_specific')

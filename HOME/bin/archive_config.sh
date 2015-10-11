#!/usr/bin/env bash

# disable-copyfile prevents getting extended attribute files on mac
# -L to resolve symbolic links
tar czv -L -f ~/config.tar.gz \
--exclude-from ~/.gitignore_global \
--disable-copyfile \
-C ~ \
 bin/ \
 .bash_profile \
 .inputrc \
 .gitconfig \
 .gitignore_global \
 .hgrc \
 .hgignore_global \
 .subversion/config \
 .screenrc \
 .vimrc

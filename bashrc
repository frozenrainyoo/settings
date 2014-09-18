#!/bin/bash

emacs_daemon() {
	if [ "$1" = "" ]; then
		emacs --daemon
	else
		emacs --daemon=$1
	fi
}

emacs_client() {
	if [ "$1" = "" ]; then
		emacsclient -nw --eval "(init-faces)"
	else
		emacsclient -nw --eval "(init-faces)" -f $1
	fi
}

emacs_client_frame() {
	if [ "$1" = "" ]; then
		emacsclient -c --eval "(init-faces)"
	else
		emacsclient -c --eval "(init-faces)" -f $1
	fi
}

export TERM=xterm-256color
export PS1="\[\033[01;32m\]\u@\h:\w\$(git branch 2>/dev/null | grep -e '\* ' | sed 's/^..\(.*\)/{\1}/')\[\033[00m\]\$ "

alias e='emacs_client'
alias ec='emacs_client_frame'
alias en='emacs -nw'
alias es='emacs_daemon'
alias grep='grep --color=auto'
alias g='git'
alias gbl='git blame'
alias gbr='git branch'
alias gd='git diff'
alias gl='git log'
alias gpush='git push'
alias gpull='git pull'
alias gs='git status'
alias gsh='git show'

dir="$(dirname ${BASH_SOURCE[0]})"
export PATH=$PATH:$dir

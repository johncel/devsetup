# .bashrc

# User specific aliases and functions

alias rm='rm'
alias cp='cp'
alias mv='mv'

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

export PATH=/opt/centos/devtoolset-1.1/root/usr/bin/:$PATH

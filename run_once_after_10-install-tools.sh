#!/bin/sh

INSTALL="$HOME/.local"
PATH="$PATH:$INSTALL/bin"

# terminfo
echo "INFO: compiling kitty-terminfo"
curl -fsSL https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/kitty.terminfo \
    | tic -x /dev/stdin

# zsh
echo "INFO: installing zsh"
curl -fsLS https://raw.githubusercontent.com/romkatv/zsh-bin/master/install \
    | sh -s -- -d $INSTALL -e no

# zplug
echo "INFO: installing zplug and plugins"
if [ ! -f ~/.zplug/init.zsh ]; then
    curl -fsLS https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
fi
zsh -ic 'zplug install'

# ranger
echo "INFO: installing ranger-fm"
if python3 -m venv --help >/dev/null 2>&1; then
    python3 -m venv $INSTALL/opt/ranger
    $INSTALL/opt/ranger/bin/python -m pip install -U pip
    $INSTALL/opt/ranger/bin/python -m pip install ranger-fm

    mkdir -p $INSTALL/bin
    ln -fs $INSTALL/opt/ranger/bin/ranger $INSTALL/bin/ranger
else
    echo "ERROR: ranger-fm not installed because python-venv is not available"
fi

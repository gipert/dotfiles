#!/bin/sh

PATH="$PATH:$HOME/.local/bin"

# zsh
curl -fsLS https://raw.githubusercontent.com/romkatv/zsh-bin/master/install \
    | sh -s -- -d ~/.local -e no

# zplug
curl -fsLS https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh

source ~/.zplug/init.zsh

# ranger
python3 -m pip install --user pipx
pipx run --spec ranger-fm ranger

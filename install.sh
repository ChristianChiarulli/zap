#!/bin/zsh

USR=$1
DEFAULT='zap-zsh'
main() {
    git clone "https://github.com/${USR:-$DEFAULT}/zap.git" "$HOME/.local/share/zap" > /dev/null 2>&1
    mkdir -p "$HOME/.local/share/zap/plugins"

    ###tis is a test

    # check if ZDOTDIR is set, and if it is, check if ZDOTDIR/.zshrc exists
    if [ -n "$ZDOTDIR" ] && [ -f "$ZDOTDIR/.zshrc" ]; then
        zshrc="$ZDOTDIR/.zshrc"
    else
        zshrc="$HOME/.zshrc"
    fi
    touch "$zshrc"

    # shellcheck disable=SC2016
    if ! grep -q '[ -f "$HOME/.local/share/zap/zap.zsh" ] && source "$HOME/.local/share/zap/zap.zsh"' "$zshrc"; then
        sed -i '1 i[ -f "$HOME/.local/share/zap/zap.zsh" ] && source "$HOME/.local/share/zap/zap.zsh"' "$zshrc"
    fi
}

main
echo " Zapped"

# vim: ft=bash ts=4 et

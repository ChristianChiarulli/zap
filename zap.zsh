#!/bin/sh

export ZAP_DIR="$HOME/.local/share/zap"
export ZAP_PLUGIN_DIR="$ZAP_DIR/plugins"

_try_source() {
    # shellcheck disable=SC1090
    [ -f "$1" ] && source "$1"
}

plug() {
    plugin="$1"
    if [ -f "$plugin" ]; then
        source "$plugin"
    else
        local full_plugin_name="$1"
        local git_ref="$2"
        local plugin_name=$(echo "$full_plugin_name" | cut -d "/" -f 2)
        local plugin_dir="$ZAP_PLUGIN_DIR/$plugin_name"
        if [ ! -d "$plugin_dir" ]; then
            echo "🔌$plugin_name"
            git clone "https://github.com/${full_plugin_name}.git" "$plugin_dir" > /dev/null 2>&1
            if [ -n "$git_ref" ]; then
                git -C "$plugin_dir" checkout "$git_ref" > /dev/null 2>&1
            fi
            if [ $? -ne 0 ]; then
                echo "Failed to install $plugin_name"
                exit 1
            fi
            echo -e "\e[1A\e[K⚡$plugin_name"
        fi
        _try_source "$plugin_dir/$plugin_name.plugin.zsh"
        _try_source "$plugin_dir/$plugin_name.zsh"
        _try_source "$plugin_dir/$plugin_name.zsh-theme"
    fi
}

_pull() {
    _is_repo=$(ls .git > /dev/null 2>&1 && echo "T" || echo "F")
    if [[ $_is_repo == "T" ]]; then
      echo "🔌$1"; git pull > /dev/null 2>&1
      if [ $? -ne 0 ]; then
          echo "Failed to Update $1"; exit 1
      fi
      echo -e "\e[1A\e[K⚡$1";
    else
      for plug in *; do
        cd $plug; echo "🔌$plug"; git pull > /dev/null 2>&1;
        if [ $? -ne 0 ]; then
            echo "Failed to Update $plug"; exit 1
        fi
        echo -e "\e[1A\e[K⚡$plug"; cd "$ZAP_PLUGIN_DIR/$1";
      done
    fi
}

update() {
    echo -e " 0  ⚡ Zap"
    plugins=$(awk 'BEGIN { FS = "[ plug]" } { print }' $ZDOTDIR/.zshrc | grep -E 'plug "' | awk 'BEGIN { FS = "[ \"]" } { print " " int((NR)) echo "  🔌 " $3 }')
    echo "$plugins"; echo ""; echo -n "🔌 Plugin Number | (a) All Plugins | (0) ⚡ Zap Itself: "; read plugin; pwd=$(pwd); echo "";
    if [[ $plugin == "a" ]]; then
      cd "$ZAP_PLUGIN_DIR"
      for plug in *; do
        cd $plug; _pull $plug; cd "$ZAP_PLUGIN_DIR";
      done
      cd $pwd > /dev/null 2>&1
    elif [[ $plugin == "0" ]]; then
        cd "$ZAP_DIR"; _pull 'zap'; cd $pwd
    else
      for plug in $plugins; do
        selected=$(echo $plug | grep $plugin | awk 'BEGIN { FS = "[ /]" } { print $5"/"$6 }'); cd "$ZAP_PLUGIN_DIR/$selected"; _pull $selected; cd - > /dev/null 2>&1
      done
    fi
}

delete() {
    plugins=$(awk 'BEGIN { FS = "[ plug]" } { print }' $ZDOTDIR/.zshrc | grep -E 'plug "' | awk 'BEGIN { FS = "[ \"]" } { print " " int((NR)) echo "  🔌 " $3 }')
    echo "$plugins"; echo ""; echo -n "🔌 Plugin Number: "; read plugin; pwd=$(pwd); echo "";
    for plug in $plugins; do
      selected=$(echo $plug | grep $plugin | awk 'BEGIN { FS = "[ /]" } { print $5"/"$6 }'); rm -rf $ZAP_PLUGIN_DIR/$selected;
    done
}

pause() {
    ls -1 "$ZAP_PLUGIN_DIR"
    echo ""
    echo -n "Plugin Name or (a) to Update All: "
    read plugin
    if [[ $plugin == "a" ]]; then
        sed -i '/^plug/s/^/#/g' $ZDOTDIR/.zshrc
    else
        sed -i "/\/$plugin/s/^/#/g" $ZDOTDIR/.zshrc
    fi
}

unpause() {
    ls -1 "$ZAP_PLUGIN_DIR"
    echo ""
    echo -n "Plugin Name or (a) to Update All: "
    read plugin
    if [[ $plugin == "a" ]]; then
        sed -i '/^#plug/s/^#//g' $ZDOTDIR/.zshrc
    else
        sed -i "/\/$plugin/s/^#//g" $ZDOTDIR/.zshrc
    fi
}

Help() {
    cat "$ZAP_DIR/doc.txt"
}

Version() {
    ref=$ZAP_DIR/.git/packed-refs
    tag=$(awk 'BEGIN { FS = "[ /]" } { print $3, $4 }' $ref | grep tags)
    ver=$(echo $tag | cut -d " " -f 2)
    echo "⚡Zap Version v$ver"
}

zap() {
    local command="$1"
    if [[ $command == "-v" ]] || [[ $command == "--version" ]]; then
        Version
        return
    else
        if [[ $command == "-h" ]] || [[ $command == "--help" ]]; then
            Help
            return
        else
            $command
            return
        fi
        echo "$command: command not found"
    fi
}

# vim: ft=bash ts=4 et

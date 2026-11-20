fish_add_path --path $HOME/.rd/bin
fish_add_path --path $HOME/.krew/bin

set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx EDITOR nvim

if type -q zoxide
    zoxide init fish | source
end

# Commands to run in interactive sessions can go here
if status is-interactive
    if test -d "$HOMEBREW_PREFIX/share/fish/completions"
        set -p fish_complete_path "$HOMEBREW_PREFIX/share/fish/completions"
    end
    if test -d "$HOMEBREW_PREFIX/share/fish/vendor_completions.d"
        set -p fish_complete_path "$HOMEBREW_PREFIX/share/fish/vendor_completions.d"
    end
    alias gst="git status -s"
    alias ls="eza"
    alias l="eza --long --binary --git --classify"
    alias ll="eza --long --binary --git --classify --grid"
    alias co="git switch"
    #alias gco="git branch --sort=-committerdate | fzf --header \"Checkout Recent Branch\" --preview \"git diff --color=always {1} | delta\" --pointer=\"\" | xargs git switch"
    alias gco="git switch (git branch --sort=-committerdate --format '%(refname:short)' | fzf --header \"Checkout Recent Branch\" --preview \"git diff --color=always {1} | delta\" --pointer=\"\")"
    alias c="cd (fd -gHt d .git ~/src | xargs dirname | fzf)"
    starship init fish | source
    set -gx SHELL "$HOMEBREW_PREFIX/bin/fish"
    alias vim="nvim"
    bind -M insert -m default \co 'cd (fd -gHt d .git ~/src | xargs dirname | fzf)'
    bind -M insert -m default \cr 'history | fzf'
end

# mise: activation at the prompt, shims for scripts (what
# `[bootstrap.mise_shell_activate] fish = "auto"` would write into config.fish)
if type -q mise
    if status is-interactive
        mise activate fish | source
    else
        mise activate fish --shims | source
    end
end

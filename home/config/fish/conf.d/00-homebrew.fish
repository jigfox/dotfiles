for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew
    if test -x $brew_bin
        $brew_bin shellenv fish | source
        break
    end
end

# path_helper copies /etc/paths.d verbatim, and an installer may write a
# relative entry there (dotnet: "~/.dotnet/tools"). A relative entry is
# resolved from the current directory, so a sandboxed agent that can write
# there could plant commands for the unsandboxed shell: keep only absolute ones.
set -gx PATH (string match -- '/*' $PATH)

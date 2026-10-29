for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew
    if test -x $brew_bin
        $brew_bin shellenv fish | source
        break
    end
end

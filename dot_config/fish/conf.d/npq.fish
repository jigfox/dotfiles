if type -q npq-hero
    if type -q npm
        alias npm="npq-hero"
    end
    if type -q yarn
        alias yarn="NPQ_PKG_MGR=yarn npq-hero"
    end
    if type -q pnpm
        alias pnpm="NPQ_PKG_MGR=pnpm npq-hero"
    end
end

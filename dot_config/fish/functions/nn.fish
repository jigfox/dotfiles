function nn --description "Run package manager based on lockfiles, fail on conflict"
    # Define candidates: "command:lockfile"
    set -l candidates pnpm:pnpm-lock.yaml yarn:yarn.lock npm:package-lock.json

    set -l best_cmd npm # Default fallback
    set -l best_dir_len -1 # Start lower than any real path length
    set -l conflict 0 # Flag to track collisions

    for candidate in $candidates
        set -l cmd (string split ":" $candidate)[1]
        set -l lockfile (string split ":" $candidate)[2]

        # Search for the lockfile
        set -l file_path (upfind $lockfile 2>/dev/null)

        if test -n "$file_path"
            # Get the directory path (ignoring the filename length)
            set -l dir_path (dirname "$file_path")
            set -l dir_len (string length "$dir_path")

            if test $dir_len -gt $best_dir_len
                # We found a lockfile deeper (closer) than previous matches
                set best_dir_len $dir_len
                set best_cmd $cmd
                set conflict 0 # Reset conflict because we found a 'better' match
            else if test $dir_len -eq $best_dir_len
                # We found a DIFFERENT lockfile at the SAME depth
                set conflict 1
            end
        end
    end

    # Handle the result
    if test $conflict -eq 1
        echo "Error: Ambiguous configuration. Multiple lockfiles found at the same directory level."
        echo "Please delete one or run the package manager directly."
        return 1
    end

    # Execute the winner
    $best_cmd $argv
end

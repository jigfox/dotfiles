function upfind --description "Search for a file/folder upwards from current directory"
    # Check if an argument is provided
    if test (count $argv) -eq 0
        echo "Usage: upfind <filename>"
        return 1
    end

    set -l filename $argv[1]
    set -l current_dir $PWD

    # Loop until we have checked the root directory
    while true
        # Check if the file exists in the current directory iteration
        if test -e "$current_dir/$filename"
            echo "$current_dir/$filename"
            return 0
        end

        # If we are at root and haven't found it, break and fail
        if test "$current_dir" = /
            break
        end

        # Move up one directory
        set current_dir (dirname "$current_dir")
    end

    # If the loop finishes without returning, the file wasn't found
    return 1
end

function e
    argparse w/wait -- $argv
    or return
    set socket_folder ~/.local/share/nvim/sockets
    mkdir -p $socket_folder
    set git_dir (upfind .git)
    set git_dir_hash (echo $git_dir | md5 )
    set socket_file {$socket_folder}/{$git_dir_hash}.sock
    if set -q _flag_wait
        nvim $argv
        return $status
    end
    if test -S $socket_file
        neovide -- --server $socket_file --remote $argv
    else
        neovide --fork $argv -- --listen $socket_file
    end
end

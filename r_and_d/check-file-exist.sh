bin_file_to_remove="/usr/local/bin/node_exporter"

    if [ -e "$bin_file_to_remove" ]; then
        # rm "$bin_file_to_remove"
        echo "File '$bin_file_to_remove' has been removed."
    else 
    echo "does not exist"
    fi
#!/bin/bash

function is_port_occupied() {
    # Get the port number from the user
    port=$1

    # Use the lsof command to check if the port is in use
    lsof -i :"$port"

    # If the port is in use, return 0
    if [[ $? -eq 0 ]]; then
        return 0
    fi

    # If the port is not in use, return 1
    return 1
}
take_input_unitill_right_port() {
    #!/bin/bash

    # Get the port number from the user
    echo "Enter the port number: "
    read port

    # Check if the port is occupied
    while is_port_occupied $port; do
        echo "Port $port is occupied. Please enter a different port: "
        read port
    done
    # If the port is not in use, print "Port is not occupied"
    echo "Port $port is not occupied"
    return 1
}

# Fetch the system's architecture and save it to a variable
system_architecture=$(dpkg --print-architecture)

# Download and Install

removeAllreadyExistedFolder() {
    #!/bin/bash

    # Remove the node_exporter configuration directory
    sudo rm -r /etc/node_exporter

    # Remove all files and directories named node_exporter
    sudo rm -r node_exporter*

    # Stop the node_exporter service
    sudo systemctl stop node_exporter_bgjhsfjhjhsfskdf

    # Print a message
    echo "after trying to stop"

    # Remove the node_exporter systemd unit file
    sudo rm -r /etc/systemd/system/node_exporter_limonnnnnnnnnnnnn*

    # Print a message
    echo "ok"
}

downloadAndInstall() {
    removeAllreadyExistedFolder
    download_link="https://github.com/prometheus/node_exporter/releases/download/v$selected_version/node_exporter-$selected_version.linux-$system_architecture.tar.gz"
    echo 'download link is: '$download_link
    wget $download_link
    # Extract
    tar xvfz node_exporter-*.*-$system_architecture.tar.gz
    # save into a variable for future use
    created_folder=node_exporter-$selected_version.linux-$system_architecture
    moveDownloadedFile
}

moveDownloadedFile() {

    sudo touch $created_folder/config.yml
    sudo mkdir /etc/node_exporter
    sudo mv $created_folder/node_exporter* /usr/local/bin
    mv $created_folder /etc/node_exporter
}
# List of available version numbers
available_versions=("1.3.1" "1.6.1")

# Prompt the user to select a version
echo "Select a version:"
for i in "${!available_versions[@]}"; do
    echo "$((i + 1)) -  ${available_versions[i]}"
done

read -p "Enter the number of the version you want to use: " selected_version_index

# Check if the user input is a valid index
if [[ "$selected_version_index" =~ ^[0-9]+$ && "$selected_version_index" -ge 1 && "$selected_version_index" -le "${#available_versions[@]}" ]]; then
    selected_version="${available_versions[selected_version_index - 1]}"
    # echo "You selected version $selected_version"
    # download_link="https://github.com/prometheus/node_exporter/releases/download/v$selected_version/node_exporter-$selected_version.linux-$system_architecture.tar.gz"
    # echo $download_link;
    # download_link = "https://github.com/prometheus/node_exporter/releases/download/v$selected_version/node_exporter-$selected_version.linux-$system_architecture.tar.gz"
    # echo 'download link is: '$download_link

    downloadAndInstall
    take_input_unitill_right_port
else
    echo "Invalid input. Please select a valid version."
    exit 1
fi

# Display the system's architecture
echo "System architecture: $system_architecture"

# Now you can use the selected_version in your script
# For example:
# if [ "$selected_version" = "3.3.1" ]; then
#     # Run code for version 3.3.1
# elif [ "$selected_version" = "3.6.1" ]; then
#     # Run code for version 3.6.1
# fi

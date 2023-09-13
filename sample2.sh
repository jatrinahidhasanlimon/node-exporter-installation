#!/bin/bash

# Fetch the system's architecture and save it to a variable
system_architecture=$(dpkg --print-architecture)

# check is port is occpied
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

#take port from user unitll its got right
function take_port_input_from_user() {
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

function is_already_installed() {
    # Get the status of the Apache2 service
    status=$(systemctl is-active apache2.service)

    # Return true if the service is active
    if [[ $status == "active" ]]; then
        return 0
    else
        return 0 ##need to change to 1 false
    fi
}

function remove_allready_existing_files_and_folder() {
    # Remove the node_exporter configuration directory
    sudo rm -r /etc/node_exporter
    # Remove all files and directories named node_exporter
    sudo rm -r node_exporter*
    # Stop the node_exporter service
    sudo systemctl stop node_exporter
    # Remove the node_exporter systemd unit file
    sudo rm -r /etc/systemd/system/node_exporter.service
}



function download_and_extract_necessary_files_and_folders() {
    # Display the system's architecture
    echo "\n System architecture: $system_architecture \n"
    download_link="https://github.com/prometheus/node_exporter/releases/download/v$selected_version/node_exporter-$selected_version.linux-$system_architecture.tar.gz"
    echo 'download link is: '$download_link
    #download from the github repository
    wget $download_link
    # Extract
    tar xvfz node_exporter-*.*-$system_architecture.tar.gz
}

function move_downloaded_files_and_folders() {
    #created folder is a combination of  selected version of node_exporter and system_architecture
    created_folder=node_exporter-$selected_version.linux-$system_architecture
    sudo touch $created_folder/config.yml
    sudo mkdir /etc/node_exporter
    sudo mv $created_folder/node_exporter* /usr/local/bin
    mv $created_folder/* /etc/node_exporter
}

function remove_downloaded_files_and_folders() {
    #created folder is a combination of  selected version of node_exporter and system_architecture
    sudo rm -r $created_folder;
}


function removeDownloaded_zip(){

}










# List of available version numbers
available_versions=("1.3.1" "1.6.1")

# Prompt the user to select a version
echo "Select a version:"
for i in "${!available_versions[@]}"; do
    echo "$((i + 1)) -  ${available_versions[i]}"
done

read -p "Enter the number of the version you want to use: " selected_version_index

#Check if the user input is a valid index

if [[ "$selected_version_index" =~ ^[0-9]+$ && "$selected_version_index" -ge 1 && "$selected_version_index" -le "${#available_versions[@]}" ]]; then
    selected_version="${available_versions[selected_version_index - 1]}"
    echo "You selected version is $selected_version "
    take_port_input_from_user
    echo "***is node exporter already checking......**"

    # Start Check if Node Exporter is already installed
    if is_already_installed; then
        # Ask the user if they want to remove the existing files and reinstall
        echo "Node Exporter is already installed. Do you want to remove the existing files and reinstall? (y/n)"
        read is_reinstall_answer
        # If the user is_reinstall_answers yes, remove the existing files and reinstall
        if [[ $is_reinstall_answer == "y" ]]; then

            echo "Removing existing files..."
            remove_allready_existing_files_and_folder
            echo "End of Removing existing files..."

            echo "Downloading files..."
            download_and_extract_necessary_files_and_folders
            echo "End of downloading files and extract..."

            echo "Moving extracted files..."
            move_downloaded_files_and_folders
            echo "End of moving extracted files..."

            echo "Removing unnecessary downloaded files and folder ..."
            remove_downloaded_raw_files_and_folders
            echo "Removing downloaded files and folder ..."
        fi
    else
        # Node Exporter is not installed, so do nothing
        echo "Node Exporter not installed."
    fi
    #End of Check if Node Exporter is already installed

    # download_and_extract_necessary_files_and_folders
else
    echo "Invalid input. Please select a valid version."
    exit 1
fi

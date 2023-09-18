#!/bin/bash
# ANSI color codes for text color
readonly green='\e[32m'
readonly red='\e[31m'
readonly reset='\e[0m'

readonly system_architecture=$(dpkg --print-architecture)
readonly available_versions=("1.3.1" "1.6.1")
readonly node_exporter_default_etc_directory="/etc/node_exporter"
readonly config_file_path="${node_exporter_default_etc_directory}/config.yml"
readonly bin_directory="/usr/local/bin"
readonly node_exporter_bin_file_path="${bin_directory}/node_exporter*"
readonly node_exporter_service_file_path="/etc/systemd/system/node_exporter.service"
readonly system_username="node_exporter"
readonly selected_version="1.6.1"

config_content=""

# Function to check if a port is in use
is_port_in_use() {
    local port="$1"
    ss -tuln | grep -q ":$port\b"
    return $?
}

# Function to validate the port
validate_port() {
    local port="$1"

    # Check if the port has any leading zeros
    if [[ "$port" =~ ^0[0-9]+$ ]]; then
        echo "Invalid port number. Port numbers cannot have leading zeros."
        return 2 # Exit with a custom code (not 0 or 1) when validation fails
    fi

    if [[ ! "$port" =~ ^[0-9]+$ || "$port" -lt 1 || "$port" -gt 65535 ]]; then
        echo "Invalid port number. Please enter a valid port (1-65535)."
        return 2 # Exit with a custom code (not 0 or 1) when validation fails
    fi

    is_port_in_use "$port"
    if [ $? -eq 0 ]; then
        echo "Port $port is already in use. Please choose a different port."
        return 2 # Exit with a custom code (not 0 or 1) when validation fails
    fi

    return 0
}

#take port from user unitll its got right
port_input_from_user_prompt() {
    # Ask the user for a valid and free port
    while true; do
        read -p "Enter a port number: " port
        validate_port "$port"
        if [ $? -eq 0 ]; then
            break
        fi
    done
}

remove_previous_installation_files_and_folder() {
    # Check if the directory exists
    if [ -d "$node_exporter_default_etc_directory" ]; then
        echo "Directory exists. Removing..."
        rm -r "$node_exporter_default_etc_directory"
    fi

    if [ -e "$node_exporter_bin_file_path" ]; then
        rm "$node_exporter_bin_file_path"
        echo "File '$node_exporter_bin_file_path' has been removed."
    fi

    if [ -e "node_exporter-$selected_version*" ]; then
        rm -r node_exporter-$selected_version*
        echo "File 'node_exporter-$selected_version*' has been removed."
    fi

    systemctl stop node_exporter

    if [ -e "$node_exporter_service_file_path" ]; then
        rm "$node_exporter_service_file_path"
        echo "File '$node_exporter_service_file_path' has been removed."
    fi
    # Create the directory
    mkdir -p "$node_exporter_default_etc_directory"

    echo "Directory created at $node_exporter_default_etc_directory"

    # Remove the node_exporter systemd unit file
}

download_and_extract_necessary_files_and_folders() {
    # Display the system's architecture
    download_link="https://github.com/prometheus/node_exporter/releases/download/v$selected_version/node_exporter-$selected_version.linux-$system_architecture.tar.gz"
    echo 'download link is: '$download_link
    #download from the github repository
    wget $download_link
    # Extract
    tar xvfz node_exporter-*.*-$system_architecture.tar.gz
}

move_extracted_files_and_folders() {
    #created folder is a combination of  selected version of node_exporter and system_architecture
    downloaded_directory=node_exporter-$selected_version.linux-$system_architecture

    mv $downloaded_directory/node_exporter* $bin_directory
    mv $downloaded_directory/* ${node_exporter_default_etc_directory}
}

create_system_user_and_give_permissions() {
    # Check if the user already exists if not create user
    if ! id "$system_username" &>/dev/null; then
        useradd -rs /bin/false $system_username
    fi
     sudo chown -R $system_username:$system_username ${node_exporter_default_etc_directory}

}

remove_downloaded_files_and_folders() {
    if [ -d "$downloaded_directory" ]; then
        rm -r $downloaded_directory*
    fi
}

create_systemd_service_file() {

    if [ -e "$node_exporter_service_file_path" ]; then
        rm "$node_exporter_service_file_path"
        echo "File'$node_exporter_service_file_path' has been removed."
    fi

    # Text to be written to the file
    content_of_service_file="[Unit]
    Description=Node Exporter
    After=network.target
    
    [Service]
    User=node_exporter
    Group=node_exporter
    Type=simple
    ExecStart=/usr/local/bin/node_exporter --web.config.file=${config_file_path} --web.listen-address=:$port
    [Install]
    WantedBy=multi-user.target"

    # Use redirection to create and write to the file
    echo "$content_of_service_file" >"$node_exporter_service_file_path"

    # Check if the file was created successfully
    if [ -e "$node_exporter_service_file_path" ]; then
        echo "File '$node_exporter_service_file_path' created and text written successfully."
    else
        echo "Error creating the file or writing text to $node_exporter_service_file_path."
    fi

}

ask_for_username_password_promt() {
    while true; do
        read -p "Enter a username: " username

        # Check if the username is not null
        if [ -n "$username" ]; then
            break
        else
            echo "Username cannot be empty. Please try again."
        fi
    done

    while true; do
        read -s -p "Enter a password (hashed, e.g., starting with '$1$'): " password
        echo # Print a newline after password input for better formatting

        # Check if the password is not null
        if [ -n "$password" ]; then
            if [[ "$password" == "$1$"* ]]; then
                break
            else
                echo "Password should start with '$1$'. Please try again."
            fi
        else
            echo "Password cannot be empty. Please try again."
        fi
    done

    echo "Username is: $username"
    echo "Password is: $password"

}

write_config_yml() {

    if [ -e "$config_file_path" ]; then
        rm "$config_file_path"
        echo "File'$config_file_path' has been removed."
    fi

    # Use redirection to create and write to the file
    echo "$config_content" >"$config_file_path"

    # Check if the file was created successfully
    if [ -e "$config_file_path" ]; then
        echo "File '$config_file_path' created and text written successfully."
    else
        echo "Error creating the file or writing text to $config_file_path."
    fi

}

user_installation_option_prompt() {
    PS3="Select an option: "
    installation_options=("Basic Installation" "Secured Installation")

    select selected_user_installation_option in "${installation_options[@]}"; do
        case $selected_user_installation_option in
        "Basic Installation")
            echo "Thank you for choosing Basic Installation."
            break
            ;;
        "Secured Installation")
            echo "Thank you for choosing Secured Installation."
            break
            ;;
        *)
            echo "Invalid choice. Please select a valid option."
            ;;
        esac
    done
}

run_all_daemon_systemctl_command() {
    systemctl daemon-reload
    systemctl enable node_exporter
    systemctl start node_exporter
    systemctl status node_exporter
}

install_from_scratch() {

    echo "Downloading files..."
    download_and_extract_necessary_files_and_folders
    echo "Files downloaded and extracted..."

    echo "Moving extracted files..."
    move_extracted_files_and_folders
    echo "End of moving extracted files..."

    echo "Removing downloaded files and folder ..."
    remove_downloaded_files_and_folders
    echo "Removed downloaded files and folder..."

    user_installation_option_prompt

    if [ -n "$selected_user_installation_option" ]; then

        if [ "$selected_user_installation_option" == "Basic Installation" ]; then
            echo "*** continue as Basic installation  *** "
        fi

        if [ "$selected_user_installation_option" == "Secured Installation" ]; then
            echo "*** continue as Secured installation  *** "
            # Text to be written to the file

            ask_for_username_password_promt

            config_content="
basic_auth_users:
  $username: $password"

        fi

        echo "Writing config file......"

        write_config_yml

        echo "*** Config file write done ***"

        echo "creating systemd file ... "
        #create systemd
        create_systemd_service_file

        echo "*** created systemd file"

        echo "creating a systemd user and giving persmission ............"

        create_system_user_and_give_permissions

        echo "*** End of creating a systemd user and giving persmission ***"

        echo "*** All daemon process reloading ***"

        run_all_daemon_systemctl_command

        echo "***all daemon process reloaded***"
    fi
}

welcome_prompt() {
    # Print a colorful welcome message
    echo -e "${green}###############################################${reset}"
    echo -e "${green}#        Welcome to Node Exporter Installer        #${reset}"
    echo -e "${green}###############################################${reset}"
    echo
    echo -e "Node Exporter Installable Version: ${selected_version}"
    echo -e "Your System Architecture: $system_architecture"
    echo -e "\n"


}

# starting main block

welcome_prompt

echo "is node exporter already installed in your system checking......"
# Start Check if Node Exporter is already installed
node_exporter_status=$(systemctl is-active node_exporter.service)
# Return true if the service is active
if [[ $node_exporter_status == "active" ]]; then

    # Ask the user if they want to remove the existing files and reinstall
    echo -e "${red}Node Exporter is already installed. Do you want to remove the existing files and reinstall? (y/n) ${reset}"
    read is_reinstall_answer
    # If the user is_reinstall_answers yes, remove the existing files and reinstall
    if [[ "${is_reinstall_answer,,}" == "y" || "${is_reinstall_answer,,}" == "yes" ]]; then

        echo "Removing existing files..."

        remove_previous_installation_files_and_folder

        echo "End of Removing existing files..."

    else
        echo "Exiting...."
        exit
    fi
else
 echo -e "${green}Couldn't found any node_exporter service in your machine! node exporter ${selected_version} installation continuing... \n ${reset}"
fi

mkdir -p "$node_exporter_default_etc_directory"

port_input_from_user_prompt

echo -e "${green}Installation starting ${reset}"
install_from_scratch
echo -e "${green}Installation Complete ${reset}"

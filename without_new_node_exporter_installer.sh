#!/bin/bash
# set -e
# Fetch the system's architecture and save it to a variable
# List of available version numbers
readonly available_versions=("1.3.1" "1.6.1")
readonly system_architecture=$(dpkg --print-architecture)
readonly node_exporter_default_etc_directory="/etc/node_exporter"
readonly config_file_path="${node_exporter_default_etc_directory}/config.yml"
readonly bin_directory="/usr/local/bin"
readonly bin_file_path="${bin_directory}/node_exporter*"
readonly temp_tls_certificates_directory="temp_tsl_certificates"
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

is_already_installed() {
    # Get the status of the Apache2 service
    status=$(systemctl is-active node_exporter.service)

    # Return true if the service is active
    if [[ $status == "active" ]]; then
        return 0
    else
        return 1 ##need to change
    fi
}

remove_allready_existing_files_and_folder() {
    # Remove the node_exporter configuration directory
    rm -r ${node_exporter_default_etc_directory}
    # Remove all files and directories named node_exporter
    rm -r node_exporter-$selected_version*
    # Stop the node_exporter service
    systemctl stop node_exporter
    # Remove the node_exporter systemd unit file
    rm -r /etc/systemd/system/node_exporter.service
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

    # Check if the directory exists
    if [ -d "$node_exporter_default_etc_directory" ]; then
        echo "Directory exists. Removing..."
        rm -r "$node_exporter_default_etc_directory"
    fi

    # Create the directory
    mkdir -p "$node_exporter_default_etc_directory"

    echo "Directory created at $node_exporter_default_etc_directory"

    #created folder is a combination of  selected version of node_exporter and system_architecture
    downloaded_directory=node_exporter-$selected_version.linux-$system_architecture

    if [ -e "$bin_file_path" ]; then
        rm "$bin_file_path"
        echo "File '$bin_file_path' has been removed."
    fi

    mv $downloaded_directory/node_exporter* $bin_directory
    mv $downloaded_directory/* ${node_exporter_default_etc_directory}
}

create_system_user_and_give_permissions() {
    useradd -rs /bin/false node_exporter
    sudo chown -R node_exporter:node_exporter ${node_exporter_default_etc_directory}
}

remove_downloaded_files_and_folders() {
    #created folder is a combinationof selected version of node_exporter and system_architecture
    if [ -d "$downloaded_directory" ]; then
        rm -r $downloaded_directory*
    fi
}

create_systemd_service_file() {
    service_file_path="/etc/systemd/system/node_exporter.service"

    if [ -e "$service_file_path" ]; then
        rm "$service_file_path"
        echo "File'$service_file_path' has been removed."
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
    echo "$content_of_service_file" >"$service_file_path"

    # Check if the file was created successfully
    if [ -e "$service_file_path" ]; then
        echo "File '$service_file_path' created and text written successfully."
    else
        echo "Error creating the file or writing text to $service_file_path."
    fi

}
ask_for_usernam_passwor_promt() {

    #!/bin/bash

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

is_crt_key_exist_in_node_exporter_folder() {
    directory="${node_exporter_default_etc_directory}" # Replace with the actual directory path
    cert_file="$directory/node_exporter.crt"
    key_file="$directory/node_exporter.key"

    if [ -e "$cert_file" ] && [ -e "$key_file" ]; then
        echo "Both files $cert_file and $key_file exist in the directory $directory."
    elif [ -e "$cert_file" ]; then
        echo "File $key_file does not exist in the directory $directory."
    elif [ -e "$key_file" ]; then
        echo "File $cert_file does not exist in the directory $directory."
    else
        echo "Exiting ..... Becusese Neither file $cert_file nor $key_file exists in the directory $directory."
        exit
    fi
}

run_all_daemon_systemctl_command() {

    systemctl daemon-reload
    systemctl enable node_exporter
    systemctl start node_exporter
    systemctl status node_exporter
}
copy_cert_files_from_temp_to_node_exporter() {

    if [ -e "${temp_tls_certificates_directory}/node_exporter.crt" ] && [ -e "${temp_tls_certificates_directory}/node_exporter.key" ]; then
        if [ -d "$node_exporter_default_etc_directory" ]; then
            cp -f ${temp_tls_certificates_directory}/node_exporter.crt ${node_exporter_default_etc_directory}
            cp -f ${temp_tls_certificates_directory}/node_exporter.key ${node_exporter_default_etc_directory}
        fi
    else
        echo "exiting ... crt,key file not exist"
        exit
    fi

}

install_new() {

    echo "Downloading files..."
    download_and_extract_necessary_files_and_folders
    echo "End of downloading files and extract..."

    echo "Moving extracted files..."
    move_extracted_files_and_folders
    echo "End of moving extracted files..."

    echo "Removing unnecessary downloaded files and folder ..."
    remove_downloaded_files_and_folders
    echo "*** Removed downloaded files and folder***"

    user_installation_option_prompt

    if [ -n "$selected_user_installation_option" ]; then

        if [ "$selected_user_installation_option" == "Basic Installation" ]; then
            echo "*** continue as Basic installation  *** "
        fi

        if [ "$selected_user_installation_option" == "Secured Installation" ]; then
            echo "*** continue as Secured installation  *** "
            # Text to be written to the file

            echo "Copying cert files from temp folder to ${node_exporter_default_etc_directory} ..."

            copy_cert_files_from_temp_to_node_exporter

            echo "*** Copied cert files from temp folder to ${node_exporter_default_etc_directory} ***"

            is_crt_key_exist_in_node_exporter_folder

            ask_for_usernam_passwor_promt

            config_content="tls_server_config:
  cert_file: node_exporter.crt
  key_file: node_exporter.key
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

# starting main block
echo "\n Your  System architecture: $system_architecture \n"
# Prompt the user to select a version
echo "Select a version:"
for i in "${!available_versions[@]}"; do
    echo "$((i + 1)) -  ${available_versions[i]}"
done

read -p "Enter the number of the version you want to use: " selected_version_index

#Check if the user input is a valid index

if [[ "$selected_version_index" =~ ^[0-9]+$ && "$selected_version_index" -ge 1 && "$selected_version_index" -le "${#available_versions[@]}" ]]; then
    selected_version="${available_versions[selected_version_index - 1]}"
    # Take Input Port from user

    echo "***is node exporter already installed checking......**"

    # Start Check if Node Exporter is already installed
    if is_already_installed; then
        # Ask the user if they want to remove the existing files and reinstall
        echo "Node Exporter is already installed. Do you want to remove the existing files and reinstall? (y/n)"
        read is_reinstall_answer
        # If the user is_reinstall_answers yes, remove the existing files and reinstall
        if [[ "${is_reinstall_answer,,}" == "y" || "${is_reinstall_answer,,}" == "yes" ]]; then

            echo "Removing existing files..."
            remove_allready_existing_files_and_folder
            echo "End of Removing existing files..."

        else
            echo "Exiting...."
            exit
        fi
    fi
    # end of Check if Node Exporter is already installed

    port_input_from_user_prompt

    echo "Installation starting ......"
    install_new
    echo "***Installing complete***"

else
    echo "Invalid input. Please select a valid version."
    exit 1
fi

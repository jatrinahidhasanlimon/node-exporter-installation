#!/bin/bash

# Fetch the system's architecture and save it to a variable
system_architecture=$(dpkg --print-architecture)

# check is port is occpied
is_port_occupied() {
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
port_input_from_user_prompt() {
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
    sudo rm -r /etc/node_exporter
    # Remove all files and directories named node_exporter
    sudo rm -r node_exporter-$selected_version*
    # Stop the node_exporter service
    sudo systemctl stop node_exporter
    # Remove the node_exporter systemd unit file
    sudo rm -r /etc/systemd/system/node_exporter.service
}

download_and_extract_necessary_files_and_folders() {
    # Display the system's architecture
    echo "\n System architecture: $system_architecture \n"
    download_link="https://github.com/prometheus/node_exporter/releases/download/v$selected_version/node_exporter-$selected_version.linux-$system_architecture.tar.gz"
    echo 'download link is: '$download_link
    #download from the github repository
    wget $download_link
    # Extract
    tar xvfz node_exporter-*.*-$system_architecture.tar.gz
}

move_extracted_files_and_folders() {
    #created folder is a combination of  selected version of node_exporter and system_architecture
    created_folder=node_exporter-$selected_version.linux-$system_architecture
    sudo mkdir /etc/node_exporter
    sudo touch /etc/node_exporter/config.yml
    sudo mv $created_folder/node_exporter* /usr/local/bin
    mv $created_folder/* /etc/node_exporter
}

create_system_user_and_give_permissions() {
    sudo useradd -rs /bin/false node_exporter
    chown -R node_exporter:node_exporter /etc/node_exporter
}

remove_downloaded_files_and_folders() {
    #created folder is a combination of  selected version of node_exporter and system_architecture
    sudo rm -r $created_folder*
}

create_systemd_service_file() {
    service_file_path="/etc/systemd/system/node_exporter.service"
    # Text to be written to the file
    content_of_service_file="[Unit]
    Description=Node Exporter
    After=network.target
    
    [Service]
    User=node_exporter
    Group=node_exporter
    Type=simple
    ExecStart=/usr/local/bin/node_exporter --web.config.file=/etc/node_exporter/config.yml 
              --web.listen-address=:$port
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
update_config_yml() {
    # Prompt the user for a username
        read -p "Enter your username: " username
        # Prompt the user for a password (and hide input)
        read -s -p "Enter your password: " password
        echo  # Add a newline after password input
        # Display the entered username and a message
        echo "You entered the following information:"
        echo "Username: $username"
        echo "Password: (hidden)"



    config_file_path="/etc/node_exporter/config.yml"
    # Text to be written to the file
    config_content="tls_server_config:
  cert_file: node_exporter.crt
  key_file: node_exporter.key
basic_auth_users:
  $username: $password"
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
    installation_options=("Basic Installation" "Secured Installation" "Quit")

    select selected_user_installation_option in "${installation_options[@]}"; do
        case $selected_user_installation_option in
        "Basic Installation")
            echo "Thank you for choosing Basic Installation."
            break
            ;;
        "Secured Installation")
            echo "Thank you for choosing Secured Installation."
            cert_certificate_options_prompt
            break
            ;;
        "Quit")
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please select a valid option."
            ;;
        esac
    done
}

cert_certificate_options_prompt() {
    PS4="Do you want to: "
    cert_installation_options=("Create a new certificate" "Use an existing certificate" "Quit")

    select selected_cert_option in "${cert_installation_options[@]}"; do
        case $selected_cert_option in
        "Create a new certificate")
            echo -e "\nYou chose to create a new certificate"
            generate_cert_and_key
            break
            ;;
        "Use an existing certificate")
            echo -e "\nYou chose to use an existing certificate"
            break
            ;;
        "Quit")
            echo "Exiting..."
            exit
            ;;
        *)
            echo "Invalid choice. Please select a valid option."
            ;;
        esac
    done
}

generate_cert_and_key() {
    sudo mkdir temp_openssl
    sudo openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout temp_openssl/node_exporter.key -out temp_openssl/node_exporter.crt
}

is_crt_key_exist_in_node_exporter_folder() {
    directory="/etc/node_exporter" # Replace with the actual directory path
    cert_file="$directory/node_exporter.crt"
    key_file="$directory/node_exporter.key"

    if [ -e "$cert_file" ] && [ -e "$key_file" ]; then
        echo "Both files $cert_file and $key_file exist in the directory $directory."
    elif [ -e "$cert_file" ]; then
        echo "File $key_file does not exist in the directory $directory."
    elif [ -e "$key_file" ]; then
        echo "File $cert_file does not exist in the directory $directory."
    else
        echo "Exiting ..... Neither file $cert_file nor $key_file exists in the directory $directory."
    fi
}

run_all_daemon_systemctl_command() {

    sudo systemctl daemon-reload
    sudo systemctl enable node_exporter
    sudo systemctl start node_exporter
    sudo systemctl status node_exporter
}

install_new() {
    port_input_from_user_prompt
    

    echo "Downloading files..."
    download_and_extract_necessary_files_and_folders
    echo "End of downloading files and extract..."

    echo "Moving extracted files..."
    move_extracted_files_and_folders
    echo "End of moving extracted files..."

    echo "Removing unnecessary downloaded files and folder ..."
    remove_downloaded_files_and_folders
    echo "Removing downloaded files and folder ..."

    user_installation_option_prompt

    if [ -n "$selected_user_installation_option" ]; then
        create_systemd_service_file

        if [ "$selected_user_installation_option" == "Basic Installation" ]; then
            echo "*** continue as Basic installation  *** "
        fi

        if [ "$selected_user_installation_option" == "Secured Installation" ]; then

            # Check if selected_cert_option is set (not null or empty)
            if [ -n "$selected_cert_option" ]; then
                # Nested check: if the variable value is equal to "Use an existing certificate"
                if [ "$selected_cert_option" == "Create a new certificate" ]; then
                    # Perform actions when selected_cert_option is set and is "Use an existing certificate"
                    sudo mv temp_openssl/* /etc/node_exporter/
                    sudo rm -r temp_openssl
                    echo "Moving cert files from temp folder to /etc/node_exporter"
                fi
                is_crt_key_exist_in_node_exporter_folder
                update_config_yml

            else
                # Handle the case when selected_cert_option is not set (null or empty)
                echo "selected_cert_option is not set."
            fi
        fi

        # relaoad daemon and enable systemctl
        echo "all daemon process reloading ............"
        chown -R node_exporter:node_exporter /etc/node_exporter
        run_all_daemon_systemctl_command
        echo "***all daemon process reloaded***"
    fi
}

# starting main block

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
    # Take Input Port from user
    
    echo "***is node exporter already installed checking......**"

    # Start Check if Node Exporter is already installed
    if is_already_installed; then
        # Ask the user if they want to remove the existing files and reinstall
        echo "Node Exporter is already installed. Do you want to remove the existing files and reinstall? (y/n)"
        read is_reinstall_answer
        # If the user is_reinstall_answers yes, remove the existing files and reinstall
        if [[ $is_reinstall_answer == "y" || $is_reinstall_answer == "yes" ]]; then

            echo "Removing existing files..."
            remove_allready_existing_files_and_folder
            echo "End of Removing existing files..."

        else
            echo "Exiting...."
            exit
        fi
    fi
    # end of Check if Node Exporter is already installed

   
    echo " Installing started"
    install_new

else
    echo "Invalid input. Please select a valid version."
    exit 1
fi


    if [ -e "/etc/node_exporter/cummins.yml" ]; then
        rm "/etc/node_exporter/cummins.yml"
        echo "File '/etc/node_exporter/cummins.yml' has been removed."
    fi

    # Text to be written to the file
    config_content="tls_server_config:
  cert_file: node_exporter.crt
  key_file: node_exporter.key
basic_auth_users:
  $username: $password"
    # Use redirection to create and write to the file
    echo "$config_content" >"/etc/node_exporter/cummins.yml"

    # Check if the file was created successfully
    if [ -e "/etc/node_exporter/cummins.yml" ]; then
        echo "File '/etc/node_exporter/cummins.yml' created and text written successfully."
    else
        echo "Error creating the file or writing text to /etc/node_exporter/cummins.yml."
    fi

#!/bin/bash

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
        return 2  # Exit with a custom code (not 0 or 1) when validation fails
    fi
    
    if [[ ! "$port" =~ ^[0-9]+$ || "$port" -lt 1 || "$port" -gt 65535 ]]; then
        echo "Invalid port number. Please enter a valid port (1-65535)."
        return 2  # Exit with a custom code (not 0 or 1) when validation fails
    fi
    
    is_port_in_use "$port"
    if [ $? -eq 0 ]; then
        echo "Port $port is already in use. Please choose a different port."
        return 2  # Exit with a custom code (not 0 or 1) when validation fails
    fi
    
    return 0
}

# Ask the user for a valid and free port
while true; do
    read -p "Enter a port number: " port
    validate_port "$port"
    if [ $? -eq 0 ]; then
        break
    fi
done

echo "Selected port: $port"
# Use the $port variable for further processing outside the function

# Add your code here to use the selected port

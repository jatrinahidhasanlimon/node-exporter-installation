# Declare port as a global variable
port=""

# Check if port is occupied
is_port_occupied() {
    local port=$1
    lsof -i :"$port" > /dev/null 2>&1
}

# Function to validate if a given value is a valid port number
is_valid_port() {
    local port=$1
    if [[ "$port" =~ ^[0-9]+$ ]] && [[ "$port" -ge 1 ]] && [[ "$port" -le 65535 ]]; then
        valid_port=true
    else
        valid_port=false
    fi
}

# Function to take port input from the user until it's available and valid
port_input_from_user_prompt() {
    local occupied=true
    local valid_port=false

    while $occupied; do
        echo "Enter the port number: "
        read port
        is_valid_port "$port"

        if ! $valid_port; then
            echo "Invalid port number. Please enter a valid port between 1 and 65535."
        elif is_port_occupied "$port"; then
            echo "Port $port is occupied. Please enter a different port."
        else
            echo "Port $port is not occupied."
            occupied=false
        fi
    done
}

# Example usage
port_input_from_user_prompt

# Now you can access the 'port' variable outside the function
echo "The selected port is: $port"

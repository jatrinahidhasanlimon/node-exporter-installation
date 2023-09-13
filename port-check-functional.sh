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
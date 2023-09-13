#!/bin/bash

# Get the port number from the user
echo "Enter the port number to check: "
read port

# Use the netstat command to check if the port is in use
netstat -an | grep ":$port"

# If the port is in use, prompt the user to enter a different port
if [[ $? -eq 0 ]]; then
  echo "Port is occupied. Please enter a different port: "
  read port
fi

# If the port is not in use, print "Port is not occupied"
if [[ $? -ne 0 ]]; then
  echo "$port Port is not occupied"
fi
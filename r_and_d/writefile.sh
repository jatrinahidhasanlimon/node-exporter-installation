#!/bin/bash

file_path="/root/TestScripts/a_test_folder/file.txt"

# Text to be written to the file
text="[Unit]
Description=Node Exporter
After=network.target
 
[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.config.file=/etc/node_exporter/config.yml \
         --web.listen-address=:$port
[Install]
WantedBy=multi-user.target"

# Use redirection to create and write to the file
echo "$text" > "$file_path"

# Check if the file was created successfully
if [ -e "$file_path" ]; then
  echo "File '$file_path' created and text written successfully."
else
  echo "Error creating the file or writing text to it."
fi

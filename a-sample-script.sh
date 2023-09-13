#!/bin/bash
echo "Even if you  hate snaps, you'd rarely find a perfect distro like Ubuntu"
echo A controvetial statement by $USER

# Present a menu to the user
while true; do
    echo "Select a version"
    echo "1. 3.3.1"
    echo "2. 3.6.1"
    echo "3. Exit"

    read -p "Enter your choice: " choice

    case $choice in
        1)
            echo "installation of ".$choice . "selected"
            ;;
        2)
            echo "installation of ".$choice. " selected"
            ;;
        3)
            echo "Exiting the script."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please select a valid option (1, 2, or 3)."
            ;;
    esac
done

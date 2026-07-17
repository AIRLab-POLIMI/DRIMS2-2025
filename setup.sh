#!/bin/bash

# Define variables
RULES_FILE="80-movidius.rules"
DEST_DIR="/etc/udev/rules.d"
GROUP_NAME="drims2"
GROUP_ID=42042

# Check if the rules file exists
if [ ! -f "$RULES_FILE" ]; then
    echo "Error: $RULES_FILE not found!"
    exit 1
fi

# Copy the rules file to /etc/udev/rules.d
echo "Copying $RULES_FILE to $DEST_DIR..."
sudo cp "$RULES_FILE" "$DEST_DIR"

ROBOTIQ_RULES_FILE="99-robotiq.rules"

# Check if the rules file exists
if [ ! -f "$ROBOTIQ_RULES_FILE" ]; then
    echo "Error: $RULES_FILE not found!"
    exit 1
fi

# Copy the rules file to /etc/udev/rules.d
echo "Copying $ROBOTIQ_RULES_FILE to $DEST_DIR..."
sudo cp "$ROBOTIQ_RULES_FILE" "$DEST_DIR"


# Create the group drims2 with GID 42042 if it doesn't exist
if ! getent group $GROUP_NAME >/dev/null; then
    echo "Creating group $GROUP_NAME with GID $GROUP_ID..."
    sudo groupadd -g $GROUP_ID $GROUP_NAME
else
    echo "Group $GROUP_NAME already exists."
fi

# Add the current user to the drims group if not already a member
if ! id -nG "$USER" | grep -qw $GROUP_NAME; then
    echo "Adding user $USER to group $GROUP_NAME..."
    sudo usermod -aG $GROUP_NAME $USER
    echo "You may need to log out and log back in for group changes to take effect."
else
    echo "User $USER is already a member of group $GROUP_NAME."
fi

# Change the group owner of the folders drims_ws and bags to drims2
echo "Changing group ownership of directories drims_ws and bags to $GROUP_NAME..."
sudo chgrp -R $GROUP_NAME "$PWD/drims_ws" "$PWD/bags"

sudo chmod 777 "$PWD/drims_ws" "$PWD/bags"

echo "Script execution completed."

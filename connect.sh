#!/bin/bash

# Variables
CONTAINER_NAME="drims2"
DOMAIN_ID_FILE="$(dirname "$0")/ros_domain_id"

# Read the domain id from the ros_domain_id file
if [ ! -f "$DOMAIN_ID_FILE" ]; then
    echo "Error: $DOMAIN_ID_FILE not found. Run start.sh first."
    exit 1
fi

ROS_DOMAIN_ID=$(tr -d '[:space:]' < "$DOMAIN_ID_FILE")
if [[ ! "$ROS_DOMAIN_ID" =~ ^[0-9]+$ ]]; then
    echo "Error: $DOMAIN_ID_FILE does not contain a number."
    exit 1
fi
echo "Using ROS_DOMAIN_ID=$ROS_DOMAIN_ID"

# Grant X permissions
#xhost +si:localuser:$(whoami)
xhost +local:root
# Check if the container is running
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo "Container $CONTAINER_NAME is running. Connecting to it..."
    docker exec -it --env ROS_DOMAIN_ID=$ROS_DOMAIN_ID $CONTAINER_NAME /bin/bash
else
    echo "Container $CONTAINER_NAME is not running."
fi

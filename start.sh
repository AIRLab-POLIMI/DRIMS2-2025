#!/bin/bash

# Check the ROS domain id passed as first argument
if [[ "$1" =~ ^[0-9]+$ ]]; then
    export ROS_DOMAIN_ID=$1
    echo "Using ROS_DOMAIN_ID=$ROS_DOMAIN_ID"
else
    echo "Error: first argument must be a number (ROS_DOMAIN_ID)."
    echo "Usage: $0 <ROS_DOMAIN_ID>"
    exit 1
fi

touch ros_domain_id
echo "${ROS_DOMAIN_ID}" > ros_domain_id

# Specify the container name
CONTAINER_NAME="drims2"
IMAGE_NAME="smentasti/drims2:2026"
#IMAGE_NAME="my_image"

# Pull the latest image
echo "Pulling the latest image: $IMAGE_NAME..."
docker pull $IMAGE_NAME

# Grant X permissions
#xhost +si:localuser:$(whoami)
xhost +local:root
# Check if the container exists
if docker ps -a | grep -q $CONTAINER_NAME; then
    echo "Container $CONTAINER_NAME exists."

    # Check if the container is running
    if [ "$(docker inspect -f {{.State.Running}} $CONTAINER_NAME)" == "true" ]; then
        echo "Container $CONTAINER_NAME is running. Stopping it now..."
        docker stop $CONTAINER_NAME
        docker rm $CONTAINER_NAME
    else
        echo "Container $CONTAINER_NAME is not running."
        docker rm $CONTAINER_NAME
    fi
else
    echo "Container $CONTAINER_NAME does not exist."
fi

docker run -it  --group-add dialout --user drims --privileged --env="ROS_DOMAIN_ID" -v /dev:/dev -v /dev/bus/usb:/dev/bus/usb --device=/dev/bus/usb --device-cgroup-rule='c 189:* rmw'  -v /etc/udev/rules.d:/etc/udev/rules.d --env="DISPLAY" --env="QT_X11_NO_MITSHM=1" --net=host --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" --volume="$(pwd)/drims_ws:/home/drims/drims_ws" --volume="$(pwd)/bags:/home/drims/bags"  --name drims2 -w /home/drims $IMAGE_NAME

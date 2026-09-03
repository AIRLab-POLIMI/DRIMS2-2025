FROM ros:humble-perception

# Populated automatically by buildx (e.g. "amd64", "arm64")
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

# Set timezone (avoid tzdata prompt)
RUN echo 'tzdata tzdata/Areas select Etc' | debconf-set-selections \
 && echo 'tzdata tzdata/Zones/Etc select UTC' | debconf-set-selections

# Base tools
RUN apt-get update && apt-get install -y \
    build-essential nano tmux iputils-ping gdb cmake git \
    openssl libssl-dev libmysqlclient-dev xvfb \
    python3-colcon-common-extensions \
    python3-pip \
    libboost-all-dev \
    ros-humble-ros2-control ros-humble-ros2-controllers \
    ros-humble-moveit ros-humble-depthai-ros ros-humble-moveit-ros-control-interface \
    ros-humble-behaviortree-cpp* ros-humble-ros-testing freeglut3-dev ros-humble-moveit-resources-* \
    ros-humble-realsense2-camera \
    ros-humble-ur \
    ros-humble-omni-base* ros-humble-play-motion2 ros-humble-diagnostic-aggregator \
    libprotobuf-dev protobuf-compiler ros-humble-tf* \
    ros-humble-rmw-cyclonedds-cpp \
    net-tools iproute2

# Gazebo Classic (gazebo11) is only published for amd64 upstream, so it is not
# installable when cross-building the arm64 image.
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        apt-get update && apt-get install -y \
            ros-humble-gazebo-ros-pkgs \
            ros-humble-gazebo-ros2-control ; \
    else \
        echo "Skipping Gazebo Classic packages: not available for $TARGETARCH" ; \
    fi

RUN apt-get update && apt-get install -y python3-pip python3-colcon-common-extensions python3-pybind11 cmake libmodbus-dev libmongoclient-dev wget ros-humble-ament-cmake-auto ros-humble-ament-cmake-core \
    && wget https://github.com/mikefarah/yq/releases/download/v4.35.1/yq_linux_${TARGETARCH} -O /usr/bin/yq \
    && chmod +x /usr/bin/yq

# Python dependencies
RUN pip3 install --upgrade scipy depthai trimesh transforms3d

# ur_rtde has no arm64 wheel upstream; building it from source on this image
# fails because a system-wide setuptools plugin pins packaging>=26.2 while
# apt's python3-packaging is 21.3, and python3-packaging cannot be upgraded
# without removing core ROS/colcon build tooling. amd64 only.
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        pip3 install --upgrade ur_rtde ; \
    else \
        echo "Skipping ur_rtde install: no arm64 wheel and source build is broken on this image" ; \
    fi

# Create user and group with correct IDs
ARG GROUP_NAME=drims2
ARG GROUP_ID=42042
ARG USER_NAME=drims
ARG USER_ID=1001

RUN groupadd -g $GROUP_ID $GROUP_NAME && \
    useradd -ms /bin/bash -u $USER_ID -g $GROUP_ID $USER_NAME && \
    echo "$USER_NAME:$USER_NAME" | chpasswd

# Setup workspace as root
RUN mkdir -p /home/$USER_NAME/static/drims2_ws/src

WORKDIR /home/$USER_NAME/static/drims2_ws/src

# installing Groot (only published as an x86_64 binary upstream, so it is
# skipped when cross-building for arm64)
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        wget https://pub-32cef6782a9e411e82222dee82af193e.r2.dev/Groot2-v1.9.0-linux-installer.run && \
        chmod +x Groot2-v1.9.0-linux-installer.run && \
        ./Groot2-v1.9.0-linux-installer.run install --root /opt/groot --accept-licenses --default-answer --confirm-command && \
        rm Groot2-v1.9.0-linux-installer.run && \
        ln -s /opt/groot/bin/groot2 /usr/local/bin/groot ; \
    else \
        echo "Skipping Groot2 install: no arm64 build available" ; \
    fi

# Clone code as root
RUN git clone https://github.com/CNR-STIIMA-IRAS/easy_motion.git
RUN vcs import < easy_motion/dependencies.repos
RUN git clone https://github.com/CNR-STIIMA-IRAS/drims2_dice_simulator.git
RUN git clone https://github.com/CNR-STIIMA-IRAS/drims_cells.git
RUN vcs import < drims_cells/deps.repos

WORKDIR /home/$USER_NAME/static/drims2_ws
RUN rosdep update

# On arm64, none of the Gazebo-related binary packages are published upstream
# (neither Gazebo Classic nor the newer gz/ros-gz packages), and neither is
# ros-humble-omni-base-description. Skip resolving those specific keys there;
# amd64 installs everything as before.
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        rosdep install --from-paths src --ignore-src -r -y ; \
    else \
        rosdep install --from-paths src --ignore-src -r -y \
            --skip-keys "gazebo_ros gazebo_plugins pal_gazebo_plugins gazebo_ros2_control gz_ros2_control ros_gz_sim omni_base_description" ; \
    fi

# Fix ownership of everything
RUN chown -R $USER_NAME:$GROUP_NAME /home/$USER_NAME

# Switch to the user
USER $USER_NAME
WORKDIR /home/$USER_NAME/static/drims2_ws

# 1st build: just build interfaces and messages
SHELL ["/bin/bash", "-c"]
RUN source /opt/ros/humble/setup.bash && colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release --packages-select drims2_msgs

# Add ROS, workspace and Gazebo to bashrc
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
RUN echo "if [ -f /usr/share/gazebo/setup.bash ]; then source /usr/share/gazebo/setup.bash; fi" >> ~/.bashrc
RUN echo "export LIBGL_ALWAYS_SOFTWARE=1" >> ~/.bashrc
RUN echo "if [ -f ~/static/drims2_ws/install/setup.bash ]; then source ~/static/drims2_ws/install/setup.bash; fi" >> ~/.bashrc

# Configure cyclone configuration to bashrc
RUN echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> ~/.bashrc


# Add the check script and setup robot connection script to the container
COPY check_script.sh /home/$USER_NAME/check_script.sh
COPY setup_robot_connection.sh /home/$USER_NAME/setup_robot_connection.sh
USER root
RUN chmod +x /home/$USER_NAME/check_script.sh
RUN chmod +x /home/$USER_NAME/setup_robot_connection.sh

# Forgotten stuff
RUN python3 -m pip install "numpy<2"
RUN echo "source /home/drims/drims_ws/install/setup.bash" >> ~/.bashrc
RUN apt-get update && apt-get install -y ros-humble-rqt ros-humble-rqt-tf-tree

# Final setup
USER $USER_NAME
WORKDIR /home/$USER_NAME/static/drims2_ws/src
RUN git clone https://github.com/MerlinLaboratory/udp_to_ros2_bridge.git
WORKDIR /home/$USER_NAME/static/drims2_ws
SHELL ["/bin/bash", "-c"]
# On arm64 a handful of packages that require Gazebo (unavailable there, see
# the rosdep step above) will fail to build; --continue-on-error lets every
# other package build anyway, and the build is allowed to end non-zero there.
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        source /opt/ros/humble/setup.bash && colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release ; \
    else \
        source /opt/ros/humble/setup.bash && colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release --continue-on-error \
            || echo "Some Gazebo-dependent packages could not be built on $TARGETARCH; continuing" ; \
    fi

WORKDIR /home/$USER_NAME

#Letsgo
CMD ["bash"]


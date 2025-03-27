ARG ROS_DISTRO=melodic
ARG UBUNTU_CODE_NAME=bionic

ARG BASE_IMAGE=osrf/ros
ARG BASE_TAG=${ROS_DISTRO}-desktop-full-${UBUNTU_CODE_NAME}



################################################################################
################################################################################
#
#           Stage: ros-base
#
################################################################################
################################################################################

# get docker image
FROM ${BASE_IMAGE}:${BASE_TAG} AS base

LABEL maintainer="florian.bergner@tum.de"

# USE German mirror to speed up things
RUN cp /etc/apt/sources.list /etc/apt/sources.list.old \
    && sed -i -e 's/http:\/\/archive\.ubuntu\.com\/ubuntu\// \
    http:\/\/de.archive\.ubuntu\.com\/ubuntu/' /etc/apt/sources.list

ENV DEBIAN_FRONTEND=noninteractive


# default command
CMD [ "/bin/bash" ]



################################################################################
################################################################################
#
#       Stage: Newer cmake (for melodic)
#
################################################################################
################################################################################

FROM base AS cmake-base

LABEL maintainer="florian.bergner@tum.de"

ENV DEBIAN_FRONTEND=noninteractive


RUN apt-get update && apt-get install -y --no-install-recommends \
        apt-transport-https \
        wget \
        ca-certificates \
        gnupg \
        software-properties-common \
        lsb-release \
    && rm -rf /var/lib/apt/lists/*


RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | apt-key add - \
    && apt-add-repository "deb https://apt.kitware.com/ubuntu/ `lsb_release -cs` main" \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        kitware-archive-keyring \
    && apt-key --keyring /etc/apt/trusted.gpg del C1F34CDD40CD72DA \
    && apt-get install -y --no-install-recommends \
        cmake \     
    && rm -rf /var/lib/apt/lists/*


# default command
CMD [ "/bin/bash" ]




################################################################################
################################################################################
#
#           Stage: Add basic build tools
#
################################################################################
################################################################################

FROM cmake-base AS build-base

LABEL maintainer="florian.bergner@tum.de"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        make \
        ninja-build \
        cmake \
        ssh \
        git \
        patchelf \
    && rm -rf /var/lib/apt/lists/*


# default command
CMD [ "/bin/bash" ]



################################################################################
################################################################################
#
#           Stage: reemc-build
#
################################################################################
################################################################################


FROM build-base AS reemc-build

LABEL maintainer="florian.bergner@tum.de"

ENV DEBIAN_FRONTEND=noninteractive


# RUN apt-get update && apt-get install -y --no-install-recommends \
#         ros-$ROS_DISTRO-jsk-rviz-plugins \
#         ros-$ROS_DISTRO-jsk-footstep-msgs \
#         ros-$ROS_DISTRO-rosbridge-server \
#         ros-$ROS_DISTRO-sbpl \
#         ros-$ROS_DISTRO-teleop-twist-joy \
#     && rm -rf /var/lib/apt/lists/*


RUN mkdir -p /software
WORKDIR /software
    
SHELL ["/bin/bash", "-c"]

COPY setup/reemc /software


RUN mkdir reemc_ws \
    && cd reemc_ws \
    && apt-get update \
    && rosinstall src /opt/ros/melodic ../reemc_melodic.rosinstall \
    && rosdep install --from-paths src --ignore-src --rosdistro melodic -y \
        --skip-keys=" \
            opencv2 \
            pal_laser_filters \
            speed_limit_node \ 
            sensor_to_cloud \ 
            hokuyo_node \
            libdw-dev \
            gmock \
            walking_utils \
            rqt_current_limit_controller \
            simple_grasping_action \
            reemc_init_offset_controller \ 
            walking_controller" \
    && rm -rf /var/lib/apt/lists/* 


RUN cd reemc_ws \    
    && source /opt/ros/melodic/setup.bash \ 
    && catkin_make -DCMAKE_BUILD_TYPE=RELEASE -DCATKIN_ENABLE_TESTING=0


RUN cd reemc_ws \
    && source /opt/ros/melodic/setup.bash \
    && catkin_make install \
    && mkdir -p /opt/pal \
    && mkdir -p /install/pal \
    && cp -a install/. /opt/pal \
    && cp -a install/. /install/pal


# default command
CMD [ "/bin/bash" ]



################################################################################
################################################################################
#
#           Stage: Add basic termnal tools for networking etc
#
#    Use dpkg -L <package_name> to list files installed by package
#
#    Use command -v <command> to get the path to the binary
#    Use dpkg -S <path> to find package that installed a file
#
#    Packages:
#        - iproute2         for "ip" command
#        - iputils-ping     for "ping" command
#        - dnsutils         for "dig" command
#        - host             for commands host and hostname
#        - net-tools        for commands 
#                               arp
#                               ifconfig
#                               netstat
#                               rarp
#                               nameif
#                               route
#        - htop             for "htop"
#        - bmon             for "bmon"
#        - rsync            for "rsync"
#        - vim              for "vim"
#        - nano             for "nano"
#        - git              for git
#        - ssh              for ssh
#        - wget             for wget
#        - tar              for tar
#        - curl             for curl
#        - tree             for tree
################################################################################
################################################################################

FROM cmake-base AS base-tools

LABEL maintainer="florian.bergner@tum.de"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        iproute2 \
        iputils-ping \
        dnsutils \
        host \
        net-tools \
        htop \
        bmon \
        rsync \
        vim \
        nano \
        git \
        ssh \
        wget \
        tar \
        curl \
        tree  \
        screen \
    && rm -rf /var/lib/apt/lists/*


# default command
CMD [ "/bin/bash" ]




################################################################################
################################################################################
#
#           Stage: python deps
#
################################################################################
################################################################################


FROM base-tools AS base-python

LABEL maintainer="florian.bergner@tum.de"

ENV DEBIAN_FRONTEND=noninteractive


# Base installation to use python in most cases
RUN apt-get update && apt-get install -y --no-install-recommends \
    python-pip \
    python-tk \
    python-scipy \
    python3-pip \
    python-rosdep \
    python-rosinstall \
    python-rosinstall-generator \
    python-wstool \
    python-catkin-tools \
    && rm -rf /var/lib/apt/lists/*


# default command
CMD [ "/bin/bash" ]



################################################################################
################################################################################
#
#           Stage: nvidia-base
#
################################################################################
################################################################################


# get docker image
FROM base-python AS base-nvidia

LABEL maintainer="florian.bergner@tum.de"


################################################################################
#   Setup nvidia graphics acceleration
#
#   https://github.com/NVIDIA/nvidia-docker
#   https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#docker
#
#   Test in container with:
#       sudo apt update
#       sudo apt install mesa-utils
#       sudo apt install glmark2
#       glxgears
#       glmark2
#
#   Test with nvidia-smi (depends on host driver version, change if necessary):
#       sudo apt install libnvidia-compute-535=535.171.04-0ubuntu0.20.04.1    
#       sudo apt install nvidia-utils-535=535.171.04-0ubuntu0.20.04.1
#
#       sudo apt install libnvidia-compute-535=535.171.04-0ubuntu0.22.04.1
#       sudo apt install nvidia-utils-535=535.171.04-0ubuntu0.22.04.1
################################################################################

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES \
    ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
    ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics

CMD [ "/bin/bash" ]



################################################################################
################################################################################
#
#           Stage: devel-base
#
################################################################################
################################################################################

FROM base-nvidia AS devel-base

LABEL maintainer="florian.bergner@tum.de"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        make \
        ninja-build \
        cmake \
        ssh \
        git \
        patchelf \
    && rm -rf /var/lib/apt/lists/*


# default command
CMD [ "/bin/bash" ]



################################################################################
################################################################################
#
#       Stage: reemc-devel
#
################################################################################
################################################################################

FROM devel-base AS reemc-devel

LABEL maintainer="florian.bergner@tum.de"


ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        ros-$ROS_DISTRO-jsk-rviz-plugins \
        ros-$ROS_DISTRO-jsk-footstep-msgs \
        ros-$ROS_DISTRO-rosbridge-server \
        ros-$ROS_DISTRO-sbpl \
        ros-$ROS_DISTRO-teleop-twist-joy \
        xvfb \
    && rm -rf /var/lib/apt/lists/*


# Fetch pre-built libraries
COPY --from=reemc-build /install/pal /opt/pal


# default command
CMD [ "/bin/bash" ]



################################################################################
################################################################################
#
#           Stage: reemc-devel-vscode
#
################################################################################
################################################################################

ARG BASH_ALIASES=setup/.bash_aliases

FROM reemc-devel AS reemc-devel-vscode
ARG BASH_ALIASES

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        bash-completion \
	&& rm -rf /var/lib/apt/lists/*


# NOTE: The IDs do no matter here, the vs code build system will automatically
#   change them to the local user
# The user name also does not matter, it will be matched to the local one
ARG CONT_USER=devel
ARG CONT_UID=1000
ARG CONT_GID=1000

ENV CONT_USER=${CONT_USER}
ENV CONT_UID=${CONT_UID}
ENV CONT_GID=${CONT_GID}

ENV CONT_HOME_DIR=/home/${CONT_USER}


# Setup bash aliases
# COPY setup/.bash_aliases /etc/skel/.bash_aliases
COPY ${BASH_ALIASES} /etc/skel/.bash_aliases

# Install user
RUN mkdir -p ${CONT_HOME_DIR} && \
    echo "${CONT_USER}:x:${CONT_UID}:${CONT_GID}:${CONT_USER},,,:${CONT_HOME_DIR}:/bin/bash" >> /etc/passwd && \
    echo "${CONT_USER}:x:${CONT_GID}:" >> /etc/group && \
    pwconv && \
    cp -r /etc/skel/. ${CONT_HOME_DIR}/ && \
    echo "${CONT_USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99_${CONT_USER} && \
    chmod 0440 /etc/sudoers.d/99_${CONT_USER} && \
    chown ${CONT_UID}:${CONT_GID} -R ${CONT_HOME_DIR}


WORKDIR ${CONT_HOME_DIR}

# Enable bash completion for apt
RUN sed -i -e 's/^/#/' /etc/apt/apt.conf.d/docker-clean

# Enable color prompt
RUN sed -i '/force_color_prompt=yes/s/^#//g' ${CONT_HOME_DIR}/.bashrc

# default command
CMD [ "bash" ]



################################################################################
################################################################################
#
#           Stage: Add user for X Server and smooth integration in host
#
#       Note: This stage should be the final stage after arranging the image.
#         This stage conflicts with the vscode stage. The final stage
#         is either this stage or the vscode stage.      
#
################################################################################
################################################################################

ARG BASH_ALIASES=setup/.bash_aliases


FROM reemc-devel AS reemc-devel-w-user

LABEL maintainer="florian.bergner@tum.de"
ARG BASH_ALIASES


ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        bash-completion \
	&& rm -rf /var/lib/apt/lists/*


# Change workdir
ENV PWD=/work
WORKDIR /work


# Default docker container user ids
ARG CONT_USER=devel
ARG CONT_UID=1000
ARG CONT_GID=1000
ARG CONT_PWD="/work"

ENV CONT_USER=${CONT_USER}
ENV CONT_UID=${CONT_UID}
ENV CONT_GID=${CONT_GID}
ENV CONT_PWD=${CONT_PWD}

# entrypoint for user creation + switch
COPY setup/entrypoint.sh /entrypoint.sh
# COPY setup/.bash_aliases /etc/skel/.bash_aliases
COPY ${BASH_ALIASES} /etc/skel/.bash_aliases

# setup before running command
ENTRYPOINT ["/entrypoint.sh"]

# default command
CMD [ "/bin/bash" ]




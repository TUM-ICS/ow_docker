# Docker Image for OpenWalker


## Create Docker Image for Standalone use

The docker image supports the handling of user permissions, and GUI apps via
the X11 windowing system.

```bash

# Build standalone image with user support
docker build \
    --build-arg BUILD_THREADS=8\
    --build-arg BASE_IMAGE=osrf/ros \
    --build-arg BASE_TAG=melodic-desktop-full-bionic \
    --file ./Dockerfile \
    --target reemc-devel-w-user \
    -t ghcr.io/tum-ics/ow_docker:melodic-reemc-devel-w-user \
    .
```

## Create Docker Image for VSCode Dev Container

The docker image supports the handling of user permissions, and GUI apps via
the X11 windowing system.

```bash
# Build image for VSCode Dev Containers
docker build \
    --build-arg BUILD_THREADS=8 \
    --build-arg BASE_IMAGE=osrf/ros \
    --build-arg BASE_TAG=melodic-desktop-full-bionic \
    --file ./Dockerfile \
    --target reemc-devel-vscode \
    -t ghcr.io/tum-ics/ow_docker:melodic-reemc-devel-vscode \
    .
```


## Pull pre-built Docker images

```bash
# Standalone image with user support
docker pull ghcr.io/tum-ics/ow_docker:melodic-reemc-devel-w-user

# Image for VSCode Dev Containers
docker pull ghcr.io/tum-ics/ow_docker:melodic-reemc-devel-vscode
```


## Using the Standalone Image


Set the bash variable `CONT_NAME` for defining the container name, and set `WORK_DIR` to mount a working directory
e.g. ROS workspace in the container.

Optional: Set `NVIDIA_ARG` to `--runtime=nvidia` if you want to use Docker with Nvidia hardware
acceleration.


```bash
CONT_NAME="ow_test_dcont"
WORK_DIR="."
NVIDIA_ARG=""

# Create standalone container
docker run \
    --name "$CONT_NAME" \
    --hostname "$CONT_NAME" \
    --add-host="$CONT_NAME"=127.0.1.2 \
    --detach \
    --net=host \
    --privileged \
    ${NVIDIA_ARG} \
    --restart=unless-stopped \
    --env "CONT_USER=`id -u -n`" \
    --env "CONT_UID=`id -u`" \
    --env "CONT_GID=`id -g`" \
    --env CONT_PWD="/work" \
    --env DISPLAY \
    --env QT_X11_NO_MITSHM=1 \
    -v /dev:/dev \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v "$WORK_DIR:/work" \
    ghcr.io/tum-ics/ow_docker:melodic-reemc-devel-w-user \
    sleep infinity


# Enter container and run bash
docker exec -it $CONT_NAME runuser -u `id -u -n` -- bash -c "cd \$CONT_PWD && export CONT_PWD_AUTO_SOURCE_SETUP=true && bash"


# Stop and remove container
docker stop $CONT_NAME
docker remove $CONT_NAME
```

## Access VSCode Dev Container outside VSCode

A Docker container that is run by the VSCode Dev Container environment can be 
accessed in any terminal by using the following command.

```bash
CONT_NAME="openwalker_devcont"
docker exec -it $CONT_NAME runuser -u devel -- bash -c "cd \$CONT_PWD && export CONT_PWD_AUTO_SOURCE_SETUP=true && bash"
```
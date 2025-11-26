#!/usr/bin/env bash

# Get dependent parameters
source "$(dirname "$(readlink -f "${0}")")/get_param.sh"

# Check if pkgs directory exists, if not, copy from image
if [ ! -d "${WS_PATH}/pkgs" ]; then
    echo "Packages not found. Copying from Docker image..."
    TEMP_CONTAINER="temp_${CONTAINER}_$(date +%s)"
    docker create --name "${TEMP_CONTAINER}" "${DOCKER_HUB_USER}"/"${IMAGE}"
    docker cp "${TEMP_CONTAINER}":/home/"${user}"/work/pkgs "${WS_PATH}"/
    docker rm "${TEMP_CONTAINER}"
    echo "Packages copied successfully!"
fi

docker run --rm \
    --privileged \
    --ipc=host \
    --network=host \
    ${GPU_FLAG} \
    -v /tmp/.Xauthority:/home/"${user}"/.Xauthority \
    -e XAUTHORITY=/home/"${user}"/.Xauthority \
    -e DISPLAY="${DISPLAY}" \
    -e QT_X11_NO_MITSHM=1 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v /etc/timezone:/etc/timezone:ro \
    -v /etc/localtime:/etc/localtime:ro \
    -v /dev:/dev \
    -v "${WS_PATH}":/home/"${user}"/work \
    -it --name "${CONTAINER}" "${DOCKER_HUB_USER}"/"${IMAGE}"

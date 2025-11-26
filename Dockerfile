# FROM ubuntu:22.04
########## zack change image for nvidia cuda toolkit ###########
ARG DEBIAN_FRONTEND=noninteractive
ARG BASE_DIST=ubuntu22.04
ARG CUDA_VERSION=11.8.0
ARG ISAAC_SIM_VERSION=4.5.0
# ARG CUDA_VERSION=11.4.2
# ARG ISAAC_SIM_VERSION=4.0.0


FROM nvcr.io/nvidia/isaac-sim:${ISAAC_SIM_VERSION} AS isaac-sim

FROM nvidia/cuda:${CUDA_VERSION}-devel-${BASE_DIST}
# FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04
############################## SYSTEM PARAMETERS ##############################
# * Arguments
ARG USER=initial
ARG GROUP=initial
ARG UID=1000
ARG GID="${UID}"
ARG SHELL=/bin/bash
ARG HARDWARE=x86_64
ARG ENTRYPOINT_FILE=entrypint.sh

ARG VULKAN_SDK_VERSION=1.3.224.1

# * Env vars for the nvidia-container-runtime.
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
# ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute

# * Setup users and groups
RUN groupadd --gid "${GID}" "${GROUP}" \
    && useradd --gid "${GID}" --uid "${UID}" -ms "${SHELL}" "${USER}" \
    && mkdir -p /etc/sudoers.d \
    && echo "${USER}:x:${UID}:${UID}:${USER},,,:/home/${USER}:${SHELL}" >> /etc/passwd \
    && echo "${USER}:x:${UID}:" >> /etc/group \
    && echo "${USER} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${USER}" \
    && chmod 0440 "/etc/sudoers.d/${USER}"

# * Replace apt urls
# ? Change to tku
RUN sed -i 's@archive.ubuntu.com@ftp.tku.edu.tw@g' /etc/apt/sources.list
# ? Change to Taiwan
# RUN sed -i 's@archive.ubuntu.com@tw.archive.ubuntu.com@g' /etc/apt/sources.list

# * Time zone
ENV TZ=Asia/Taipei
RUN ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone

# * Copy custom configuration
# ? Requires docker version >= 17.09
COPY --chmod=0775 ./${ENTRYPOINT_FILE} /entrypoint.sh
COPY --chown="${USER}":"${GROUP}" --chmod=0775 config config
# ? docker version < 17.09
# COPY ./${ENTRYPOINT_FILE} /entrypoint.sh
# COPY config config
# RUN sudo chmod 0775 /entrypoint.sh && \
# sudo chown -R "${USER}":"${GROUP}" config \
# && sudo chmod -R 0775 config

############################### INSTALL #######################################
# * Install packages
RUN apt update \
    && apt install -y --no-install-recommends \
    sudo \
    git \
    htop \
    nvtop \
    wget \
    curl \
    psmisc \
    openssh-server \
    usbutils \
    # * Shell
    tmux \
    terminator \
    # * base tools
    udev \
    python3-pip \
    python3-dev \
    python3-setuptools \
    # python3-colcon-common-extensions \
    software-properties-common \
    lsb-release \
    libmodbus-dev \
    # ros-humble-rmw-cyclonedds-cpp \
    pkg-config \
    libglvnd-dev \
    libgl1-mesa-dev \
    libegl1-mesa-dev \
    libgles2-mesa-dev \
    # * Work tools
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    && add-apt-repository -y ppa:git-core/ppa \
    && apt-get update && apt-get install -y \
    curl \
    lsb-core \
    wget \
    build-essential \
    cmake \
    git \
    git-lfs \
    iputils-ping \
    make \
    openssh-server \
    openssh-client \
    libeigen3-dev \
    libssl-dev \
    python3-pip \
    python3-ipdb \
    python3-tk \
    python3-wstool \
    sudo git bash unattended-upgrades \
    apt-utils \
    && rm -rf /var/lib/apt/lists/*

    # https://catalog.ngc.nvidia.com/orgs/nvidia/containers/cudagl

RUN apt-get update && apt-get install -y --no-install-recommends \
    libatomic1 \
    libegl1 \
    libglu1-mesa \
    libgomp1 \
    libsm6 \
    libxi6 \
    libxrandr2 \
    libxt6 \
    libfreetype-dev \
    libfontconfig1 \
    openssl \
    libssl3 \
    wget \
    vulkan-tools \
    curl \
    tcl \
    && apt-get -y autoremove \
    && apt-get clean autoclean \
    && rm -rf /var/lib/apt/lists/*



RUN VULKAN_SDK_VERSION=$(curl -s https://vulkan.lunarg.com/sdk/latest/linux.txt) && \
    wget -q --show-progress \
    --progress=bar:force:noscroll \
    https://sdk.lunarg.com/sdk/download/${VULKAN_SDK_VERSION}/linux/vulkan_sdk.tar.xz \
    -O /tmp/vulkan_sdk.tar.xz \
    && echo "Installing Vulkan SDK ${VULKAN_SDK_VERSION}" \
    && mkdir -p /opt/vulkan \
    && tar -xf /tmp/vulkan_sdk.tar.xz -C /opt/vulkan \
    && mkdir -p /usr/local/include/ && cp -ra /opt/vulkan/${VULKAN_SDK_VERSION}/x86_64/include/* /usr/local/include/ \
    && mkdir -p /usr/local/lib && cp -ra /opt/vulkan/${VULKAN_SDK_VERSION}/x86_64/lib/* /usr/local/lib/ \
    && cp -a /opt/vulkan/${VULKAN_SDK_VERSION}/x86_64/lib/libVkLayer_*.so /usr/local/lib \
    && mkdir -p /usr/local/share/vulkan/explicit_layer.d \
    && cp /opt/vulkan/${VULKAN_SDK_VERSION}/x86_64/share/vulkan/explicit_layer.d/VkLayer_*.json /usr/local/share/vulkan/explicit_layer.d \
    && mkdir -p /usr/local/share/vulkan/registry \
    && cp -a /opt/vulkan/${VULKAN_SDK_VERSION}/x86_64/share/vulkan/registry/* /usr/local/share/vulkan/registry \
    && cp -a /opt/vulkan/${VULKAN_SDK_VERSION}/x86_64/bin/* /usr/local/bin \
    && ldconfig \
    && rm /tmp/vulkan_sdk.tar.xz && rm -rf /opt/vulkan

# Open ports for live streaming
EXPOSE 47995-48012/udp \
    47995-48012/tcp \
    49000-49007/udp \
    49000-49007/tcp \
    49100/tcp \
    8011/tcp \
    8012/tcp \
    8211/tcp \
    8899/tcp \
    8891/tcp

# ENV OMNI_SERVER=http://omniverse-content-production.s3-us-west-2.amazonaws.com/Assets/Isaac/${ISAAC_SIM_VERSION}
# ENV OMNI_SERVER omniverse://localhost/NVIDIA/Assets/Isaac/2022.1
# ENV OMNI_USER admin
# ENV OMNI_PASS admin
ENV MIN_DRIVER_VERSION=525.60.11

# Copy Isaac Sim files
COPY --from=isaac-sim /isaac-sim /isaac-sim
RUN mkdir -p /root/.nvidia-omniverse/config
COPY --from=isaac-sim /root/.nvidia-omniverse/config /root/.nvidia-omniverse/config
COPY --from=isaac-sim /etc/vulkan/icd.d/nvidia_icd.json /etc/vulkan/icd.d/nvidia_icd.json
COPY --from=isaac-sim /etc/vulkan/icd.d/nvidia_icd.json /etc/vulkan/implicit_layer.d/nvidia_layers.json

# Create necessary cache and config directories for Isaac Sim
RUN mkdir -p /isaac-sim/kit/cache && chmod -R 777 /isaac-sim/kit/cache
RUN mkdir -p /isaac-sim/kit/logs && chmod -R 777 /isaac-sim/kit/logs
RUN mkdir -p /isaac-sim/kit/data && chmod -R 777 /isaac-sim/kit/data

# Give user access to Isaac Sim
RUN chmod -R a+rX /isaac-sim

WORKDIR /isaac-sim


ENV TORCH_CUDA_ARCH_LIST="7.0+PTX"

# create an alias for omniverse python
ENV omni_python='/isaac-sim/python.sh'

#* Switch user to ${USER} early for package building
USER ${USER}

# Create user-specific Isaac Sim directories
RUN mkdir -p /home/${USER}/Documents/Kit/shared \
    && mkdir -p /home/${USER}/.nvidia-omniverse/logs \
    && mkdir -p /home/${USER}/.nvidia-omniverse/config \
    && mkdir -p /home/${USER}/.local/share/ov/data

RUN echo "alias omni_python='/isaac-sim/python.sh'" >> ~/.bashrc \
    && echo "export CARB_APP_DISABLE_AUDIO=1" >> ~/.bashrc

# Create user workspace and work there
RUN sudo mkdir -p /home/"${USER}"/work && sudo chown "${USER}":"${GROUP}" /home/"${USER}"/work
WORKDIR /home/"${USER}"/work

# Add cache date to avoid using cached layers older than this
ARG CACHE_DATE=2024-04-11

RUN mkdir pkgs && cd pkgs && git clone https://github.com/NVlabs/curobo.git

RUN $omni_python -m pip install ninja wheel tomli

RUN cd pkgs/curobo && $omni_python -m pip install .[dev] --no-build-isolation

WORKDIR /home/"${USER}"/work/pkgs/curobo


# install nvblox:
# install gflags and glog statically, instructions from: https://github.com/nvidia-isaac/nvblox/blob/public/docs/redistributable.md

RUN cd /home/"${USER}"/work/pkgs && wget https://cmake.org/files/v3.27/cmake-3.27.1.tar.gz && \
    tar -xvzf cmake-3.27.1.tar.gz && \
    sudo apt update && sudo apt install -y build-essential checkinstall zlib1g-dev libssl-dev && \
    cd cmake-3.27.1 && ./bootstrap && \
    make -j8 && \
    sudo make install && sudo rm -rf /var/lib/apt/lists/*

ENV USE_CX11_ABI=0
ENV PRE_CX11_ABI=ON

RUN cd /home/"${USER}"/work/pkgs && git clone https://github.com/sqlite/sqlite.git -b version-3.39.4 && \
    cd /home/"${USER}"/work/pkgs/sqlite && CFLAGS=-fPIC ./configure --prefix=/home/"${USER}"/work/pkgs/sqlite/install/ && \
    make && make install

RUN cd /home/"${USER}"/work/pkgs && git clone https://github.com/google/glog.git -b v0.6.0 && \
    cd glog && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_INSTALL_PREFIX=/home/"${USER}"/work/pkgs/glog/install/ \
    -DWITH_GFLAGS=OFF -DWITH_GTEST=OFF -DBUILD_SHARED_LIBS=OFF -DCMAKE_CXX_FLAGS=-D_GLIBCXX_USE_CXX11_ABI=${USE_CX11_ABI} \
    && make -j8 && make install

RUN cd /home/"${USER}"/work/pkgs && git clone https://github.com/gflags/gflags.git -b v2.2.2 && \
    cd gflags &&  \
    mkdir build && cd build && \
    cmake .. -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_INSTALL_PREFIX=/home/"${USER}"/work/pkgs/gflags/install/ \
    -DGFLAGS_BUILD_STATIC_LIBS=ON -DCMAKE_CXX_FLAGS=-D_GLIBCXX_USE_CXX11_ABI=${USE_CX11_ABI} \
    && make -j8 && make install

RUN cd /home/"${USER}"/work/pkgs &&  git clone https://github.com/valtsblukis/nvblox.git && cd /home/"${USER}"/work/pkgs/nvblox/nvblox && \
    mkdir build && cd build && \
    cmake ..  -DBUILD_REDISTRIBUTABLE=ON \
    -DCMAKE_CXX_FLAGS=-D_GLIBCXX_USE_CXX11_ABI=${USE_CX11_ABI}  -DPRE_CXX11_ABI_LINKABLE=${PRE_CX11_ABI} \
    -DSQLITE3_BASE_PATH="/home/"${USER}"/work/pkgs/sqlite/install/" -DGLOG_BASE_PATH="/home/"${USER}"/work/pkgs/glog/install/" \
    -DGFLAGS_BASE_PATH="/home/"${USER}"/work/pkgs/gflags/install/" -DCMAKE_CUDA_FLAGS=-D_GLIBCXX_USE_CXX11_ABI=${USE_CX11_ABI} \
    -DBUILD_TESTING=OFF && \
    make -j32 && \
    sudo make install

# we also need libglog for pytorch:
RUN cd /home/"${USER}"/work/pkgs/glog && \
    mkdir build_isaac && cd build_isaac && \
    cmake .. -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DWITH_GFLAGS=OFF -DWITH_GTEST=OFF -DBUILD_SHARED_LIBS=OFF -DCMAKE_CXX_FLAGS=-D_GLIBCXX_USE_CXX11_ABI=${USE_CX11_ABI} \
    && make -j8 && sudo make install

RUN cd /home/"${USER}"/work/pkgs && git clone https://github.com/NVlabs/nvblox_torch.git && \
    cd /home/"${USER}"/work/pkgs/nvblox_torch && \
    sh install_isaac_sim.sh $($omni_python -c 'import torch.utils; print(torch.utils.cmake_prefix_path)') && \
    $omni_python -m pip install -e .

# install realsense for nvblox demos:
RUN $omni_python -m pip install pyrealsense2 opencv-python transforms3d

RUN $omni_python -m pip install "robometrics[evaluator] @ git+https://github.com/fishbotics/robometrics.git"

RUN sudo add-apt-repository universe
RUN sudo apt update
RUN sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key  -o /usr/share/keyrings/ros-archive-keyring.gpg
# RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
RUN sudo apt update
# RUN sudo  apt install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" keyboard-configuration
RUN sudo DEBIAN_FRONTEND=noninteractive apt install -y ros-humble-desktop
#ROS2 Cyclone DDS
RUN sudo apt install -y ros-humble-rmw-cyclonedds-cpp
#colcon depend
RUN sudo apt install -y python3-colcon-common-extensions


##################### ZACK ADD BEGIN ##################################
###################### RealSense #############################
RUN sudo mkdir -p /etc/apt/keyrings
RUN curl -sSf https://librealsense.intel.com/Debian/librealsense.pgp | sudo tee /etc/apt/keyrings/librealsense.pgp > /dev/null
RUN echo "deb [signed-by=/etc/apt/keyrings/librealsense.pgp] https://librealsense.intel.com/Debian/apt-repo `lsb_release -cs` main" \
    | sudo tee /etc/apt/sources.list.d/librealsense.list


RUN sudo apt update && sudo apt install -y \
    # ros2
    python3-rosdep \
    ros-humble-diagnostic-updater \
    # realsense
    librealsense2-utils \
    librealsense2-dev \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/*

RUN sudo pip3 install setuptools
# opencv-contrib-python==4.11.0.86

#################### PyTorch ######################
# RUN pip3 install --ignore-install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

#################### Kinect Azure ###############################
# RUN apt-get update && apt install -y \
#     libgl1-mesa-dev libsoundio-dev libvulkan-dev libx11-dev libxcursor-dev libxinerama-dev libxrandr-dev libusb-1.0-0-dev libssl-dev libudev-dev mesa-common-dev uuid-dev

# WORKDIR /home/${USER}/work/azure
# RUN wget https://packages.microsoft.com/ubuntu/18.04/prod/pool/main/k/k4a-tools/k4a-tools_1.4.2_amd64.deb
# RUN wget https://packages.microsoft.com/ubuntu/18.04/prod/pool/main/libk/libk4a1.4-dev/libk4a1.4-dev_1.4.2_amd64.deb
# RUN wget https://packages.microsoft.com/ubuntu/18.04/prod/pool/main/libk/libk4a1.4/libk4a1.4_1.4.2_amd64.deb
# RUN wget http://ftp.de.debian.org/debian/pool/main/libs/libsoundio/libsoundio1_1.1.0-1_amd64.deb

# RUN ACCEPT_EULA=Y dpkg -i libk4a1.4_1.4.2_amd64.deb &&\
#     dpkg -i libk4a1.4-dev_1.4.2_amd64.deb
# RUN dpkg -i libsoundio1_1.1.0-1_amd64.deb
# RUN dpkg -i k4a-tools_1.4.2_amd64.deb

# RUN rm libk4a1.4_1.4.2_amd64.deb \
#     libk4a1.4-dev_1.4.2_amd64.deb \
#     libsoundio1_1.1.0-1_amd64.deb \
#     k4a-tools_1.4.2_amd64.deb

# WORKDIR /home/${USER}/work/azure
# RUN git clone https://github.com/microsoft/Azure-Kinect-Sensor-SDK.git
# WORKDIR /home/${USER}/work/azure/Azure-Kinect-Sensor-SDK
# RUN mkdir -p /etc/udev/rules.d/ && \
#     cp ./scripts/99-k4a.rules /etc/udev/rules.d/

# RUN rm -rf /home/${USER}/work/azure/Azure-Kinect-Sensor-SDK

WORKDIR /
# RUN ./config/pip/pip_setup.sh
##################### ZACK ADD END ##################################

############################## USER CONFIG ####################################
RUN ./config/shell/bash_setup.sh "${USER}" "${GROUP}" \
    && ./config/shell/terminator/terminator_setup.sh "${USER}" "${GROUP}" \
    && ./config/shell/tmux/tmux_setup.sh "${USER}" "${GROUP}" \
    && sudo rm -rf /config

RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
RUN echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> ~/.bashrc

# * Switch workspace to ~/work
WORKDIR /home/"${USER}"/work


# # create an alias for omniverse python
# ENV omni_python='/isaac-sim/python.sh'
# RUN echo "alias omni_python='/isaac-sim/python.sh'" >> ~/.bashrc
# # install curobo in work directory
# RUN git clone https://github.com/NVlabs/curobo.git
# RUN $omni_python -m pip install ninja wheel tomli
# RUN cd curobo && $omni_python -m pip install .[dev] --no-build-isolation

# * Make SSH available
EXPOSE 22

ENTRYPOINT [ "/entrypoint.sh", "terminator" ]
# ENTRYPOINT [ "/entrypoint.sh", "tmux" ]
# ENTRYPOINT [ "/entrypoint.sh", "bash" ]
# ENTRYPOINT [ "/entrypoint.sh" ]

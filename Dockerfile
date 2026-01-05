FROM ros:humble

# Install deps  
RUN apt update && apt upgrade -y
RUN apt install -y python3-pip


# ## Install PiCamera2 ##
# Install libcamera
WORKDIR /tmp
# Installing picamera2 package and dependencies
RUN apt update && apt install -y \
    python3 python3-dev python3-pip git python3-jinja2 \
    libcamera-dev libepoxy-dev libjpeg-dev libtiff5-dev libpng-dev \
    libboost-dev \
    libgnutls28-dev openssl pybind11-dev liblttng-ust-dev \
    qtbase5-dev libqt5core5a libqt5gui5 libqt5widgets5 \
    cmake ninja-build \
    python3-yaml python3-ply
    # libglib2.0-dev libgstreamer-plugins-base1.0-dev # Optional for gstreamer support

# Install meson via pip as the apt version is outdated
RUN pip install --no-cache-dir meson

# Clone and build libcamera
RUN git clone https://github.com/raspberrypi/libcamera.git --branch v0.5.0+rpt20250429
WORKDIR /tmp/libcamera
# ENV PATH="/tmp/.local/bin:$PATH"
# For gstreamer support, change -Dgstreamer=enabled
RUN /bin/bash -c "meson setup build --buildtype=release \
        -Dpipelines=rpi/vc4,rpi/pisp -Dipas=rpi/vc4,rpi/pisp \
        -Dv4l2=true -Dgstreamer=disabled -Dtest=false \
        -Dlc-compliance=disabled -Dcam=disabled -Dqcam=disabled \
        -Ddocumentation=disabled -Dpycamera=enabled"
# Append the -j 1 flag to ninja commands to limit the build to a single process. 
RUN ninja -C build && ninja -C build install

# Install rpicam-apps
WORKDIR /tmp
RUN apt update && apt install -y \
    libboost-program-options-dev libdrm-dev libexif-dev
RUN git clone https://github.com/raspberrypi/rpicam-apps.git --branch v1.7.0
WORKDIR /tmp/rpicam-apps
# For headless operation
RUN /bin/bash -c "meson setup build -Denable_libav=disabled -Denable_drm=enabled -Denable_egl=disabled -Denable_qt=disabled -Denable_opencv=disabled -Denable_tflite=disabled -Denable_hailo=disabled"
# For desktop operation
# RUN /bin/bash -c "meson setup build -Denable_libav=enabled -Denable_drm=enabled -Denable_egl=enabled -Denable_qt=enabled -Denable_opencv=disabled -Denable_tflite=disabled -Denable_hailo=disabled"
# Append the -j 1 flag to meson commands to limit the build to a single process.
RUN /bin/bash -c "meson compile -C build && meson install -C build"


# Install libkms dependencies
RUN apt update && apt install -y \
libfmt-dev libdrm-dev libcap-dev

# Install kmsxx
WORKDIR /tmp
RUN git clone https://github.com/tomba/kmsxx.git
WORKDIR /tmp/kmsxx
RUN meson setup build -Dpykms=enabled
RUN ninja -C build install

# Updates the dynamic linker run-time bindings. This ensures that shared libraries 
# are properly loaded and available for use by the system and applications.
RUN ldconfig


# Get python bindings for pykms and libcamera
RUN echo "/usr/local/lib/x86_64-linux-gnu/python3.10/site-packages" | tee /usr/local/lib/python3.10/dist-packages/kms_custom.pth

# RUN pip install --upgrade pip
# RUN pip install rpi-libcamera -C setup-args="-Drepository=https://github.com/raspberrypi/libcamera.git" -C setup-args="-Drevision=v0.5.0+rpt20250429"
RUN pip install picamera2


# Clean up
RUN rm -rf /tmp/libcamera
RUN rm -rf /tmp/rpicam-apps
RUN rm -rf /tmp/kmsxx

WORKDIR /home

ENTRYPOINT ["/bin/bash"]
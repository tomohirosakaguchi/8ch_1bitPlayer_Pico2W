FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PICO_SDK_PATH=/opt/pico-sdk
ENV PICO_TOOLCHAIN_PATH=/opt/arm-toolchain

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    python3 \
    python3-pip \
    libusb-1.0-0-dev \
    pkg-config \
    gcc-arm-none-eabi \
    libnewlib-arm-none-eabi \
    libstdc++-arm-none-eabi-newlib \
    && rm -rf /var/lib/apt/lists/*

# Clone Pico SDK v2.0.0
RUN git clone -b 2.0.0 https://github.com/raspberrypi/pico-sdk.git ${PICO_SDK_PATH} && \
    cd ${PICO_SDK_PATH} && \
    git submodule update --init

# Clone Pico Tools (optional for building, but useful for flashing)
RUN git clone https://github.com/raspberrypi/pico-tools.git /opt/pico-tools && \
    cd /opt/pico-tools && \
    git submodule update --init || true

# Build and install picotool (optional)
RUN cd /opt/pico-tools && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install || echo "picotool build skipped"

# Set working directory
WORKDIR /workspace

# Create a build script
RUN echo '#!/bin/bash\n\
set -e\n\
echo "Building Pico project..."\n\
\n\
# Remove old build directory if it exists\n\
rm -rf /workspace/build\n\
\n\
mkdir -p /workspace/build\n\
cd /workspace/build\n\
\n\
# Configure with explicit Pico 2 settings\n\
cmake -DCMAKE_BUILD_TYPE=Release \\\n\
    -DPICO_BOARD=pico2 \\\n\
    -DPICO_PLATFORM=rp2350 \\\n\
    ..\n\
\n\
make -j$(nproc)\n\
echo "Build complete!"\n\
\n\
# Find and move .uf2 files to workspace root\n\
if find /workspace/build -name "*.uf2" -type f > /dev/null 2>&1; then\n\
    find /workspace/build -name "*.uf2" -type f -exec mv {} /workspace/ \;\n\
    echo "uf2 files moved to /workspace/"\n\
    ls -lh /workspace/*.uf2\n\
else\n\
    echo "Warning: No .uf2 files found"\n\
fi\n\
\n\
# Remove build directory\n\
cd /workspace\n\
rm -rf /workspace/build\n\
echo "Build directory removed"\n\
' > /usr/local/bin/build-pico.sh && chmod +x /usr/local/bin/build-pico.sh

CMD ["/bin/bash"]

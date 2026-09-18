FROM rust:latest AS builder
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        cmake \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /work
COPY ./netmuxd /work/netmuxd
RUN cd /work/netmuxd && \
    rm -rf target && \
    cargo build --release --bin netmuxd

FROM debian:latest
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git \
    build-essential \
    make \
    cmake \
    automake \
    autoconf \
    libtool \
    pkg-config \
    openssl \
    curl \
    libusb-1.0-0 \
    libzip-dev \
    libreadline8 \
    libssl-dev \
    libcurl4-openssl-dev \
    libusb-1.0-0-dev \
    python3-dev \
    libreadline-dev \
    libxml2-dev \
    ca-certificates \
    python3-pip \
    usbutils \
    iproute2 \
    psmisc \
    net-tools \
 && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    build_lib() { \
        repo="$1"; \
        ref="${2:-}"; \
        src_dir="/usr/src/"; \
        src="${src_dir}/${repo}"; \
        git clone "https://github.com/libimobiledevice/$repo.git" "$src"; \
        cd "$src"; \
        if [ -n "$ref" ]; then git checkout "$ref"; fi; \
        ./autogen.sh; \
        make -j"$(nproc)"; \
        make install; \
        cd "${src_dir}"; \
        rm -rf "${src_dir}/${repo}"; \
    }; \
    build_lib libplist; \
    build_lib libtatsu; \
    build_lib libimobiledevice-glue; \
    build_lib libusbmuxd; \
    build_lib libimobiledevice; \
    build_lib usbmuxd; \
    build_lib libirecovery; \
    build_lib idevicerestore; \
    build_lib libideviceactivation; \
    ldconfig

COPY --from=builder /work/netmuxd/target/release/netmuxd /usr/local/bin/netmuxd
RUN mkdir -p /var/lib/lockdown /data/idevice-backups

RUN python3 -m pip install --break-system-packages -U pymobiledevice3

COPY /container-files/start.sh /
COPY /container-files/device-backup.sh /
RUN chmod +x /start.sh /device-backup.sh
ENTRYPOINT [ "/start.sh" ]

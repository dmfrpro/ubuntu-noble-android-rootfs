FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV FORCE_UNSAFE_CONFIGURE=1

RUN dpkg --add-architecture i386


RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y apt-utils \
    && apt-get install -y \
    software-properties-common \
    libncursesw5-dev \
    libsqlite3-dev \
    libgdbm-dev \
    tk-dev \
    git \
    gnupg \
    flex \
    bison \
    build-essential \
    zip \
    curl \
    unzip \
    rsync \
    wget \
    make \
    bc \
    procps \
    zlib1g-dev \
    zlib1g-dev:i386 \
    gcc-multilib \
    g++-multilib \
    libc6-dev \
    libc6-dev-i386 \
    libncurses-dev:i386 \
    libx11-dev:i386 \
    libgl1-mesa-dev:i386 \
    libxml2-utils \
    libbz2-dev \
    xsltproc \
    fontconfig \
    adb \
    fastboot \
    acpica-tools \
    autoconf \
    automake \
    ccache \
    cpio \
    cscope \
    device-tree-compiler \
    e2tools \
    expect \
    ftp-upload \
    gdisk \
    libgnutls28-dev \
    libattr1-dev \
    libcap-ng-dev \
    libfdt-dev \
    libftdi1-dev \
    libglib2.0-dev \
    libgmp-dev \
    libhidapi-dev \
    libmpc-dev \
    libpixman-1-dev \
    libslirp-dev \
    libssl-dev \
    libtool \
    libusb-1.0-0-dev \
    mtools \
    netcat-openbsd \
    ninja-build \
    python3-cryptography \
    python3-pip \
    python3-pyelftools \
    python3-serial \
    python3-tomli \
    swig \
    uuid-dev \
    xdg-utils \
    xterm \
    xz-utils \
    zstd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz \
    && tar -xzf Python-2.7.18.tgz \
    && cd Python-2.7.18 \
    && ./configure \
    && make -j$(nproc) \
    && make install \
    && cd .. \
    && rm -rf Python-2.7.18 Python-2.7.18.tgz

RUN update-alternatives --install /usr/bin/python python /usr/local/bin/python2.7 100 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.12 50 \
    && update-alternatives --set python /usr/local/bin/python2.7 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 100 \
    && update-alternatives --set python3 /usr/bin/python3.12

RUN if [ ! -L /lib ] || [ "$(readlink /lib)" != "usr/lib" ]; then \
    rm -rf /lib && ln -sf usr/lib /lib ; \
    fi

RUN ln -sf usr/lib/i386-linux-gnu /lib32

ARG NIX_VERSION=2.34.6
RUN wget https://nixos.org/releases/nix/nix-${NIX_VERSION}/nix-${NIX_VERSION}-$(uname -m)-linux.tar.xz \
    && tar xf nix-${NIX_VERSION}-$(uname -m)-linux.tar.xz \
    && addgroup --gid 30000 --system nixbld \
    && for i in $(seq 1 30); do \
    useradd --system \
    --no-create-home \
    --home /var/empty \
    --comment "Nix build user $i" \
    --uid $((30000 + i)) \
    --gid nogroup \
    --groups nixbld \
    --shell /bin/false \
    nixbld$i ; \
    done \
    && mkdir -m 0755 /etc/nix \
    && echo 'sandbox = false' > /etc/nix/nix.conf \
    && mkdir -m 0755 /nix && USER=root sh nix-${NIX_VERSION}-$(uname -m)-linux/install \
    && ln -s /nix/var/nix/profiles/default/etc/profile.d/nix.sh /etc/profile.d/ \
    && rm -r /nix-${NIX_VERSION}-$(uname -m)-linux* \
    && /nix/var/nix/profiles/default/bin/nix-collect-garbage --delete-old \
    && /nix/var/nix/profiles/default/bin/nix-store --optimise \
    && /nix/var/nix/profiles/default/bin/nix-store --verify --check-contents

ONBUILD ENV \
    ENV=/etc/profile \
    USER=root \
    PATH=/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin \
    GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt \
    NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

ENV \
    ENV=/etc/profile \
    USER=root \
    PATH=/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin \
    GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt \
    NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    NIX_PATH=/nix/var/nix/profiles/per-user/root/channels

FROM alpine:3.18 AS build
# Enable community repository
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.18/community" >> /etc/apk/repositories && \
    apk add --no-cache \
        binutils \
        boost-dev \
        build-base \
        cmake \
        crypto++-dev \
        fmt-dev \
        gcc \
        g++ \
        gdb \
        gmp-dev \
        luajit-dev \
        make \
        mariadb-connector-c-dev \
        pugixml-dev && \
    rm -rf /var/cache/apk/*

COPY cmake /usr/src/forgottenserver/cmake/
COPY src /usr/src/forgottenserver/src/
COPY CMakeLists.txt /usr/src/forgottenserver/
WORKDIR /usr/src/forgottenserver/build

# Debug build: RelWithDebInfo with debug symbols
RUN cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo .. && \
    make -j$(nproc)

FROM alpine:3.18
# Enable community repository
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.18/community" >> /etc/apk/repositories && \
    apk add --no-cache \
        boost-iostreams \
        boost-system \
        boost-filesystem \
        crypto++ \
        fmt \
        gdb \
        gmp \
        luajit \
        mariadb-connector-c \
        pugixml \
        libstdc++ \
        libgcc \
        netcat-openbsd && \
    rm -rf /var/cache/apk/*

# Create non-root user for security
RUN addgroup -g 1000 tfs && \
    adduser -D -u 1000 -G tfs tfs && \
    mkdir -p /srv/data /srv && \
    chown -R tfs:tfs /srv

COPY --from=build --chown=tfs:tfs /usr/src/forgottenserver/build/tfs /usr/local/bin/tfs

USER tfs
EXPOSE 7171 7172
WORKDIR /srv

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD nc -z localhost 7171 || exit 1

ENTRYPOINT ["/usr/local/bin/tfs"]

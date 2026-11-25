# Build the ARM64-compatible ejabberd image from the pinned upstream source.
# This follows ProcessOne's 24.10 container build while retaining the
# /home/ejabberd layout used by the existing Ansible role.

ARG OTP_VERSION=26.2
ARG ELIXIR_VERSION=1.16.2
ARG EJABBERD_VERSION=24.10
ARG EJABBERD_SOURCE_COMMIT=601fcba4cbf881942fae4ab89bc8f666f7a9213f
ARG EJABBERD_UID=9000
ARG EJABBERD_USER=ejabberd
ARG EJABBERD_HOME=opt/ejabberd
ARG BUILD_DIR=/ejabberd

FROM docker.io/erlang:${OTP_VERSION}-alpine AS builder

RUN apk -U add --no-cache \
        autoconf \
        automake \
        bash \
        build-base \
        ca-certificates \
        curl \
        expat-dev \
        file \
        gd-dev \
        git \
        jpeg-dev \
        libpng-dev \
        libwebp-dev \
        linux-pam-dev \
        openssl-dev \
        sqlite-dev \
        yaml-dev \
        zlib-dev

ARG ELIXIR_VERSION
RUN wget -qO- "https://github.com/elixir-lang/elixir/archive/v${ELIXIR_VERSION}.tar.gz" \
        | tar -xzf - \
    && make -C "elixir-${ELIXIR_VERSION}" install clean

RUN mix local.hex --force \
    && mix local.rebar --force

ARG BUILD_DIR
ARG EJABBERD_VERSION
ARG EJABBERD_SOURCE_COMMIT
RUN git clone --branch "${EJABBERD_VERSION}" --depth 1 \
        https://github.com/processone/ejabberd.git "${BUILD_DIR}" \
    && test "$(git -C "${BUILD_DIR}" rev-parse HEAD)" = "${EJABBERD_SOURCE_COMMIT}"

WORKDIR ${BUILD_DIR}
RUN mv .github/container/ejabberdctl.template . \
    && ./autogen.sh \
    && ./configure --with-rebar=mix --enable-all \
    && make deps \
    && make rel

WORKDIR /rootfs
ARG EJABBERD_HOME
ARG EJABBERD_VERSION
ARG BUILD_DIR
RUN mkdir -p "${EJABBERD_HOME}" "${EJABBERD_HOME}-${EJABBERD_VERSION}" \
    && cp -r "${BUILD_DIR}/_build/prod/rel/ejabberd/." \
        "${EJABBERD_HOME}-${EJABBERD_VERSION}/" \
    && mv "${EJABBERD_HOME}-${EJABBERD_VERSION}/conf" \
        "${EJABBERD_HOME}/conf" \
    && cp -p "${BUILD_DIR}"/tools/captcha*.sh \
        "${EJABBERD_HOME}-${EJABBERD_VERSION}/lib/" \
    && find "${EJABBERD_HOME}-${EJABBERD_VERSION}/bin" \
        -name ejabberd -delete \
    && find "${EJABBERD_HOME}-${EJABBERD_VERSION}/releases" \
        -name COOKIE -delete \
    && wget -qO "${EJABBERD_HOME}/conf/cacert.pem" \
        https://curl.se/ca/cacert.pem

RUN apk -U add --no-cache git libcap openssl

RUN mkdir -p \
        usr/local/bin \
        "${EJABBERD_HOME}/database" \
        "${EJABBERD_HOME}/logs" \
        "${EJABBERD_HOME}/upload"

RUN home_root_dir="$(dirname "${EJABBERD_HOME}")" \
    && ejabberdctl_path="$(find "${home_root_dir}" -name ejabberdctl -type f | head -n 1)" \
    && setcap cap_net_bind_service=+ep \
        "$(find "${home_root_dir}" -name beam.smp -type f | head -n 1)" \
    && printf '%s\n' \
        '#!/bin/sh' \
        ': "${ERLANG_NODE_ARG:=ejabberd@localhost}"' \
        'export ERLANG_NODE_ARG' \
        "export CONFIG_DIR=/${EJABBERD_HOME}/conf" \
        "export LOGS_DIR=/${EJABBERD_HOME}/logs" \
        "export SPOOL_DIR=/${EJABBERD_HOME}/database" \
        "exec /${ejabberdctl_path} \"\$@\"" \
        > usr/local/bin/ejabberdctl \
    && chmod 0755 usr/local/bin/ejabberdctl \
    && scanelf --needed --nobanner --format '%n#p' \
        --recursive "${home_root_dir}" \
        | tr ',' '\n' \
        | sort -u \
        | awk -v root="${home_root_dir}" \
            'system("[ -e " root $1 " ]") == 0 { next } { print "so:" $1 }' \
        | sed -e "s|so:libc.so|so:libc.musl-$(uname -m).so.1|" \
        > /tmp/runtime-dependencies

ARG EJABBERD_UID
RUN chown -R "${EJABBERD_UID}:${EJABBERD_UID}" \
        "${EJABBERD_HOME}" "${EJABBERD_HOME}-${EJABBERD_VERSION}"

FROM docker.io/erlang:${OTP_VERSION}-alpine AS runtime

RUN apk del .erlang-rundeps \
    && rm -f "$(command -v rebar3)" \
    && find /usr -type d -name erlang -exec rm -rf {} + \
    && find /usr -type l ! -exec test -e {} \; -delete

COPY --from=builder /tmp/runtime-dependencies /tmp/runtime-dependencies
RUN apk -U upgrade --available --no-cache \
    && apk add --no-cache \
        $(cat /tmp/runtime-dependencies) \
        ca-certificates \
        so:libcap.so.2 \
        tini \
    && rm /tmp/runtime-dependencies

ARG EJABBERD_USER
ARG EJABBERD_UID
ARG EJABBERD_HOME
RUN addgroup "${EJABBERD_USER}" -g "${EJABBERD_UID}" \
    && adduser -s /sbin/nologin -D -u "${EJABBERD_UID}" \
        -h "/${EJABBERD_HOME}" -G "${EJABBERD_USER}" "${EJABBERD_USER}" \
    && mkdir -p "/${EJABBERD_HOME}" \
    && ln -s /usr/local/bin "/${EJABBERD_HOME}/bin" \
    && rm -rf /home \
    && ln -s /opt /home

FROM scratch

ARG EJABBERD_USER
ARG EJABBERD_HOME

ENV HOME=/${EJABBERD_HOME} \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

COPY --from=runtime / /
COPY --from=builder /rootfs /

HEALTHCHECK --interval=1m --timeout=5s --start-period=10s --retries=10 \
    CMD ejabberdctl status

WORKDIR /${EJABBERD_HOME}
USER ${EJABBERD_USER}

EXPOSE 1883 4369-4399 5222 5269 5280 5443

ENTRYPOINT ["/sbin/tini", "--", "ejabberdctl"]
CMD ["foreground"]

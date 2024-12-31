FROM debian:11

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        xl2tpd ppp iptables iproute2 && \
    rm -rf /var/lib/apt/lists/*

# Simple entrypoint to start xl2tpd
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 1701/udp

ENTRYPOINT ["/entrypoint.sh"]

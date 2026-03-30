FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates procps iproute2 net-tools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
COPY start-victim.sh /opt/start-victim.sh
RUN chmod +x /opt/start-victim.sh

ENTRYPOINT ["/opt/start-victim.sh"]

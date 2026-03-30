FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
COPY start-agent.sh /opt/start-agent.sh
RUN chmod +x /opt/start-agent.sh

ENTRYPOINT ["/opt/start-agent.sh"]

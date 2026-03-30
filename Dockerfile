FROM bcsecurity/empire:latest

EXPOSE 1337 5000

# Root Dockerfile to build Empire from repository root.
LABEL org.opencontainers.image.title="C2 Labs Empire"
LABEL org.opencontainers.image.description="Local Empire image for C2 lab"

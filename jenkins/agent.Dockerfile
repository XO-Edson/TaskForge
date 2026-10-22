FROM jenkins/inbound-agent:jdk21

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       git curl ca-certificates nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# Copy the Docker CLI, not a separate Docker daemon.
COPY --from=docker:cli /usr/local/bin/docker /usr/local/bin/docker

# Match the mounted Docker socket's group ID.
RUN groupadd -g 1001 hostdocker \
    && usermod -aG hostdocker jenkins

USER jenkins


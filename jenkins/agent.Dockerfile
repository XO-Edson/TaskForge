
FROM jenkins/inbound-agent:jdk21

USER root

ARG KUBECTL_VERSION=v1.37.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       git curl ca-certificates nodejs npm awscli \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    curl -fsSLo /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"; \
    curl -fsSLo /tmp/kubectl.sha256 \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"; \
    echo "$(cat /tmp/kubectl.sha256)  /usr/local/bin/kubectl" | sha256sum --check; \
    chmod +x /usr/local/bin/kubectl; \
    rm /tmp/kubectl.sha256

COPY --from=docker:cli /usr/local/bin/docker /usr/local/bin/docker

RUN groupadd -g 1001 hostdocker \
    && usermod -aG hostdocker jenkins

USER jenkins



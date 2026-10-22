FROM jenkins/jenkins:lts-jdk21

USER root

RUN groupadd -g 1001 hostdocker \
    && usermod -aG hostdocker jenkins

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       nodejs npm \
    && rm -rf /var/lib/apt/lists/*

COPY --from=docker:cli /usr/local/bin/docker /usr/local/bin/docker

USER jenkins


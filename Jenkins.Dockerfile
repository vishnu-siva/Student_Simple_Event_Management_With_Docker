FROM jenkins/jenkins:lts-jdk17

USER root

# Install dependencies and Docker CLI
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       git \
       curl \
       ca-certificates \
    && curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-27.5.1.tgz -o docker.tgz \
    && tar -xzvf docker.tgz --strip 1 -C /usr/local/bin docker/docker \
    && rm docker.tgz \
    && chmod +x /usr/local/bin/docker \
    && mkdir -p /usr/local/lib/docker/cli-plugins \
    && curl -L https://github.com/docker/compose/releases/download/v2.29.7/docker-compose-linux-x86_64 \
       -o /usr/local/lib/docker/cli-plugins/docker-compose \
    && chmod +x /usr/local/lib/docker/cli-plugins/docker-compose \
    && groupadd -f docker \
    && usermod -aG docker jenkins \
    && rm -rf /var/lib/apt/lists/*

USER jenkins

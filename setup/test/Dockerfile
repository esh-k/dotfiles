# Fresh Ubuntu with a sudo-capable non-root user, to exercise install.sh as on a real sandbox.
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends sudo curl ca-certificates git \
    && useradd -m -s /bin/bash dev && echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev
USER dev
WORKDIR /home/dev
COPY --chown=dev . /home/dev/setup

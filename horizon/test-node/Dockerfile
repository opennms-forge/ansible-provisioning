# Build Ubuntu image with base functionality.
FROM ubuntu:jammy AS ubuntu-base
ENV DEBIAN_FRONTEND noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Setup the default user.
RUN useradd -rm -d /home/ubuntu -s /bin/bash -g root -G sudo ubuntu
RUN echo 'ubuntu:ubuntu' | chpasswd
USER ubuntu
WORKDIR /home/ubuntu

# Build image with Python and SSHD.
FROM ubuntu-base AS ubuntu-with-sshd
USER root
ENV MACHINE_ID ""

# Install required tools.
RUN apt-get -qq update \
    && apt-get -qq --no-install-recommends install vim-tiny \
    && apt-get -qq --no-install-recommends install sudo \
    && apt-get -qq --no-install-recommends install python3-pip \
    && apt-get -qq --no-install-recommends install python3-apt \
    && apt-get -qq --no-install-recommends install openssh-server \
    && apt-get -qq --no-install-recommends install iproute2 \
    && apt-get -qq --no-install-recommends install inetutils-ping \
    && apt-get -qq --no-install-recommends install dnsutils \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

# Configure SSHD.
# SSH login fix. Otherwise user is kicked off after login
# Create a fake machine_id which is used from Ansible facts as a unique identifier in OpenNMS Horizon
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
    && mkdir /var/run/sshd \
    && echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config \
    && bash -c 'install -m755 <(printf "#!/bin/sh\nexit 0") /usr/sbin/policy-rc.d' \
    && ex +'%s/^#\zeListenAddress/\1/g' -scwq /etc/ssh/sshd_config \
    && ex +'%s/^#\zeHostKey .*ssh_host_.*_key/\1/g' -scwq /etc/ssh/sshd_config \
    && RUNLEVEL=1 dpkg-reconfigure openssh-server \
    && ssh-keygen -A -v \
    && update-rc.d ssh defaults

# Configure sudo.
RUN ex +"%s/^%sudo.*$/%sudo ALL=(ALL:ALL) NOPASSWD:ALL/g" -scwq! /etc/sudoers

# Generate and configure user keys.
USER ubuntu
RUN ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
COPY ./entrypoint.sh /entrypoint.sh
#COPY --chown=ubuntu:root "./files/authorized_keys" /home/ubuntu/.ssh/authorized_keys

# Setup default command and/or parameters.
EXPOSE 22
CMD ["/entrypoint.sh"]

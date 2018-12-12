#!/bin/bash
# Setup of riff mattermost on an Ubuntu base image
# having copied files to /setupfiles
# env variable(s) NODE_VER(unused right now) and GOLANG_VER must be set (use dockerfile ARG)

MM_USER="${MM_USER:-mmuser}"
MM_UID=${MM_UID:-1000}

# packages needed to install
INSTALL_PKGS=( curl apt-utils gcc g++ make wget gnupg2 ca-certificates )
MM_PKGS=( build-essential libpng-dev git )
DEV_PKGS=( vim-tiny )

# Setting found in Stack Overflow answer to:
# https://stackoverflow.com/questions/22466255/is-it-possible-to-answer-dialog-questions-when-installing-under-docker
# could be an ARG in dockerfile, or we just export it here. It won't persist in the docker image.
export DEBIAN_FRONTEND=noninteractive

# Update package db and install needed packages
echo "SETUP: Update apt and install packages ..."
apt-get update
apt-get install -y --no-install-recommends "${INSTALL_PKGS[@]}" "${MM_PKGS[@]}" "${DEV_PKGS[@]}"

# Install node --set up the apt repository to get the latest node ver 10
# (for production we may want to "lock it down" and use a different way of installing node.
#  such as: https://nodejs.org/dist/v10.13.0/node-v10.13.0-linux-x64.tar.xz)
echo "SETUP: Installing node 10.x ..."
curl -sL https://deb.nodesource.com/setup_10.x | bash -
apt-get install -y --no-install-recommends nodejs
npm install -g npm

# Install golang
echo "SETUP: Installing golang ${GOLANG_VER} ..."
GOLANG_ARC="go${GOLANG_VER}.linux-amd64.tar.gz"
wget --progress=dot:mega "https://dl.google.com/go/${GOLANG_ARC}"
tar -C /usr/local -xzf "${GOLANG_ARC}"
rm "${GOLANG_ARC}"

# In order to have /usr/local/go/bin on the path when running the entrypoint cmd
# we need to use the ENV command in the dockerfile, adding it in /etc/profile won't
# work because that isn't an interactive shell.
# echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile

# Clean up apt package cache
echo "SETUP: Clean up the apt package cache ..."
rm -rf /var/lib/apt/lists/*

# Create a non-root mattermost user to run riff mattermost in this container
echo "SETUP: Create non-root user ${MM_USER} ..."
useradd ${MM_USER} --uid ${MM_UID} --shell /bin/bash --create-home

# Modified bashrc which defines some aliases and an interactive prompt
mv /root/.bashrc /root/bashrc-original
ln -s /setupfiles/bashrc /root/.bashrc

mv /home/${MM_USER}/.bashrc /home/${MM_USER}/bashrc-original
ln -s /setupfiles/bashrc /home/${MM_USER}/.bashrc

ln -s /setupfiles/run.sh /home/${MM_USER}/run.sh

# Create the working directory for the mattermost server and webapp
mkdir -p /home/${MM_USER}/go/src/github.com/mattermost/mattermost-{server,webapp}

# Give ownership of everything in the MM_USER's home to the MM_USER
chown -R ${MM_USER}:${MM_USER} /home/${MM_USER}

# set the root password to password (I don't care that it's simple it's only for development)
# this shouldn't exist in a production container
echo "root:password" | chpasswd

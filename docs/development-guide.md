# Riff Development Guide

This guide explains how you can work on the various parts of the Riff platform; client,
platform API, data API ...

Because the components are inter-related, you will need to have all of these repositories
cloned locally. You do not need to have the following directory structure (you may set
environment variables to point to other locations) but the defaults are set to work with
this relative directory layout.

```
.
├── riff-docker
├── riff-rtc
└── riff-server
```

## Initial setup

### Prerequisites

- git
- docker
- make
- Python 3

### Clone and initialize working directories

```sh
mkdir riff
cd riff
git clone https://github.com/rifflearning/riff-docker.git
git clone https://github.com/rifflearning/riff-rtc.git
git clone https://github.com/rifflearning/riff-server.git
cd riff-docker
make init-rtc
make init-server
```

### Create development docker images

from the riff-docker working directory:

```sh
make build-dev
```

Re-run this command to rebuild the images. You only need to do that when
you want to refresh the base image (ie update node w/ any new patches).

## Running

run `make up` Then access `http://localhost`.

The containers are started detached so use `make stop` to stop the containers.

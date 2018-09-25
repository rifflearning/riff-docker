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
. nobuild-vars
make build-dev
```

Re-run this command to rebuild the images. Because the development images expect
the local repository working directories to be bound to the containers, you only
need to rebuild when you want to refresh the base image (ie update node w/ any new
patches).

It's best if you tag the development images w/ the `dev` tag, which will be set if
you don't override it. Running `. nobuild-vars` will unset all of the environment
variables which would set the image tags. Those environment variables are most often
used when building production images.

The `build-dev` target depends on (and therefore will create if they don't exist)
the self-signed ssl files.

## Running

run `make up` Then access `http://localhost`.

The containers are started detached so use `make stop` to stop the containers.
You can use `make down` to stop (if running) and remove the containers.

### Configuration

Use a `config/local-development.yml` file for local configuration settings in
`riff-rtc` (or `config/local.yml` if you want).

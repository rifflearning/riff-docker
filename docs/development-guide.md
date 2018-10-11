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
├── riff-server
└── signalmaster
```

## Initial setup

### Prerequisites

- git
- docker
- make
- Python 3 (only for needed for deploying)

### Clone and initialize working directories

```sh
mkdir riff
cd riff
git clone https://github.com/rifflearning/riff-docker.git
git clone https://github.com/rifflearning/riff-rtc.git
git clone https://github.com/rifflearning/riff-server.git
git clone https://github.com/rifflearning/signalmaster.git
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
the self-signed ssl files used by the `web-server` dev image.

## Working on the code

### riff-rtc and riff-server

These 2 projects use nodejs. You must either have the correct version of nodejs
installed locally or you may also use a container to run node commands such as
`npm` to update and install packages.

The Makefile has 2 targets to start an interactive commandline with the correct
node environment, `dev-rtc` and `dev-server`.


## Running

run `make up` Then access `https://localhost`.

You can use `export MAKE_UP_OPTS=-d` to have `make up` start the containers
detached in which case you will want to use `make stop` to stop the containers.
If the containers aren't running detached use `CTRL-C` to stop the containers.

If the containers are running detached you probably would like to follow the
logs (stdout) from one of them, likely the `riff-rtc` container. You can use
`make logs-rtc OPTS=-f`.

Use `make down` to stop (if running) and remove the containers.

### Configuration

Use a `config/local-development.yml` file for local configuration settings in
`riff-rtc` (or `config/local.yml` if you want).

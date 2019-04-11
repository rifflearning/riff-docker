#
# Makefile to manipulate docker images and containers for riff services
#

# force the shell used to be bash because for some commands we want to use
# set -o pipefail
SHELL=/bin/bash

# Directory where the files representing built images are located
IMAGE_DIR := images
DOCKER_LOG := $(IMAGE_DIR)/docker.log

# Directory where the ssl keys should be created/found
SSL_DIR := web-server/ssl

# The order to combine the compose/stack config files for spinning up
# the riff services using either docker-compose or docker stack
# for development, production or deployment in a docker swarm
CONF_BASE   := docker-compose.yml
CONF_DEV    := $(CONF_BASE) docker-compose.dev.yml
CONF_PROD   := $(CONF_BASE) docker-compose.prod.yml
CONF_DEPLOY := $(CONF_PROD) docker-stack.yml

COMPOSE_CONF_DEV := $(patsubst %,-f %,$(CONF_DEV))
COMPOSE_CONF_PROD := $(patsubst %,-f %,$(CONF_PROD))
STACK_CONF_DEPLOY := $(patsubst %,-c %,$(CONF_DEPLOY))

# The pull-images target is a helper to update the base docker images used
# by the edu stack services. This is a list of those base images.
BASE_IMAGES := \
	node:10 \
	mhart/alpine-node:10 \
	mysql:5.7 \
	mongo:latest \
	nginx:latest \
	ubuntu:latest


# These environment variables are used as build arguments by the docker-compose
# and docker-stack configuration files.
# The BUILD_ARG_OPTIONS build-prod target-specific variable contains a --build-arg
# option for each of these BUILD_ARGS which has a non-empty value.
# NOTE: spaces in the values of these environment variables will cause problems.
#       If spaces are needed in these values additional work will be needed to
#       support them.
BUILD_ARGS := \
	RIFF_SERVER_REF \
	RIFF_SERVER_TAG \
	SIGNALMASTER_TAG \
	SIGNALMASTER_REF \

# Not sure listing the other env vars that are used by the compose files
# and maybe by the Dockerfiles is useful here, so this is currently an
# unused variable
OTHER_ENV_ARGS := \
	UBUNTU_VER \
	NODE_VER \
	GOLANG_VER \
	MONGO_VER \
	NGINX_VER \
	DEPLOY_SWARM \

# command string which displays the values of all BUILD_ARGS
SHOW_ENV = $(patsubst %,echo '%';,$(foreach var,$(BUILD_ARGS) $(OTHER_ENV_ARGS),$(var)=$($(var))))


# Test if a variable has a value, callable from a recipe
# like $(call ndef,ENV)
ndef = $(if $(value $(1)),,$(error $(1) not set))

SSL_FILES := \
	$(SSL_DIR)/private/nginx-selfsigned.key \
	$(SSL_DIR)/certs/nginx-selfsigned.crt \
	$(SSL_DIR)/certs/dhparam.pem \


.DELETE_ON_ERROR :
.PHONY : help up down stop up-dev up-prod clean dev-server dev-sm
.PHONY : logs logs-mm logs-server logs-web logs-mongo
.PHONY : build-init-image init-server init-signalmaster
.PHONY : show-env build-dev build-prod push-prod

help :
	@echo ""                                                                           ; \
	echo "The mattermost branch in riff-docker no longer works. Use the edu-docker repository." ; \
	echo "" ; \
	echo "All the targets you used here should perform the same function in the edu-docker repo." ; \
	echo ""

up : help

up-dev :

up-prod :

down : help

stop : help

logs : help

clean : help

show-env : help

build-dev : help

build-prod : help

push-prod : help

deploy-stack : help

pull-images : help

dev-server : _start-dev

dev-sm : SERVICE_NAME = signalmaster
dev-sm : _start-dev

dev-mm : SERVICE_NAME = riff-mm
dev-mm : _start-dev

.PHONY : _start-dev
_start-dev : help

init-server : NODEAPP_PATH = $(realpath ../riff-server)
init-server : _nodeapp-init

init-signalmaster : NODEAPP_PATH = $(realpath ../signalmaster)
init-signalmaster : _nodeapp-init

.PHONY : _nodeapp-init
_nodeapp-init : help

.PHONY : logs-web logs-mm logs-server logs-mongo logs-mysql
logs-web : SERVICE_NAME = web-server
logs-web : logs

logs-mm : SERVICE_NAME = riff-mm
logs-mm : logs

logs-mysql : SERVICE_NAME = mm-mysql
logs-mysql : logs

logs-server : SERVICE_NAME = riff-server
logs-server : logs

logs-mongo : SERVICE_NAME = mongo-server
logs-mongo : logs

dev-swarm-labels : help

deploy-support-stack : help

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
SSL_DIR := pltfrm-web/ssl

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
	redis:latest \
	mongo:latest \
	nginx:latest

# The pull-support-images target is a helper to update the support docker images used
# by the support stack services. This is a list of those images.
SUPPORT_IMAGES := \
	registry:2 \
	dockersamples/visualizer:stable


# These environment variables are used as build arguments by the docker-compose
# and docker-stack configuration files.
# The BUILD_ARG_OPTIONS build-prod target-specific variable contains a --build-arg
# option for each of these BUILD_ARGS which has a non-empty value.
# NOTE: spaces in the values of these environment variables will cause problems.
#       If spaces are needed in these values additional work will be needed to
#       support them.
BUILD_ARGS := \
	RIFF_RTC_REF \
	RIFF_RTC_TAG \
	RTC_BUILD_TAG \
	RIFF_SERVER_REF \
	RIFF_SERVER_TAG \
	SIGNALMASTER_TAG \
	SIGNALMASTER_REF \

# Not sure listing the other env vars that are used by the compose files
# and maybe by the Dockerfiles is useful here, so this is currently an
# unused variable
OTHER_ENV_ARGS := \
	NODE_VER \
	MONGO_VER \
	NGINX_VER \
	REDIS_VER \
	DEPLOY_SWARM \

# command string which displays the values of all BUILD_ARGS
SHOW_ENV = $(patsubst %,echo '%';,$(foreach var,$(BUILD_ARGS) $(OTHER_ENV_ARGS),$(var)=$($(var))))

# If not defined on the make commandline or set in the environment set the default
# git ref for the commit in the riff-rtc repo to be used to create the rtc-build
# docker image.
# (see rtc-build-image target)
RIFF_RTC_REF ?= master
riff_rtc_context = https://github.com/rifflearning/riff-rtc.git\#$(RIFF_RTC_REF)
# The build tag that will be used for the created rtc-build docker images
# (see rtc-build-image target)
RTC_BUILD_TAG ?= latest

# if the RTC_BUILD_TAG is 'dev' build the rtc-build image from the local
# repo at ../riff-rtc instead of from a commit in the github repo.
ifeq ($(RTC_BUILD_TAG), dev)
	RIFF_RTC_REF := _LocalWorkingDirectory_
	RIFF_RTC_PATH ?= ../riff-rtc
	riff_rtc_context := $(RIFF_RTC_PATH)
endif


# Test if a variable has a value, callable from a recipe
# like $(call ndef,ENV)
ndef = $(if $(value $(1)),,$(error $(1) not set))

SSL_FILES := \
	$(SSL_DIR)/private/nginx-selfsigned.key \
	$(SSL_DIR)/certs/nginx-selfsigned.crt \
	$(SSL_DIR)/certs/dhparam.pem \


.DELETE_ON_ERROR :
.PHONY : help up down stop up-dev up-prod clean dev-server dev-rtc
.PHONY : logs logs-rtc logs-server logs-web logs-mongo
.PHONY : build-init-image init-rtc init-server init-signalmaster rtc-build-image
.PHONY : show-env build-dev build-prod push-prod

help :
	@echo ""                                                                           ; \
	echo "Useful targets in this riff-docker Makefile:"                                ; \
	echo "- up           : run docker-compose up (w/ dev config)"                      ; \
	echo "- up-prod      : run docker-compose up (w/ prod config)"                     ; \
	echo "- down         : run docker-compose down"                                    ; \
	echo "- stop         : run docker-compose stop"                                    ; \
	echo "- logs         : run docker-compose logs"                                    ; \
	echo "- logs-rtc     : run docker-compose logs for the riff-rtc service"           ; \
	echo "- logs-web     : run docker-compose logs for the web-server service"         ; \
	echo "- show-env     : displays the env var values used for building"              ; \
	echo "- build-dev    : (re)build the dev images pulling the latest base images"    ; \
	echo "- build-prod   : (re)build the prod images pulling the latest base images"   ; \
	echo "- push-prod    : push the prod images to the localhost registry"             ; \
	echo "- deploy-stack : deploy the riff-stack that was last pushed"                 ; \
	echo "- dev-server   : start a dev container for the riff-server"                  ; \
	echo "- dev-rtc      : start a dev container for the riff-rtc"                     ; \
	echo "- build-init-image  : build the initialization image used by init-rtc and init-server"          ; \
	echo "- init-rtc          : initialize the riff-rtc repo using the init-image to run 'make init'"     ; \
	echo "- init-server       : initialize the riff-server repo using the init-image to run 'make init'"  ; \
	echo "- init-signalmaster : initialize the signalmaster repo using the init-image to run 'make init'" ; \
	echo "- rtc-build-image   : create the rifflearning/rtc-build image needed as"     ; \
	echo "                      a base image for building the production riff-rtc"     ; \
	echo "                      and web-server images"                                 ; \
	echo "                      uses the RIFF_RTC_REF and RTC_BUILD_TAG vars."         ; \
	echo "- dev-swarm-labels  : add all constraint labels to single swarm node"        ; \
	echo "- deploy-support-stack : deploy the support stack needed for deploying other local images" ; \
	echo ""

up : up-dev

up-dev :
	docker-compose $(COMPOSE_CONF_DEV) up $(MAKE_UP_OPTS) $(OPTS)

up-prod :
	docker-compose $(COMPOSE_CONF_PROD) up --detach $(OPTS)

down :
	docker-compose down

stop :
	docker-compose stop

logs :
	docker-compose logs $(OPTS) $(SERVICE_NAME)

clean :
	-rm $(IMAGE_DIR)/*

show-env :
	@echo ""                                          ; \
	echo "Here are the current environment settings:" ; \
	$(SHOW_ENV)                                         \
	echo ""

build-dev : $(SSL_FILES)
	docker-compose build --pull $(OPTS) $(SERVICE_NAME)

build-prod : BUILD_ARG_OPTIONS := $(patsubst %,--build-arg %,$(filter-out %=,$(foreach var,$(BUILD_ARGS),$(var)=$($(var)))))
build-prod : rtc-build-image $(SSL_FILES)
	docker-compose $(COMPOSE_CONF_PROD) build $(BUILD_ARG_OPTIONS) $(SERVICE_NAME)

push-prod :
	docker-compose $(COMPOSE_CONF_PROD) push $(SERVICE_NAME)

deploy-stack :
# require that the DEPLOY_SWARM be explicitly defined.
	$(call ndef,DEPLOY_SWARM)
	docker stack deploy $(STACK_CONF_DEPLOY) -c docker-stack.$(DEPLOY_SWARM).yml pltfrm-stack

pull-images :
	echo $(BASE_IMAGES) | xargs -n 1 docker pull
	docker images

dev-server : SERVICE_NAME = pltfrm-riffdata
dev-server : _start-dev

dev-rtc : SERVICE_NAME = pltfrm-riffrtc
dev-rtc : _start-dev

dev-sm : SERVICE_NAME = pltfrm-signalmaster
dev-sm : _start-dev

.PHONY : _start-dev
_start-dev :
	$(call ndef,SERVICE_NAME)
	-docker-compose $(COMPOSE_CONF_DEV) run --service-ports $(OPTS) $(SERVICE_NAME) bash
	-docker-compose rm --force -v
	-docker-compose stop

# The build-init-image is a node based docker image used by the init-rtc and
# init-server targets it only needs to be rebuilt if the node image it is based
# on has been updated.
# See the _nodeapp-init target for its use. It will run 'make init' in the directory
# bound at /app and then exit.
build-init-image : $(IMAGE_DIR)/nodeapp-init.latest

init-rtc : NODEAPP_PATH = $(realpath ../riff-rtc)
init-rtc : _nodeapp-init

init-server : NODEAPP_PATH = $(realpath ../riff-server)
init-server : _nodeapp-init

init-signalmaster : NODEAPP_PATH = $(realpath ../signalmaster)
init-signalmaster : _nodeapp-init

.PHONY : _nodeapp-init
_nodeapp-init : build-init-image
	$(call ndef,NODEAPP_PATH)
	docker run --rm --tty --mount type=bind,src=$(NODEAPP_PATH),dst=/app rifflearning/nodeapp-init

.PHONY : logs-web logs-rtc logs-server logs-mongo
logs-web : SERVICE_NAME = pltfrm-web
logs-web : logs

logs-rtc : SERVICE_NAME = pltfrm-riffrtc
logs-rtc : logs

logs-server : SERVICE_NAME = pltfrm-riffdata
logs-server : logs

logs-mongo : SERVICE_NAME = pltfrm-riffdata-db
logs-mongo : logs

# Add all constraint labels to the single docker node running in swarm mode on a development machine
dev-swarm-labels :
	docker node update --label-add registry=true \
                       --label-add web=true \
                       --label-add mongo=true \
                       $(shell docker node ls --format="{{.ID}}")

# The support stack includes the registry which is needed to deploy any locally built images
# and the visualizer to show what's running on the nodes of the swarm
deploy-support-stack : pull-support-images

	docker stack deploy -c docker-stack.support.yml support-stack

pull-support-images :
	echo $(SUPPORT_IMAGES) | xargs -n 1 docker pull

$(SSL_DIR)/certs :
$(SSL_DIR)/private :
	@mkdir -p $(SSL_DIR)/certs $(SSL_DIR)/private

# Create the self-signed key & cert for https
$(SSL_DIR)/private/nginx-selfsigned.key : | $(SSL_DIR)/private
$(SSL_DIR)/certs/nginx-selfsigned.crt : | $(SSL_DIR)/certs
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $(SSL_DIR)/private/nginx-selfsigned.key -out $(SSL_DIR)/certs/nginx-selfsigned.crt

# Create a strong Diffie-Hellman group, which is used in negotiating Perfect Forward Secrecy with clients.
$(SSL_DIR)/certs/dhparam.pem : | $(SSL_DIR)/certs
	openssl dhparam -out $(SSL_DIR)/certs/dhparam.pem 2048

# The rtc-build-image contains the riff-rtc built files. These built files are copied from this
# image to the rtc-server and web-server images.
rtc-build-image : $(IMAGE_DIR)/rtc-build.$(notdir $(RTC_BUILD_TAG))

$(IMAGE_DIR) :
	@mkdir -p $(IMAGE_DIR)

$(IMAGE_DIR)/rtc-build.$(notdir $(RTC_BUILD_TAG)) : | $(IMAGE_DIR)
	set -o pipefail ; docker build $(OPTS) --rm --force-rm --pull --target build -t rifflearning/rtc-build:$(RTC_BUILD_TAG) $(riff_rtc_context)  2>&1 | tee $(DOCKER_LOG).$(notdir $@)
	@touch $@

$(IMAGE_DIR)/nodeapp-init.latest : | $(IMAGE_DIR)
	set -o pipefail ; docker build $(OPTS) --rm --force-rm --pull -t rifflearning/nodeapp-init:latest nodeapp-init 2>&1 | tee $(DOCKER_LOG).$(notdir $@)
	@touch $@

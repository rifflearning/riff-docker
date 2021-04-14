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
SSL_DIR := pfm-web/ssl

# The order to combine the compose/stack config files for spinning up
# the riff services using either docker-compose or docker stack
# for development, production or deployment in a docker swarm
# production used to have additional config but now it's just base.
CONF_BASE   := docker-compose.yml
CONF_DEV    := $(CONF_BASE) docker-compose.dev.yml
CONF_PROD   := $(CONF_BASE)
CONF_DEPLOY := $(CONF_PROD) docker-stack.yml

COMPOSE_CONF_DEV := $(patsubst %,-f %,$(CONF_DEV))
COMPOSE_CONF_PROD := $(patsubst %,-f %,$(CONF_PROD))
STACK_CONF_DEPLOY := $(patsubst %,-c %,$(CONF_DEPLOY))

# The pull-images target is a helper to update the base docker images used
# by the edu stack services. This is a list of those base images.
BASE_IMAGES := \
	node:14 \
	node:14-alpine \
	redis:latest \
	mongo:latest \
	nginx:latest

# The pull-support-images target is a helper to update the support docker images used
# by the support stack services. This is a list of those images.
SUPPORT_IMAGES := \
	registry:2 \
	dockersamples/visualizer:stable


# These environment variables are used as deploy arguments by the docker-compose
# and docker-stack configuration files.
DEPLOY_ARGS := \
	RIFF_RTC_TAG \
	RIFF_SERVER_TAG \
	DEPLOY_SWARM \

# command string which displays the values of all DEPLOY_ARGS
SHOW_ENV = $(patsubst %,echo '%';,$(foreach var,$(DEPLOY_ARGS),$(var)=$($(var))))


# Test if a variable has a value, callable from a recipe
# like $(call ndef,ENV)
ndef = $(if $(value $(1)),,$(error $(1) not set))

SSL_FILES := \
	$(SSL_DIR)/private/nginx-selfsigned.key \
	$(SSL_DIR)/certs/nginx-selfsigned.crt \
	$(SSL_DIR)/certs/dhparam.pem \


.DEFAULT_GOAL := help
.DELETE_ON_ERROR :
.PHONY : help up down stop up-dev up-prod clean dev-server dev-rtc
.PHONY : logs logs-rtc logs-server logs-web logs-mongo
.PHONY : build-init-image init-rtc init-server init-signalmaster rtc-build-image
.PHONY : show-env build-dev build-prod push-prod

up : up-dev ## run docker-compose up (w/ dev config)

up-dev :
	docker-compose $(COMPOSE_CONF_DEV) up $(MAKE_UP_OPTS) $(OPTS)

up-prod : ## run docker-compose up (w/ prod config)
	docker-compose $(COMPOSE_CONF_PROD) up --detach $(OPTS)

down : ## run docker-compose down
	docker-compose down

stop : ## run docker-compose stop
	docker-compose stop

logs : ## run docker-compose logs
	docker-compose logs $(OPTS) $(SERVICE_NAME)

clean : ## remove all build artifacts (including the tracking files for created images)
	-rm $(IMAGE_DIR)/*

clean-dev-images : down ## remove dev docker images
	docker rmi rifflearning/{pfm-riffrtc:dev,pfm-riffdata:dev,pfm-signalmaster:dev,pfm-web:dev}

show-env : ## displays the env var values used for building
	@echo ""                                          ; \
	echo "Here are the current environment settings:" ; \
	$(SHOW_ENV)                                         \
	echo ""

show-ps : ## Show all docker containers w/ limited fields
	docker ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}'

build-dev : $(SSL_FILES) ## (re)build the dev images pulling the latest base images
	docker-compose $(COMPOSE_CONF_DEV) build --pull $(OPTS) $(SERVICE_NAME)

deploy-stack : ## deploy the pfm-stk stack defined by compose/stack config and env var tags
# require that the DEPLOY_SWARM be explicitly defined.
	$(foreach var,$(DEPLOY_ARGS),$(call ndef,$(var)))
	docker stack deploy $(STACK_CONF_DEPLOY) -c docker-stack.$(DEPLOY_SWARM).yml --with-registry-auth pfm-stk

pull-images : ## Update base docker images
	echo $(BASE_IMAGES) | xargs -n 1 docker pull
	docker images

dev-server : SERVICE_NAME = pfm-riffdata ## start a dev container for the riff-server
dev-server : _start-dev

dev-rtc : SERVICE_NAME = pfm-riffrtc ## start a dev container for the riff-rtc
dev-rtc : _start-dev

dev-sm : SERVICE_NAME = pfm-signalmaster ## start a dev container for the signalmaster
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
build-init-image : $(IMAGE_DIR)/nodeapp-init.latest ## build the initialization image used by init-rtc and init-server

init-rtc : ## initialize the riff-rtc repo using the init-image to run 'make init'
init-rtc : NODEAPP_PATH = $(realpath ../riff-rtc)
init-rtc : _nodeapp-init

init-server : ## initialize the riff-server repo using the init-image to run 'make init'
init-server : NODEAPP_PATH = $(realpath ../riff-server)
init-server : _nodeapp-init

init-signalmaster : ## initialize the signalmaster repo using the init-image to run 'make init'
init-signalmaster : NODEAPP_PATH = $(realpath ../signalmaster)
init-signalmaster : _nodeapp-init

.PHONY : _nodeapp-init
_nodeapp-init : build-init-image
	$(call ndef,NODEAPP_PATH)
	docker run --rm --tty \
		--mount type=bind,src=$(NODEAPP_PATH),dst=/app \
		--mount type=bind,src=$(HOME)/.npmrc,dst=/home/mmuser/.npmrc \
		rifflearning/nodeapp-init

.PHONY : logs-web logs-rtc logs-server logs-mongo
logs-web : SERVICE_NAME = pfm-web ## run docker-compose logs for the pfm-web service
logs-web : logs

logs-rtc : SERVICE_NAME = pfm-riffrtc ## run docker-compose logs for the pfm-riffrtc service
logs-rtc : logs

logs-server : SERVICE_NAME = pfm-riffdata ## run docker-compose logs for the pfm-riffdata service
logs-server : logs

logs-mongo : SERVICE_NAME = pfm-riffdata-db ## run docker-compose logs for the pfm-riffdata-db service
logs-mongo : logs

# Add all constraint labels to the single docker node running in swarm mode on a development machine
dev-swarm-labels : ## add all constraint labels to single swarm node
	docker node update --label-add registry=true \
                       --label-add web=true \
                       --label-add mongo=true \
                       $(shell docker node ls --format="{{.ID}}")

# The support stack includes the registry which is needed to deploy any locally built images
# and the visualizer to show what's running on the nodes of the swarm
deploy-support-stack : pull-support-images ## deploy the support stack needed for deploying other local images
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

$(IMAGE_DIR) :
	@mkdir -p $(IMAGE_DIR)

$(IMAGE_DIR)/nodeapp-init.latest : | $(IMAGE_DIR)
	set -o pipefail ; docker build $(OPTS) --rm --force-rm --pull -t rifflearning/nodeapp-init:latest nodeapp-init 2>&1 | tee $(DOCKER_LOG).$(notdir $@)
	@touch $@

# Help documentation à la https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
# if you want the help sorted rather than in the order of occurrence, pipe the grep to sort and pipe that to awk
help : ## this help documentation (extracted from comments on the targets)
	@echo ""                                            ; \
	echo "Useful targets in this riff-docker Makefile:" ; \
	(grep -E '^[a-zA-Z_-]+ ?:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = " ?:.*?## "}; {printf "\033[36m%-20s\033[0m : %s\n", $$1, $$2}') ; \
	echo ""

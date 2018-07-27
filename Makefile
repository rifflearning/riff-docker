#
# Makefile to manipulate docker containers for riff (server and rtc)
#

# Test if a variable has a value, callable from a recipe
# like $(call ndef,ENV)
ndef = $(if $(value $(1)),,$(error $(1) not set))

.DELETE_ON_ERROR :
.PHONY : help up down stop rebuild dev-server dev-rtc start-dev image-web-server

help :
	@echo ""                                                                     ; \
	echo "Useful targets in this riff-docker Makefile:"                          ; \
	echo "- up          : run docker-compose up (w/ dev images)"                  ; \
	echo "- down        : run docker-compose down"                                ; \
	echo "- stop        : run docker-compose stop"                                ; \
	echo "- logs        : run docker-compose logs"                                ; \
	echo "- rebuild     : rebuild the images pulling the latest dependent images" ; \
	echo "- dev-server  : start a dev container for the riff-server"              ; \
	echo "- dev-rtc     : start a dev container for the riff-rtc"                 ; \
	echo "- build-init-image : build the initialization image used by init-rtc and init-server" ; \
	echo "- init-rtc    : initialize the riff-rtc repo by running using the init-image to run 'make init'" ; \
	echo "- init-server : initialize the riff-server repo by running using the init-image to run 'make init'" ; \
	echo ""

up :
	docker-compose up

down :
	docker-compose down

stop :
	docker-compose stop

logs :
	docker-compose logs $(SERVICE-NAME)

rebuild :
	docker-compose build --pull $(SERVICE-NAME)

dev-server : SERVICE-NAME = riff-server
dev-server : _start-dev

dev-rtc : SERVICE-NAME = riff-rtc
dev-rtc : _start-dev

_start-dev :
	$(call ndef,SERVICE-NAME)
	-docker-compose run --service-ports $(SERVICE-NAME) bash
	-docker-compose rm --force
	-docker-compose stop

# The build-init-image is a node based docker image used by the init-rtc and
# init-server targets it only needs to be rebuilt if the node image it is based
# on has been updated.
# See the _nodeapp-init target for its use. It will run 'make init' in the directory
# bound at /app and then exit.
build-init-image :
	docker build --pull -t rifflearning/nodeapp-init nodeapp-init

init-rtc : NODEAPP-PATH = $(realpath ../riff-rtc)
init-rtc : _nodeapp-init

init-server : NODEAPP-PATH = $(realpath ../riff-server)
init-server : _nodeapp-init

_nodeapp-init :
	$(call ndef,NODEAPP-PATH)
	docker run --rm --tty --mount type=bind,src=$(NODEAPP-PATH),dst=/app rifflearning/nodeapp-init

# I'm leaving this target although I've removed it from the help because
# it's not as generally needed anymore.
image-web-server : SERVICE-NAME = web-server
image-web-server : rebuild

logs-web : SERVICE-NAME = web-server
logs-web : logs

logs-rtc : SERVICE-NAME = riff-rtc
logs-rtc : logs

logs-mongo : SERVICE-NAME = mongo-server
logs-mongo : logs



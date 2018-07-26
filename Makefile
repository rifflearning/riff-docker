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
	echo "- up         : run docker-compose up"                                  ; \
	echo "- down       : run docker-compose down"                                ; \
	echo "- stop       : run docker-compose stop"                                ; \
	echo "- rebuild    : rebuild the images pulling the latest dependent images" ; \
	echo "- dev-server : start a dev container for the riff-server"              ; \
	echo "- dev-rtc    : start a dev container for the riff-rtc"                 ; \
	echo "- image-web-server : rebuild the web-server image"                     ; \
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

image-web-server : SERVICE-NAME = web-server
image-web-server : rebuild

logs-web : SERVICE-NAME = web-server
logs-web : logs

logs-rtc : SERVICE-NAME = riff-rtc
logs-rtc : logs

logs-mongo : SERVICE-NAME = mongo-server
logs-mongo : logs



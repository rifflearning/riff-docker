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
	docker-compose logs $(CONTAINER-NAME)

rebuild :
	docker-compose build --pull $(CONTAINER-NAME)

dev-server : CONTAINER-NAME = riff-server
dev-server : start-dev

dev-rtc : CONTAINER-NAME = riff-rtc
dev-rtc : start-dev

start-dev :
	$(call ndef,CONTAINER-NAME)
	-docker-compose run --service-ports $(CONTAINER-NAME) bash
	-docker-compose rm --force
	-docker-compose stop

image-web-server : CONTAINER-NAME = web-server
image-web-server : rebuild

logs-web : CONTAINER-NAME = web-server
logs-web : logs

logs-rtc : CONTAINER-NAME = riff-rtc
logs-rtc : logs

logs-mongo : CONTAINER-NAME = mongo-server
logs-mongo : logs



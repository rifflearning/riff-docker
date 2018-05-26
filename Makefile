#
# Makefile to manipulate docker containers for rhythm (server and rtc)
#

# Test if a variable has a value, callable from a recipe
# like $(call ndef,ENV)
ndef = $(if $(value $(1)),,$(error $(1) not set))

.DELETE_ON_ERROR :
.PHONY : help up rebuild dev-server dev-rtc start-dev

help :
	@echo ""                                                                     ; \
	echo "Useful targets in this rhythm-docker Makefile:"                        ; \
	echo "- up         : run docker-compose up"                                  ; \
	echo "- down       : run docker-compose down"                                ; \
	echo "- stop       : run docker-compose stop"                                ; \
	echo "- rebuild    : rebuild the images pulling the latest dependent images" ; \
	echo "- dev-server : start a dev container for the rhythm-server"            ; \
	echo "- dev-rtc    : start a dev container for the rhythm-rtc"               ; \
	echo ""

up :
	docker-compose up

down :
	docker-compose down

stop :
	docker-compose stop

rebuild :
	docker-compose build --pull

dev-server :  CONTAINER-NAME = rhythm-server
dev-server : start-dev

dev-rtc : CONTAINER-NAME = rhythm-rtc
dev-rtc : start-dev

start-dev :
	$(call ndef,CONTAINER-NAME)
	-docker-compose run --service-ports $(CONTAINER-NAME) bash
	-docker-compose rm --force
	-docker-compose stop

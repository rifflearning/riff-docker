.DELETE_ON_ERROR :
.PHONY : help build push up down

help :
	@echo ""                                                                           ; \
	echo "This Makefile is for getting and renewing letsencrypt ssl domain certificates." ; \
	echo "To do that you need to:"                                                     ; \
	echo "- build an image containing nginx and certbot"                               ; \
	echo "- Run that image somewhere that the domains can be pointed"                  ; \
	echo "  at the image such that nginx can respond to requests at the"               ; \
	echo "  domain to be renewed at port 80."                                          ; \
	echo "- copy the current letsencrypt structure into the running container"         ; \
	echo "- run certbot in the container w/ the appropriate options to renew"          ; \
	echo "  the certificates"                                                          ; \
	echo "- copy the updated letsencrypt structure w/ the updated certificates"	       ; \
	echo "  out of the container"                                                      ; \
	echo "- shutdown the certbot container"	                                           ; \
	echo ""                                                                            ; \
	echo "Do the following:"                                                           ; \
	echo "  make build"                                                                ; \
	echo "  make push"                                                                 ; \
	echo "  make up"                                                                   ; \
	echo "  ./renew.sh <letsencrypt archive file name> <fq domain to renew>"           ; \
	echo "  make down"                                                                 ; \
	echo ""	                                                                           ; \
	echo "Useful targets in this ssl-stack Makefile:"                                  ; \
	echo "- build        : build the certbot image"                                    ; \
	echo "- push         : push the certbot image to a registry so it can be deployed" ; \
	echo "- up           : run the certbot image by deploying it as a stack service"   ; \
	echo "- down         : remove the stack that deployed the certbot service"         ; \
	echo ""

build:
	docker-compose build

push:
	docker-compose push

up:
	echo "Deploying the ssl-stack"
	docker stack deploy -c docker-compose.yml ssl-stack

down:
	echo "Removing the ssl-stack"
	docker stack rm ssl-stack



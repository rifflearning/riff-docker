# riff-docker

The riff-docker project provides docker, docker-compose and stack configuration along with
scripts for developing the riff services and for deploying them using docker containers.

Currently the riff services are the [riff-rtc][] (server & client) and the [riff-server][].

[riff-server]: <https://github.com/rifflearning/riff-server> "Riff Learning riff-server repository"
[riff-rtc]: <https://github.com/rifflearning/riff-server> "Riff Learning riff-rtc repository"


## Usage

### Deploying to AWS

See the [deployment guide][].

[deployment guide]: <./docs/deployment-guide.md> "Deploying the Riff Platform to AWS"

### Development

See the [development guide][].

[development guide]: <./docs/development-guide.md> "Developing the Riff Platform Services"


### Makefile

`make` or `make help` will list useful targets provided.


### Development make targets

- `up`           : run docker-compose up (w/ dev config)
- `down`         : run docker-compose down
- `stop`         : run docker-compose stop
- `logs`         : run docker-compose logs
- `build-dev`    : (re)build the dev images pulling the latest base images
- `dev-server`   : starts an interactive bash prompt in the riff-server container
                   where commands such as _npm install_ and _npm test_ (or
                   _make test_) can be executed.
- `dev-rtc`      : starts an interactive bash prompt in the riff-rtc container
                   where commands such as _make build_, _npm install_,
                   _npm test_ (or _make test_) can be executed.
- `init-rtc`     : initialize the riff-rtc repo using the init-image to run 'make init'
- `init-server`  : initialize the riff-server repo using the init-image to run 'make init'


### Production make targets

Useful targets in this riff-docker Makefile:
- `prod-up`      : run docker-compose up (w/ prod config)
- `down`         : run docker-compose down
- `stop`         : run docker-compose stop
- `logs`         : run docker-compose logs
- `clean`        : removes any created files so they will be rebuilt (in particular the
                   files used to determine if make created a docker image)
- `push-prod`    : push the prod images to the localhost registry
- `deploy-stack` : deploy the riff-stack that was last pushed
- `rtc-build-image` : create the rifflearning/rtc-build image needed as
                    a base image for building the production riff-rtc
                    and web-server images
                    uses the RIFF_RTC_REF and RTC_BUILD_TAG vars.


## How the pieces fit together

### Dockerfiles

Each Riff repository contains Dockerfile(s) related to itself. The Dockerfile in
the root of the repository is the production Dockerfile which creates a
production image with all files needed to run the service provided by that
repository. If the repository is for client code, the image created will
be "built" and contain all build artifacts that should be served.

Dockerfiles for required services that need specialized configuration are in
subdirectories of this (riff-docker) repository e.g. the web-server Dockerfile
and configuration files are in the `web-server` subdirectory.

The Riff repositories also contain a development Dockerfile named `Dockerfile-dev`
located in the `docker` subdirectory of the repository. This docker directory
is the context used for building a Dockerfile-dev image. The context is minimal
because the repository directory is expected to be bound to any container run
using this dev image.

#### riff-rtc has 2 target production images (special case)

The `riff-rtc` repository contains code for both a server AND client code.
As such what is needed in the production rtc server image is different but
related to what is needed in the image which serves the client artifacts.

In order to make this work, a special intermediate build image must be created.
This intermediate image is created using the production Dockerfile in
riff-rtc and saving the image at the `build` stage with the image name
`rifflearning/rtc-build`.

Then the special Dockerfile in the riff-rtc repository `docker/Dockerfile-prod-server`
is used to create the rtc server image. It copied the files it needs from
the `rifflearning/rtc-build` image.

The `web-server/Dockerfile-prod` dockerfile in this riff-docker repository also
copies files needed from the `rifflearning/rtc-build` image.

_Example docker command to build the `rifflearning/rtc-build` image:_
```
docker build --target build -t rifflearning/rtc-build ../riff-rtc
```

### The "stack"

The files in this riff-docker repository define the "stack" of containers needed
both for development and for production deployment to a docker swarm in "the cloud"
(currently [AWS][]).

For development the images created will expect to have volumes bound to your
local working directories. This is so that changes there can be utilized
without having to rebuild images. These images usually only need to be rebuilt
when the base image (ie node) has changed.

For deployment to the cloud, the images created will contain all code needed
within the image.

### Compose/stack configuration files

The compose/swarm configuration files have been set up to try to avoid having
duplicate configuration where possible.

The configuration files in various combinations support the following tasks:

* Build development images
* Build production images
* Start containers/services for development
* Deploy stack to a docker swarm
* Update stack/services in a docker swarm

#### docker-compose.yml

The `docker-compose.yml` file contains configuration for building development
riff images and other required service images, but not enough information to
run those images in containers.

```
make rebuild
```
or
```
docker-compose build --pull
```

### docker-compose.dev.yml

The `docker-compose.dev.yml` file contains the additional configuration needed
for running the development services defined in `docker-compose.yml`. In particular
it defines how to bind mount the volumes needed by those images to local directories.

```sh
make up
```
or
```sh
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

Because all of the services are defined in `docker-compose.yml` you can use
`docker-compose stop`, `docker-compose down` and `docker-compose logs`. Or
just use `make stop`, `make down` and `make logs`.

### docker-compose.prod.yml

The `docker-compose.prod.yml` file contains additional configuration and
overrides development values in the base `docker-compose.yml` with production
values.

Because an rtc-build image is needed by the Dockerfiles specified in
`docker-compose.prod.yml` for the riff-rtc and web-server services, building
the images for production services requires building the `rifflearning/rtc-build`
image first.

```sh
export RIFF_SERVER_REF=feature/docker_4_swarm
export RIFF_RTC_REF=test
rm images/rtc-build.latest
make build-prod
make push-prod

```

### docker-stack.yml

The `docker-stack.yml` file contains additional configuration to be overlayed
on the configuration specified by the `docker-compose.yml` and the `docker-compose-prod.yml`
when deploying the stack of services to a docker swarm.

Assuming you have just run the `build-prod` and `push-prod` targets you can use
the `deploy-stack` target to deploy to the attached docker swarm.

```sh
make deploy-stack
```

### nodeapp-init

&lt;Description not written yet>

### Misc

The docker images that are created are all named with a prefix to facilitate
pushing the image to a local private repository (`localhost:5000/`), which may
actually be the remote cloud's private repository.

### Environment variables

#### Docker build/compose/deploy variables

* RIFF_RTC_PATH - path to riff-rtc repository. Default: .\./riff-rtc
* RIFF_SERVER_PATH - path to riff-server repository. Default: .\./riff-server
* RIFF_DB_PATH - path to location for Mongo DB files. Default: ./mongodata

* NODE_VER - nginx docker version (tag) to use when building the node based images
             such as riff-rtc and riff-server. 
             Default: 8
* NGINX_VER - nginx docker version (tag) to use when building the web-server. 
              Default: latest
* MONGO_VER - mongo docker version (tag) to use when building the mongo
              database service. 
              Default: latest

* RIFF_SERVER_TAG - Docker image tag to apply to riff-server production image. 
                    Default: latest
* RIFF_RTC_TAG    - Docker image tag to apply to riff-rtc production image and the
                    web-server production image. 
                    Default: latest
* RTC_BUILD_TAG   - Docker image tag to apply to the rifflearning/rtc-build image
                    which is used to build the riff-rtc and web-server production
                    images. 
                    Default: latest

* RIFF_SERVER_REF - for the production image build, defines the git reference
                    of the commit in the github riff-server repository to use
                    for the docker context. 
                    Default: master
* RIFF_RTC_REF    - for the production image build, defines the git reference
                    of the commit in the github riff-rtc repository to use
                    for the docker context. 
                    Default: master

#### riff-server image variables

The defaults for many of these defined in `docker-compose.yml` should be fine.
Others will need to be set before building production images.

* AUTH_ON
* AUTH_TOKEN_EXPIRESIN
* AUTH_TOKEN_SECRET
* CRYPTO_KEY
* DEFAULT_USER_EMAIL
* DEFAULT_USER_PASSWORD
* MONGODB_URI
* MONGO_CERT
* REPORT_EMAIL_FROM
* REPORT_EMAIL_HOST
* REPORT_EMAIL_LOGIN
* REPORT_EMAIL_PASSWORD
* REPORT_EMAIL_SUBJECT
* REPORT_EMAIL_TEXT
* SEND_REPORT
* END_MEETING_AFTER_MINUTES


#### riff-rtc image variables

* FIREBASE_CONFIG
* DATASERVER_EMAIL
* DATASERVER_PASSWORD
* SESSION_SECRET
* CONSUMER_SECRET
* CONSUMER_SECRET


[AWS]: <http://aws.amazon.com/> "Amazon Web Services"

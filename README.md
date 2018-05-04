# rhythm-docker

The rhythm-docker project provides docker configuration to get the [rhthm-server][] and
[rhythm-rtc][] projects up and running in a local development environment.

[rhthm-server]: <https://github.com/HumanDynamics/rhythm-server> "HumanDynamics rhythm-server repository"
[rhythm-rtc]: <https://github.com/HumanDynamics/rhythm-server> "HumanDynamics rhythm-rtc repository"


## Setup

The `docker-compose.yml` file is set up to expect the `rhythm-server` and `rhythm-rtc` repositories
to be in peer directories of this repository's working directory (although you may use environment
variables to override this).

```
.
├── rhythm-docker
├── rhythm-rtc
└── rhythm-server
```

### rhythm-server configuration

### rhythm-rtc configuration


## Usage

The `Makefile` provides useful targets for doing development on the `rhythm-server` and `rhythm-rtc`
repositories as well as other actions.

`make` or `make help` will list useful targets provided.

* `make dev-server` : starts an interactive bash prompt in the rhythm-server container where commands
                      such as `npm install` and `npm test` (or `make test`) can be executed.
* `make dev-rtc`    : starts an interactive bash prompt in the rhythm-rtc container where commands
                      such as `npm install` and `npm test` (or `make test`) can be executed.
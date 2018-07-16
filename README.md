# riff-docker

The riff-docker project provides docker configuration to get the [riff-server][] and
[riff-rtc][] projects up and running in a local development environment.

[riff-server]: <https://github.com/rifflearning/riff-server> "Riff Learning riff-server repository"
[riff-rtc]: <https://github.com/rifflearning/riff-server> "Riff Learning riff-rtc repository"


## Setup

The `docker-compose.yml` file is set up to expect the `riff-server` and `riff-rtc` repositories
to be in peer directories of this repository's working directory (although you may use environment
variables to override this).

```
.
├── riff-docker
├── riff-rtc
└── riff-server
```

### riff-server configuration

`.env` file:
```
AUTH_ON="true"
AUTH_TOKEN_EXPIRESIN="1000d"
AUTH_TOKEN_SECRET="my-secret"
CRYPTO_KEY="'your-key-here'"
DEFAULT_USER_EMAIL="default-user-email"
DEFAULT_USER_PASSWORD="default-user-password"
MONGODB_URI="mongodb://mongo-server/riff-test"
MONGO_CERT="some-fake-cert"
NODE_ENV="default"
PORT="3000"
REPORT_EMAIL_FROM="'MM Reports' <email@address.com>"
REPORT_EMAIL_HOST="smtp server here"
REPORT_EMAIL_LOGIN="email@address.com"
REPORT_EMAIL_PASSWORD="emailpassword"
REPORT_EMAIL_SUBJECT="Your Group Discussion Report"
REPORT_EMAIL_TEXT="See attached for a visual report of your recent group discussion!"
SEND_REPORT="false"
END_MEETING_AFTER_MINUTES=2
```

### riff-rtc configuration

`.env` file:
```
REACT_APP_SERVER_TOKEN=my-secret
REACT_APP_SERVER_URL=
REACT_APP_SERVER_EMAIL=default-user-email
REACT_APP_SERVER_PASSWORD=default-user-password
REACT_APP_TRACK_FACE=false
REACT_APP_DEBUG=true
REACT_APP_SIGNALMASTER_URL=<put a valid signaling url here>
PORT=3001
CONSUMER_KEY=key
CONSUMER_SECRET=secret
SESSION_SECRET=secret
ROOM_MAP_URL=nope
REDIS_URL=<redis instance>
CI=false
```
You must use a valid `REACT_APP_SIGNALMASTER_URL`, I have not listed one here because that is a
resource that must be provided.

The `REDIS_URL` is only needed when the `ROOM_MAP_URL` value is not `nope` for LTI launches.

The `REACT_APP_SERVER_URL=localhost:3000` value points to the URL for the videodata server (`riff-server`).
However the `web-server` container (nginx) is now configured to reverse proxy
at the http port (80) both `riff-rtc` and `riff-server`, so that property
should now be blank.

## Usage

### Deploying to AWS

See the [deployment guide].

[deployment guide]: <./docs/deployment-guide.md> "Deploying the Riff Platform to AWS"


### Running

run `make up` Then access `http://localhost/chat` optionally appending `?user=<name>&email=<email>&room=<roomName>`

Use &lt;ctrl>-c to stop the containers.

### Makefile

The `Makefile` provides useful targets for doing development on the `riff-server` and `riff-rtc`
repositories as well as other actions.

`make` or `make help` will list useful targets provided.

* `make dev-server` : starts an interactive bash prompt in the rhythm-server container where commands
                      such as `npm install` and `npm test` (or `make test`) can be executed.
* `make dev-rtc`    : starts an interactive bash prompt in the rhythm-rtc container where commands
                      such as `npm install` and `npm test` (or `make test`) can be executed.
* `make up`         : docker-compose up
* `make down`       : docker-compose down
* `make stop`       : docker-compose stop
* `make rebuild`    : rebuild images pulling latest dependent FROM images


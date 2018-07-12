# riff-docker

The rhythm-docker project provides docker configuration to get the [riff-server][] and
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
The `web-server` container (nginx) is no configured to reverse proxy at the http port (80) both
`riff-rtc` and `riff-server`, so that property should now be blank.

## Usage

### Deploying

We include two scripts to make deployment to a public Docker swarm "easy":
`cloudformation.py` and `swarm.py`. The basic usage for deployment involves:

1. Provision and start a cloudformation stack, creating a docker swarm on AWS
2. SSH tunnel to a manager in the cloudformation docker swarm you just made
2. Initialize the swarm by making a registry and starting everything in swarm mode
3. Build and push docker images to the remote registry in your swarm
4. Bring your swarm up! 

I go through the steps in detail below:

1. **Provision and start a cloudformation stack, creating a docker swarm on AWS**

To provision a cloudformation stack using `cloudformation.py`, first make sure
you have your AWS credentials configured correctly by running `aws configure`,
and make sure you know the name of the key you'll use to SSH to the created
instances. 

To create a swarm with 4 worker nodes that are t2.micro instances, 3 (the
default) managers that are t2.small instances, name it riffdeploy, and use the
ssh key pair named "dan", run:

```
cloudformation create_docker_stack -s 4 -i t2.micro -I t2.small riffdeploy dan
```

You can monitor the creation status of your swarm using:

```
❯ cloudformation stack_status riffdeploy
CREATE_IN_PROGRESS
```

once the status is `CREATE_COMPLETE`, you can move onto the next step.

2. **SSH tunnel to a manager in the cloudformation docker swarm you just made***

To ssh tunnel into your swarm and use the remote manager as your `DOCKER_HOST`,
you can run:

```
cloudformation.py tunnel -i ~/attic/aws/dan.pem riffdeploy
```

You should see output like:

```
❯ cloudformation.py tunnel -i ~/attic/aws/dan.pem riffdeploy
CREATE_COMPLETE
Instance IDs:
        0) i-02f4bd917994cf277
        1) i-0e13c196d1d0b8c59
        2) i-0f5153edf558f3af6
Enter the instance index:
```

The swarm you created has some number of manager nodes. To run properly, you
need to tunnel into just one. It usually doesn't matter which one you choose.

```
❯ cloudformation.py tunnel -i ~/attic/aws/dan.pem riffdeploy
CREATE_COMPLETE
Instance IDs:
        0) i-02f4bd917994cf277
        1) i-0e13c196d1d0b8c59
        2) i-0f5153edf558f3af6
Enter the instance index: 0
Manager IP: 54.91.27.98
No existing docker tunnel ssh processes found. Continuing to tunnel...
Continue tunneling? (y/n): y
```

You should see some output like this:

```
>> tunneling using:  ssh -i /home/dcalacci/attic/aws/dan.pem -f -NL localhost:2374:/var/run/docker.sock docker@54.91.27.98
The authenticity of host '54.91.27.98 (54.91.27.98)' can't be established.
ECDSA key fingerprint is SHA256:GxwBwJ358jbH8eLUpn8mpkFkYsEDK5mSsHG+GNqnbiU.
Are you sure you want to continue connecting (yes/no)? yes


Tunnel up.
Matching tunnel process IDs:
26414
To kill this tunnel, use the command kill_tunnel

 To use this tunnel with your local docker config, run:

         export DOCKER_HOST=localhost:2374

 To reset to your local environment, run:

         export DOCKER_HOST=
```

To complete tunneling, do what the output says, and run:

```
export DOCKER_HOST=localhost:2374
```


2. **Initialize the swarm by making a registry and starting everything in swarm mode
To initialize the swarm, you can run:**

```
❯ ./swarm.py init
```

```
❯ ./swarm.py init
Initializing docker swarm...
> docker swarm init
Starting registry at localhost:5000 named registry
> docker service create --name registry --publish ppublished=5000,target=5000 registry:2
Error response from daemon: This node is already part of a swarm. Use "docker swarm leave" to leave this swarm and join another one.
Registry 'registry' up, docker in swarm mode
Ready to deploy to local swarm.
```


3. **Build and push docker images to the remote registry in your swarm**

To build and push a configuration from a docker stack config named `production.yml`, run: 
```
❯ ./swarm.py push -f production.yml
```

You should see output like this, while it builds your image. It's being built on the remote manager node:
```
❯ ./swarm.py push -f production.yml

Building from production.yml
Continue? (y/n): y
WARNING: Some services (mongo-server, riff-rtc, riff-server, signalmaster, visualizer, web-server) use the 'deploy' key, which will be ignored. Compose does not support deploy configuration - use `docker stack deploy` to deploy to a swarm.
visualizer uses an image, skipping
mongo-server uses an image, skipping
Building riff-server
Step 1/50 : FROM node:8
8: Pulling from library/node
3d77ce4481b1: Pull complete
7d2f32934963: Pull complete
0c5cf711b890: Pull complete
9593dc852d6b: Pull complete
4b16c2786be5: Pull complete
5fcdaabfa451: Pull complete
5c8b2b2e4dd1: Pull complete
```

Eventually, it should push, and you should see a message like this:

```
.
. 
.
Pushing signalmaster (127.0.0.1:5000/signalmaster:latest)...
The push refers to repository [127.0.0.1:5000/signalmaster]
9cfe4beca73b: Pushed
1bbd865744b9: Pushed
e6b14dd6688f: Pushed
9ef882f5c2ea: Pushed
9dfa40a0da3b: Pushed
latest: digest: sha256:4dcf926009f0750c730f2ae9ef5d135eb66d9abe6c7a6bb5d73ddd373d00f869 size: 1366

To deploy the images you just pushed, run `swarm.py deploy`
```

4. **Deploy and bring your swarm up!**

To finally deploy, use `swarm.py deploy`. You have to give your stack a name. To
deploy `production.yml` and name it `riffdeploy`, run:

```
❯ ./swarm.py deploy -f production.yml -n riffdeploy
```

```
❯ ./swarm.py deploy -f production.yml -n riffdeploy
Have you already pushed this project to your repo? (y/n): y
Ignoring unsupported options: build

Creating network riffdeploy_default
Creating service riffdeploy_mongo-server
Creating service riffdeploy_signalmaster
Creating service riffdeploy_visualizer
Creating service riffdeploy_web-server
Creating service riffdeploy_riff-server
Creating service riffdeploy_riff-rtc
```

If you now run `docker service ls`, you should see the status of your services:

```
❯ docker service ls
ID                  NAME                      MODE                REPLICAS            IMAGE                                PORTS
4l7hp7iqdfmt        riffdeploy_signalmaster   replicated          1/1                 127.0.0.1:5000/signalmaster:latest   *:0->8888/tcp
hpnpv8trec3t        riffdeploy_web-server     replicated          1/1                 127.0.0.1:5000/web-server:latest     *:80->80/tcp
q4w9u2di1fmv        riffdeploy_mongo-server   replicated          1/1                 mongo:latest
q9eou1krhfa9        riffdeploy_visualizer     replicated          1/1                 dockersamples/visualizer:stable      *:8080->8080/tcp
t0gb5ujssskj        registry                  replicated          1/1                 registry:2                           *:5000->5000/tcp
w92gmp9ne454        riffdeploy_riff-rtc       replicated          0/1                 127.0.0.1:5000/riff-rtc:latest       *:0->3001/tcp
xw1xvel2ii6r        riffdeploy_riff-server    replicated          0/1                 127.0.0.1:5000/riff-server:latest    *:0->3000/tcp
```

5. **Get the public DNS, and test!**

You can get the public DNS of your swarm using `cloudformation.py
get_stack_dns`. To get the DNS of the stack we just deployed, named
`riffdeploy`, run:

```
❯ cloudformation get_stack_dns riffdeploy
riffdeplo-External-QH833A1J8HE8-1547422939.us-east-1.elb.amazonaws.com
```

This URL is the url you can use to access your newly deployed app!

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


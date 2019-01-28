# Riff Platform AWS deployment as Docker swarm

As of 2018-11-16 this is still a work in progress documenting the deployment
process. However it has more/additional information than the 1st
deployment-deguide.md document does. Eventually it should replace that document. -mjl

## Deploying

We include two scripts to make deployment to a public Docker swarm "easy":
`cloudformation.py` and `swarm.py`. (if you have problems getting those scripts
to run see the [setup python][] doc.) You will also need to have [docker][docker install]
and the [AWS CLI][] installed.


There are two major components to deploying in AWS.

The first component is creating the docker swarm running in AWS. We do that by
using the Amazon [cloudformation][] service to create a cloudformation stack
which creates all the composite pieces (instances, VPC, load balancer, etc.)
needed to run a docker swarm.

The second component is to deploy the Riff Platform docker stack (same name,
different concept from a cloudformation stack) to the cloudformation stack
that is our AWS docker swarm.

Once the cloudformation stack is up and running, you only need to repeat the
second part of deploying the docker stack to the cloudformation stack, you
won't need to continually recreate the cloudformation stack.

### Creating the docker swarm CloudFormation stack

By default the cloudformation script will use the cloudformation template
provided by docker, see [docker for AWS][].

To provision a cloudformation stack using `cloudformation.py`, first make sure
you have your AWS credentials configured correctly by running `aws configure`,
and make sure you know the name of the key you'll use to SSH to the created
instances.

To create a swarm with 4 worker nodes that are t2.micro instances, 3 (the
default) managers that are t2.small instances, name it betaAswarm, and use the
ssh key pair named "riffswarm_useast2_key", run:

```sh
bin/cloudformation.py create-docker-stack -s 4 -i t2.micro -m 3 -I t2.small betaAswarm riffswarm_useast2_key
```

You can monitor the creation status of your swarm using:

```console
$ bin/cloudformation.py stack-status betaAswarm
CREATE_IN_PROGRESS
```

once the status is `CREATE_COMPLETE`, you can move onto the next step.

You may want to add an entries in your ~/.ssh/config file something like this:

```
# Riff Learning Amazon Web Services (aws) betaswarm stack docker swarm manager 0 (& 1 & 2)
#   Note `ForwardAgent` is needed in order to ssh to the swarm manager, and then
#   ssh from there to the swarm workers, see https://docs.docker.com/docker-for-azure/deploy/#connecting-to-your-linux-worker-nodes-using-ssh
#   It does require that you ssh-add the identityfile before ssh'ing to the manager.
Host RiffBetaASwarm 18.223.134.226
  HostName 18.223.134.226
  User docker
  IdentityFile ~/.ssh/riffswarm_useast2_key.pem
  IdentitiesOnly yes
  ForwardAgent yes

# the other betaAswarm managers have no friendly alias
Host 13.59.116.65 18.219.140.58
  User docker
  IdentityFile ~/.ssh/riffswarm_useast2_key.pem
  IdentitiesOnly yes
  ForwardAgent yes
```

get the IP address(es) by looking at the details of the AWS EC2 instances for the
swarm managers you just created, or by using:

```sh
bin/cloudformation.py get-stack-manager-ip betaAswarm
```

Now we tunnel into one of the docker swarm's manager nodes so that we can use
the `docker` command locally to manipulate the swarm via that manager node.

If you haven't added the entries to your .ssh/config you will need to point
to the private ssh key you specified when creating the cloudformation stack:

```sh
bin/cloudformation.py tunnel -i ~/.ssh/riffswarm_useast2_key.pem betaAswarm
```

```sh
export DOCKER_HOST=localhost:2374
```

Next we add labels to the nodes used to constrain what services run on which
nodes.

```
docker node update --label-add web=true <node-id>
docker node update --label-add mongo=true <node-id>
docker node update --label-add registry=true <node-id>
```

Find the node ids using `docker node ls`.

If you are running 1 manager and 1 worker, I'd suggest that you put the
`web` and `registry` labels on the manager and the `mongo` label on the
worker.


Now start the support stack (the registry and visualizer):

```sh
docker stack deploy -c docker-stack.support.yml support-stack
```

### Deploying a new "production" riffplatform docker stack

- Edit `.env` (if it doesn't exist, copy env_template to .env first).
- Edit `build-vars` to define the refs/tags for riff-rtc and riff-server to
  be built for deployment
- activate the python virtual environment
- tunnel to the AWS docker swarm, and point `DOCKER_HOST` at the tunnel
- build the production images
- push the images to the private registry in the AWS docker swarm
- deploy the riff platform stack

```sh
cp env_template .env
vim .env
vim build-vars
. activate
./cloudformation.py tunnel -i ~/.ssh/riffswarm_useast2_key.pem riffswarm
export DOCKER_HOST=localhost:2374
. build-vars
make show-env
make build-prod
make push-prod
make deploy-stack
```

(FUTURE NOTE: see if there is some way to build the images on the local docker machine
rather than the swarm manager, and push those images to the private registry
running in the swarm)





## Appendix

You can use the `~/.ssh/config` to let ssh know what key file to use for a particular
destination IP address. For example if you put the following in your `~/.ssh/config`:

```
# Riff Learning Amazon Web Services (aws) riffswarm manager 0 instance
Host RiffBetaSwarm 18.223.120.39
  HostName 18.223.120.39
  User docker
  IdentityFile ~/.ssh/riffswarm_useast2_key.pem
  IdentitiesOnly yes
```







------
The basic usage for deployment involves:

1. Provision and start a [cloudformation][] stack, creating a [docker swarm][] on AWS
1. SSH tunnel to a manager in the cloudformation docker swarm you just made
1. Initialize the swarm by making a registry and starting everything in swarm mode
1. Build and push docker images to the remote registry in your swarm
1. Deploy the docker stack to the docker swarm running in the cloudformation
   stack. (Note that there are 2 different types of stacks referenced in this step!)

I go through the steps in detail below:

### 1. Provision and start a cloudformation stack, creating a docker swarm on AWS

### 2. SSH tunnel to a manager in the cloudformation docker swarm you just made

To ssh tunnel into your swarm and use the remote manager as your `DOCKER_HOST`,
you can run:

```
cloudformation.py tunnel -i ~/attic/aws/dan.pem riffswarm
```

You should see output like:

```
❯ cloudformation.py tunnel -i ~/attic/aws/dan.pem riffswarm
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
❯ cloudformation.py tunnel -i ~/attic/aws/dan.pem riffswarm
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


### 3. Initialize the swarm by making a registry and starting everything in swarm mode

To initialize the swarm, you can run:

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


### 4. Build and push docker images to the remote registry in your swarm

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

### 5. Deploy and bring your swarm up!

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

### 6. Get the public DNS, and test!

You can get the public DNS of your swarm using `cloudformation.py
get_stack_dns`. To get the DNS of the stack we just deployed, named
`riffdeploy`, run:

```
❯ cloudformation get_stack_dns riffdeploy
riffdeplo-External-QH833A1J8HE8-1547422939.us-east-1.elb.amazonaws.com
```

This URL is the url you can use to access your newly deployed app!


[setup python]: <./python-setup.md> "Set up python virtual environment for scripts"
[docker install]: <https://docs.docker.com/install/> "Installing Docker"
[AWS CLI]: <https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html> "AWS Command Line Interface"
[docker for AWS]: <https://docs.docker.com/docker-for-aws/why/> "Docker for AWS"
[cloudformation]: <https://aws.amazon.com/cloudformation/> "AWS CloudFormation"
[docker swarm]: <https://docs.docker.com/engine/swarm/> "Swarm mode overview"
[getstarted swarm]: <https://docs.docker.com/get-started/part4/> "Get Started, Part 4: Swarms"


## Appendix

### How to switch the docker config of a service
from [Example: Rotate a config](https://docs.docker.com/engine/swarm/configs/#example-rotate-a-config)

Both configs must exist. Here I'm swapping out one config for another in which I've
changed the log level to debug, hence the config name.

```sh
docker service update \
--config-rm riff-rtc.local-production.yml.4 \
--config-add source=riff-rtc.local-production.yml.4.debug,target=/app/config/local-production.yml \
riff-stack_riff-rtc
```

## Bugs

init failed but continued.
```
(venv) mjl@lm18x ~/Projects/riff/riff-docker $ ./swarm.py init
Initializing docker swarm...
> docker swarm init
Starting registry at localhost:5000 named registry
> docker service create --name registry --publish published=5000,target=5000 registry:2
Error response from daemon: could not choose an IP address to advertise since this system has multiple addresses on different interfaces (10.0.2.15 on enp0s3 and 192.168.56.101 on enp0s8) - specify one with --advertise-addr

Failed to create registry. You may already have another one running:                                                    
Error response from daemon: This node is not a swarm manager. Use "docker swarm init" or "docker swarm join" to connect this node to swarm and try again.
Do you  want to use an existing registry? (y/n): n
Enter registry name: registry
Registry 'registry' up, docker in swarm mode
Ready to deploy to local swarm.
```

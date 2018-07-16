# Glossary of container terms

cluster
: see swarm

container
: A container image is a lightweight, stand-alone, executable package of a
  piece of software that includes everything needed to run it: code, runtime,
  system tools, system libraries, settings.
: Containers and virtual machines have similar resource isolation and
  allocation benefits, but function differently because containers virtualize the
  operating system instead of hardware. Containers are more portable and
  efficient.

docker-compose
: Command used to configure and manage a group of related containers. It is a
  frontend to the same api's used by the docker cli, so you can reproduce it's
  behavior with commands like docker run.

docker-compose.yml
: Definition file for a group of containers, used by docker-compose and now
  also by swarm mode.

orchestration
: Constantly trying to correct any differences between the current state and
  the target state of a stack.

node
: A docker machine in a swarm cluster.

service
: One or more containers for the same image and configuration within a swarm,
  multiple containers provide scalability.

stack (Docker)
: One or more services within a swarm, these may be defined using a DAB or a
  docker-compose.yml file.

stack (AWS CloudFormation)
: A collection of AWS resources you want to deploy together as a group. You use
  a CloudFormation template to define all the AWS resources you want in your
  stack. This can include Amazon Elastic Compute Cloud (EC2) instances, Amazon
  Relational Database Service DB Instances, and other resources.

swarm
: A swarm consists of multiple Docker hosts which run in swarm mode and act
  as managers (to manage membership and delegation) and workers (which run
  swarm services). A given Docker host can be a manager, a worker, or perform
  both roles. (see [docker swarm][])

: A swarm is a group of machines that are running Docker and joined into a
  cluster. After that has happened, you continue to run the Docker commands
  you’re used to, but now they are executed on a cluster by a swarm manager. The
  machines in a swarm can be physical or virtual. After joining a swarm, they are
  referred to as nodes.

swarm mode
: Used to manage a group of docker engines as a single entity and provide
  orchestration (constantly trying to correct any differences between the current
  state and the target state).

----
Many of the definitions above were copied from the [Stack Overflow answer by BMitch][so ans with defs]

----



**Docker slant on some terms (from [DZone article][]):**

swarm
: A Swarm consists of manager and worker nodes that run services.

Managers
: distribute tasks across the cluster, with one manager orchestrating the worker nodes that make up the swarm.

Workers
: run Docker containers assigned to them by a manager.

Services
: an interface to a particular set of Docker containers running across the swarm.

Tasks
: the individual Docker containers running the image, plus commands, needed by a particular service.

Key-value store
: etcd, Consul, or Zookeeper storing the swarm's state and providing service discoverability.

[docker swarm]: <https://docs.docker.com/engine/swarm/key-concepts/#what-is-a-swarm> "What is a swarm?"
[so ans with defs]: <https://stackoverflow.com/questions/42545431/when-to-use-docker-compose-and-when-to-use-docker-swarm> "See answer w/ definitions"
[DZone article]: <https://dzone.com/articles/introduction-to-container-orchestration> "Intro to container orchestration"

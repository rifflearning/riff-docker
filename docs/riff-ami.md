Creating the base Riff AMI
==========================


# Launch a new EC2 instance

1. For the base AMI choose:
    `Ubuntu Server 18.04 LTS (HVM), SSD Volume Type - ami-07ebfd5b3428b6f4d (64-bit x86)`


1. Pick an instance type (`t3a.micro` works and is cheap)

1. No Instance details need to be changed

1. Add storage:
    - leave the minimum 8GB size
    - change the Volume type to `standard` (it's 1/2 the price of general purpose SSD)

1. No tags needed

1. Attach security groups
    - `ssh_MikeLippert_SG_<region>`
    - `ssh_JordanReedie_SG_<region>`

1. Use a dev keypair for access

1. Give the instance a name, e.g. `riff-ami-creator`


# SSH to the new instance

e.g. assuming the IP address is `3.233.242.132` and the key used is `~/.ssh/riffdev_1_useast1_key.pem`
```
$ ssh -i ~/.ssh/riffdev_1_useast1_key.pem ubuntu@3.233.242.132
```

## Update and upgrade

```
sudo apt update
sudo apt upgrade
```

exit, reboot and ssh back in

## Install and setup required applications

### Docker

Instructions copied from: [Docker installation][docker-install]
Installing using the repository will make it easier to keep docker
up-to-date by using apt update/upgrade.
```
sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

Add the ubuntu user to the docker group
```
sudo usermod -a -G docker ubuntu
```

exit and ssh back in to have the permissions from the docker group in
order to continue.

Put docker in swarm mode
```
docker swarm init
```

### docker-compose

Instructions copied from: [docker-compose installation][compose-install].

**Note** The version (currently 1.25.4) is embedded in the install instructions
so check for an updated version and modify the command accordingly.

```
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### Nodejs

Instructions copied from: [Node installation][node-install]

Node version 12 is the current LTS version
```
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g npm
```

### aws cli v2

Instructions copied from: [AWS CLI installation][awscli-install]

```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip awscliv2.zip 
sudo aws/install 
aws --version
rm -r aws*
```

### Build tools

```
sudo apt install make vim jq git tmux curl
```

### Riff deployment repository

```
mkdir ~/riff
cd ~/riff
git clone https://github.com/rifflearning/riff-docker.git
```

Append a couple of items to the bashrc
```
cat << EOF >> .bashrc

# Riff settings
export DEPLOY_SWARM="Update_.bashrc"
export MAKE_UP_OPTS=--detach

cd ~/riff/riff-docker
if [ -f ./bin/status.sh ]; then
    ./bin/status.sh
fi
EOF
```

## Clean up and exit (Basic Riff Environment is done)
Remove files so the AMI is lean.

```
sudo apt clean
```

exit, and stop the instance.

## Create the AMI from the Instance

- Go to the AWS Console
- Open the EC2 Service
- Go to the Instances
- Select the stopped riff-ami-creator instance (from above)
- Under Actions select Image > Create Image
- Set the properties
    - name: `riff-base-20-04-15` (use today's date)`
    - desciption: `18.04+docker+node12+make+awscli+riff-docker repo`
- click _Create Image_ button
- Go to the AMIs
- Give the new image the same _Name_ as its _AMI Name_ (above)


[docker-install]: <https://docs.docker.com/engine/install/ubuntu/>
[compose-install]: <https://docs.docker.com/compose/install/>
[node-install]: <https://github.com/nodesource/distributions/blob/master/README.md>
[awscli-install]: <https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html>



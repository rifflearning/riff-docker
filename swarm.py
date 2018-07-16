#!/usr/bin/env python3

# swarm.py
# author: Dan Calacci dan@rifflearning.com
# Command line tool for managing local and remote Docker swarms

import cloudformation
import os
import subprocess
import json
import click
import sys

def _highlight(x, fg='green'):
    if not isinstance(x, str):
        x = json.dumps(x, sort_keys=True, indent=2)
    click.secho(x, fg=fg)

@click.command()
@click.option("-name", default="registry", help="Name of registry")
def start_registry(name):
    """Start a registry on localhost with port 5000 with the given name.
    """
    print("Starting registry at localhost:5000 named {}".format(name))
    cmd = "docker service create --name registry --publish published=5000,target=5000 registry:2"
    _highlight("> {}".format(cmd))
    ps = subprocess.Popen(cmd, shell=True,
                          stdout=subprocess.PIPE,
                          stdin=subprocess.PIPE,
                          stderr=subprocess.PIPE)
    stat = ps.poll()
    while stat == None:
        stat = ps.poll()
    if stat != 0:
        _highlight("\nFailed to create registry. You may already have another one running:", fg='red')
        ps = subprocess.Popen("docker service ls | grep registry", shell=True)
        ps.wait()
        if (click.prompt("Do you  want to use an existing registry? (y/n)")):
            return click.prompt("Enter registry name", type=str)
        else:
            sys.exit()
    else:
        return name


@click.command()
@click.pass_context
def start_swarm(ctx):
    """Start docker in swarm mode
    """
    _highlight("Initializing docker swarm...")
    cmd = "docker swarm init"
    _highlight("> {}".format(cmd))
    ps = subprocess.Popen(cmd, shell=True)

@click.command()
@click.option("--registry-name", '-rn', default='registry', help="name of registry")
@click.pass_context
def init(ctx, registry_name):
    """Initialize docker for swarm mode, and create a registry or choose one to use.
    """
    ctx.invoke(start_swarm)
    registry_name = ctx.invoke(start_registry, name=registry_name)
    _highlight("Registry '{}' up, docker in swarm mode".format(registry_name))
    _highlight("Ready to deploy to local swarm.")

@click.command()
@click.option("--dockerfile", "-f", default="docker-compose.yml", help="path to docker-compose file")
@click.pass_context
def push(ctx, dockerfile):
    build_cmd = "docker-compose -f {} build".format(dockerfile)
    push_cmd = "docker-compose -f {} push".format(dockerfile)
    _highlight("\nBuilding from {}".format(dockerfile))

    cont = click.prompt('Continue? (y/n)', type=bool)
    if cont:
        ps = subprocess.Popen(build_cmd, shell=True)
        ps.wait()
    else:
        if not click.prompt('Continue without new build? (y/n)', type=bool):
            print("Exiting!")
            sys.exit()

    _highlight("\nPushing build to registry {}".format(dockerfile))
    if (click.prompt('Continue? (y/n)', type=bool)):
        ps = subprocess.Popen(push_cmd, shell=True)
        ps.wait()

    _highlight("To deploy the images you just pushed, run `swarm.py deploy`")

@click.command()
@click.option("--dockerfile", "-f", default="docker-compose.yml", help="path to docker-compose file")
@click.option("--stack-name", "-n", default="docker-stack", help="Name to give to your stack")
@click.pass_context
def deploy(ctx, dockerfile, stack_name):
    """Deploy dockerfile that has already been pushed to a repo
    """
    if (click.prompt("Have you already pushed this project to your repo? (y/n)")):
        cmd = "docker stack deploy --compose-file {} {}".format(dockerfile, stack_name)
        ps = subprocess.Popen(cmd, shell=True)
        ps.wait()
    else:
        _highlight("Run `swarm.py push -f ...` before running deploy.")


@click.group()
@click.pass_context
def cli(ctx):
    """Create and manage swarm deployments for Riff

    """
    pass


cli.add_command(init)
cli.add_command(deploy)
cli.add_command(push)
cli.add_command(start_registry)
cli.add_command(start_swarm)

if __name__ == "__main__":
    cli(obj={})

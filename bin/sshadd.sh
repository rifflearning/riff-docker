#! /usr/bin/env bash
# This script add the ssh key for the known Riff Platform docker swarm to the
# ssh-agent.
# This is needed when ssh'ing to the swarm manager and then ssh'ing from there
# to a worker node. For this to work the .ssh/config must also have specified
# "ForwardAgent yes" for the swarm manager.
# If there are "too many" keys in the agent you may get an error, and the
# easiest solution is to reduce the number of keys in the agent.

# Quick test to see if this script is being sourced (it does not have to be)
# https://stackoverflow.com/a/28776166/2184226
(return 0 2>/dev/null) && sourced=1 || sourced=0

# Show help if no argument is given
if [[ -z "$1" ]]
then
    echo "This script will add the ssh key for a 'known' Riff Platform docker swarm to the ssh-agent."
    echo
    echo "It should be run from the root of the riff-docker working directory"
    echo '  bin/sshadd.sh <known swarm name defined in bin/aws_stack_vars>'
    echo
    if [[ $sourced -ne 1 ]] ; then exit 1 ; fi
    return 1
fi

# Check that it is run from the expected location
if [[ ! -e bin/aws_stack_vars ]]; then
    echo "You do not seem to have run this script from the root of the riff-docker working directory."
    echo "Change to the riff-docker working directory and run:"
    echo "  bin/sshadd.sh <swarm name>"
    echo
    if [[ $sourced -ne 1 ]] ; then exit 2 ; fi
    return 2
fi

# Set the AWS stack variables (the stack suffix and the region, keypair maps) and the
# derived variables for '$1' (DEPLOY_SWARM, AWS_CF_STACK_NAME, AWS_STACK_REGION, AWS_STACK_KEYPAIR)
source bin/aws_stack_vars $1

# Check that $1 was a known swarm name
if [[ -z "$DEPLOY_SWARM" ]]
then
    echo "'$1' is not a known Riff Platform swarm name. It must be one of:"
    echo "  ${SWARM_NAMES[@]}"
    echo
    if [[ $sourced -ne 1 ]] ; then exit 3 ; fi
    return 3
fi

echo
echo "Adding the '${AWS_STACK_KEYPAIR}' for the $DEPLOY_SWARM AWS swarm to the ssh-agent..."
ssh-add ~/.ssh/${AWS_STACK_KEYPAIR}.pem

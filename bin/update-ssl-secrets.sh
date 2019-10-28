#! /usr/bin/env bash
# This is a preliminary script still under development
# TODO test that the old version secret is actually in use, and that the new version has been created

# Quick test to see if this script is being sourced (it does not have to be)
# https://stackoverflow.com/a/28776166/2184226
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [[ $sourced -eq 1 ]]
then
    echo "Don't source this script!"
    return 100
fi

RIFF_APP=pfm

if [[ "$RIFF_APP" = "pfm" ]]
then
    MAIN_DOMAIN_NAME=riffplatform.com
    WEB_SERVICE_NAME=${RIFF_APP}-stk_${RIFF_APP}-web
elif [[ "$RIFF_APP" = "edu" ]]
then
    MAIN_DOMAIN_NAME=riffedu.com
    WEB_SERVICE_NAME=${RIFF_APP}-stack_${RIFF_APP}-web
fi

# Show help if wrong number of arguments is given
if [[ $# -ne 2 ]]
then
    echo "This script will replace the ssl crt and key secrets in use by the web service."
    echo
    echo "It should be run from the root of the riff-docker working directory"
    echo '  bin/update-ssl-secrets.sh <old ver #> <new ver #>'
    echo
    exit 1
fi

# Check that DEPLOY_SWARM is defined
if [[ -z "$DEPLOY_SWARM" ]]
then
    echo "DEPLOY_SWARM must be defined before running this script, which it would be if"
    echo "the tunnel script was used to tunnel to a deployed swarm."
    echo
    exit 2
fi

SECRET_VER_OLD=$1
SECRET_VER_NEW=$2
DOMAIN_NAME=$DEPLOY_SWARM.$MAIN_DOMAIN_NAME


OLD_SECRET_CRT=$DOMAIN_NAME.crt.$SECRET_VER_OLD
OLD_SECRET_KEY=$DOMAIN_NAME.key.$SECRET_VER_OLD
NEW_SECRET_CRT=$DOMAIN_NAME.crt.$SECRET_VER_NEW
NEW_SECRET_KEY=$DOMAIN_NAME.key.$SECRET_VER_NEW

JQ_FILTER_SECRETS='[.[0].Spec.TaskTemplate.ContainerSpec.Secrets[] | {src: .SecretName, tgt: .File.Name}]'
docker secret ls
echo docker service inspect "$WEB_SERVICE_NAME" '|' jq "$JQ_FILTER_SECRETS"
docker service inspect "$WEB_SERVICE_NAME" | jq "$JQ_FILTER_SECRETS"

echo
echo "Replace:"
echo "  $OLD_SECRET_CRT with $NEW_SECRET_CRT"
echo "  $OLD_SECRET_KEY with $NEW_SECRET_KEY"
read -rsp $'Press any key to continue or Ctrl-C to abort\n' -n1 key
echo

docker service update \
    --secret-rm $OLD_SECRET_KEY \
    --secret-rm $OLD_SECRET_CRT \
    --secret-add source=$NEW_SECRET_KEY,target=site.key \
    --secret-add source=$NEW_SECRET_CRT,target=site.crt $WEB_SERVICE_NAME

echo docker service inspect "$WEB_SERVICE_NAME" '|' jq "$JQ_FILTER_SECRETS"
docker service inspect "$WEB_SERVICE_NAME" | jq "$JQ_FILTER_SECRETS"

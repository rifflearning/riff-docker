# Riff Development Guide

This guide explains how you can work on the various parts of the Riff platform; client,
platform API, data API ...

Because the components are inter-related, you will need to have all of these repositories
cloned locally. You do not need to have the following directory structure (you may set
environment variables to point to other locations) but the defaults are set to work with
this relative directory layout.

```
.
├── riff-docker
├── mattermost-server
├── mattermost-webapp
├── riff-server
└── signalmaster
```

## Initial setup

### Prerequisites

- git
- docker
- make
- Python 3 (only for needed for deploying)

### Clone and initialize working directories

```sh
mkdir riff
cd riff
git clone https://github.com/rifflearning/riff-docker.git
git clone https://github.com/rifflearning/mattermost-server.git
git clone https://github.com/rifflearning/mattermost-webapp.git
git clone https://github.com/rifflearning/riff-server.git
git clone https://github.com/rifflearning/signalmaster.git
pushd riff-docker
make init-server
make init-signalmaster
pushd ../mattermost-server/config
ln -s config-dev.json config.json
popd
```

You may need a `local-development.yml` file w/ the keys for using twilio
in signalmaster/config. If you find you do, ask another developer for it on
our slack. But you may also be fine w/o using twilio for signaling.

### Create development docker images

from the riff-docker working directory:

```sh
. bin/nobuild-vars
make build-dev
```

Re-run this command to rebuild the images. Because the development images expect
the local repository working directories to be bound to the containers, you only
need to rebuild when you want to refresh the base image (ie update node w/ any new
patches).

It's best if you tag the development images w/ the `dev` tag, which will be set if
you don't override it. Running `. bin/nobuild-vars` will unset all of the environment
variables which would set the image tags. Those environment variables are most often
used when building production or staging images.

The `build-dev` target depends on (and therefore will create if they don't exist)
the self-signed ssl files used by the `web-server` dev image.

You may want to run `make up` once to get things started. It is important that
the `mattermost-webapp/node_modules` NOT EXIST the 1st time you run `make up`.
Some of the mattermost-webapp dependent packages MUST be installed from inside
the container.



## Working on the code

### riff-server

This project uses nodejs. You must either have the correct version of nodejs
installed locally or you may also use a container to run node commands such as
`npm` to update and install packages.

The riff-docker Makefile has a target to start an interactive commandline
with the correct node environment, `dev-server`.

### mattermost-webapp

This is the client code (implemented with the react framework).

Using `make up` starts up development containers for the mattermost app, running
webpack watch, so that changes you make to sources in the mattermost-webapp
directory should cause a reload.

Keep in mind that it takes a **really** **really** long time for the mattermost
dev app to be ready when you start it with `make up`.

### mattermost-server

The mattermost-server is implemented using go.

&lt; section still under construction >

You can use the `make dev-mm` target to get a commandline in the `riff-mm`
container, change to the `~/go/src/github.com/mattermost/mattermost-server`
directory and use the Makefile targets from there while doing development.
Keep in mind that the Makefile has targets which spin up docker containers
AND docker is NOT installed inside of that docker container!

## Running

run `make up` Then access `https://localhost`.

You can use `export MAKE_UP_OPTS=-d` to have `make up` start the containers
detached in which case you will want to use `make stop` to stop the containers.
If the containers aren't running detached use `CTRL-C` to stop the containers.

If the containers are running detached you probably would like to follow the
logs (stdout) from one of them, likely the `riff-rtc` container. You can use
`make logs-rtc OPTS=-f`.

Use `make down` to stop (if running) and remove the containers.

### Configuration

&lt; section still under construction >


## Process ##

The development process involves more than just the Riff developers, it also involves
product management and qa.

### Lifecycle

#### Developers

1. For any feature or fix there should exist a card on our Trello board in the _Backlog_ or
   _To Do_ columns. If not, the developer should create one and inform Product Management (Amy)
   that they've done so.
1. The developer should Move the Trello card to the _Doing_ column, and add themself to the card.
   (Only the person actually doing the work should move a card to _Doing_)
1. The developer should fetch the latest code for the repository they will be working in and
   create a branch from the HEAD of the `develop` branch for this feature or fix with a name
   prefixed by `feature/` or `fix/`. 
   The creator of a branch is the **owner** of the branch and may force push it to github at
   any time (due to rebasing the branch back to the HEAD of `develop` or squashing or otherwise
   modifying commits).
1. The developer should fetch the latest code in the repo from github and rebase their branch
   on top of the HEAD of `develop` on a regular basis.(**do not merge** the develop branch into
   your branch).
1. (optional) it is useful for other developers be able to see the code in progress in a fix or
   feature branch, so pushing it is encouraged (force pushing if needed).
1. When the feature or fix is complete, make sure the branch is still based on the HEAD of
   `develop` and rebase it if not, push it and open a PR (Pull Request) to merge to `develop`.
1. Assign the integration developer (Mike) to the PR. (This is a good point to ask for review
   of the code if you want it). The branch is now owned by the integration developer who may
   force push it if needed so new commits, if needed, should be coordinated with him.
1. Add the integration developer (Mike) to the Trello card (leaving it in _Doing_), add the
   github PR to the card, and add a comment that it is ready to be merged.
1. go back to step 1 to start a new fix or feature.

At this point the integration developer takes over.

#### Integration/deployment developer

1. Check that any desired discussion/review has been completed.
1. Confirm that the PR branch is still based from the HEAD of `develop`, and rebase and
   force push it if not.
1. Merge the PR.
1. Fetch the latest commits from the repository.
1. Check out the `develop` branch.
1. Verify that it builds.
1. Delete the merged branch from github.
1. Repeat until there are no more open PRs that need to be merged now.
1. (optional) check for outdated packages (`npm outdated`) and update those with new minor
   and patch versions. While this might cause an issue, it should not, and it is better to
   stay on top of this and make sure we're using packages with the latest fixes (security
   and otherwise). If it causes an issue, it should be easier to catch and figure out which
   is the offending package if we update consistently. Commit the updated package.json if
   needed.
1. Update the version (`npm version prerelease`).
1. Edit the new commit's message to read: "Bump pre-release to 0.4.0-dev.41" where the version
   is whatever the new version actually is.
1. Push the `develop` branch w/ the new commit(s) to github.
1. Delete the tag created that has a 'v' prefix as we don't use that.
1. Create a new annotated (signed if you've got a gpg signing key) tag that is just the straight
   new version number, e.g. `0.4.0-dev.41`, and push it to github.
1. Deploy the new code to the `staging` AWS swarm.
1. Move all associated Trello cards to the _Testing_ column, add a QA or Product manager (Amy)
   to the card, take yourself off the card and add a comment w/ the new version number that
   contains the fix or feature of the card.

At this point the QA engineer or Product manager takes over.

#### QA engineer (testing)

1. Test that the fix/feature meets the requirements if possible (some backend fixes/features may
   not be testable on their own, in which case it seems reasonable to just consider them "good".
1. If the fix/feature meets the requirements, move it to _Done_. Moving a Trello card to _Done_
   should **only** be done by QA or Product management and not by developers.
1. If there are issues with the fix/feature, comments in the Trello card are the best place to
   record any needed discussion with the implementing developer to determine if the issues are
   real, and if new code will be needed to address them. If the need for new code is obvious
   just move to the next step.
1. If new code is needed to fix issues w/ a fix/feature in _Testing_, a new card should be created
   in _To Do_ and a link to the original card should be in the new card's description. A link to
   the new card should be added to the original card in a comment. It is possible that several new
   cards may be needed to address issues, so there may be several comments linking to new cards
   that will fix those issues.
1. When testing is complete and there are no issues or there are new cards and links for all
   issues found the card should be moved to _Done_.

<!-- Amy wanted something about making sure that product management got the chance to prioritize
     but found this to be confusing, so I'm leaving it, but commenting it out. -mjl
It should also be noted that sometimes testing uncovers new functionality/behavior that could
be desireable. This new functionality/behavior could reasonably be considered not a bug in the
initial implementation but an enhancement. These should be treated as new features by the QA
engineer and a card in Trello created and put in the _Backlog_ for prioritization by the product
manager.
-->
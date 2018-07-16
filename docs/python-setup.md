# Setup python for running the scripts in riff-docker

The riff-docker python scripts use python version 3 and need some
packages installed.

This will setup the ability to activate a python 3 virtual environment
for the riff-docker scripts, and install the packages those scripts
require.

The following commands are issued from the root of the riff-docker repository
working directory (e.g. `~/Projects/riff-docker`):

    cd ~/Projects/riff-docker
    python3 -m venv venv
    ln -s venv/bin/activate activate
    . activate
    pip install --upgrade pip
    pip install -r requirements.txt

Now you can use `. activate` to activate the virtual environment so that the
`python` command runs python v3, and the pip command installs python 3 packages
and those packages are available to python scripts run while the virtual environment
is active.

(Note: you can use `deactivate` to deactivate the python3 virtual environment)


#!/usr/bin/env make

.PHONY: *

# Runs initial setup
init: env setup-node setup-python

# Sets up the environment with direnv
env:
	direnv allow

# Installs node js dependencies
setup-node:
	npm run ci

# Installs python dependencies
setup-python: venv
	./venv/bin/pip install -r requirements.txt

# Creates a virtual environment for separating requirements
venv:
	virtualenv venv

# Creates the requirements file
requirements.txt:
	./venv/bin/pip freeze > requirements.txt

## Aliases

# Generates the usage docs in the README
docs:
	npm run build

# Runs the testing suite
test:
	npm run test

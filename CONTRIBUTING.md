# Collaboration

## Requirements

* [Make](https://www.gnu.org/software/make/)
* [Direnv](https://direnv.net/)
* [Pre-commit](https://pre-commit.com/)
* [NodeJS](https://nodejs.org/en/)
* [Python](https://www.python.org/)

## Setup

Installs dependencies and sets up developer environment.

```bash
make init
```

## Running tests

Runs the testing suite.

```bash
make test
```

## Generating Usage Docs

Generates the usage docs within the readme.

```bash
make docs
```

## Generating requirements

Generates the requirements.txt file for locking python dependencies.

```bash
make requirements.txt
```

.DEFAULT_GOAL := help

CURRENT_GITHOOKS_FOLDER := $(shell git config --get core.hooksPath)
GITHOOKS_FOLDER := .githooks

COVERAGE_THRESHOLD := 10

.PHONY: init
init:
ifneq ($(CURRENT_GITHOOKS_FOLDER),$(GITHOOKS_FOLDER))
	chmod 775 .githooks/*
	git config core.hooksPath .githooks
endif

.PHONY: freeze
freeze:
	cd requirements/production; pip-compile --resolver=backtracking
	cd requirements/development; pip-compile --resolver=backtracking

.PHONY: lint-local
lint-local:
	isort src tests
	black src tests
	flake8 src tests
	mypy src tests

.PHONY: lint-ci
lint-ci:
	isort --check src tests
	black --check src tests
	flake8 src tests
	mypy src tests

.PHONY: test-local
test-local: export ENVIRONMENT=test
test-local:
	pytest .

.PHONY: docker-build
docker-build:
	# if container is already running, stop it and remove it
	make docker-remove || true
	docker build -t instructpix2pix-runpod-serverless .
	docker run -d --name instructpix2pix-runpod-serverless instructpix2pix-runpod-serverless sleep infinity

.PHONY: docker-start
docker-start:
	docker start instructpix2pix-runpod-serverless

.PHONY: docker-stop
docker-stop:
	docker stop instructpix2pix-runpod-serverless

.PHONY: docker-remove
docker-remove:
	docker stop instructpix2pix-runpod-serverless
	docker rm instructpix2pix-runpod-serverless

.PHONY: test
test:
	docker exec instructpix2pix-runpod-serverless make test-local

.PHONY: shell
shell:
	docker exec -it instructpix2pix-runpod-serverless bash

# -- help

# COLORS
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)
TARGET_MAX_CHAR_NUM=20
## Show help.
help:
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  ${YELLOW}%-$(TARGET_MAX_CHAR_NUM)s${RESET} ${GREEN}%s${RESET}\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

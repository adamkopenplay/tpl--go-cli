PROJECT_GIT_URL=<< git_host >>/<< org >>/<< name >>
PROJECT_NAME=<< name >>
DOCKER_COMPOSE=docker-compose -p ${PROJECT_NAME}-local -f ./docker-compose.yaml

MOCKS_DIR=./test/mocks
MOCKS_GEN_ARGS=--case underscore --with-expecter --exported

ifdef BUILD_VERSION
	LDFLAGS_VAL=-X '$(PROJECT_GIT_URL)/Version=$(BUILD_VERSION)'
endif

ifndef ARGS
	ARGS="./..."
endif

LDFLAGS=-ldflags="$(LDFLAGS_VAL)"

# This is a combination of the following suggestions:
# https://gist.github.com/prwhite/8168133#gistcomment-1420062
help: ## This help dialog.
	@IFS=$$'\n' ; \
	help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##/:/'`); \
	printf "%-30s %s\n" "target" "help" ; \
	printf "%-30s %s\n" "------" "----" ; \
	for help_line in $${help_lines[@]}; do \
			IFS=$$':' ; \
			help_split=($$help_line) ; \
			help_command=`echo $${help_split[0]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
			help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
			printf '\033[36m'; \
			printf "%-30s %s" $$help_command ; \
			printf '\033[0m'; \
			printf "%s\n" $$help_info; \
	done

.PHONY: up
up: ## Start the dev env hot recompilation
	$(DOCKER_COMPOSE) up -d

.PHONY: down
down: ## Destroy the dev env hot recompilation container
	$(DOCKER_COMPOSE) down

.PHONY: restart
restart: ## Restart the got recompilation container
	$(DOCKER_COMPOSE) restart compiler

.PHONY: tail
tail: ## Tail logs from the recompilation container
	$(DOCKER_COMPOSE) logs -f compiler

.PHONY: exec
exec: ## Exec into the hot recompilation container
	$(DOCKER_COMPOSE) exec compiler bash

.PHONY: dc
dc: ## Show the docker compose command to interact with the containers
	@echo $(DOCKER_COMPOSE)

# --- The below commands should be run from within the container
.PHONY: build
build: ## Build the binary (should be used within the docker image)
	go mod tidy
	go build $(LDFLAGS) -o /go/bin/$(PROJECT_NAME) cmd/$(PROJECT_NAME)/*.go

.PHONY: make-executable
make-executable: ## Makes the built tool executable
	chmod +x /go/bin/$(PROJECT_NAME)

.PHONY: fmt
fmt: ## Format code using go fmt ./...
	go fmt ./...

.PHONY: gen-mocks 
gen-mocks:
	mockery

.PHONY: test
test: ## Runs the tests for the app code
	go test -coverprofile test/coverage.out $(ARGS)
	go tool cover -o=test/coverage.html -html=test/coverage.out

.PHONY: help build test test-local test-sample-data clean docker-build docker-push deps

# Variables
BINARY_NAME=mongo-telegraf-query
DOCKER_IMAGE=telegraf-mongodb-querier
DOCKER_TAG=latest
DOCKER_REGISTRY?=your-registry.example.com

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

deps: ## Download Go dependencies
	go mod download
	go mod tidy

build: ## Build binary locally
	CGO_ENABLED=0 go build -o $(BINARY_NAME) .
	chmod +x $(BINARY_NAME)

test: ## Run Go unit tests
	go test -v ./...

test-local: build ## Test with local MongoDB (usage_db)
	cd test && ./test-local.sh

test-sample-data: build ## Create sample data and run tests
	cd test && ./test-sample-data.sh && ./test-with-sample-data.sh

clean: ## Clean build artifacts
	rm -f $(BINARY_NAME)
	go clean

docker-build: ## Build Docker image
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

docker-tag: docker-build ## Tag Docker image for registry
	docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(DOCKER_REGISTRY)/$(DOCKER_IMAGE):$(DOCKER_TAG)

docker-push: docker-tag ## Push Docker image to registry
	docker push $(DOCKER_REGISTRY)/$(DOCKER_IMAGE):$(DOCKER_TAG)

docker-run: docker-build ## Run Docker container locally
	docker run --rm \
		-v $(PWD)/examples/queries:/etc/telegraf/queries \
		-e MONGO_URI="mongodb://localhost:27017" \
		$(DOCKER_IMAGE):$(DOCKER_TAG) \
		/usr/local/bin/mongo-telegraf-query -config /etc/telegraf/queries/user-stats.json

# Development targets
dev-up: ## Start local development environment (MongoDB + ClickHouse)
	docker-compose up -d

dev-down: ## Stop local development environment
	docker-compose down

dev-logs: ## Show development logs
	docker-compose logs -f

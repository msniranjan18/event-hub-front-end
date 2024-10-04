# Define variables
IMAGE_NAME := eventhub-frontend
IMAGE_TAG := 2.0.0
BUILD_DIR := ${PWD}/build
CONTAINER_NAME := eventhub-frontend
APP_NAME := eventhub-frontend
PORT := 8080

# Default target
all: build

# Build the Go application
build:
	# Note: This build will only run on this machine, for docker build will use multi stage Dockerfile to build a machine comaptible binary.
	@echo "Building the Go application..." 
	mkdir -p $(BUILD_DIR)
	# GOOS=linux GOARCH=amd64 go build -a -o $(BUILD_DIR)/$(APP_NAME) main.go
	go mod tidy
	go build -o $(BUILD_DIR)/$(APP_NAME) main.go

# Build Docker image for linux/amd64 architecture
docker-build:
	@echo "Building Docker image..."
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG)-amd64 \
	--build-arg GOOS=linux \
	--build-arg GOARCH=amd64 \
	--build-arg CGO_ENABLED=1 \
	--build-arg APP_ENV=$(APP_ENV) \
	--build-arg PORT=$(PORT) \
	--build-arg APP_NAME=$(APP_NAME) \
	--build-arg BUILD_VERSION=$(BUILD_VERSION) \
	-f docker/Dockerfile .

# Build Docker image for linux/amr64 architecture
docker-build-aarch64:
	@echo "Building Docker image..."
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG)-arm64 \
	--build-arg GOOS=linux \
	--build-arg GOARCH=arm64 \
	--build-arg CGO_ENABLED=1 \
	--build-arg APP_ENV=$(APP_ENV) \
	--build-arg PORT=$(PORT) \
	--build-arg APP_NAME=$(APP_NAME) \
	--build-arg BUILD_VERSION=$(BUILD_VERSION) \
	-f docker/Dockerfile .

# Build Docker image for linux/amr64 architecture; using buildx driver as docker default driver doesnot support multiplateform- currently not working
# step-1: Create and use the buildx instance:
# 	docker buildx create --name mybuilder --use
# step-2: Check the instance and initialize it:
# 	docker buildx inspect --bootstrap
# step-3: run make command
# sudo make docker-build-multiplatform
docker-build-multiplatform:
	@echo "Building Docker image..."
	docker buildx build --platform linux/amd64,linux/arm64 -t $(IMAGE_NAME):$(IMAGE_TAG) \
	--build-arg GOOS=linux \
	--build-arg GOARCH=arm64 \
	--build-arg CGO_ENABLED=1 \
	--build-arg APP_ENV=$(APP_ENV) \
	--build-arg PORT=$(PORT) \
	--build-arg APP_NAME=$(APP_NAME) \
	--build-arg BUILD_VERSION=$(BUILD_VERSION) \
	-f docker/Dockerfile .


# Run Docker container
docker-run:
	@echo "Stopping and removing existing Docker container..."
	# Stop and remove any existing container with the same name
	CONTAINER_ID=$$(docker ps -aq -f name=$(CONTAINER_NAME)); \
	if [ -n "$$CONTAINER_ID" ]; then \
		docker stop $$CONTAINER_ID || true; \
		docker rm $$CONTAINER_ID || true; \
	fi
	@echo "Running Docker container..."
	# running in detach mode
	docker run -d -p 8080:8080 --name $(CONTAINER_NAME) $(IMAGE_NAME):$(IMAGE_TAG)

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)/$(APP_NAME)
	CONTAINER_ID=$$(docker ps -aq -f name=$(CONTAINER_NAME)); \
	if [ -n "$$CONTAINER_ID" ]; then \
		docker stop $$CONTAINER_ID || true; \
		docker rm -f $$CONTAINER_ID || true; \
	fi
	docker rmi $(IMAGE_NAME):$(IMAGE_TAG)

# Run all tests
test:
	@echo "Running tests..."
	go test ./...

# Apply Kubernetes configurations
k8s-deploy:
	@echo "Applying Kubernetes configurations..."
	kubectl apply -f kubernetes/namespace.yaml
	kubectl apply -f kubernetes/

# Help message
help:
	@echo "Makefile for managing the frontend application"
	@echo ""
	@echo "Usage:"
	@echo "  make build          			Build the Go application"
	@echo "  make docker-build   			Build the Docker image for linux/amd64"
	@echo "  make docker-build-aarch64   		Build the Docker image for linux/arm64"
	@echo "  make docker-build-multiplatform   	Build the Docker image for linux/amd64, linux/arm64"
	@echo "  make docker-run     			Run the Docker container"
	@echo "  make clean          			Clean build artifacts and Docker image"
	@echo "  make test           			Run tests"
	@echo "  make k8s-deploy     			Apply Kubernetes configurations"
	@echo "  make help           			Show this help message"

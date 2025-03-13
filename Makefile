VERSION ?= 0.0.1
CONTAINER_MANAGER ?= podman

# Image URL to use all building/pushing image targets
IMG ?= quay.io/pffp2025/seminario:v${VERSION}

# Go and compilation related variables
GOPATH ?= $(shell go env GOPATH)
BUILD_DIR ?= out
GOOS := $(shell go env GOOS)
GOARCH := $(shell go env GOARCH)

# Add default target
.PHONY: default
default: install

# Create and update the vendor directory
.PHONY: vendor
vendor:
	go mod tidy
	go mod vendor

# Start of the actual build targets
$(BUILD_DIR)/seminario: $(SOURCES)
	GOOS="$(GOOS)" GOARCH=$(GOARCH) go build -buildvcs=false -o $(BUILD_DIR)/seminario .
 
.PHONY: build
build: $(BUILD_DIR)/seminario

.PHONY: test
test:
	go test .

$(GOPATH)/bin/golangci-lint:
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.60.0

# Run golangci-lint against code
.PHONY: lint
lint: $(GOPATH)/bin/golangci-lint
	$(GOPATH)/bin/golangci-lint run

.PHONY: check
check: build test lint

.PHONY: clean ## Remove all build artifacts
clean:
	rm -rf $(BUILD_DIR)

.PHONY: oci-build
oci-build:
	${CONTAINER_MANAGER} build -t $(IMG) -f oci/Containerfile .

.PHONY: oci-save
oci-save:
	${CONTAINER_MANAGER} save -m -o pffp.tar $(IMG)
	
.PHONY: oci-run
oci-run:
	${CONTAINER_MANAGER} run -d --rm -p 8080:8080 $(IMG)
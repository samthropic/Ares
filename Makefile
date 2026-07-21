SHELL := /bin/sh

CLUSTER_NAME ?= ares-dev
KIND_CONFIG ?= deploy/kind/kind-config.yaml

.PHONY: kind-up kind-down audit-up audit-down test web-check

kind-up:
	kind create cluster --name $(CLUSTER_NAME) --config $(KIND_CONFIG)

kind-down:
	kind delete cluster --name $(CLUSTER_NAME)

audit-up:
	docker compose up -d postgres

audit-down:
	docker compose down

test:
	cd backend && packages="$$(go list ./...)"; \
	if [ -n "$$packages" ]; then go test ./...; else go mod verify; fi

web-check:
	npm run web:check

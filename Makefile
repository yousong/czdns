all: build

.PHONY: build
build:
	@./scripts/hack.sh build

.PHONY: run
run:
	@./scripts/hack.sh run

.PHONY: release
release:
	@./scripts/hack.sh release

tags:
	@./scripts/hack.sh tags
.PHONY: tags

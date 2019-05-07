CZDNS_DIR:=files/etc/czdns
USE_LIST=chn
CHNLIST:=files/etc/czdns/china.conf
GFWLIST:=files/etc/czdns/gfwlist.conf

all: build

$(CHNLIST): | $(CZDNS_DIR)
	wget -O $@.1 https://github.com/felixonmars/dnsmasq-china-list/raw/master/accelerated-domains.china.conf
	mv $@.1 $@

$(GFWLIST): gfwlist | $(CZDNS_DIR)
	./gfwlist >$(CURDIR)/$@.1
	mv $@.1 $@

$(CZDNS_DIR):
	mkdir -p $@

gfwlist: gfwlist.go
	CGO_ENABLED=0 go build -tags 'netgo' -ldflags '-extldflags "-static"' gfwlist.go

build: gfwlist $(CHNLIST) $(GFWLIST)
	docker build -t yousong/czdns:latest $(CURDIR)

run: build
	docker rm --force czdns || true
	docker run \
		--name czdns \
		--rm \
		--env USE_LIST="$(USE_LIST)" \
		--env DNSMASQ_EXTRA_CONF="$(DNSMASQ_EXTRA_CONF)" \
		--env CHINA_NAMES="$(CHINA_NAMES)" \
		--env OTHER_NAMES="$(OTHER_NAMES)" \
		--cap-add NET_ADMIN \
		-p 2053:53/udp \
		-p 2053:53/tcp \
		yousong/czdns \
			"--no-ping" \
			"--no-poll" \
			"--no-resolv" \
			"--no-daemon" \
			"--log-facility" "-" \
			"--log-queries" \

clean:
	rm -rvf $(CZDNS_DIR)
	rm -vf gfwlist

release:
	echo "$(VERSION)" | grep -qE "^v[0-9]+\.[0-9]+\.[0-9]+$$"
	git tag --force "$(VERSION)" HEAD
	git push origin HEAD --tags
	docker tag yousong/czdns:latest "yousong/czdns:$(VERSION)"
	docker push yousong/czdns:latest
	docker push "yousong/czdns:$(VERSION)"

.PHONY: build
.PHONY: run
.PHONY: release
.PHONY: clean

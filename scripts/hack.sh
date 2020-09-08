#!/usr/bin/env bash

set -o errexit
set -o pipefail

TOPDIR="$(readlink -f "$(dirname "$0")/..")"

buildgo() {
	go build -o "$TOPDIR/gfwlist" "$TOPDIR/gfwlist.go"
}

buildprep() {
	rm -rf "$TOPDIR/files/etc"
	mkdir -p "$TOPDIR/files/etc/czdns"
	wget -O "$TOPDIR/files/etc/czdns/china.conf" \
		https://github.com/felixonmars/dnsmasq-china-list/raw/master/accelerated-domains.china.conf

	buildgo
	"$TOPDIR/gfwlist" >"$TOPDIR/files/etc/czdns/gfwlist.conf"
}

build() {
	buildprep
	docker build -t yousong/czdns:latest "$TOPDIR"
}

run() {
	local use_list="${czdns_use_list:-chn}"
	local dnsmasq_extra_conf="${czdns_dnsmasq_extra_conf:-}"
	local china_names="${czdns_china_names:-}"
	local other_names="${czdns_other_names:-}"
	local make_confd_tar="${czdns_make_confd_tar:-}"

	docker rm --force czdns &>/dev/null || true
	docker run \
		--name czdns \
		--rm \
		--env MAKE_CONFD_TAR="${czdns_make_confd_tar}" \
		--env USE_LIST="$use_list" \
		--env DNSMASQ_EXTRA_CONF="$dnsmasq_extra_conf" \
		--env CHINA_NAMES="$china_names" \
		--env OTHER_NAMES="$other_names" \
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

}

release() {
	echo "$VERSION" | grep -qE "^v[0-9]+\.[0-9]+\.[0-9]+$"
	git tag --force "$VERSION" HEAD
	git push origin HEAD --tags
	buildprep
	docker buildx build \
		--platform linux/amd64,linux/386,linux/arm64,linux/arm/v7,linux/arm/v6 \
		--tag "yousong/czdns:$VERSION" \
		--tag "yousong/czdns:latest" \
		--push \
		"$TOPDIR"
}

tags() {
	local py_print='
import json, sys
rs = json.load(sys.stdin)
rs = rs["results"]
rs = "\n".join("{name} {full_size} {images[0][os]} {images[0][architecture]} {last_updated}".format(**r) for r in rs)
print("Name Bytes OS Arch Updated")
print(rs)
'
	curl -s -L https://registry.hub.docker.com/v2/repositories/yousong/czdns/tags \
		| python -c "$py_print" \
		| column -t
}

"$@"

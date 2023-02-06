#!/usr/bin/env bash

set -o errexit
set -o pipefail

TOPDIR="$(readlink -f "$(dirname "$0")/..")"

retry() {
	local i=0

	while true; do
		if "$@"; then
			return 0
		fi

		let i=i+1
		if test "$i" -eq 3; then
			echo "retry: failed: $*" >&2
			return 1
		fi
		echo "retry: waiting: $*" >&2
		sleep 1
	done
}

buildgo() {
	go build -o "$TOPDIR/gfwlist" "$TOPDIR/gfwlist.go"
}

buildprep_chnconf() {
	local tmpf
	tmpf="$(mktemp)"

	if ! wget \
		--tries 2 \
		--read-timeout 11 \
		--connect-timeout 4 \
		-O "$tmpf" \
		https://github.com/felixonmars/dnsmasq-china-list/raw/master/accelerated-domains.china.conf; \
	then
		rm -f "$tmpf"
		return 1
	fi
	grep -v '^#' "$tmpf" >"$TOPDIR/files/etc/czdns/china.conf"
	rm -f "$tmpf"
}

buildprep_gfwlist() {
	local tmpf

	tmpf="$(mktemp)"
	if ! "$TOPDIR/gfwlist" -httpgettimeout 30 >"$tmpf"; then
		rm -f "$tmpf"
		return 1
	fi
	mv "$tmpf" "$TOPDIR/files/etc/czdns/gfwlist.conf"
}

buildprep() {
	rm -rf "$TOPDIR/files/etc"
	mkdir -p "$TOPDIR/files/etc/czdns"

	buildgo
	retry buildprep_gfwlist

	retry buildprep_chnconf
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

release_tag() {
	if test -z "$GITHUB_ACTIONS"; then
		git tag --force "$VERSION" HEAD
		git push origin HEAD --tags
	fi
}

release() {
	echo "$VERSION" | grep -qE "^v[0-9]+\.[0-9]+\.[0-9]+$"
	release_tag
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

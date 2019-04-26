# Usage

	docker rm --force czdns
	docker run \
		--name czdns \
		--detach \
		--restart always \
		--cap-add SETUID \
		--cap-add NET_ADMIN \
		-p 2053:53/udp \
		-p 2053:53/tcp \
		yousong/czdns

See dnsmasq [FAQ](http://thekelleys.org.uk/dnsmasq/docs/FAQ) for info on capability requirement.

# Environment variables

| Name  | Default | Note |
| ------- | ------ | ---- |
| `CHINA_DNS0`  | `223.5.5.5`  |  Name server for resolving dns names from China  |
| `OTHER_DNS0`  | `8.8.8.8`  |  Name server for resolving dns names from other region  |
| `OTHER_DNS1`  | `8.8.4.4`  |  Same as `OTHER_DNS0`, but for backup |

# Links

- czdns docker hub page, https://hub.docker.com/r/yousong/czdns/tags
- neatdns, https://github.com/ustclug/neatdns
- named忽略了forwarder响应中CNAME名字关联的A记录, https://github.com/ustclug/neatdns/issues/12
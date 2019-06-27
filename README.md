[![Join the chat at https://gitter.im/czdns/community](https://badges.gitter.im/czdns/community.svg)](https://gitter.im/czdns/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Docker Pulls](https://img.shields.io/docker/pulls/yousong/czdns.svg)](https://hub.docker.com/r/yousong/czdns)
[![Docker Stars](https://img.shields.io/docker/stars/yousong/czdns.svg)](https://hub.docker.com/r/yousong/czdns)

# Usage

	docker rm --force czdns
	docker run \
		--name czdns \
		--detach \
		--restart always \
		--cap-add NET_ADMIN \
		-p 2053:53/udp \
		yousong/czdns

See dnsmasq [FAQ](http://thekelleys.org.uk/dnsmasq/docs/FAQ) for info on capability requirement.

# Environment variables

| Name                 | Default                        | Note                                                                                                              |
| ----                 | -------                        | ----                                                                                                              |
| `USE_LIST`           | `chn`                          | Select nameservers based on whether dns names are<br>  - `chn`, from China<br>  - `gfw`, parts of gfwlist.txt<br> |
| `CHINA_DNS`          | `114.114.114.114 119.29.29.29` | Name servers for resolving dns names from China                                                                   |
| `OTHER_DNS`          | `8.8.8.8 1.1.1.1`              | Name servers for resolving dns names from other region                                                             |
| `CHINA_NAMES`        |                                | Names separated by whitespace chars.  Overrides `USE_LIST` setting and resolve these names with `CHINA_DNS`       |
| `OTHER_NAMES`        |                                | Names separated by whitespace chars.  Overrides `USE_LIST` setting and resolve these names with `OTHER_DNS`       |
| `DNSMASQ_EXTRA_CONF` |                                | Extra conf to be included by dnsmasq                                                                              |

Example value for `DNSMASQ_EXTRA_CONF`

	cache-size=40960
	dns-forward-max=4096
	add-subnet=24

Example settings for `CHINA_NAMES`, `OTHER_NAMES`

	CHINA_NAMES='github.com centos.org'
	OTHER_NAMES='gist.github.com'

# Links

- czdns docker hub page, https://hub.docker.com/r/yousong/czdns/tags
- neatdns, https://github.com/ustclug/neatdns
- named忽略了forwarder响应中CNAME名字关联的A记录, https://github.com/ustclug/neatdns/issues/12

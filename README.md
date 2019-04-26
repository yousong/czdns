# 使用

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

# 环境变量

| 变量名  | 默认值 | 备注 |
| ------- | ------ | ---- |
| `CHINA_DNS0`  | `223.5.5.5`  |  用于解析中国域名的DNS服务器  |
| `OTHER_DNS0`  | `8.8.8.8`  |  用于解析其他地区域名的DNS服务器 |
| `OTHER_DNS1`  | `8.8.4.4`  |  同`OTHER_DNS0`，备用 |

# 相关链接

- neatdns, https://github.com/ustclug/neatdns
- named忽略了forwarder响应中CNAME名字关联的A记录, https://github.com/ustclug/neatdns/issues/12

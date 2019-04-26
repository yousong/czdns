FROM alpine:3.9
MAINTAINER Yousong Zhou <yszhou4tech@gmail.com>

RUN apk add dnsmasq

#RUN apk add bind-tools strace tcpdump

RUN wget -O /etc/dnsmasq.d/china.conf \
	https://github.com/felixonmars/dnsmasq-china-list/raw/master/accelerated-domains.china.conf
ADD files/entrypoint /

EXPOSE 53/udp
EXPOSE 53/tcp

ENV CHINA_DNS0=223.5.5.5
ENV OTHER_DNS0=8.8.8.8
ENV OTHER_DNS1=8.8.4.4

ENTRYPOINT ["/entrypoint"]
CMD [ \
	"--no-ping", \
	"--no-poll", \
	"--no-resolv", \
	"--keep-in-foreground", \
	"--log-facility", "-" \
]
# run in debug mode, ctrl-c quit
#
#	"--no-daemon", \
#
# log dns queries
#
#	"--log-queries", \
#
# --no-ping, ping newly allocated address from dhcp
# --no-poll, do not poll /etc/resolv.conf
# --no-resolv, do not read resolv.conf file
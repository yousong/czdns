FROM alpine:3.9
MAINTAINER Yousong Zhou <yszhou4tech@gmail.com>

RUN apk add dnsmasq

#RUN apk add bind-tools strace tcpdump

ADD files/ /

EXPOSE 53/udp
EXPOSE 53/tcp

ENV \
	USE_LIST=chn \
	CHINA_DNS="114.114.114.114 119.29.29.29" \
	CHINA_NAMES= \
	OTHER_DNS="8.8.8.8 1.1.1.1" \
	OTHER_NAMES= \
	DNSMASQ_EXTRA_CONF=

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

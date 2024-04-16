FROM binbashing/fail2ban:latest

RUN apk add jq

COPY cf-iplist /usr/local/bin/cf-iplist
COPY cloudflare-iplist.conf /etc/fail2ban/action.d/cloudflare-iplist.conf

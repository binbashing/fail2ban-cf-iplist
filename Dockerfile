FROM binbashing/fail2ban:latest

RUN apk add jq

COPY cloudflare-iplist /usr/local/bin/cloudflare-iplist
COPY cloudflare-iplist.conf /etc/fail2ban/action.d/cloudflare-iplist.conf

FROM binbashing/fail2ban:latest

RUN apk add jq

COPY cf-iplist.sh /usr/local/bin/cf-iplist.sh
COPY cloudflare-iplist.conf /etc/fail2ban/action.d/cloudflare-iplist.conf

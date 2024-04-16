![Build and Push](https://github.com/binbashing/fail2ban-cf-iplist/actions/workflows/build-push.yaml/badge.svg)

# fail2ban-cf-iplist

Fail2Ban configuration and CLI tool to update [Cloudflare Custom IP Lists](https://developers.cloudflare.com/waf/tools/lists/custom-lists/#ip-lists)

## Requirements
* A Cloudflare API Token with the following permissions ([Docs](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)):

    > `Account:Account Filter Lists:Edit`

    > `Account:Account Filter Lists:Read`

    > `Account:Account Settings: Read`

* A Cloudflare Custom IP List ([Docs](https://developers.cloudflare.com/waf/tools/lists/create-dashboard/))

## Contents

### [cloudflare-iplist.conf](./cloudflare-iplist.conf)
A Fail2Ban Action configuration file.  On most systems this belongs in `/etc/fail2ban/actions.d`

### [cloudflare-iplist](./cloudflare-iplist)
A CLI shell utility for adding and removing IP address from a Cloudflare Custom IP List

Requires CF_API_TOKEN environment variable containing a Cloudflare API Token


Usage:
```bash
    cloudflare-iplist -l <list> -a <action> -i <ip>

    Options:
    -l <list>     name of the IP list.
    -a <action>   action of operation. Can be 'add' or 'remove'.
    -i <ip>       IP address to add or remove.

    Example:
    cloudflare-iplist -l my_blocklist -a add -i 192.0.2.0
```


### [Dockerfile](./Dockerfile)

A simple Docker container defintion Based on [binbashing/fail2ban](https://github.com/binbashing/fail2ban-docker) with cloudflare-iplist installed

[Docker Hub](https://hub.docker.com/r/binbashing/fail2ban-cf-iplist)
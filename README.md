# vpn-client

## About

This Bash script helps with managing
[VPN](https://en.wikipedia.org/wiki/Virtual_private_network)
connections with [OpenVPN](https://openvpn.net/).

## How It Works

On line four of the script, you may specify a default VPN client by
making it the value of the variable `DClient`:

```
#DClient="a.dummy.client"
```

You may specify other clients by adding them to the array `PClients`
(possible clients) that begins on line seven:

```
PClients[0]="a.dummy.client"
PClients[1]="b.dummy.client"
PClients[2]="c.dummy.client"
PClients[3]="d.dummy.client"
```

If you want the script to start clients, you need to list at least one
valid client at the top of the script, either as a default or as a
"possible client." This is because users don't typically have access
to `/etc/openvpn/client/`, where client configuration files reside, so
the script doesn't attempt to determine which clients are available to
start. You need to tell it, manually.

One more condition for starting a client is an internet connection. If
you don't have an internet connection, you can only use the script to
stop clients or check their status.

Suppose, then, that you listed at least one valid client at the top of
the script and have an internet connection. If you run the script
without options, and no client is active, the script asks to start a
client. If you listed only one client at the top of the script, the
script asks to start it. If you listed more than one, the script
prints that list. You may choose one to start or choose "skip" to exit
the script. A default client, if you gave one, appears at the top of
the list with the flag `[default]`. You can simply press Enter to
start it.

If you run the script without options, and a client is active, the
script asks if you want to stop or restart the active client or "skip"
to exit the script.

You may also run the script with several options:

```
$ vpn-client.sh [restart [now]|start [now]|status|stop [now]]
```

The option `status` reports on [OpenVPN](https://openvpn.net/):
whether it's running and, if so, which client is active. If the script
detects that a client is active but without an internet connection,
the script reports that, too.

The options `restart`, `start`, and `stop` attempt to perform their
respective actions on the client. Adding `now` does so without asking
for confirmation.

## Portability

Since the script uses arrays, it's not strictly
[POSIX](https://en.wikipedia.org/wiki/POSIX)-compliant. As a result,
it isn't compatible with
[Dash](http://gondor.apana.org.au/~herbert/dash/) and probably a good
number of other shells.

## License

This project is in the public domain under [The
Unlicense](https://choosealicense.com/licenses/unlicense/).

## Requirements

* [OpenVPN](https://openvpn.net/)


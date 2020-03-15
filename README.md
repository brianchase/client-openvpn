# client-openvpn

## About

This Bash script helps with managing
[VPN](https://en.wikipedia.org/wiki/Virtual_private_network "VPN")
connections with [OpenVPN](https://openvpn.net "OpenVPN").

## How It Works

You may specify a default VPN client by making it the value of the
variable `DClient`:

```
#DClient="a.dummy.client"
```

You may specify other clients by adding them to the array `PClient`
(the *p* is for *possible*):

```
PClient[0]="a.dummy.client"
PClient[1]="b.dummy.client"
PClient[2]="c.dummy.client"
PClient[3]="d.dummy.client"
```

To start clients, you need to list at least one valid `DClient` or
`PClient`. This is because users don't typically have access to
`/etc/openvpn/client/`, where client configuration files reside, so
the script doesn't attempt to determine which clients are available to
start. You need to tell it, manually.

Suppose, then, that you've listed at least one valid client. If you
run the script without options, and no client is active, the script
asks to start a client. If you've listed only one client (whether as a
`DClient` or `PClient` or both makes no difference), the script asks
to start that client. If you've listed more than one, the script
prints a numbered list of them, and you may choose one to start or
choose "skip" to exit the script. A default client, if you gave one,
appears at the top of the list with the flag `[default]`. You may
simply press Enter to start it.

If you run the script without options, and a client is active, the
script asks if you want to stop or restart the active client or "skip"
to exit the script.

Below is a summary of options:

```
$ client-openvpn.sh [restart|start|stop] [now]
```

Use `restart`, `start`, or `stop` to perform those actions on a
client. Adding `now` bypasses prompts for confirmation.

If no client is active, `restart` and `restart now` give error
messages, then ask to start a profile, if you've listed any. By
contrast, `stop` just gives an error message, while `stop now` just
exits with an error code. The latter is helpful when all you care
about is that [OpenVPN](https://openvpn.net "OpenVPN") is stopped, not
whether there was an active client to begin with.

## License

This project is in the public domain under [The
Unlicense](https://choosealicense.com/licenses/unlicense "The
Unlicense").

## Requirements

* [OpenVPN](https://openvpn.net "OpenVPN")


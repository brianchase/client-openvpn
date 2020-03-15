#!/bin/bash

# From: https://github.com/brianchase/client-openvpn

# Optional default client:
#DClient=""

# Array of possible clients (change as necessary):
PClients[0]="a.dummy.client"
PClients[1]="b.dummy.client"
PClients[2]="c.dummy.client"
PClients[3]="d.dummy.client"

client_loop () {
  until [ "$Client" ]; do
    local DefTag N=0 Opt i j
    printf '%s\n\n' "Please choose:"
    if [ "$DClient" ]; then
# If DClient has a value, make it Profiles[0].
      for i in "${!PClient[@]}"; do
        if [ "${PClient[$i]}" = "$DClient" ]; then
          unset "PClient[$i]"
          PClient=("${PClient[@]}")
          break
        fi
      done
      PClient=("$DClient" "${PClient[@]}")
      DefTag=" [default]"
    fi
# Now build the rest of the menu.
    printf '\t%s\n' "$((N += 1)). Start OpenVPN client ${PClient[0]}$DefTag"
    for j in "${!PClient[@]}"; do
      if [ "$j" != 0 ]; then
        printf '\t%s\n' "$((N += 1)). Start OpenVPN client ${PClient[j]}"
      fi
    done
    printf '\t%s\n' "$((N += 1)). Skip"
    read -r Opt
    case $Opt in
      *[!1-9]*) continue ;;
      "$N") return 1 ;;
    esac
    if [ -z "$Opt" ] && [ -z "$DClient" ]; then
      continue
    elif [ -z "$Opt" ]; then
      Client="${PClient[0]}"
    elif [ "$Opt" -ge 1 ] && [ "$Opt" -lt "$N" ]; then
      Client="${PClient[(($Opt - 1))]}"
    fi
  done
}

vpn_client () {
  if [ -z "$DClient" ] && [ "${#PClient[*]}" -eq 0 ]; then
    printf '%s\n' "No listed OpenVPN clients!" >&2
    return 1
  elif [ -z "$DClient" ] && [ "${#PClient[*]}" -eq 1 ]; then
    Client="${PClient[*]}"
  elif [ "$DClient" ] && [ "${#PClient[*]}" -eq 0 ]; then
    Client="$DClient"
  elif [ "${#PClient[*]}" -eq 1 ] && [ "$DClient" = "${PClient[*]}" ]; then
    Client="$DClient"
  else
    set -- "start" "now"
    client_loop || return 1
  fi
  vpn_arg start "$2"
}

vpn_op () {
  until [ "$Opt" ]; do
    printf '%s\n\n\t%s\n\t%s\n\t%s\n' "Please choose:" \
      "1. Stop OpenVPN client $Client" \
      "2. Restart OpenVPN client $Client" \
      "3. Skip"
    local Opt
    read -r Opt
    case $Opt in
      1) vpn_arg stop now ;;
      2) vpn_arg restart now ;;
      3) return 1 ;;
      *) unset Opt ;;
    esac
  done
}

vpn_arg () {
  if [ "$2" != now ]; then
    local Confirm
    read -r -p "${1^} OpenVPN client $Client? [y/n] " Confirm
    [ "$Confirm" = y ] || return 1
  fi
  if ! systemctl "$1" openvpn-client@"$Client"; then
    printf '%s\n' "Failed to $1 OpenVPN client $Client!" >&2
    return 1
  fi
}

vpn_main () {
  Client="$(systemctl list-units -t service --state=running | grep -oP 'OpenVPN tunnel for \K.*\b')"
  if [ "$Client" ]; then
    case $1 in
      restart|stop) vpn_arg "$1" "$2" ;;
      *) vpn_op ;;
    esac
  else
    case $1 in
      restart) printf "No active OpenVPN client! " >&2 ;;
      stop) case $2 in
              now) return 1 ;;
              *) printf '%s\n' "No active OpenVPN client!" >&2
                 return 1 ;;
            esac ;;
    esac
    vpn_client start "$2"
  fi
}

vpn_main "$1" "$2"

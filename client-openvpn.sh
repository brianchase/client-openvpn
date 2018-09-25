#!/bin/bash

# From: https://github.com/brianchase/client-openvpn

# Optional default client:
#DClient="a.dummy.client"

# Array of possible clients (change as necessary):
PClients[0]="a.dummy.client"
PClients[1]="b.dummy.client"
PClients[2]="c.dummy.client"
PClients[3]="d.dummy.client"

vpn_op () {
  until [ "$Opt" ]; do
    printf '%s\n\n\t%s\n\t%s\n\t%s\n' "Please choose:" \
      "1. Stop OpenVPN client $Client" \
      "2. Restart OpenVPN client $Client" \
      "3. Skip"
    local Opt
    read -r Opt
    case $Opt in
      1) vpn_arg stop ;;
      2) vpn_arg restart ;;
      3) return 1 ;;
      *) unset Opt ;;
    esac
  done
}

client_loop () {
  until [ "$Client" ]; do
    local DefTag N=0 Opt i j
    printf '%s\n\n' "Please choose:"
    if [ "$DClient" ]; then
# If DClient has a value, make it Profiles[0].
      for i in "${!PClients[@]}"; do
        if [ "${PClients[$i]}" = "$DClient" ]; then
          unset "PClients[$i]"
          PClients=("${PClients[@]}")
          break
        fi
      done
      PClients=("$DClient" "${PClients[@]}")
      DefTag=" [default]"
    fi
# Now build the rest of the menu.
    printf '\t%s\n' "$((N += 1)). Start OpenVPN client ${PClients[0]}$DefTag"
    for j in "${!PClients[@]}"; do
      if [ "$j" != 0 ]; then
        printf '\t%s\n' "$((N += 1)). Start OpenVPN client ${PClients[j]}"
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
      Client="${PClients[0]}"
    elif [ "$Opt" -ge 1 ] && [ "$Opt" -lt "$N" ]; then
      Client="${PClients[(($Opt - 1))]}"
    fi
  done
}

vpn_start () {
  if [ -z "$DClient" ] && [ "${#PClients[*]}" -eq 0 ]; then
    printf '%s\n' "Could not start OpenVPN! No listed clients!" >&2
    return 1
  elif [ -z "$DClient" ] && [ "${#PClients[*]}" -eq 1 ]; then
    Client="${PClients[*]}"
  elif [ "$DClient" ] && [ "${#PClients[*]}" -eq 0 ]; then
    Client="$DClient"
  elif [ "${#PClients[*]}" -eq 1 ] && [ "$DClient" = "${PClients[*]}" ]; then
    Client="$DClient"
  else
# If there's more than one client, choose which one to start.
    client_loop && vpn_arg start
    return
  fi
# If there's just one client, set about starting it.
  vpn_confirm start "$1"
}

vpn_arg () {
  if ! systemctl "$1" openvpn-client@"$Client"; then
    printf '%s\n' "Failed to $1 OpenVPN client $Client!" >&2
    return 1
  fi
}

vpn_confirm () {
  if [ "$2" = now ]; then
    vpn_arg "$1"
  else
    local Confirm
    read -r -p "${1^} OpenVPN client $Client? [y/n] " Confirm
    [ "$Confirm" = y ] || return 1
    vpn_arg "$1"
  fi
}

vpn_online () {
  if wget -q --tries=10 --timeout=20 --spider http://google.com; then
    if [ "$1" = restart ]; then
# An internet connection, OpenVPN is active, and '$1' is 'restart'.
      vpn_confirm restart "$2"
    elif [ "$Client" ]; then
# An internet connection and OpenVPN is active.
      vpn_op
    else
# An internet connection and OpenVPN is inactive.
      vpn_start "$2"
    fi
  elif [ "$Client" ]; then
# No internet connection and OpenVPN is active.
    printf '%s\n' "OpenVPN client $Client is active but offline!" >&2
    vpn_confirm stop
  else
# No internet connection and OpenVPN is inactive.
    printf '%s\n' "No internet connection or active OpenVPN client!" >&2
    return 1
  fi
}

vpn_main () {
  if systemctl is-active -q openvpn-client@*; then
    Client="$(systemctl list-units -t service | grep -oP 'OpenVPN tunnel for \K.*\b')"
    case $1 in
      stop) vpn_confirm "$1" "$2" ;;
      *) vpn_online "$1" "$2" ;;
    esac
  else
    case $1 in
      restart) printf "No active OpenVPN client! " >&2
               vpn_start "$2" ;;
      stop) case $2 in
              now) return 1 ;;
              *) printf '%s\n' "No active OpenVPN client!" >&2
                 return 1 ;;
            esac ;;
      *) vpn_online "$1" "$2" ;;
    esac
  fi
}

vpn_main "$1" "$2"

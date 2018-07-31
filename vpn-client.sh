#!/bin/bash

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
    local N=0 Opt i j k
    printf '%s\n\n' "Please choose:"
    if [ "$DClient" ]; then
      for i in "${PClients[@]}"; do
        if [ "$i" = "$DClient" ]; then
          for j in "${!PClients[@]}"; do
            if [ "${PClients[$j]}" = "$i" ]; then
              unset "PClients[$j]"
              PClients=("${PClients[@]}")
              break;
            fi
          done
        fi
      done
      PClients=("$DClient" "${PClients[@]}")
      for k in "${!PClients[@]}"; do
        if [ "$k" = 0 ]; then
          printf '\t%s\n' "$((N += 1)). OpenVPN client ${PClients[k]} [default]"
        else
          printf '\t%s\n' "$((N += 1)). OpenVPN client ${PClients[k]}"
        fi
      done
      printf '\t%s\n' "$((N += 1)). Skip"
      read -r Opt
      case $Opt in
        *[!1-9]*) continue ;;
      esac
      if [ -z "$Opt" ]; then
        Client="${PClients[0]}"
      elif [ "$Opt" -gt "$N" ]; then
        continue
      elif [ "$Opt" -ne "$N" ]; then
        Client="${PClients[(($Opt - 1))]}"
      fi
    else
      for i in "${!PClients[@]}"; do
        printf '\t%s\n' "$((N += 1)). OpenVPN client ${PClients[i]}"
      done
      printf '\t%s\n' "$((N += 1)). Skip"
      read -r Opt
      case $Opt in
        ''|*[!1-9]*) continue ;;
      esac
      if [ "$Opt" -gt "$N" ]; then
        continue
      elif [ "$Opt" -ne "$N" ]; then
        Client="${PClients[(($Opt - 1))]}"
      fi
    fi
    if [ "$Opt" ] && [ "$Opt" -eq "$N" ]; then
      return 1
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
    client_loop && vpn_arg start
    return
  fi
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
    if [ "$Confirm" = y ]; then
      vpn_arg "$1"
    else
      return 1
    fi
  fi
}

vpn_online () {
  if wget -q --tries=10 --timeout=20 --spider http://google.com; then
    if [ "$1" = restart ]; then
      vpn_confirm restart "$2"
    elif [ "$Client" ]; then
      vpn_op
    else
      vpn_start "$2"
    fi
  elif [ "$Client" ]; then
    printf '%s\n' "OpenVPN client $Client is active but offline!"
    vpn_confirm stop
  else
    printf '%s\n' "No internet connection or active OpenVPN client!" >&2
    return 1
  fi
}

vpn_main () {
  if systemctl is-active -q openvpn-client@*; then
    Client="$(systemctl list-units -t service | grep -oP 'OpenVPN tunnel for \K.*\b')"
    case $1 in
      status) printf '%s\n' "OpenVPN client $Client is active" ;;
      stop) vpn_confirm "$1" "$2" ;;
      *) vpn_online "$1" "$2" ;;
    esac
  else
    case $1 in
      restart|stop) return 1 ;;
      status) printf '%s\n' "No active OpenVPN client" ;;
      *) vpn_online "$1" "$2" ;;
    esac
  fi
}

vpn_main "$1" "$2"

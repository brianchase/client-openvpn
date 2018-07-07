#!/bin/bash

# Optional default client:
#DC="a.dummy.client"

# Array of possible clients (change as necessary):
PC[0]="a.dummy.client"
PC[1]="b.dummy.client"
PC[2]="c.dummy.client"
PC[3]="d.dummy.client"

vpn_op () {
  until [ "$OP" ]; do
    printf '%s\n\n' "Please choose:"
    printf '\t%s\n' "1. Stop OpenVPN client $CL"
    printf '\t%s\n' "2. Restart OpenVPN client $CL"
    printf '\t%s\n' "3. Skip"
    read -r OP
    case $OP in
      1) vpn_arg stop ;;
      2) vpn_arg restart ;;
      3) return 1 ;;
      *) unset OP ;;
    esac
  done
}

client_loop () {
  until [ "$CL" ]; do
    N=0
    printf '%s\n\n' "Please choose:"
    if [ "$DC" ]; then
      for i in "${PC[@]}"; do
        if [ "$i" = "$DC" ]; then
          for j in "${!PC[@]}"; do
            if [ "${PC[$j]}" = "$i" ]; then
              unset "PC[$j]"
              PC=("${PC[@]}")
              break;
            fi
          done
        fi
      done
      PC=("$DC" "${PC[@]}")
      for j in "${!PC[@]}"; do
        if [ "$j" = 0 ]; then
          printf '\t%s\n' "$((N += 1)). OpenVPN client ${PC[j]} [default]"
        else
          printf '\t%s\n' "$((N += 1)). OpenVPN client ${PC[j]}"
        fi
      done
      printf '\t%s\n' "$((N += 1)). Skip"
      read -r OP
      case $OP in
        *[!1-9]*) continue ;;
      esac
      if [ -z "$OP" ]; then
        CL="${PC[0]}"
      elif [ "$OP" -gt "$N" ]; then
        continue
      elif [ "$OP" -ne "$N" ]; then
        CL="${PC[(($OP - 1))]}"
      fi
    else
      for i in "${!PC[@]}"; do
        printf '\t%s\n' "$((N += 1)). OpenVPN client ${PC[i]}"
      done
      printf '\t%s\n' "$((N += 1)). Skip"
      read -r OP
      case $OP in
        ''|*[!1-9]*) continue ;;
      esac
      if [ "$OP" -gt "$N" ]; then
        continue
      elif [ "$OP" -ne "$N" ]; then
        CL="${PC[(($OP - 1))]}"
      fi
    fi
    if [ "$OP" ] && [ "$OP" -eq "$N" ]; then
      return 1
    fi
  done
}

vpn_start () {
  if [ -z "$DC" ] && [ "${#PC[*]}" -eq 0 ]; then
    printf '%s\n' "Could not start OpenVPN! No listed clients!"
    return 1
  elif [ -z "$DC" ] && [ "${#PC[*]}" -eq 1 ]; then
    CL="${PC[*]}"
  elif [ "$DC" ] && [ "${#PC[*]}" -eq 0 ]; then
    CL="$DC"
  elif [ "${#PC[*]}" -eq 1 ] && [ "$DC" = "${PC[*]}" ]; then
    CL="$DC"
  else
    client_loop && vpn_arg start
    return
  fi
  vpn_confirm start "$1"
}

vpn_arg () {
  if ! systemctl "$1" openvpn-client@"$CL"; then
    printf '%s\n' "Failed to $1 OpenVPN client $CL!"
    return 1
  fi
}

vpn_confirm () {
  if [ "$2" = now ]; then
    vpn_arg "$1"
  else
    read -r -p "${1^} OpenVPN client $CL? [y/n] " CF
    if [ "$CF" = y ]; then
      vpn_arg "$1"
    else
      return 1
    fi
  fi
}

chk_online () {
  if wget -q --tries=10 --timeout=20 --spider http://google.com; then
    if [ "$1" = restart ]; then
      vpn_confirm restart "$2"
    elif [ "$CL" ]; then
      vpn_op
    else
      vpn_start "$2"
    fi
  elif [ "$CL" ]; then
    printf '%s\n' "OpenVPN client $CL is active but offline!"
    vpn_confirm stop
  else
    printf '%s\n' "No internet connection or active OpenVPN client!"
    return 1
  fi
}

vpn_main () {
  if systemctl is-active -q openvpn-client@*; then
    CL="$(systemctl list-units -t service | grep -oP 'OpenVPN tunnel for \K.*\b')"
    case $1 in
      status) printf '%s\n' "OpenVPN client $CL is active" ;;
      stop) vpn_confirm "$1" "$2" ;;
      *) chk_online "$1" "$2" ;;
    esac
  else
    case $1 in
      restart|stop) return 1 ;;
      status) printf '%s\n' "No active OpenVPN client" ;;
      *) chk_online "$1" "$2" ;;
    esac
  fi
}

vpn_main "$1" "$2"

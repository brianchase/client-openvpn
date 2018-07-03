#!/bin/bash

# Optional default client:
#DC="a.dummy.client"

# Array of possible clients (change as necessary):
PC[0]="a.dummy.client"
PC[1]="b.dummy.client"
PC[2]="c.dummy.client"
PC[3]="d.dummy.client"

vpn_stop () {
  if [ "$1" != now ]; then
    read -r -p "Stop OpenVPN client $CL? [y/n] " DN
  fi
  if [ "$DN" = y ] || [ "$1" = now ]; then
    vpn_arg stop
  fi
}

vpn_restart () {
  if chk_online; then
    if [ "$1" != now ]; then
      read -r -p "Restart OpenVPN client $CL? [y/n] " RV
    fi
    if [ "$RV" = y ] || [ "$1" = now ]; then
      vpn_arg restart
    fi
  fi
}

vpn_op () {
  until [ "$OP" ]; do
    printf '%s\n\n' "Please choose:"
    printf '\t%s\n' "1. Stop OpenVPN client $CL"
    printf '\t%s\n' "2. Restart OpenVPN client $CL"
    printf '\t%s\n' "3. Skip"
    read -r OP
    case $OP in
      1) vpn_stop now ;;
      2) vpn_restart now ;;
      3) break ;;
      *) unset OP ;;
    esac
  done
}

chk_online () {
  if ! wget -q --tries=10 --timeout=20 --spider http://google.com; then
    printf '%s\n' "Not online! Please connect, then rerun this script!"
    return 1
  fi
}

client_loop () {
  until [ "$CL" ]; do
    if [ -z "$DC" ] && [ "${#PC[*]}" -eq 0 ]; then
      printf '%s\n' "Could not start OpenVPN! No listed clients!"
      return 1
    elif [ -z "$DC" ] && [ "${#PC[*]}" -eq 1 ]; then
      CL="${PC[0]}"
    elif [ "$DC" ] && [ "${#PC[*]}" -eq 0 ]; then
      CL="$DC"
    elif [ "${#PC[*]}" -eq 1 ] && [ "$DC" = "${PC[*]}" ]; then
      CL="$DC"
    else
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
    fi
  done
}

vpn_arg () {
  if ! systemctl "$1" openvpn-client@"$CL"; then
    printf '%s\n' "Failed to $1 OpenVPN client $CL!"
    return 1
  fi
}

vpn_start () {
  if chk_online && client_loop; then
    vpn_arg start
  fi
}

vpn_main () {
  if systemctl is-active -q openvpn-client@*; then
    CL="$(systemctl status openvpn-client@* | grep -oP 'OpenVPN tunnel for \K.*')"
    case $1 in
      restart) vpn_restart "$2" ;;
      status) printf '%s\n' "OpenVPN client $CL is active" ;;
      stop) vpn_stop "$2" ;;
      *) vpn_op ;;
    esac
  else
    case $1 in
      restart|status|stop) printf '%s\n' "No OpenVPN client is active" ;;
      *) vpn_start ;;
    esac
  fi
}

vpn_main "$1"

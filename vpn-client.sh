#!/bin/bash

# Optional default client:
#DC="a.dummy.client"

# Array of possible clients (change as necessary):
PC[0]="a.dummy.client"
PC[1]="b.dummy.client"
PC[2]="c.dummy.client"
PC[3]="d.dummy.client"

# Useful for scripts (see online-netctl.sh):
vpn_stopnow () {
  printf '%s\n' "Stopping OpenVPN... "
  vpn_arg stop
}

vpn_stop () {
  read -r -p "Stop OpenVPN client $AC? [y/n] " DN
  if [ "$DN" = y ]; then
    vpn_stopnow
  fi
}

vpn_arg () {
  if systemctl "$1" openvpn-client@*; then
    chk_status "$1"
  fi
}

vpn_restart () {
  if chk_online; then
    read -r -p "Restart OpenVPN client $AC? [y/n] " RV
    if [ "$RV" = y ]; then
      vpn_arg restart
    fi
  fi
}

vpn_op () {
  until [ "$OP" ]; do
    printf '%s\n\n' "Please choose:"
    printf '\t%s\n' "1. Stop OpenVPN client $AC"
    printf '\t%s\n' "2. Restart OpenVPN client $AC"
    printf '\t%s\n' "3. Exit"
    read -r OP
    case $OP in
      1) vpn_stop ;;
      2) vpn_restart ;;
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

vpn_client () {
  until [ "$DC" ]; do
    if [ "${#PC[*]}" -eq 0 ]; then
      printf '%s\n' "Could not start OpenVPN! No listed clients!"
      return 1
    elif [ "${#PC[*]}" -eq 1 ]; then
      DC="${PC[*]}"
    else
      N=0
      printf '%s\n\n' "Please choose:"
      for i in "${!PC[@]}"; do
        printf '\t%s\n' "$((N += 1)). ${PC[i]}"
      done
      printf '\t%s\n' "$((N += 1)). Exit"
      read -r OP
      case $OP in
        ''|*[!1-9]*) continue ;;
      esac
      if [ "$OP" -gt "$N" ]; then
        continue
      elif [ "$OP" -eq "$N" ]; then
        return 1
      else
        DC="${PC[(($OP - 1))]}"
      fi
    fi
  done
}

vpn_active_client () {
  AC="$(systemctl status openvpn-client@* | grep -oP "OpenVPN tunnel for \K.*")"
}

chk_status () {
  if systemctl is-active -q openvpn-client@*; then
    vpn_active_client
    printf '%s\n' "OpenVPN active client: $AC"
  else
    printf '%s\n' "OpenVPN is inactive"
  fi
}

vpn_start () {
  if chk_online; then
    if vpn_client; then
      read -r -p "Start OpenVPN client $DC? [y/n] " UP
      if [ "$UP" = y ]; then
        systemctl start openvpn-client@"$DC"
        chk_status
      fi
    fi
  fi
}

vpn_main () {
  if systemctl is-active -q openvpn-client@*; then
    vpn_active_client
    case $1 in
      restart) vpn_restart ;;
      status) printf '%s\n' "OpenVPN active client: $AC" ;;
      stop) vpn_stop ;;
      stopnow) vpn_stopnow ;;
      *) vpn_op ;;
    esac
  else
    case $1 in
      restart) printf '%s\n' "OpenVPN is inactive"
               chk_online ;;
      status|stop) printf '%s\n' "OpenVPN is inactive" ;;
      stopnow) ;;
      *) vpn_start ;;
    esac
  fi
}

vpn_main $1

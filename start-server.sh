#!/bin/bash

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

function echo-info {
    echo -e "\e[34;1m[+]\e[0m \e[34mInfo: $1\e[0m" >&2
}

function echo-warning {
    echo -e "\e[31;1m[!] Warning: $1\e[0m" >&2
}

function printInfo {
  echo -e "\e[34;1mUsage:\e[0m"
  echo -e "\e[34;1m- Start PXE server: \e[0m \e[34m$0 pxe <interface>\e[0m"
  echo -e "\e[34;1m- Start SMB server: \e[0m \e[34m$0 smb <interface>\e[0m"
}


# Function to start the PXE and DHCP server
function start-pxe-server {
  interface=$1

  if [[ "$interface" = "" ]]; then
    echo-warning "No interface specified!"
    printInfo
    exit
  fi

  # Add IP address to interface
  addr="10.13.37.100/24"
  echo-info "Interface $interface has IP address $addr"



  if ! ip link show "$interface" 2>/dev/null | grep -q "state UP"; then
      echo-info "[$interface] is DOWN → bringing it UP…"
      sudo ip link set dev "$interface" up
  else
      echo-info "[$interface] already UP."
  fi


  if ip -4 addr show dev "$interface" | grep -q "\b${addr%/*}\b"; then
      echo-info "[$interface] already has $addr"
  else
      echo-info "Adding $addr to $interface"
      sudo ip addr add "$addr" dev "$interface"
  fi

  stop-servers

  # Start dnsmasq
  echo-info "Starting dnsmasq..."
  sudo dnsmasq --no-daemon --interface=$interface --dhcp-range=10.13.37.100,10.13.37.200,255.255.255.0,1h --dhcp-boot=bootmgfw.efi --enable-tftp --tftp-root=$SCRIPTPATH/pxe-server
  echo-info "Stopping dnsmasq..."
}

# Function to start the SMBserver
function start-smb-server {
  interface=$1

  if [[ -f /root/venv/bin/activate ]]; then
      source /root/venv/bin/activate
  fi

  if [[ "$interface" = "" ]]; then
    echo-warning "No interface specified!"
    printInfo
    exit
  fi

  # Add IP address to interface
  sudo ip a add 10.13.37.100/24 dev $interface
  echo-info "Interface $interface has IP address 10.13.37.100/24"

  # Start dnsmasq
  echo-info "Starting smbserver.py..."
  sudo $(which smbserver.py) -smb2support smb "$SCRIPTPATH/pxe-server"
  echo-info "Stopping smbserver.py..."
}

# Function to stop the servers
function stop-servers {
  echo-info "Killing all dnsmasq processes..."
  sudo killall dnsmasq
}


if [[ "$1" = "smb" ]]; then
  start-smb-server $2
  exit
elif [[ "$1" = "pxe" ]]; then
  start-pxe-server $2
  exit
else
  printInfo
  exit
fi

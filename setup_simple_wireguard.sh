#!/bin/bash
# SYNOPSIS
#    
# DESCRIPTION
#   Install Pre-requisites for wg-quick and creates the configuration file for the wg
#   interface at /etc/wireguard/wg0
#
#   If, on Peer A, we configure an Endpoint setting for Peer B, we can skip configuring an Endpoint setting on
#   Peer B for Peer A — Peer B will wait until Peer A connects to it,
#   and then dynamically update its Endpoint setting to the actual IP address and port from which Peer A connected.
#   https://www.procustodibus.com/blog/2021/01/wireguard-endpoints-and-ip-addresses/
#
# OPTIONS
# -k    Peer Public-Key
# -p    Wireguard Port.                            DEFAULT = 51820"
# -a    IP Address of the Wireguard Interface.     DEFAULT = 10.0.2.1/32"
# -i    Set the local network interface.           DEFAULT = enp1s0"
# -d    Delete wireguard configuration.
#
# EXAMPLES
#   Minimal, use all default values
#   ./setup_simple_wireguard.sh -k {PublicKey of PEER Machine}
#
#   ./setup_simple_wireguard.sh -k {PublicKey of PEER Machine} -p 51821 -a 10.10.1.1/32 -d eth0
#================================================================
# IMPLEMENTATION
#    author          Simon
#    license         GNU GENERAL PUBLIC LICENSE Version 3
#================================================================

#################################################################
# Help                                                          #
#################################################################
help() {
cat << EOF
Setup a simple Wireguard connection between Server and Client
Usage: setup_simple_wireguard.sh [-k|p|a|i|d|h]
Install Pre-requisites for wg-quick and creates the configuration file for the wg0
interface at /etc/wireguard/wg0

-k    Peer Public-Key
-p    Wireguard Port.                            DEFAULT = 51820"
-a    IP Address of the Wireguard Interface.     DEFAULT = 10.0.2.1/32"
-i    Set the local network interface.           DEFAULT = enp1s0"
-d    Delete wireguard configuration.
-h    Print this Help

EOF
}
#################################################################
# Main program                                                  #
#################################################################
create_key() {
    umask 077
    wg genkey | tee private_key | wg pubkey > publickey
    private_key="$(cat private_key)"
    umask 022
}

create_wg_config() {
    cat>/etc/wireguard/wg0.conf <<-EOF
    # local settings for Endpoint A
    [Interface]
    PrivateKey = ${private_key}
    ListenPort = ${wireguard_port}
    Address = ${interface_address}

    # IP forwarding
    PreUp = sysctl -w net.ipv4.ip_forward=1
    # IP masquerading (source NAT)
    PostUp = iptables -A FORWARD -i %i -j ACCEPT
    PostUp = iptables -A FORWARD -o %i -j ACCEPT
    PostUp = iptables -t nat -A POSTROUTING -o ${local_interface} -j MASQUERADE

    PostDown = iptables -D FORWARD -i %i -j ACCEPT
    PostDown = iptables -D FORWARD -o %i -j ACCEPT
    PostDown = iptables -t nat -D POSTROUTING -o ${local_interface} -j MASQUERADE

    # remote settings for Host B
    [Peer]
    PublicKey = ${peer_public_key}
    AllowedIPs = ${allowed_peer_ip}
EOF
}

start_enable_wgquick() {
    systemctl enable wg-quick@wg0
    systemctl start wg-quick@wg0
}

reset_all() {
  read -p "All WireGuard configuration will be deleted? [Y/n] " -n 1 -r
  echo # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    systemctl stop wg-quick@wg0
    systemctl disable wg-quick@wg0
    rm -rf /etc/wireguard/wg0.conf
    dnf remove wireguard-tools -y
  else
    exit;
  fi
}

install_prerequisites() {
  sudo dnf install wireguard-tools -y
  firewall-cmd --add-port=51820/udp --permanent
}
main() {
  install_prerequisites
  create_key
  create_wg_config
  start_enable_wgquick
}

#################################################################
# Process the input options. Add options as needed.             #
#################################################################
# Set default values for variables
wireguard_port="51820"
interface_address="10.0.2.1/32"
local_interface="enp1s0"
allowed_peer_ip="10.0.2.2/32"

# Get the options
while getopts ":ha:p::k:i::r:d" option; do
    case $option in
        h) # display Help
            help
            exit;;
        a) # Interface Address
            interface_address=$OPTARG
            ;;
        p) # Wireguard Port
            wireguard_port=$OPTARG
            ;;
        k) # Enter Peer Public-Key
            peer_public_key=$OPTARG
            ;;
        i) # Enter local interface
            local_interface=$OPTARG
            ;;
        r) # Allowed Peer IPs
            allowed_peer_ip=$OPTARG
            ;;
        d) # Delete wireguard configuration
            reset_all
            exit
            ;;
        *) # Invalid option
            help
            exit
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${peer_public_key}" ]; then
  help
else
  main "$@"
fi
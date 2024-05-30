#!/bin/bash
# SYNOPSIS
#    
# DESCRIPTION
#    This is a script template
#    to start any good shell script.
#    Note that you only need to configure a static Endpoint setting on one side of a WireGuard connection. 
#    If, on Peer A, we configure an Endpoint setting for Peer B, we can skip configuring an Endpoint setting on Peer B for Peer A — Peer B will wait until Peer A connects to it, 
#    and then dynamically update its Endpoint setting to the actual IP address and port from which Peer A connected.
#    https://www.procustodibus.com/blog/2021/01/wireguard-endpoints-and-ip-addresses/
#
# OPTIONS
#
# EXAMPLES
#   setup_wireguard.sh
#
#================================================================
# IMPLEMENTATION
#    version         setup_simple_wireguard.sh 0.0.1
#    author          Simon
#    license         GNU GENERAL PUBLIC LICENSE Version 3
#================================================================

############################################################
# Help                                                     #
############################################################
help() {

    # Display Help
    echo "Setup a simple Wireguard connection between Server and Client"
    echo
    echo "Syntax: setup_simple_wireguard.sh [-g|h|v|V]"
    echo "options:"
    echo "k     Peer Public-Key"
    echo "p     Wireguard Port. DEFAULT = 51820"
    echo "a     IP Address of the Wireguard Interface. DEFAULT = 10.0.2.1/32"
    echo "i     Set the local network interface. DEFUALT = eth0"
    echo "r     Allowed Peer IPs. DEFAUTL = 10.0.2.2/32"
    echo "d     Delete wireguard configuration."
    echo "h     Print this Help."
    echo "v     Verbose mode."
    echo "V     Print software version and exit."
    echo 
}

create_key() {
    umask 077
    wg genkey | tee privatekey | wg pubkey > publickey
    privatekey= cat privatekey
    umask 022
}

create_wg_config() {
    cat>/etc/wireguard/wg0.conf <<-EOF
    # local settings for Endpoint A
    [Interface]
    PrivateKey = ${privatekey}
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
    AllowedIPs = 10.0.2.2/24
EOF 
}

start_enable_wgquick() {
    systemc enable wg-quick@wg0
    systemc start wg-quick@wg0
}

reset_all() {
    read -r -p "${1:- All WireGurad configuraiton will be deleted?} [Y/n] " response
    case "$response" in
        @([nN])*([oO]))
            false
            exit;;
        *)
            systemctl stop wg-quick@wg0
            systemctl disable wg-quick@wg0
            rm -y /etc/wireguard/wg0.conf
            exit;;
    esac
}

main() {
    create_key
    create_wg_config
    start_enable_wgquick
}

############################################################
# Process the input options. Add options as needed.        #
############################################################
# Set default values for variables
wireguard_port= "51820"
interface_address= "10.0.2.1/32"
local_interface= "eth0"
allowed_peer_ip= "10.0.2.2/32"

# Get the options
while getopts ":hn:" option; do
    case $option in
        h) # display Help
            help
            exit;;
        a) # Interface Address
            interface_address=$OPTARG
        p) # Wireguard Port
            wireguard_port=$OPTARG
        k) # Enter Peer Public-Key
            peer_public_key=$OPTARG
        i) # Enter local interface
            local_interface=$OPTARG
        r) # Allowed Peer IPs
            allowed_peer_ip=$OPTARG
        d) # Delte wireguard configuration
            #ToDo confirmation
            reset_all
            exit;;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit;;
    esac
done

main "$@"
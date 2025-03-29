#!/usr/bin/env bash

case "$1" in
    connect)
        ./ethz-vpn-connect.exp
        ;;
    disconnect)
        /opt/cisco/secureclient/bin/vpn disconnect
        ;;
    stats)
        /opt/cisco/secureclient/bin/vpn stats
        ;;
    status)
        /opt/cisco/secureclient/bin/vpn status
        ;;
    *)
        echo "Usage: $0 {connect|disconnect|stats|status}"
        exit 1
        ;;
esac


read -r -d '' VPN_CONNECT << 'EOF'
#!/usr/bin/expect

cd /opt/cisco/secureclient/bin

set timeout 3                   ;# timeout in seconds
set addr "sslvpn.ethz.ch"       ;# VPN host address
set user "bfeitknecht@student-net.ethz.ch"      ;# ethz username, make this stored in variable?
set group "1"                                   ;# assuming "student-net" corresponds to group 1
set ETHZ_VPN "ETHZ_VPN"                         ;# keychainItem for vpn account password
set TOTP_CLI_DB "TOTP_CLI_DB"                   ;# keychainItem for totp-cli database password



#check if VPN is already connected
spawn ./vpn state

expect {
    "state: Connected" {
        send_user "\nVPN is already connected. Exiting..\n\n"
        exit 0
    }
    "state: Disconnected" {
        send_user "\nVPN is not connected. Proceeding..\n\n"
    }
    timeout {
        send_user "\ntimed out while checking VPN state. Proceeding..\n\n"
    }
}

spawn ./vpn
sleep 1  ;# add a 1-second delay

expect "VPN>"
send -- "connect $addr\r"

expect "Group:"
send -- "$group\r"

expect "Username:"
send -- "$user\r"

expect "Password:"
set password [exec security find-generic-password -s $ETHZ_VPN -w] ;# retrieve vpn account password from keychain
send -- "$password\r"

expect "Second Password:"
set TOTP [exec security find-generic-password -s $TOTP_CLI_DB -w | totp-cli generate ETH bfeitknecht@ethz.ch 2>/dev/null] ;# retrieve TOTP from totp-cli
send -- "$TOTP\r"

expect eof

#expect "state: Connected"

# uncomment this line to keep the shell open for interactive use
#interact
EOF

#!/usr/bin/env bash

USERNAME=""                 # ETHZ username (kürzel)
KEY_VPN="ETHZ_VPN"          # keychainItem of ETHZ VPN password
KEY_TOTP="TOTP_CLI_DB"      # keychainItem of totp-cli database password

# Check if USERNAME is set
if [ -z "$USERNAME" ]; then
    echo "*** ERROR: \$USERNAME needs to be set to your ETHZ kürzel!"
    exit 1
fi

connect() {
    SCRIPT=$(cat <<-EOF
		cd /opt/cisco/secureclient/bin

		set timeout 3                   ;# timeout in seconds
		set addr "sslvpn.ethz.ch"       ;# VPN host address
		set user "$USERNAME@student-net.ethz.ch"        ;# VPN user account
		set group "1"                                   ;# assuming "student-net" corresponds to group 1

		# check if VPN is already connected
		spawn ./vpn state

		expect {
			"state: Connected" {
				send_user "\nVPN is already connected. Exiting...\n\n"
				exit 0
			}
			"state: Disconnected" {
				send_user "\nVPN is not connected. Proceeding...\n\n"
			}
			timeout {
				send_user "\ntimed out while checking VPN state. Exiting...\n\n"
				exit 1
			}
		}

		spawn ./vpn
		sleep 1

		expect "VPN>"
		send -- "connect \$addr\r"

		expect "Group:"
		send -- "\$group\r"

		expect "Username:"
		send -- "\$user\r"

		expect "Password:"
		set password [exec security find-generic-password -s $KEY_VPN -w] ;# retrieve vpn account password from keychain
		send -- "\$password\r"

		expect "Second Password:"
		set otp [exec security find-generic-password -s $KEY_TOTP -w | totp-cli generate ETHZ VPN 2> /dev/null] ;# retrieve TOTP from totp-cli
		send -- "\$otp\r"

		expect eof

		# expect "state: Connected"

		# uncomment to keep interactive shell open
		# interact
	EOF
    )
    echo "$SCRIPT" | expect -
}

toggle() {
	CONNECTED=$(/opt/cisco/secureclient/bin/vpn state | grep -q "state: Connected")

	if [ "$CONNECTED" ]; then
		/opt/cisco/secureclient/bin/vpn disconnect
	else
	   connect
	fi
}

HELP_MESSAGE="\
Usage: ethz-vpn.sh <command>

Commands:
    connect      Connect to the VPN (with automatic 2FA).
    disconnect   Disconnect from the VPN.
    toggle       Toggle VPN connection (connect if disconnected, disconnect if connected).
    status       Show current VPN connection status.
    stats        Show VPN connection statistics.

Make sure your credentials for the VPN and totp-cli are stored in the macOS Keychain as required.
"


case "$1" in
    toggle)
        toggle
        ;;
    connect)
        connect
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
        echo "$HELP_MESSAGE"
        exit 1
        ;;
esac

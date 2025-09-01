#!/usr/bin/env bash

KEY_KURZ="ETHZ_KUERZEL"     # ETHZ username (kürzel)
KEY_VPN="ETHZ_VPN"          # ETHZ VPN password
KEY_TOTP="ETHZ_TOTP_TOKEN"  # ETHZ TOTP token
VPN="/opt/cisco/secureclient/bin/vpn"   # cisco VPN binary

function setup() {
    set -e

    # account associated with keychain
    account="$(whoami)"

    # check for totp-cli
    if ! command -v totp-cli &>/dev/null; then
        echo "totp-cli not found. Would you like to install it via Homebrew? [y/N]"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Installation aborted."
            return 1
        fi

        # check for homebrew
        if ! command -v brew &>/dev/null; then
            echo "Homebrew is not installed. Please install it first: https://brew.sh/"
            return 1
        fi
        brew install totp-cli
    fi

    # check keychain for n.ethz kürzel
    if security find-generic-password -s "$KEY_KURZ" &>/dev/null; then
        echo "Keychain item '$KEY_KURZ' already exists."
    else
        read -r "Enter ETHZ username (kürzel): " kuerzel
        security add-generic-password -a "$account" -s "$KEY_KURZ" -w "$kuerzel" -U
    fi

    # check keychain for VPN password
    if security find-generic-password -s "$KEY_VPN" &>/dev/null; then
        echo "Keychain item '$KEY_VPN' already exists."
    else
        read -rsp "Enter ETHZ VPN password: " password
        echo
        security add-generic-password -a "$account" -s "$KEY_VPN" -w "$password" -U
    fi

    # check keychain for TOTP token
    if security find-generic-password -s "$KEY_TOTP" &>/dev/null; then
        echo "Keychain item '$KEY_TOTP' already exists."
    else
        read -rsp "Enter ETHZ TOTP token: " token
        echo
        security add-generic-password -a "$account" -s "$KEY_TOTP" -w "$token" -U
    fi

    echo "Setup complete. You can now use ethz-vpn.sh to connect to the ETHZ VPN."
}

function connect() {
    username=$(security find-generic-password -s $KEY_KURZ -w)
    script=$(cat <<-EOF
		set timeout 3                   ;# timeout in seconds
		set addr "sslvpn.ethz.ch"       ;# VPN host address
		set user "$username@student-net.ethz.ch"        ;# VPN user account
		set group "1"                                   ;# assuming "student-net" corresponds to group 1

		# check if VPN is already connected
		spawn $VPN state

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

		spawn $VPN
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
		set otp [exec security find-generic-password -s $KEY_TOTP -w | totp-cli instant] ;# retrieve TOTP from totp-cli
		send -- "\$otp\r"

		expect eof
	EOF
    )
    echo "$script" | expect -
}

function toggle() {
	if $VPN state | grep -q "state: Connected"; then
	    $VPN disconnect
	else
	   connect
	fi
}

VERSION="v0.1.0"

HELP_MESSAGE="\
Usage: ethz-vpn.sh <command>

Commands:
    setup        Set up credentials and TOTP token for VPN connection
    connect      Connect to the VPN (with automatic 2FA)
    disconnect   Disconnect from the VPN
    toggle       Toggle VPN connection (connect if disconnected, disconnect if connected)
    status       Show current VPN connection status
    stats        Show VPN connection statistics

Make sure your credentials for the VPN and ETHZ TOTP are stored in the macOS Keychain as required.

For further information visit https://github.com/bfeitknecht/ethz-vpn.
"

case "$1" in
    setup)
        setup
        ;;
    toggle)
        toggle
        ;;
    connect)
        connect
        ;;
    disconnect)
        $VPN disconnect
        ;;
    stats)
        $VPN stats
        ;;
    status)
        $VPN status
        ;;
    "--version")
        echo "ethz-vpn.sh $VERSION"
        ;;
    *)
        echo "$HELP_MESSAGE"
        exit 1
        ;;
esac

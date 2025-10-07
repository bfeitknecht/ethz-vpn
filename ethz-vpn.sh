#!/usr/bin/env bash
#
# DEPENDENCIES:
# - EHTZ VPN client (secureclient)

KEY_KURZ="ETHZ_KUERZEL"         # ETHZ username (kürzel)
KEY_PASSWD="ETHZ_VPN_PASSWD"    # ETHZ VPN password
KEY_TOTP="ETHZ_TOTP_TOKEN"      # ETHZ TOTP token
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
    if security find-generic-password -s "$KEY_PASSWD" &>/dev/null; then
        echo "Keychain item '$KEY_PASSWD' already exists."
    else
        read -rsp "Enter ETHZ VPN password: " password
        echo
        security add-generic-password -a "$account" -s "$KEY_PASSWD" -w "$password" -U
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
    totp="$(security find-generic-password -s "$KEY_TOTP" -w | totp-cli instant)"
    kurz="$(security find-generic-password -s "$KEY_KURZ" -w)"
    passwd="$(security find-generic-password -s "$KEY_PASSWD" -w)"
    "$VPN" -s <<EOF
connect sslvpn.ethz.ch/student-net
${kurz}@student-net.ethz.ch
${passwd}
${totp}
EOF
}

function connected() {
    coproc vpnc { stdbuf -oL "$VPN" state; }
    while read -r line <&"${vpnc[0]}"; do
        if [[ "$line" =~ Disconnected ]]; then
            return 1
        fi
    done
}

function toggle() {
    if connected; then
        "$VPN" disconnect
    else
        connect
    fi
}

VERSION="v0.1.1"

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
        "$VPN" disconnect
        ;;
    stats)
        "$VPN" stats
        ;;
    status)
        connected
        ;;
    "--version")
        echo "ethz-vpn.sh $VERSION"
        ;;
    *)
        echo "$HELP_MESSAGE"
        exit 1
        ;;
esac

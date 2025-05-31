#!/usr/bin/env bash

set -e

KEY_VPN="ETHZ_VPN"
KEY_TOTP="TOTP_CLI_DB"
ACCOUNT_NAME="$(whoami)"


# check for totp-cli
if ! command -v totp-cli >/dev/null 2>&1; then
    echo "totp-cli not found. Would you like to install it via Homebrew? [y/N]"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Installation aborted."
        exit 1
    fi

    # check for homebrew
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew is not installed. Please install it first: https://brew.sh/"
        exit 1
    fi
    brew install totp-cli
fi

function check_keychain_item() {
    local service="$1"
    if security find-generic-password -s "$service" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function add_keychain_item() {
    local service="$1"
    local prompt="$2"
    read -rsp "$prompt: " password
    echo
    security add-generic-password -a "$ACCOUNT_NAME" -s "$service" -w "$password" -U
}

# check keychain for VPN password
if check_keychain_item "$KEY_VPN"; then
    echo "Keychain item '$KEY_VPN' already exists."
else
    add_keychain_item "$KEY_VPN" "Enter your ETHZ VPN password"
fi

# check keychain for totp-cli database password
if check_keychain_item "$KEY_TOTP"; then
    echo "Keychain item '$KEY_TOTP' already exists."
else
    add_keychain_item "$KEY_TOTP" "Enter your totp-cli database password"
fi

echo "Installation and setup complete."

#!/usr/bin/env bash

vpn_toggle() {
	VPN_STATE=$(/opt/cisco/secureclient/bin/vpn state | grep -q "state: Connected")

	if [ "$VPN_STATE" ]; then
		/opt/cisco/secureclient/bin/vpn disconnect
	else
		./ethz-vpn-connect.exp
	fi
}

vpn_toggle
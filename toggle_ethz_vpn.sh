#!/usr/bin/env bash

VPN_STATE=$(/opt/cisco/secureclient/bin/vpn state | grep -c "state: Connected")

if [ "$VPN_STATE" -gt 0 ]; then
    # VPN is connected, disconnect
	/opt/cisco/secureclient/bin/vpn disconnect
else
    # VPN is disconnected, connect
    ./ethz-vpn-connect.exp
fi

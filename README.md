# ETHZ VPN CLI

This is a small CLI script for managing the ETHZ VPN on macOS.

## Dependencies
- `totp-cli` database with ETH OTP secret
- `security` keychain item with VPN password


## Setup
```
# install totp-cli and add ETHZ OTP token
brew install totp-cli
totp-cli add
> DB-PASSWD
> ETH
> username@ethz.ch
> TOKEN
```


```
# add N-ETHZ username and password to Apple Keychain
security add -s 'eth-vpn' -a 'KÜRZEL' -w 'PASSWORT'
```


```
echo "alias vpn=~$(pwd)/ethz_vpn.sh" >> ~/.zshrc
```

Or similar for your shell


## Development
- path of vpn binary: ?/opt/cisco/secureclient/bin/vpn`
- get vpn state: `/opt/cisco/secureclient/bin/vpn state | grep -E 'state:' | tail -n 1`

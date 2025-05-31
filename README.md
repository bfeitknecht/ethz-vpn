# ETHZ VPN CLI

This is a small `expect` script for managing the ETHZ VPN on macOS. It works but development is still in progress.


## Dependencies

- `totp-cli` database with ETHZ's secret token for OTP
- `security` keychain item with VPN and `totp-cli` database password


## Setup

A setup script is provided for convenience. Remember to set `$USERNAME` to your ETHZ username (kürzel) in `ethz-vpn.sh`.

```
git clone https://github.com/bfeitknecht/ethz-vpn
bash ethz-vpn/setup.sh
# ...
echo "alias vpn=$(pwd)/ethz-vpn/ethz-vpn.sh" >> ~/.zshrc
```

Or similar for your shell

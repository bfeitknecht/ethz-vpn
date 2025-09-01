# ETHZ VPN

Little script for managing the ETHZ VPN on macOS.


## Dependencies

The ETHZ TOTP token is required. Either `totp-cli` is already installed or it will be installed with `brew`. The native `security` utility is used to safely store the credentials.


## Installation

Just clone this repository. A setup subcommand is provided for convenience.

```zsh
git clone https://github.com/bfeitknecht/ethz-vpn
./ethz-vpn setup
# ...
echo "alias vpn=$(pwd)/ethz-vpn/ethz-vpn.sh" >> ~/.zshrc # or similar for your shell
```

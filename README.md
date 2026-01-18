# ETHZ VPN

Little script for managing the ETHZ VPN on macOS.

## Dependencies

Your ETHZ TOTP token is required to generate 2FA codes with [`totp-cli`](https://github.com/yitsushi/totp-cli). If the binary is not installed can optionally be installed with [`brew`](https://homebrew.sh). The native `security` utility is used to safely store the credentials.

## Installation

Just clone this repository. A setup subcommand is provided for convenience.

```zsh
git clone https://github.com/bfeitknecht/ethz-vpn
cd ethz-vpn
./ethz-vpn setup
# ...
echo "alias vpn=$(pwd)/ethz-vpn.sh" >> ~/.zshrc # or similar for your shell
```


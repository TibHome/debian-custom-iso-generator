# Debian custom ISO generator

This Bash script automates the generation and configuration of a fully unattended Debian installation ISO using customizable environment variables.

## Features

- Automatically downloads the specified Debian ISO if not already present.
- Pre-configures user accounts, passwords, time zone, keyboard layout, and disk partition sizes.
- Supports unattended installation through preseed configuration.

## Requirements

- Bash
- `wget` or `curl`
- `xorriso`, `genisoimage`, or similar ISO tools
- Internet access to download Debian ISO (if not present)

## Environment Variables

You can override the following variables when running the script to customize the installation:

| Variable        | Default Value     | Description                                |
|----------------|-------------------|--------------------------------------------|
| `DEBIAN_VERSION` | `12.10.0`         | Debian version to download and install     |
| `SIZE_G_SWAP`   | `2`               | Size of the swap partition in GB           |
| `SIZE_G_VAR`    | `5`               | Size of the `/var` partition in GB         |
| `SIZE_G_OPT`    | `5`               | Size of the `/opt` partition in GB         |
| `SIZE_G_TMP`    | `10`              | Size of the `/tmp` partition in GB         |
| `USER_NAME`     | `debian`          | Username for the created user              |
| `USER_PASS`     | `password`        | Password for the user                      |
| `ROOT_PASS`     | `password`        | Root password                               |
| `TIME_ZONE`     | `Europe/Paris`    | Time zone for the system                   |
| `KEYBOARD_LANG` | `fr`              | Keyboard layout (e.g., `fr`, `en`, etc.)   |
| `BOOT_DISK`     | `/dev/sda`        | Target boot disk (e.g., `/dev/sda`)        |

## Usage CLI

Run the script directly:

```bash
./build_iso.sh
```

## Running in Docker container

To use the Docker image, execute the following command:

```sh
docker  run \
        -v /tmp/output:/output \            # mapping for final ISO
        -v /tmp/original:/original \        # mapping for original ISO
        -e VARIABLE="MA_VAR" \              # define your parameters
        tibhome/debian-custom-iso-generator
```
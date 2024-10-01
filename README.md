# fediverse-development

- The development environment for fediverse softwares

## Requirements

- NixOS or Nix package manager - This configuration uses nix with flake as command launcher
- Join to tailscale network - The test fediverse network build on tailscale
- Can access to endpoint by HTTPS - In my case, I uses Let's Encrypt certificates

## Directory structure

- {repo}
  - bin/ - the scripts directory
  - app/
    - {appname}/ - the application code of fediverse softwares
  - data/
    - {appname}/
      - env - `env` for application
      - db/ - the datadir for database
  - {appname}.yaml - The `process-compose.ymal` for {appname}

## How to setup fediverse softwares

### GoToSocial

- In this configuration, use `sqlite3` as db, and store media files to local dir

```bash
# Checkout source code to `app/gotosocial` directory.
$ cd app
$ git clone https://github.com/superseriousbusiness/gotosocial gotosocial

# Edit `data/gotosocial/env` file.
# This repository set all gotosocial settings by environment variables.
$ nvim data/gotosocial/env

# Launch by `process-compose`
$ process-compose -e data/gotosocial/env -f gotosocial.yaml

# Setup instance users as admin
$ bin/run gotosocial gotosocial admin create --email foo@example.com --user foo --password "12345!@#$%QAZWSXEDC"
$ bin/run gotosocial gotosocial admin confirm --user foo
$ bin/run gotosocial gotosocial admin promote --user foo
```

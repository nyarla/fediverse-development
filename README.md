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

### Mastodon

#### Setup Postgres by user permissions

```bash
# Enter to development bash shell
$ nix develop

# Initialize database directory.
$ cd data/mastodon/db
$ nix shell nixpkgs#postgresql --command initdb -U $(id -u -n) .

# Edit some configurations.
# In this environment requires to change these settings:
# ---
# external_pid_file = '/run/user/1000/postgres/mastodon/pid' # for send `kill -SIGTERM` to postres instance
# port = 50029 # postgres server running on user permissions, so we should use to non-reserved port
# unix_socket_directories = '/run/user/1000/postgres/mastodon' # use user `/run` directory as socket dir
# ---
$ nvim postgresql.conf

# Do testing for database is able to running by user permissions
$ nix shell nixpkgs#postgresql --command pg_ctl -D . start

# Setup system databse
$ nix shell nixpkgs#postgresql --command createdb -h 127.0.0.1 -p 50029 $(id -u -n)
```

### Setup mastodon

```bash
# Launch postgres and redis servers
# These server is required by mastodon setup
$ process-compose -e data/mastodon/env -f mastodon.yaml up postgresql redis

# Checkout mastodon source code to `app/mastodon`
$ git clone https://github.com/mastodon/mastodon app/mastodon

# Manual install of mastodon
$ cd app/mastodon
$ bundle config deployment 'true'
$ bundle config without 'development test'
$ bundle install -j$(nproc --all --ignore 1)
$ yarn install --pure-lockfile

# Initialize mastodon configurations
$ RAILS_ENV=production bundle exec rake mastodon:setup

# Edit more configurations to .env.production
# We should add these:
# ---
# AUTHORIZED_FETCH=false
# DEFAULT_LOCAL=ja # change to your language
# RAILS_ENV=production
# RAILS_SERVE_STATIC_FILES=true
# NODE_ENV=production
# TRUSTED_PROXY_IP=127.0.0.1,100.64.0.0/10
# PORT=50020
# ALLOWED_PRIVATE_ADDRESSES=100.64.0.0/10
# ---
$ nvim .env.production

# Add user as admin
$ rails_env=production ./bin/tootctl accounts create $(id -u -n) --email "$(id -u -n)@example.com"
$ rails_env=production ./bin/tootctl accounts modify $(id -u -n) --confirm
$ rails_env=production ./bin/tootctl accounts modify $(id -u -n) --approve
$ rails_env=production ./bin/tootctl accounts modify $(id -u -n) --role Admin
```

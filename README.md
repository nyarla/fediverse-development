# fediverse-development

> My development environment for fediverse softwares

## Using environment, networking and configurations

- NixOS, Let's Encrypt by `security.acme` and caddyserver configuration
- Tailscaled and my localhost domain for development. this is `*.f.localhost.thotep.net`

I use these NixOS configurations to setup this environment:

```nix
{ pkgs, ... }: {
  security.acme = {
    acceptTerms = true;
    defaults = {
      enableDebugLogs = false;
      email = "nyarla@kalaclista.com";
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      environmentFile = "/persist/var/lib/acme/cloudflare";
    };

    certs."localhost.thotep.net" = {
      extraDomainNames = [
        "*.localhost.thotep.net"
        "*.f.localhost.thotep.net"
      ];
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts = {
      "gts.f.localhost.thotep.net" = {
        listenAddresses = [ "100.103.65.77" ];
        useACMEHost = "localhost.thotep.net";
        logFormat = ''
          output stdout
        '';
        extraConfig = ''
          reverse_proxy 127.0.0.1:50000
        '';
      };

      "masto.f.localhost.thotep.net" = {
        listenAddresses = [ "100.103.65.77" ];
        useACMEHost = "localhost.thotep.net";
        logFormat = ''
          output stdout
        '';
        extraConfig = ''
          handle /api/v1/streaming* {
            reverse_proxy 127.0.0.1:50021
          }

          handle {
            reverse_proxy 127.0.0.1:50020
          }
        '';
      };
    };
  };
}
```

## Directory structure

- {rootdir of this repo}/
  - bin/ - the helper scripts directory
  - app/
    - {appname}/ - the application code of fediverse softwares
  - data/
    - {appname}/ - the data directory for fediverse softwares
  - {appname}.yaml - The `process-compose.ymal` for {appname}

## How to setup fediverse softwares

### GoToSocial

In this configuration, use `sqlite3` as db, and store media files to local dir

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

This configuration uses postgres as database, official redis.

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

# WordPress Docker Stack

A docker-compose based local/dev environment for a WordPress site, built
around one core idea: **only your custom code should be in git** - not
WordPress core, not third-party plugins, not the media library, not the
database.

## Architecture

| Piece                          | Where it lives                                      | Tracked by git? |
|---------------------------------|-------------------------------------------------------|:---------------:|
| WordPress core (wp-admin, wp-includes, etc.) | Named Docker volume `wp_core`             | No (physically outside the repo) |
| Database                        | Named Docker volume `db_data`                          | No |
| Media Files             | Bind mount `./wp-content/uploads`                        | No (gitignored) |
| Third-party plugins              | Bind mount `./wp-content/plugins`, no name prefix         | No (gitignored) |
| **Custom, locally-developed plugins** | Bind mount `./wp-content/plugins/acme-*`             | **Yes** |
| Third-party themes               | Bind mount `./wp-content/themes`, no name prefix         | No (gitignored) |
| **Custom, locally-developed themes** | Bind mount `./wp-content/themes/acme-*`              | **Yes** |
| **Compatibility fixes for third-party plugins/themes** | `./patches/plugins/<slug>/`, `./patches/themes/<slug>/` | **Yes** (diffs only, not the plugin/theme code) |

Custom and third-party plugins live in the *same* host folder
(`wp-content/plugins/`) because that's the one directory WordPress actually
scans for plugins. What separates them is a naming convention enforced by
`wp-content/plugins/.gitignore`: folders prefixed `acme-` (rename to your own
prefix) are versioned, everything else is ignored.

Similarly, custom and third-party themes live in the *same* host folder
(`wp-content/themes/`) and have the same conventions as plugins.

This also means:

- Editing a file under `wp-content/plugins/acme-your-plugin/` or `wp-content/themes/acme-your-theme/` on your host
  machine is picked up **immediately** by the container - it's a live bind
  mount into Apache/PHP, no rebuild or restart needed.

- Third-party plugins/themes can be installed/updated from wp-admin or unpacked
  from the production export without ever touching git.

- If a third-party plugins/themes needs a compatibility fix, it's tracked as a
  small patch file under `patches/`, not by editing the plugin/theme in
  place - see [Patching third-party plugins/themes](#patching-third-party-pluginsthemes)
  below.

## Quick start

```bash
cp .env.example .env

# adjust ports/versions as needed

# Drop your production export into init-data/ (see init-data/README.md)

# optional: add compatibility patches for third-party plugins/themes to patches/
# (see patches/README.md)

make first-run  # starts the stack, imports init-data/* if present AND apply existent patches
```

Site: http://localhost:8080 (or whatever `WORDPRESS_PORT` you set).

If you don't have production data to import yet, just run `make up` - you'll
get a fresh, empty WordPress install.

## First-run data import

Requirement: load a gzipped DB dump, a gzipped `uploads/` folder, a gzipped
`plugins/` folder and a gzipped `themes/` folder on first run.

Put the following into `init-data/` (all gitignored, see `init-data/README.md` for exact naming/format):

- `database.sql.gz` - imported into the `db` container via `mysql`

- `uploads.tar.gz` - extracted into `wp-content/uploads/`

- `plugins.tar.gz` - extracted into `wp-content/plugins/` (third-party
  plugins only; your custom `acme-*` plugins are unaffected)

- `themes.tar.gz` - extracted into `wp-content/themes/` (third-party
  themes only; your custom `acme-*` themes are unaffected)

Then run:

```bash
make init  # or `make first-run` if the stack isn't up yet
```

The script is idempotent - it writes `wp-content/.initialized` after a
successful run and no-ops on subsequent calls. Force a re-import with
`make reset-init && make init`.

Immediately after extraction, `init.sh` also applies any compatibility
patches from `patches/` (see next section) and `chown`s
`wp-content/{uploads,plugins,themes}` to `www-data` so the `wordpress`
service can read and write them.

## Patching third-party plugins/themes

Full instructions for generating and applying patches are in `patches/README.md`.

## Adding a custom plugin

```bash
mkdir wp-content/plugins/acme-my-plugin

# ... add acme-my-plugin.php with a standard WP plugin header ...

git add wp-content/plugins/acme-my-plugin
```

That's it - no compose/gitignore changes needed, the `acme-*` prefix rule in
`wp-content/plugins/.gitignore` picks it up automatically. Rename the prefix
project-wide (in `.gitignore`) if you'd rather use your own company/project
name instead of `acme-`.

If you'd prefer each custom plugin to be its own independently-versioned
repo (e.g. for separate CI/release cycles), turn `acme-my-plugin/` into a
git submodule instead - the bind mount and gitignore rule work the same way
either way.

## Adding a custom theme

Just follow the same instructions of custom plugins generation but using `wp-content/themes` folder instead.

## Upgrading WordPress

Edit `.env`:

```
WORDPRESS_VERSION=6.7
```

then:

```bash
docker compose up -d --pull always wordpress
```

Because core lives in a Docker volume, the new image's core files replace
the old ones on container recreation while `wp-content/plugins`,
`wp-content/themes` and `wp-content/uploads` and the database are untouched. 
Always back up the `db` volume and test in a copy of your dev stack before 
upgrading anything with production data.

## Useful commands

```bash
make up     # start db + wordpress
make down   # stop everything
make logs   # tail logs
make shell  # bash shell inside the wordpress container
make wp CMD="plugin list"   # run any wp-cli command
make patch  # (re-)apply patches/ to third-party plugins/themes, no full re-init
```

## Notes on permissions

If you hit permission errors (e.g. after manually creating files as your host user),
you can run the following fix directly:

```bash
docker compose exec wordpress chown -R www-data:www-data /var/www/html/wp-content/uploads /var/www/html/wp-content/plugins /var/www/html/wp-content/themes
```

or, more thoroughly, re-run the init container's ownership step:

```bash
make patch   # also re-chowns/chmods as a side effect of scripts/init.sh's flow
```

On Linux hosts with SELinux enabled (Fedora/RHEL/CentOS), if permission
errors persist despite correct Unix ownership, add the `:z` flag to the
three bind mounts in `docker-compose.yml` (both `wordpress` and `wpcli`
services):

```yaml
      - ./wp-content/plugins:/var/www/html/wp-content/plugins:z
      - ./wp-content/themes:/var/www/html/wp-content/themes:z
      - ./wp-content/uploads:/var/www/html/wp-content/uploads:z
```

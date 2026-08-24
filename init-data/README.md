# init-data/

Drop your production export files here before running `make first-run` (or
`make init`). Everything in this folder is gitignored - nothing you put here
ever gets committed.

The init script (`scripts/init.sh`) auto-detects files by name pattern:

| File                    | Pattern           | What happens                                            |
|--------------------------|--------------------|----------------------------------------------------------|
| Database dump            | `*.sql.gz`         | gunzipped and imported into the `db` container           |
| Media library             | `uploads*.tar.gz`  | extracted into `wp-content/uploads/`                      |
| Third-party plugins       | `plugins*.tar.gz`  | extracted into `wp-content/plugins/` (alongside custom ones) |
| Third-party themes        | `themes*.tar.gz`   | extracted into `wp-content/themes/` (alongside custom ones)  |

Only the first matching file of each type is used.

## Creating the archives correctly

The script extracts archives directly into the target folder, so build them
so their contents sit at the top level (no wrapping parent folder):

```bash
# Database
gzip -c /path/to/production-dump.sql > init-data/database.sql.gz

# Uploads
cd /path/to/production/wp-content/uploads
tar -czf /path/to/repo/init-data/uploads.tar.gz .

# Third-party plugins (skip any folder you're going to version manually under wp-content/plugins/acme-*/ - no need to include it here)

cd /path/to/production/wp-content/plugins
tar -czf /path/to/repo/init-data/plugins.tar.gz .

# Third-party themes (skip any folder you're going to version manually under wp-content/themes/acme-*/ - no need to include it here)

cd /path/to/production/wp-content/themes
tar -czf /path/to/repo/init-data/themes.tar.gz .
```

## Re-running the import

The script writes a marker file at `wp-content/.initialized` after a
successful run and refuses to run again so you don't accidentally clobber
local changes. To force a fresh import:

```bash
make reset-init
make init
```

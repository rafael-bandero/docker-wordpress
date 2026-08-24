# Third-party plugin/theme patches

Third-party plugin and theme code is **not** tracked in git (only `acme-*/`
custom plugins/themes are — see the root `.gitignore`). When a third-party
plugin needs a compatibility fix, don't edit it in place: the fix will be
silently lost the next time someone re-runs `make first-run` on a clean
checkout, or the plugin is updated from a fresh archive.

Instead, track the fix as a small unified diff here. `scripts/apply-patches.sh`
applies everything in this folder automatically, right after plugins/themes
are extracted during init.

## Layout

```
patches/
  plugins/
    <plugin-slug>/
      001-fix-php83-deprecation.patch
      002-fix-fatal-on-init.patch
  themes/
    <theme-slug>/
      001-some-fix.patch
```

`<plugin-slug>` / `<theme-slug>` must exactly match the directory name under
`wp-content/plugins/` or `wp-content/themes/`.

## Creating a patch

1. Make a throwaway copy of the plugin/theme folder before editing, e.g.:
   ```bash
   cp -r wp-content/plugins/some-plugin /tmp/some-plugin-orig
   ```

2. Edit the live files under `wp-content/plugins/some-plugin/` until the
   compatibility issue is fixed and verified.

3. Create the destination folder, then generate the diff (rooted so it
   applies with `-p1`) — run this from the **repo root**, since the paths
   below are matched literally by the `sed` substitution:
   ```bash
   mkdir -p patches/plugins/some-plugin
   diff -ruN /tmp/some-plugin-orig wp-content/plugins/some-plugin \
     | sed 's|/tmp/some-plugin-orig|a|; s|wp-content/plugins/some-plugin|b|' \
     > patches/plugins/some-plugin/001-fix-description.patch
   ```
   (Alternatively: `git init` a throwaway copy of the *original* file(s),
   commit that as a baseline, then copy your *edited* files on top and run
   `git diff` — this gives you clean `a/`/`b/` headers for free without the
   `sed` step.)
   
4. Test it applies cleanly:
   ```bash
   make patch
   ```

## Re-applying after a plugin/theme update

If `init-data/plugins*.tar.gz` or `init-data/themes*.tar.gz` gets refreshed with
a newer version, run:

```bash
make patch
```

This re-applies every patch without a full re-init. If a patch fails to
apply (`apply-patches.sh` exits non-zero and says so), the plugin's/theme's code has
likely drifted from what the patch expects — regenerate the patch against
the new version using the steps above.

## Notes

- Patches are applied in filename order within each plugin/theme folder —
  use `001-`, `002-`, ... prefixes to make ordering explicit.
- `apply-patches.sh` is idempotent: it detects already-applied patches (via
  `patch --dry-run -R`) and skips them, so re-running `make patch` after
  `make init` is always safe.
- Keep patches small and single-purpose (one compatibility issue per file)
  so failures are easy to diagnose and patches are easy to rebase.

## Troubleshoot

Some third-party plugins (revslider is a known offender) ship PHP files with
Windows-style CRLF line endings instead of plain LF. `apply-patches.sh` runs
`patch` with `--binary`, which applies line endings *literally* rather than
guessing — so if your patch file's line endings don't match the target
file's own convention exactly, the patch will fail to apply even though the
content change itself is fine.

If you have trouble after following standard instructions, check what you're dealing with:

```bash
file wp-content/plugins/some-plugin/some-file.php
# or:
cat -A wp-content/plugins/some-plugin/some-file.php | head
# CRLF lines end in ^M$, plain LF lines end in just $
```

- **If the file is CRLF**, make sure your editor preserves CRLF on save, and
  that the throwaway copy you diff against is also CRLF (a straight `cp -r`
  preserves it; some editors/tools silently normalize to LF on save/copy —
  double-check after editing). If your `.patch` file ends up with mixed or
  fully LF endings despite the target being CRLF, force it back with
  `unix2dos patches/plugins/some-plugin/001-your-fix.patch` before testing.
- **If the file is LF** (the common case), nothing special is needed — just
  make sure your editor isn't configured to save with CRLF.

When in doubt, verify after generating the patch:

```bash
# counts should match if the whole file is consistently CRLF
cat -A patches/plugins/some-plugin/001-your-fix.patch | grep -c '\^M\$'
wc -l < patches/plugins/some-plugin/001-your-fix.patch
```
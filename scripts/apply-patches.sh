#!/bin/sh
# Applies compatibility patches to third-party plugins/themes after they've
# been extracted by init.sh. Safe to re-run (skips already-applied patches).
#
#   make patch          # apply/re-apply all patches without a full re-init
#
# Patch layout (tracked in git, plugin/theme CODE itself is NOT):
#
#   patches/
#     plugins/
#       <plugin-slug>/
#         001-fix-php83-deprecation.patch
#         002-fix-fatal-on-init.patch
#     themes/
#       <theme-slug>/
#         001-some-fix.patch
#
# Each *.patch should be a unified diff (git diff / diff -u) rooted at the
# plugin or theme's own directory (i.e. `-p1`, paths like a/foo.php b/foo.php).

set -eu

WP_PATH="/var/www/html"
PATCH_ROOT="/patches"

apply_patches_for() {
  # $1 = "plugins" or "themes"
  kind="$1"
  base_dir="$PATCH_ROOT/$kind"
  [ -d "$base_dir" ] || return 0

  for slug_dir in "$base_dir"/*/; do
    [ -d "$slug_dir" ] || continue
    slug=$(basename "$slug_dir")
    target="$WP_PATH/wp-content/$kind/$slug"

    if [ ! -d "$target" ]; then
      echo "!! [$kind] '$slug' not found at $target - skipping its patches."
      continue
    fi

    for p in "$slug_dir"*.patch; do
      [ -f "$p" ] || continue
      name=$(basename "$p")

      if (cd "$target" && patch -p1 --binary --dry-run -R < "$p" >/dev/null 2>&1); then
        echo "==> [$kind/$slug] $name already applied - skipping."
        continue
      fi

      dry_run_output=$(cd "$target" && patch -p1 --binary --dry-run < "$p" 2>&1) && dry_run_ok=1 || dry_run_ok=0

      if [ "$dry_run_ok" = "1" ]; then
        echo "==> [$kind/$slug] applying $name..."
        (cd "$target" && patch -p1 --binary < "$p")
      else
        echo "!! [$kind/$slug] $name does NOT apply cleanly. Real patch output below:"
        echo "$dry_run_output" | sed 's/^/!!     /'
        echo "!! This usually means either (a) the plugin/theme file content actually"
        echo "!! changed since the patch was made (even if the version string didn't"
        echo "!! bump), (b) the patch's line endings don't match the target file's"
        echo "!! convention (see patches/README.md), or (c) the diff was generated"
        echo "!! with paths that don't match '-p1' rooted at $target."
        exit 1
      fi
    done
  done
}

if [ ! -d "$PATCH_ROOT" ]; then
  echo "==> No $PATCH_ROOT directory mounted - nothing to patch."
  exit 0
fi

echo "==> Applying plugin/theme compatibility patches..."
apply_patches_for "plugins"
apply_patches_for "themes"
echo "==> Done."

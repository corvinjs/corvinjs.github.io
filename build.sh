#!/usr/bin/env bash
# Builds the whole site into _site/, the same way in CI and locally.
#
# The site is made of sites: home/ is mounted at /, every submodule at /<path>.
# - A site with a build.sh is built by it:  build.sh BASEURL OUTDIR
#   OUTDIR may still hold its previous output, which it is free to reuse.
#   An optional "# apt: pkg ..." line in build.sh lists the Debian packages
#   it needs; they are installed in CI only, and only when the site is built.
# - A site without one is published as-is (its git-tracked files).
#
# A site is skipped when its output was built from the committed revision and
# the working tree has no changes in it (OUTDIR/.rev records that revision).
set -euo pipefail
cd "$(dirname "$0")"

declare -A mount=([home]=/)
for dir in $(git config -f .gitmodules --get-regexp '\.path$' | cut -d' ' -f2); do
  mount[$dir]=/$dir
done

for dir in "${!mount[@]}"; do
  out="$PWD/_site${mount[$dir]%/}"
  rev=$(git rev-parse "HEAD:$dir")
  if [ "$(cat "$out/.rev" 2>/dev/null)" = "$rev" ] && git diff --quiet HEAD -- "$dir"; then
    echo "Skip $dir (built from ${rev:0:7})"
    continue
  fi
  echo "::group::Build $dir (${rev:0:7})"
  [ -n "$(ls -A "$dir")" ] || git submodule update --init --depth 1 -- "$dir"
  mkdir -p "$out"
  rm -f "$out/.rev"
  if [ -f "$dir/build.sh" ]; then
    pkgs=$(sed -n 's/^# apt: //p' "$dir/build.sh")
    if [ -n "${CI:-}" ] && [ -n "$pkgs" ]; then
      # shellcheck disable=SC2086
      sudo apt-get update -qq && sudo apt-get install -yqq --no-install-recommends $pkgs
    fi
    (cd "$dir" && bash build.sh "${mount[$dir]%/}" "$out")
  else
    # Replace the previous copy, but keep the sites mounted inside this one.
    keep=()
    for other in "${!mount[@]}"; do
      if [ "$other" != "$dir" ] && [ "$(dirname "${mount[$other]}")" = "${mount[$dir]}" ]; then
        keep+=(-not -name "$(basename "${mount[$other]}")")
      fi
    done
    find "$out" -mindepth 1 -maxdepth 1 "${keep[@]}" -exec rm -rf {} +
    git -C "$dir" ls-files -z | (cd "$dir" && xargs -0 cp --parents -t "$out")
  fi
  echo "$rev" > "$out/.rev"
  echo "::endgroup::"
done

git rev-parse --short HEAD > _site/COMMIT

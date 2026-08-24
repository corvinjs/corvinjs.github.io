#!/usr/bin/bash

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$@"
  fi
}

cd "$(dirname "$0")" || exit 1

if [ ! -f .gitmodules ]; then
  echo "No .gitmodules found" >&2
  exit 1
fi

git submodule update --init --recursive

changed=()
conflicts=()

while IFS= read -r path; do
  [ -n "$path" ] || continue
  [ -d "$path" ] || continue

  parent_commit=$(git ls-tree HEAD "$path" 2>/dev/null | awk '{print $3}')

  if ! git -C "$path" pull --rebase; then
    conflicts+=("$path")
    continue
  fi

  if git -C "$path" rev-parse -q --verify REBASE_HEAD >/dev/null 2>&1 || \
     git -C "$path" diff --name-only --diff-filter=U | grep -q .; then
    conflicts+=("$path")
    continue
  fi

  submodule_commit=$(git -C "$path" rev-parse HEAD)
  if [ "$parent_commit" != "$submodule_commit" ]; then
    changed+=("$path")
  fi
done < <(git config --file .gitmodules --get-regexp 'submodule\..*\.path' | awk '{print $2}')

if [ ${#conflicts[@]} -gt 0 ]; then
  echo "Merge conflicts in: ${conflicts[*]}" >&2
  notify "update-submodules" "Merge conflicts: ${conflicts[*]}"
  exit 1
fi

if [ ${#changed[@]} -eq 0 ]; then
  echo "No submodule changes"
  notify "update-submodules" "No submodule changes"
  exit 0
fi

for path in "${changed[@]}"; do
  git add "$path"
done

msg="update"
for path in "${changed[@]}"; do
  msg+=" ${path}/"
done

git commit -m "$msg"

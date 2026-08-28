#!/bin/sh
# Run this here.
# Installs a post-commit hook in each submodule that auto-commits
# the updated submodule ref in the parent and pushes.

set -e

PARENT_DIR="$(pwd)"

git submodule foreach '
  GIT_DIR="$(git rev-parse --git-dir)"
  HOOKS_DIR="$GIT_DIR/hooks"
  HOOK="$HOOKS_DIR/post-commit"

  mkdir -p "$HOOKS_DIR"
  cat > "$HOOK" << HOOKEOF
#!/bin/sh
SUBMODULE_NAME="'"$name"'"
SUBMODULE_MSG="\$(git log -1 --pretty=%s)"
git --git-dir="'"$PARENT_DIR"'/.git" --work-tree="'"$PARENT_DIR"'" add "'"$PARENT_DIR"'/$SUBMODULE_NAME"
git --git-dir="'"$PARENT_DIR"'/.git" --work-tree="'"$PARENT_DIR"'" diff --cached --quiet || \
  git --git-dir="'"$PARENT_DIR"'/.git" --work-tree="'"$PARENT_DIR"'" commit -m "\$SUBMODULE_NAME: \$SUBMODULE_MSG"
git --git-dir="'"$PARENT_DIR"'/.git" --work-tree="'"$PARENT_DIR"'" push
HOOKEOF
  chmod +x "$HOOK"
  echo "Installed hook in submodule: $name"
'

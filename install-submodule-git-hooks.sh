#!/bin/sh
# Run this from the root of the parent repo.
# Installs a post-commit hook in each submodule that auto-commits
# the updated submodule ref in the parent and pushes.

set -e

PARENT_DIR="$(pwd)"

git submodule foreach '
  # .git in a submodule is a file pointing to the real git dir;
  # resolve the actual hooks directory via the worktree config.
  GIT_DIR="$(git rev-parse --git-dir)"
  HOOKS_DIR="$GIT_DIR/hooks"
  HOOK="$HOOKS_DIR/post-commit"
  SUBMODULE_NAME="$name"

  mkdir -p "$HOOKS_DIR"
  cat > "$HOOK" << HOOKEOF
#!/bin/sh
cd '"$PARENT_DIR"'
git add "$SUBMODULE_NAME"
# Only commit if there is actually a staged change
git diff --cached --quiet || git commit -m "update $SUBMODULE_NAME"
git push
HOOKEOF
  chmod +x "$HOOK"
  echo "Installed hook in submodule: $name"
'
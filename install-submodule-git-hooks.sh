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

# So gh actions can find the new commit
(git push --quiet && echo Pushed changes to origin.) &

# Unset Git environment variables set by the host commit process
unset \$(git rev-parse --local-env-vars)

SUBMODULE_NAME="$sm_path"
SUBMODULE_MSG="\$(git log -1 --pretty=%s)"

cd "'"$PARENT_DIR"'"
git add "$sm_path"
if git diff --cached --quiet; then
  echo "Warning: Parent did not find changes."
else
  git commit -m "\$SUBMODULE_NAME: \$SUBMODULE_MSG" && echo "Included changes in parent."
fi
git push --quiet && echo Pushed parent to origin.
HOOKEOF
  chmod +x "$HOOK"
  echo "Installed hook in submodule: $sm_path"
'

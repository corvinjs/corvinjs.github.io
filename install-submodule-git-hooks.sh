#!/bin/sh
# Install a post-commit hook in each submodule
# so the parent directly includes changes and pushes both.

set -e

PARENT_DIR="$(pwd)"

git submodule foreach '
  HOOKS_DIR="$(git rev-parse --git-path hooks)"

  mkdir -p "$HOOKS_DIR"
  cat > "$HOOKS_DIR/post-commit" << HOOKEOF
#!/bin/sh

SUBMODULE_COMMIT_MSG="\$(git log -1 --pretty=%s)"

(git push --quiet && echo "Pushed $sm_path to origin.") &

# Unset Git environment variables that force git to target the submodule
unset \$(git rev-parse --local-env-vars)
cd "'"$PARENT_DIR"'"

git add "$sm_path"
if git diff --cached --quiet -- "$sm_path"; then
  echo "Warning: Parent did not find changes for $sm_path."
else
  git commit --quiet -m "$sm_path: \$SUBMODULE_COMMIT_MSG" -- "$sm_path"
  (git push --quiet && echo "Pushed parent to origin.") &
fi

wait
HOOKEOF
  chmod +x "$HOOKS_DIR/post-commit"
  echo "Installed hook in submodule: $sm_path"
'

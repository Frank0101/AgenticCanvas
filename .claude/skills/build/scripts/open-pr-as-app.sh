#!/usr/bin/env bash
# Commits the current working tree changes on a new branch, pushes it, and opens
# a pull request — all authenticated as the repo's GitHub App bot identity
# (see .claude/skills/build/app-config.env), not the local user's own git/gh identity.
#
# Usage:
#   open-pr-as-app.sh --title "..." --body-file /path/to/body.md --commit-message "..." [--branch name]
set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

# shellcheck disable=SC1091
source "$REPO_ROOT/.claude/skills/build/app-config.env"

PRIVATE_KEY="$REPO_ROOT/$GH_APP_PRIVATE_KEY_PATH"
BOT_NAME="${GH_APP_SLUG}[bot]"
BOT_EMAIL="${GH_APP_ID}+${GH_APP_SLUG}[bot]@users.noreply.github.com"

TITLE=""
BODY_FILE=""
COMMIT_MESSAGE=""
BRANCH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title) TITLE="$2"; shift 2 ;;
    --body-file) BODY_FILE="$2"; shift 2 ;;
    --commit-message) COMMIT_MESSAGE="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ -n "$TITLE" ]] || { echo "--title is required" >&2; exit 1; }
[[ -n "$BODY_FILE" && -f "$BODY_FILE" ]] || { echo "--body-file must point to an existing file" >&2; exit 1; }
[[ -n "$COMMIT_MESSAGE" ]] || { echo "--commit-message is required" >&2; exit 1; }
[[ -f "$PRIVATE_KEY" ]] || { echo "Private key not found at $PRIVATE_KEY" >&2; exit 1; }

if [[ -z "$(git status --porcelain)" ]]; then
  echo "Nothing to commit — working tree is clean." >&2
  exit 1
fi

if [[ -z "$BRANCH" ]]; then
  BRANCH="claude/build-$(date +%Y%m%d-%H%M%S)"
fi

BASE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
HAD_LOCAL_NAME=$(git config --local --get user.name || true)
HAD_LOCAL_EMAIL=$(git config --local --get user.email || true)

cleanup() {
  git checkout "$BASE_BRANCH" >/dev/null 2>&1 || true
  if [[ -n "$HAD_LOCAL_NAME" ]]; then
    git config --local user.name "$HAD_LOCAL_NAME"
  else
    git config --local --unset user.name 2>/dev/null || true
  fi
  if [[ -n "$HAD_LOCAL_EMAIL" ]]; then
    git config --local user.email "$HAD_LOCAL_EMAIL"
  else
    git config --local --unset user.email 2>/dev/null || true
  fi
  unset TOKEN 2>/dev/null || true
}
trap cleanup EXIT

# --- Mint a short-lived installation access token ---
b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

NOW=$(date +%s)
JWT_HEADER=$(printf '{"alg":"RS256","typ":"JWT"}' | b64url)
JWT_PAYLOAD=$(printf '{"iat":%d,"exp":%d,"iss":%s}' "$((NOW - 60))" "$((NOW + 300))" "$GH_APP_ID" | b64url)
JWT_UNSIGNED="$JWT_HEADER.$JWT_PAYLOAD"
JWT_SIG=$(printf '%s' "$JWT_UNSIGNED" | openssl dgst -sha256 -sign "$PRIVATE_KEY" | b64url)
APP_JWT="$JWT_UNSIGNED.$JWT_SIG"

TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $APP_JWT" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/app/installations/${GH_APP_INSTALLATION_ID}/access_tokens" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])')

[[ -n "$TOKEN" && "$TOKEN" != "None" ]] || { echo "Failed to mint installation token" >&2; exit 1; }

# --- Commit as the bot ---
git checkout -b "$BRANCH"
git config --local user.name "$BOT_NAME"
git config --local user.email "$BOT_EMAIL"
git add -A
git commit -q -m "$COMMIT_MESSAGE"

# --- Push using the installation token (never embedded in the remote URL) ---
BASIC=$(printf 'x-access-token:%s' "$TOKEN" | openssl base64 -A)
git -c http.extraHeader="Authorization: Basic $BASIC" push -q origin "$BRANCH"

# --- Open the PR as the bot ---
PR_URL=$(GH_TOKEN="$TOKEN" gh pr create \
  --base "$BASE_BRANCH" \
  --head "$BRANCH" \
  --title "$TITLE" \
  --body-file "$BODY_FILE")

echo "$PR_URL"

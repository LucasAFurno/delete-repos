#!/usr/bin/env bash
set -euo pipefail

# delete_repos.sh — delete GitLab projects via the API
# WARNING: This operation is irreversible! Only specify repositories you truly intend to delete.

API_URL="https://gitlab.com/api/v4/projects"
AUTO_CONFIRM=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -h            Show this help message and exit
  -g GROUP      GitLab group path (e.g. my-group)
  -r REPOS      Comma-separated list of project names to delete
  -y            Auto-confirm deletions (skip interactive prompts)

Description:
  Deletes one or more GitLab projects via the GitLab API.
  Require: an environment variable GITLAB_TOKEN with "api" scope.
EOF
}

# Parse command-line options
while getopts ":hg:r:y" opt; do
  case $opt in
    h) usage; exit 0 ;;
    g) GROUP_RAW="$OPTARG" ;;
    r) REPOS_INPUT="$OPTARG" ;;
    y) AUTO_CONFIRM=true ;;
    *) usage; exit 1 ;;
  esac
done
shift $((OPTIND -1))

# 1) Ensure token is set
if [[ -z "${GITLAB_TOKEN:-}" ]]; then
  echo "❌ ERROR: Please export your GitLab token first:"
  echo "   export GITLAB_TOKEN=glpat-…"
  exit 1
fi

# 2) Prompt for group if not provided
if [[ -z "${GROUP_RAW:-}" ]]; then
  read -rp "Enter GitLab group path (e.g. my-group): " GROUP_RAW
fi

# URL-encode group path
GROUP_ENCODED=$(python3 - <<EOF
import urllib.parse,sys
print(urllib.parse.quote(sys.argv[1], safe=""))
EOF
  "$GROUP_RAW")

# 3) Prompt for repos if not provided
if [[ -z "${REPOS_INPUT:-}" ]]; then
  read -rp "Enter repository names to DELETE (comma-separated): " REPOS_INPUT
fi

IFS=',' read -r -a REPOS <<< "$REPOS_INPUT"

# 4) Loop through each repo
for repo in "${REPOS[@]}"; do
  PROJECT_PATH="$GROUP_RAW/$repo"
  PROJECT_ENCODED=$(python3 - <<EOF
import urllib.parse,sys
print(urllib.parse.quote(sys.argv[1], safe=""))
EOF
  "$PROJECT_PATH")

  # Fetch project ID
  ID=$(curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
         "$API_URL/$PROJECT_ENCODED" | jq -r '.id // empty')

  if [[ -z "$ID" ]]; then
    echo "❌ Not found: $PROJECT_PATH"
    continue
  fi

  # 5) Confirm deletion
  if [[ "$AUTO_CONFIRM" != true ]]; then
    read -rp "Are you sure you want to DELETE '$repo' (ID $ID)? [y/N]: " reply
    [[ "$reply" =~ ^[Yy]$ ]] || { echo "⏭ Skipping $repo"; continue; }
  fi

  # 6) Delete project
  if curl -s -f -X DELETE \
       -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
       "$API_URL/$ID"; then
    echo "✅ Deleted: $repo (ID $ID)"
  else
    echo "❌ Failed to delete: $repo (ID $ID)"
  fi
done

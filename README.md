GitLab Project Deleter

A simple, robust Bash script that deletes one or more GitLab projects via the GitLab API.
Features:

Authentication via GITLAB_TOKEN environment variable (must have api scope)

Group & project selection: specify a group path and a comma-separated list of project names

Interactive prompts for each deletion, with an auto-confirm flag (-y)

Help menu (-h) and clear usage instructions

Error handling with set -euo pipefail

Minimal dependencies: bash, curl, jq, and python3

⚠️ Use with caution: deletions are permanent and cannot be undone.

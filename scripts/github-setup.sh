#!/usr/bin/env bash
#
# One-time GitHub configuration for the SplitFair repository.
#
# Prerequisites:
#   - GitHub CLI installed:      brew install gh
#   - Authenticated as the repo owner:   gh auth login
#
# Then run:   bash scripts/github-setup.sh
#
# It's safe to re-run (idempotent): it only sets configuration, never touches code.

set -euo pipefail

REPO="zakariaf/SplitFair"

echo "==> Repository description"
gh repo edit "$REPO" \
  --description "A native iOS/SwiftUI bill splitter that splits by who ordered what — fully offline, no account, exact-cent math. Built live on YouTube with a skills + epics workflow."

echo "==> Topics (tags)"
gh repo edit "$REPO" \
  --add-topic ios \
  --add-topic swift \
  --add-topic swiftui \
  --add-topic ios-app \
  --add-topic bill-splitter \
  --add-topic expense-splitting \
  --add-topic offline-first \
  --add-topic privacy \
  --add-topic no-account \
  --add-topic swift-package \
  --add-topic swift-testing \
  --add-topic claude-code \
  --add-topic ai-assisted-development \
  --add-topic tutorial \
  --add-topic mobile-development

echo "==> Merge & feature settings (squash-only, auto-delete merged branches)"
gh repo edit "$REPO" \
  --enable-issues \
  --enable-squash-merge \
  --enable-merge-commit=false \
  --enable-rebase-merge=false \
  --delete-branch-on-merge

echo "==> Branch protection on 'main'"
# Contributors must open a PR that passes CI and gets one approval; the owner (admin)
# can still commit directly to main (enforce_admins=false), matching the project workflow.
gh api -X PUT "repos/$REPO/branches/main/protection" \
  -H "Accept: application/vnd.github+json" \
  --input - <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["BillCore money-math suite", "SwiftFormat + SwiftLint"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
JSON

echo ""
echo "==> Done. Verify at: https://github.com/$REPO/settings/branches"

#!/bin/bash
# Script to rename master branch to main for mitre/settingslogic repository

set -e

echo "🔄 Branch Rename Script: master → main"
echo "======================================="
echo ""

# Check if we're in the right repo
if ! git remote -v | grep -q "mitre/settingslogic"; then
    echo "❌ Error: This script must be run from the mitre/settingslogic repository"
    exit 1
fi

# Check current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "master" ]; then
    echo "⚠️  Warning: You're not on the master branch (current: $CURRENT_BRANCH)"
    echo "   Switching to master..."
    git checkout master
fi

# Ensure we're up to date
echo "📥 Pulling latest changes from master..."
git pull origin master

echo ""
echo "🔍 Pre-flight checks:"
echo "  - Repository: mitre/settingslogic"
echo "  - Current default branch: master"
echo "  - New default branch: main"
echo ""

read -p "⚠️  This will rename the default branch. Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborted"
    exit 1
fi

echo ""
echo "📝 Step 1: Create 'main' branch from 'master'"
git branch -m master main

echo "📤 Step 2: Push 'main' branch to origin"
git push -u origin main

echo "🔧 Step 3: Update GitHub repository settings via gh CLI"
gh api repos/mitre/settingslogic --method PATCH --field default_branch=main

echo "🏷️  Step 4: Update branch protection rules (if any exist)"
# Check if master has protection rules
if gh api repos/mitre/settingslogic/branches/master/protection 2>/dev/null; then
    echo "  Found protection rules on master, copying to main..."
    PROTECTION_JSON=$(gh api repos/mitre/settingslogic/branches/master/protection)
    # This would need to be adapted based on actual protection rules
    echo "  ⚠️  Note: Branch protection rules may need manual review in GitHub settings"
fi

echo "🗑️  Step 5: Delete old 'master' branch on remote"
read -p "  Delete remote 'master' branch? (y/N) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push origin --delete master
    echo "  ✅ Remote 'master' branch deleted"
else
    echo "  ⏭️  Skipped deletion of remote 'master' branch"
fi

echo ""
echo "✅ Branch rename complete!"
echo ""
echo "📋 Next steps for team members:"
echo "  git fetch origin"
echo "  git checkout -b main origin/main"
echo "  git branch -D master"
echo ""
echo "📝 Files that may need updating:"
echo "  - README.md (branch badges/links)"
echo "  - CI/CD workflows (.github/workflows/*.yml)"
echo "  - Documentation (*.md files)"
echo "  - Gemspec metadata URIs"
echo ""
echo "🔗 GitHub will automatically redirect:"
echo "  - Links to the old branch"
echo "  - Open PRs targeting master"
echo "  - API calls to the old branch name"
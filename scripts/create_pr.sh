#!/bin/bash

# Helper function to get current and base branch information
get_branch_info() {
    current_branch=$(git branch --show-current)
    
    # Extract version from current branch (assuming pattern like aminescu/dev_v25_3/...)
    base_branch=$(echo "$current_branch" | grep -o 'dev_v[0-9]\+_[0-9]\+' | head -1)

    # If we couldn't extract from branch name, default to dev_v25_3
    if [ -z "$base_branch" ]; then
        echo "Warning: Could not determine base branch from current branch name." >&2
        return 1
    fi
}

rebase_latest() {
    # Get branch information
    get_branch_info || return 1
    
    local origin_base="origin/$base_branch"

    echo "Checking if local $base_branch is up to date with $origin_base..."
    git fetch origin "$base_branch"

    local local_commit=$(git rev-parse "$base_branch" 2>/dev/null)
    local origin_commit=$(git rev-parse "$origin_base" 2>/dev/null)
    
    if [ "$local_commit" != "$origin_commit" ]; then
        echo "Local $base_branch is behind $origin_base. Updating..."
        git checkout "$base_branch"
        git pull origin "$base_branch"
        git checkout "$current_branch"
    fi
    echo "Local $base_branch is up to date with $origin_base ✓"
    
    # Rebase current branch onto the updated base branch
    echo "Rebasing $current_branch onto $base_branch..."
    git rebase "$base_branch"
    
    if [ $? -ne 0 ]; then
        echo "Rebase failed. Please resolve conflicts and try again."
        return 1
    fi

    if [ "$current_branch" == "$base_branch" ]; then
        echo "Current branch is the same as base branch. Skipping push."
        return 0
    fi
    echo "Push rebased branch to origin/$current_branch..."
    git push --force-with-lease origin "$current_branch"
}

create_pr() {
    # Check if title is provided
    if [ -z "$1" ]; then
        echo "Error: Please provide a PR title"
        echo "Usage: create_pr \"Your PR Title\""
        return 1
    fi
    
    local pr_title="$1"
    
    echo "Starting PR creation process..."
    echo "Step 1: Rebasing branch to latest..."
    
    # First, rebase the current branch
    rebase_latest
    if [ $? -ne 0 ]; then
        echo "Rebase failed. Cannot create PR."
        return 1
    fi
    
    echo ""
    echo "Step 2: Creating pull request..."
    
    # Get branch information (rebase_latest already called get_branch_info, but let's be explicit)
    get_branch_info || return 1
    
    # Show confirmation
    echo ""
    echo "======= PR CREATION CONFIRMATION ======="
    echo "Title:        $pr_title"
    echo "Base:         $base_branch"
    echo "Head:         $current_branch"
    echo "========================================"
    echo ""

    gh pr create \
        --title "$pr_title" \
        --assignee @me \
        --reviewer mburlacu-dn,amihu-dn,bistoc-dn,colaru-dn,anstancu \
        --base "$base_branch" \
        --head "$current_branch"
        
    if [ $? -eq 0 ]; then
        echo "PR created successfully! 🎉"
    else
        echo "Failed to create PR"
        return 1
    fi
}

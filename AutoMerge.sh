#!/bin/bash

LOG_FILE="automerge.log"

# Function to log messages (both terminal & file)
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}

# Function to display usage
usage() {
    log "Usage:"
    log "  $0 -from <source_branch> -to <target_branch>         # Merge in current repo"
    log "  $0 -a -from <source_branch> -to <target_branch>     # Merge in all repos in current directory"
    exit 1
}

# Function to check if a branch exists locally
branch_exists_locally() {
    git show-ref --verify --quiet refs/heads/"$1"
}

# Function to check if a branch exists remotely
branch_exists_remotely() {
    git ls-remote --exit-code --heads origin "$1" > /dev/null
}

# Function to ensure a branch exists locally (fetch if needed)
ensure_branch_exists() {
    local branch="$1"
    if ! branch_exists_locally "$branch"; then
        if branch_exists_remotely "$branch"; then
            log "Fetching remote branch '$branch'..."
            git fetch origin "$branch":"$branch" || { log "Error: Failed to fetch branch '$branch'"; return 1; }
        else
            log "Error: Branch '$branch' does not exist locally or remotely!"
            return 1
        fi
    fi
    return 0
}

# Function to merge branches in a given repository
merge_branch() {
    local repo_path="$1"
    local from_branch="$2"
    local to_branch="$3"

    log "Processing repository: $repo_path"
    cd "$repo_path" || { log "Error: Failed to access $repo_path"; return; }

    # Check if it's a Git repository
    if [ ! -d ".git" ]; then
        log "Skipping: $repo_path is not a Git repository"
        cd - > /dev/null
        return
    fi

    # Fetch latest changes
    git fetch origin || { log "Error: Failed to fetch origin in $repo_path"; cd - > /dev/null; return; }

    # Ensure source and target branches exist
    ensure_branch_exists "$from_branch" || { cd - > /dev/null; return; }
    ensure_branch_exists "$to_branch" || { cd - > /dev/null; return; }

    # Switch to target branch
    git checkout "$to_branch" || { log "Error: Failed to checkout branch '$to_branch'"; cd - > /dev/null; return; }
    git pull origin "$to_branch" || { log "Error: Failed to pull latest changes for '$to_branch'"; cd - > /dev/null; return; }

    # Merge branches
    if git merge "$from_branch" --no-ff -m "Auto-merged $from_branch into $to_branch"; then
        log "Successfully merged '$from_branch' into '$to_branch'"
    else
        log "Error: Merge conflict or failure in $repo_path"
        cd - > /dev/null
        return
    fi

    # Push changes
    if git push origin "$to_branch"; then
        log "Successfully pushed '$to_branch' to origin"
    else
        log "Error: Failed to push '$to_branch' in $repo_path"
    fi

    cd - > /dev/null  # Return to the previous directory
}

# Parse command-line arguments
apply_all=false
from_branch=""
to_branch=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -a) apply_all=true ;;
        -from) from_branch="$2"; shift ;;
        -to) to_branch="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

# Ensure required arguments are provided
if [[ -z "$from_branch" || -z "$to_branch" ]]; then
    usage
fi

log "Starting automerge process..."
log "From: $from_branch | To: $to_branch | Apply to all: $apply_all"

if [[ "$apply_all" = true ]]; then
    # Detect all Git repositories in the current directory
    for repo in */; do
        if [ -d "$repo/.git" ]; then
            merge_branch "$repo" "$from_branch" "$to_branch"
        fi
    done
else
    # Run in the current repository
    merge_branch "$(pwd)" "$from_branch" "$to_branch"
fi

log "Automerge process completed!"

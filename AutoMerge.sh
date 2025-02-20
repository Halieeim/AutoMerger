#!/bin/bash

LOG_FILE="automerge.log"

# Function to log messages (both terminal & file)
log() {
    echo -e "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}

# Function to log errors (Red in terminal)
log_error() {
    echo -e "\e[31m$(date +"%Y-%m-%d %H:%M:%S") - ERROR: $1\e[0m" | tee -a "$LOG_FILE" >&2
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
            if ! git fetch origin "$branch":"$branch" 2>&1 | tee -a "$LOG_FILE"; then
                log_error "Failed to fetch branch '$branch'"
                return 1
            fi
        else
            log_error "Branch '$branch' does not exist locally or remotely!"
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
    cd "$repo_path" || { log_error "Failed to access $repo_path"; return; }

    # Check if it's a Git repository
    if [ ! -d ".git" ]; then
        log_error "Skipping: $repo_path is not a Git repository"
        cd - > /dev/null
        return
    fi

    # Fetch latest changes
    if ! git fetch origin 2>&1 | tee -a "$LOG_FILE"; then
        log_error "Failed to fetch origin in $repo_path"
        cd - > /dev/null
        return
    fi

    # Ensure source and target branches exist remotely
    ensure_branch_exists "$from_branch" || { cd - > /dev/null; return; }
    ensure_branch_exists "$to_branch" || { cd - > /dev/null; return; }

    # Switch to target branch
    if ! git checkout "$to_branch" 2>&1 | tee -a "$LOG_FILE"; then
        log_error "Failed to checkout branch '$to_branch'"
        cd - > /dev/null
        return
    fi

    # Pull latest changes
    if ! git pull origin "$to_branch" 2>&1 | tee -a "$LOG_FILE"; then
        log_error "Failed to pull latest changes for '$to_branch'"
        cd - > /dev/null
        return
    fi

    # Merge from remote branch explicitly
    merge_output=$(git merge "origin/$from_branch" --no-ff -m "Auto-merged origin/$from_branch into $to_branch" 2>&1 | tee -a "$LOG_FILE")
    
    if echo "$merge_output" | grep -q "Already up to date"; then
        log "No new changes to merge. Proceeding with push."
    elif echo "$merge_output" | grep -q "CONFLICT"; then
        log_error "Merge conflict detected in $repo_path. Manual resolution required."
        cd - > /dev/null
        return
    elif [ $? -ne 0 ]; then
        log_error "Merge failed in $repo_path. See log file for details."
        cd - > /dev/null
        return
    else
        log "Successfully merged 'origin/$from_branch' into '$to_branch'"
    fi

    # Push changes
    if ! git push origin "$to_branch" 2>&1 | tee -a "$LOG_FILE"; then
        log_error "Failed to push '$to_branch' in $repo_path"
        cd - > /dev/null
        return
    fi

    log "Successfully pushed '$to_branch' to origin"
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

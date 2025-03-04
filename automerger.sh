#!/bin/bash

source mylogger.sh
source filehandler.sh

# Function to check if a branch exists locally
branch_exists_locally() {
    git show-ref --verify --quiet refs/heads/"$1"
}

# Function to check if a branch exists remotely
branch_exists_remotely() {
    git ls-remote --exit-code --heads origin "$1" > /dev/null
}

# Function to check if a directory is in the exclusion list
is_excluded() {
    local dir_name="$1"
    for excluded in "${exclude_dirs[@]}"; do
        if [[ "$dir_name" == "$excluded" ]]; then
            return 0  # Yes, this directory is excluded
        fi
    done
    return 1  # No, this directory is not excluded
}

# Function to ensure a branch exists locally (fetch if needed)
ensure_branch_exists() {
    local branch="$1"
    if ! branch_exists_locally "$branch"; then
        if branch_exists_remotely "$branch"; then
            log "Fetching remote branch '$branch'..."
            if ! git fetch origin "$branch":"$branch" 2>&1 ; then
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

# Function to check if there are uncommitted changes
needs_stash() {
    if [[ -n $(git status --porcelain | grep -Ev '^\?\? ') ]]; then
        return 0  # Yes, changes need to be stashed
    fi
    return 1  # No, working directory is clean
}

# Function to merge branches in a given repository
merge_branch() {
    local repo_path="$1"
    local from_branch="$2"
    local to_branch="$3"
    local original_branch
    local stash_applied=false

    log "Processing repository: $repo_path"
    cd "$repo_path" || { log_error "Failed to access $repo_path"; return; }

    # Check if it's a Git repository
    if [ ! -d ".git" ]; then
        log_error "Skipping: $repo_path is not a Git repository"
        cd - > /dev/null
        return
    fi

    # Ensure source and target branches exist remotely
    ensure_branch_exists "$from_branch" || { cd - > /dev/null; return; }
    ensure_branch_exists "$to_branch" || { cd - > /dev/null; return; }

    # Store the current branch
    original_branch=$(git rev-parse --abbrev-ref HEAD)

    # Stash changes if necessary
    if needs_stash; then
        log "Stashing uncommitted changes in '$original_branch'"
        git stash push -m "Auto-stash before merge" 2>&1
        stash_applied=true
    fi

    # Fetch latest changes
    if ! git fetch origin 2>&1; then
        log_error "Failed to fetch origin in $repo_path"
        cd - > /dev/null
        return
    fi

    # Checkout target branch
    if ! git checkout "$to_branch" 2>&1; then
        log_error "Failed to checkout branch '$to_branch'"
        cd - > /dev/null
        return
    fi

    # Pull latest changes
    if ! git pull origin "$to_branch" 2>&1; then
        log_error "Failed to pull latest changes for '$to_branch'"
        cd - > /dev/null
        return
    fi

    # Merge from remote branch explicitly
    merge_output=$(git merge --stat --verbose "origin/$from_branch" 2>&1)
    merge_status=${PIPESTATUS[0]}
    
    if echo "$merge_output" | grep -q "Already up to date"; then
        log "No new changes to merge. Proceeding with push."
    elif echo "$merge_output" | grep -q "CONFLICT"; then
        log_error "Merge conflict detected in $repo_path. Manual resolution required."
        cd - > /dev/null
        return
    elif [ $merge_status -ne 0 ]; then
        log_error "Merge failed in $repo_path."
        cd - > /dev/null
        return
    else
        log "$merge_output";
        log_success "Successfully merged 'origin/$from_branch' into '$to_branch'"
    fi

    # Push changes
    if ! git push origin "$to_branch" 2>&1; then
        log_error "Failed to push '$to_branch' in $repo_path"
        cd - > /dev/null
        return
    fi

    log_success "Successfully pushed '$to_branch' to origin"

    # Switch back to original branch
    git checkout "$original_branch" 2>&1 || log_error "Failed to switch back to '$original_branch'"

    # Pop the stash if it was applied
    if $stash_applied; then
        log "Restoring stashed changes in '$original_branch'"
        git stash pop 2>&1 || log_error "Failed to apply stashed changes"
    fi

    cd - > /dev/null  # Return to the previous directory
}

#Diplays the banner
displayBanner

# Parse command-line arguments
apply_all=false
from_branch=""
to_branch=""
exclude_dirs=()
file=""
isFileProvided=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -a) apply_all=true ;;
        -from) from_branch="$2"; shift ;;
        -to) to_branch="$2"; shift ;;
        -ex) IFS=',' read -r -a exclude_dirs <<< "$2"; shift ;;
        -f) isFileProvided=true && file="$2" && extract_branches_from_file "$2"; shift ;;
        -h|--help) usage ;;
        *) log "Invalid argument: $1\n"; usage;;
    esac
    shift
done

if [[ "$isFileProvided" == "true" && ( "$apply_all" == "true" || -n "$from_branch" || -n "$to_branch" ) ]]; then
    usage
fi

# Ensure required arguments are provided
if [[ -z "$file" ]] && ([[ -z "$from_branch" ]] || [[ -z "$to_branch" ]]); then
    usage
elif [[ -n "$file" ]] && ([[ -n "$from_branch" ]] || [[ -n "$to_branch" ]]); then
    usage
fi

log "Starting automerge process..."
log "From: $from_branch | To: $to_branch | Apply to all: $apply_all | Reading From File: $isFileProvided | Excluded: ${exclude_dirs[*]}"

if [[ "$apply_all" == "true" ]]; then
    # Detect all Git repositories in the current directory
    for repo in */; do
        repoName=$(basename "$repo")
        if is_excluded "$repoName"; then
            log "Skipping excluded directory: $repoName"
            continue
        fi
        if [ -d "$repo/.git" ]; then
            merge_branch "$repo" "$from_branch" "$to_branch"
        else
            log "Skipping non-Git directory: $repoName"
        fi
    done
elif [[ "$isFileProvided" == "true" ]]; then
    for i in "${!repos_from_file[@]}"; do
        repoPath=${repos_from_file[$i]}
        repoName=$(basename "$repoPath")
        if is_excluded "$repoName"; then
            log "Skipping excluded directory: $repoName"
            continue
        fi

        from_branch=$(echo "${source_branches_from_file[$i]}" | xargs)
        to_branch=$(echo "${target_branches_from_file[$i]}" | xargs)
        
        if [ -d "$repoPath/.git" ]; then
            merge_branch "$repoPath" "$from_branch" "$to_branch"
        else
            log "Skipping non-Git directory: $repoName"
        fi
    done
else
    # Run in the current repository
    merge_branch "$(pwd)" "$from_branch" "$to_branch"
fi

log "Automerge process completed!"

#!/bin/bash

source mylogger.sh

repos_from_file=()
source_branches_from_file=()
target_branches_from_file=()

# Read the branches.csv file
extract_branches_from_file() {
    if [[ -z "$1" ]]; then
        log_error "No file provided to read branches from!"
        usage
    fi
    while IFS=, read -r repo from_branch to_branch; do
        repos_from_file+=("$repo")
        source_branches_from_file+=("$from_branch")
        target_branches_from_file+=("$to_branch")
    done < <(tail -n +2 $1)
}
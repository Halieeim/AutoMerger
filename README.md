## Purpose
> This script will help you automate the process of merging branches in one repo or in several repos in one shot if and only if all repos have the same branches names.

## Usage
> To merge two branches on the same repo in the current directory:
> 
> ```automerge.sh -from <source_branch> -to <target_branch>```
>
> To merge two branches on all repositories in the current directory:
>
> ```automerge.sh -a -from <source_branch> -to <target_branch>```
>
> To merge two branches on all repositories in the current directory and exclude some directories:
>
> ```automerge.sh -a -from <source_branch> -to <target_branch> -ex dir1,dir2```
>
> ### ==> Note: write the branch name without 'origin/'. 

## What does this script specificlly do?
> - Excluding undesired directories if [-a] option is applied
>
> - Filter Directories that do not have ".git" directory "Not a Repository"
>
> - If the current branch has uncommited changes, the script will stash these changes before checking out and after the merge process is completed, it checks out back to that branch and pop the stashed changes
> 
> - Validating branches locally & remotely
>
> - Fetching origin & pull updates before merging
>
> - Merging the remote branch of the source branch to the local branch of the target branch, and checking the merge status
>
> - Then, push the merged changes
>
> - Logs for each step for better debugging

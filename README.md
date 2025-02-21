## Purpose
> This script automates the process of merging branches in a single repository or across multiple repositories in one go, provided that all repositories have the same branch names.

## Usage
> To merge two branches on the same repo in the current directory:
> 
> ```automerger.sh -from <source_branch> -to <target_branch>```
>
> To merge two branches on all repositories in the current directory:
>
> ```automerger.sh -a -from <source_branch> -to <target_branch>```
>
> To merge two branches on all repositories in the current directory and exclude some directories:
>
> ```automerger.sh -a -from <source_branch> -to <target_branch> -ex dir1,dir2```
>
> #### ==> Note: write the branch name without 'origin/'.
>
> ## In Windows
>   
>> - Add the FOLDER path of the script in the environment variables in ```path```
>>
>> - Open Git Bash terminal so you can execute it, and run any of the above commands

## What does this script specifically do?
> - Excludes undesired directories if [-a] option is applied
>
> - Filters Directories that do not have ".git" directory "Not a Repository"
>
> - If the current branch has uncommited changes, the script will stash these changes before checking out and after the merge process is completed, it checks out back to that branch and pop the stashed changes
> 
> - Validates branches locally & remotely
>
> - Fetches origin & pull updates before merging
>
> - Merges the remote branch of the source branch to the local branch of the target branch, and checks the merge status
>
> - Then, pushes the merged changes
>
> - Logs for each step for better debugging

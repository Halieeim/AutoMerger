## Purpose
> This script automates the process of merging branches in a single repository or across multiple repositories in one go.

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
> To merge two branches on all repositories in a file and you may also exclude some directories from that file with [-ex] option:
>
> ```automerger.sh -f <file_name or file_path>``` you need also to put your repos full paths in the first column of branches.csv then source branch then target branch  **` Do Not delete/change the values of the first row of the sheet `**
> 
> #### ==> Note: write the branch name without 'origin/'. For example: 'main' NOT 'origin/main'
>
> ## In Windows
>   
>> - Add the FOLDER path of the script in the environment variables in ```path```
>>
>> - Open Git Bash terminal so you can execute it, and run any of the above commands

## What does this script specifically do?
> - Excludes undesired directories and filters Directories that do not have ".git" directory "Not a Repository"
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

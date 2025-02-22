#!/bin/bash

# Function to log messages (both terminal & file)
log() {
    echo -e "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}

# Function to log errors in red
log_error() {
    echo -e "\e[31m$(date +"%Y-%m-%d %H:%M:%S") - ERROR: $1\e[0m" >&2
}

# Function to log success in green
log_success() {
    echo -e "\e[32m$(date +"%Y-%m-%d %H:%M:%S") - SUCCESS: $1\e[0m"
}

banner="
 .S_SSSs     .S       S.   sdSS_SSSSSSbs    sSSs_sSSs                      
.SS~SSSSS   .SS       SS.  YSSS~S%SSSSSP   d%%SP~YS%%b                     
S%S   SSSS  S%S       S%S       S%S       d%S'     \`S%b                    
S%S    S%S  S%S       S%S       S%S       S%S       S%S                    
S%S SSSS%S  S&S       S&S       S&S       S&S       S&S                    
S&S  SSS%S  S&S       S&S       S&S       S&S       S&S                    
S&S    S&S  S&S       S&S       S&S       S&S       S&S                    
S&S    S&S  S&S       S&S       S&S       S&S       S&S                    
S*S    S&S  S*b       d*S       S*S       S*b       d*S                    
S*S    S*S  S*S.     .S*S       S*S       S*S.     .S*S                    
S*S    S*S   SSSbs_sdSSS        S*S        SSSbs_sdSSS                     
SSS    S*S    YSSP~YSSY         S*S         YSSP~YSSY                      
       SP                       SP                                         
       Y                        Y                                          
                                                                           
             .S_SsS_S.     sSSs   .S_sSSs      sSSSSs    sSSs   .S_sSSs    
            .SS~S*S~SS.   d%%SP  .SS~YS%%b    d%%%%SP   d%%SP  .SS~YS%%b   
            S%S \`Y' S%S  d%S'    S%S   \`S%b  d%S'      d%S'    S%S   \`S%b  
            S%S     S%S  S%S     S%S    S%S  S%S       S%S     S%S    S%S  
            S%S     S%S  S&S     S%S    d*S  S&S       S&S     S%S    d*S  
            S&S     S&S  S&S_Ss  S&S   .S*S  S&S       S&S_Ss  S&S   .S*S  
            S&S     S&S  S&S~SP  S&S_sdSSS   S&S       S&S~SP  S&S_sdSSS   
            S&S     S&S  S&S     S&S~YSY%b   S&S sSSs  S&S     S&S~YSY%b   
            S*S     S*S  S*b     S*S   \`S%b  S*b \`S%%  S*b     S*S   \`S%b  
            S*S     S*S  S*S.    S*S    S%S  S*S   S%  S*S.    S*S    S%S  
            S*S     S*S   SSSbs  S*S    S&S   SS_sSSS   SSSbs  S*S    S&S  
            SSS     S*S    YSSP  S*S    SSS    Y~YSSY    YSSP  S*S    SSS  
                    SP           SP                            SP          
                    Y            Y                             Y           
"

displayBanner(){
    echo -e "\e[36m$banner\e[0m"
}

# Function to display usage
usage() {
    scriptName=$(basename "$0")
    log "Usage:"
    log "  $scriptName -from <source_branch> -to <target_branch>                   # Merge in current repo"
    log "  $scriptName -a -from <source_branch> -to <target_branch>                # Merge in all repos in current directory"
    log "  $scriptName -a -from <source_branch> -to <target_branch> -ex dir1,dir2  # Exclude specific directories"
    log "  $scriptName -f <filename.csv>                                           # Merge in all repos listed in <filename>.csv"
    exit 1
}
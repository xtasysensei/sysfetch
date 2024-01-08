#!/usr/bin/env bash

########################## !!! IMPORTANT NOTE !!! #############################
#                                                                             #
#  must run script one time from terminal using ./<path/to/script> to         #
#  generate the sysinfo.txt file for terminal to display, also if you use     #
#  the list_updates portion of the script, or create any other function that  #
#  displays any sort of data that changes, you will want to set the script    #
#  to run as a cronjob to verify the correct and current information is       #
#  displayed.                                                                 #
#                                                                             #
###############################################################################

### CHECKS WHICH DISTRO YOU ARE RUNNING
distro() {
    file='/etc/os-release'
    if [[ -f $file && -r $file ]]; then
        while IFS='=' read key value; do
            if [[ $key == NAME ]]; then
                printf '%s\n' "${value//\"/}"

                break
            fi
        done < "$file"
    else
        printf '?'
    fi
}

### CHECKS FOR INIT SYSTEM
### ADD YOUR OWN LINE IF YOU USE OTHER INIT SYSTEM
find_init() {
    if pidof systemd &> /dev/null; then
        printf 'SystemD'
    elif [[ -f /sbin/openrc ]]; then
        printf 'OpenRC'
    else
        file='/proc/1/comm'
        if [[ -r $file ]]; then
            read data < "$file"
            printf '%s' "${data%% *}"
        else
            printf '?'
        fi
    fi
}

log() {
  printf """  
     ___
    (.· | 
    (<> |
    / __  \
   ( /  \ /|
  _/\ __)/_)
  \/-____\/
"""
}
### COUNTS NUMBER OF INSTALLED PACKAGES FOR APT PACMAN AND XBPS
### ADD YOUR OWN LINE IF YOUR MANAGER IS NOT LISTED
pkg_count() {
    for pkg_mgr in xbps-install apt pacman; do
        type -P "$pkg_mgr" &> /dev/null || continue

        case $pkg_mgr in
            xbps-install)
                xbps-query -l | wc -l ;;
            apt)
                while read abbrev _; do
                    [[ $abbrev == ii ]] && (( line_count++ ))
                done <<< "$(dpkg -l)"
                printf '%d' $line_count ;;
            pacman)
                readarray lines <(pacman -Q)
                printf '%d' ${#lines[*]} ;;
        esac
        return
    done
    printf 'Not Found'
}

### CHECKS FOR NUMBER OF UPDATES, ONLY SET UP TO RUN ON VOID
### EDIT LINES FOR APT OR PACMAN OR ADD YOUR OWN LINES FOR OTHER MANAGERS
list_updates() {
    for pkg_mgr in xbps-install apt pacman; do
        type -P "$pkg_mgr" &> /dev/null || continue

        #TODO: Unfinished. May need to add code for each package manager.
        case $pkg_mgr in
            xbps-install)
                sudo xbps-install -nuM | wc -l
                #printf '%d' ${#lines[*]} ;;
                ;;
            apt)
                printf '?' ;;
            pacman)
                printf '?' ;;
        esac
        return
    done
    printf 'Not Found'
}

mem() {
    MEMORY=$(free -m | awk '/Mem/{print $3}')
   TMEMORY=$(free -m | awk '/Mem/{print $2}')
   PMEM=$(free -m | awk 'NR==2{printf "%.2f%%\t\t", $3*100/$2 }')
   GAP=" "
  #DISK=$(df -h | awk '$NF=="/"{printf "%s\t\t", $5}')
  #cpuUsage=$(top -bn1 | awk '/Cpu/ { print $2}')
  #CPU=$(top -bn1 | grep load | awk '{printf "%.2f%%\t\t\n", $(NF-2)}')
   printf '%s' ${MEMORY}/${TMEMORY} mb" "$PMEM
}

### CHECKS WHICH VERSION OF ZSH IS RUNNING, CHANGE FOR BASH OR OTHER SHELLS

# Display the basename of the '$SHELL' environment variable.
get_shell() {
        zsh=$(zsh --version | awk '/zsh/{print $1" "$2}')
       printf '%s' "$zsh"
    #log shell "${SHELL##*/}" >&6
}

shell() {
   if type -P bash &> /dev/null; then
       bash -c "printf '%s' \"$BASH_VERSION\""
    elif type -P zsh &> /dev/null; then
        zsh -c "printf '%s' \"$ZSH_VERSION\""
    else
        printf '?'
    fi
}

{
    # printf "$(log)"
   # printf "\n"
    printf """
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
+        System specs       +
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    """
    printf "\n"
    printf '[ LSB: %s ] ' "$(distro)"
    printf "\n"
    printf '[ Init: %s ] ' "$(find_init)"
    printf '[ Upd: %s ] ' "$(list_updates)"
    printf "\n\n"
    printf '[ Shell: %s ] ' "$(get_shell)"
    printf "\n"
    printf '[ PKGs: %s ] ' "$(pkg_count)"
    printf '[ MEM: %s ] ' "$(mem)"
    printf "\n\n"
}

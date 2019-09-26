#!/usr/bin/env bash
# Author: AshkanRafiee - https://github.com/AshkanRafiee/
flag=""
currentVersion="1.5"
configuredClient=""

## This function determines which http get tool the system has installed and returns an error if there isnt one
getConfiguredClient()
{
  if  command -v curl &>/dev/null; then
    configuredClient="curl"
  elif command -v wget &>/dev/null; then
    configuredClient="wget"
  elif command -v http &>/dev/null; then
    configuredClient="httpie"
  elif command -v fetch &>/dev/null; then
    configuredClient="fetch"
  else
    echo "Error: This tool requires either curl, wget, httpie or fetch to be installed." >&2
    return 1
  fi
}

## Allows to call the users configured client without if statements everywhere
httpGet()
{
  case "$configuredClient" in
    curl)  curl -A curl -s "$@" ;;
    wget)  wget -qO- "$@" ;;
    httpie) http -b GET "$@" ;;
    fetch) fetch -q "$@" ;;
  esac
}

update()
{
  repositoryName="No-Sanction" #Name of repostiory to be updated ex. Sandman-Lite
  githubUserName="AshkanRafiee" #username that hosts the repostiory ex. alexanderepstein
  nameOfInstallFile="install.sh" # change this if the installer file has a different name be sure to include file extension if there is one
  latestVersion=$(httpGet https://api.github.com/repos/$githubUserName/$repositoryName/tags | grep -Eo '"name":.*?[^\\]",'| head -1 | grep -Eo "[0-9.]+" ) #always grabs the tag without the v option

  if [[ $currentVersion == "" || $repositoryName == "" || $githubUserName == "" || $nameOfInstallFile == "" ]]; then
    echo "Error: update utility has not been configured correctly." >&2
    exit 1
  elif [[ $latestVersion == "" ]]; then
    echo "Error: no active internet connection" >&2
    exit 1
  else
    if [[ "$latestVersion" != "$currentVersion" ]]; then
      echo "Version $latestVersion available"
      echo -n "Do you wish to update $repositoryName [Y/n]: "
      read -r answer
      if [[ "$answer" == [Yy] ]]; then
        cd ~ || { echo 'Update Failed'; exit 1; }
        if [[ -d  ~/$repositoryName ]]; then rm -r -f $repositoryName || { echo "Permissions Error: try running the update as sudo"; exit 1; } ; fi
        echo -n "Downloading latest version of: $repositoryName."
        git clone -q "https://github.com/$githubUserName/$repositoryName" && touch .ARHiddenFile || { echo "Failure!"; exit 1; } &
        while [ ! -f .ARHiddenFile ]; do { echo -n "."; sleep 2; };done
        rm -f .ARHiddenFile
        echo "Success!"
        cd $repositoryName || { echo 'Update Failed'; exit 1; }
        git checkout "v$latestVersion" 2> /dev/null || git checkout "$latestVersion" 2> /dev/null || echo "Couldn't git checkout to stable release, updating to latest commit."
        chmod a+x install.sh #this might be necessary in your case but wasnt in mine.
        ./$nameOfInstallFile "update" || exit 1
        cd ..
        rm -r -f $repositoryName || { echo "Permissions Error: update succesfull but cannot delete temp files located at ~/$repositoryName delete this directory with sudo"; exit 1; }
      else
        exit 1
      fi
    else
      echo "$repositoryName is already the latest version"
    fi
  fi
}

active()
{
networksetup -setdnsservers Wi-Fi 178.22.122.100 185.51.200.2
#sudo discoveryutil mdnsflushcache #deprecated
sudo killall -HUP mDNSResponder; sleep 1;
}

checkInternet()
{
  httpGet github.com > /dev/null 2>&1 || { echo "Error: no active internet connection" >&2; return 1; } # query github with a get request
}

deactive()
{
networksetup -setdnsservers Wi-Fi 8.8.8.8 8.8.4.4 
#sudo discoveryutil mdnsflushcache #deprecated
sudo killall -HUP mDNSResponder; sleep 1;
}

usage()
{
 cat <<EOF
No-Sanction
Description: Internet Connection Immunity to Sanctions.
Usage: no-sanction [flags] or no-sanction [flags] [arguments]
  -a  Activeate No-Sanction
      Can also use active instead of -a
  -d  Deactiveate No-Sanction
      Can also use deactive instead of -d
  -u  Update No-Sanction
  -h  Show the help
  -v  Get the tool version
Examples:
   no-sanction-macOSX -a
   no-sanction-macOSX -d
   no-sanction-macOSX -u
   no-sanction-macOSX -h
   no-sanction-macOSX -v
EOF
}
pping()
{
  ping -c 4 cloudflare.com
}
while getopts "hvdaup" opt; do
  case "$opt" in
    \?) echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    h)  usage
        exit 0
        ;;
    v)  echo "Version $currentVersion"
        exit 0
        ;;
    d)  if [[ $flag == "" ]]; then
          flag="deactive"
        else
          echo "Error: all flags are mutually exclusive"
          exit 1
        fi
        ;;
    a)  if [[ $flag == "" ]]; then
          flag="active"
        else
          echo "Error: all flags are mutually exclusive"
          exit 1
        fi
        ;;
    u)  getConfiguredClient || exit 1
        checkInternet || exit 1
        update
        exit 0
        ;;
    p)  pping
        ;;
    :)  echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
  esac
done

if [[ $# == "0" ]]; then
  usage
elif [[ $# == "1" ]]; then
  if [[ $1 == "update" ]]; then
    getConfiguredClient || exit 1
    checkInternet || exit 1
    update || exit 1
    exit 0
  elif [[ $1 == "help" ]]; then
    usage
    exit 0
  elif [[ $flag == "active" || $1 == "active" ]]; then active "${*:2}" && tput setaf 4 &&echo -e "No-Sanction Activated Successfully!"  || exit 1
  elif [[ $flag == "deactive" || $1 == "deactive" ]]; then deactive ${*:2} && tput setaf 1 && echo -e "No-Sanction Deactivated Successfully!" || exit 1
  else { echo "Error: the argument $1 is not valid"; exit 1; }; fi
else { usage; exit 1; };
fi
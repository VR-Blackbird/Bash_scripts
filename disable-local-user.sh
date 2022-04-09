#!/bin/bash


# Display usage on how to run the script

usage() {

     echo "Usage: ${0} [-dvra] USERNAME...." >&2
     echo "Disable or delete the accounts"
     echo
     echo "OPTION        DESCRIPTION"
     echo " -d         Delete account[s]"
     echo " -v         Verbose mode turned on"
     echo " -r         Delete home directory"
     echo " -a         Create an Archive of user home directory"

}

# Display detailed information when verbose mode is turned on

log() {

     local VERBOSITY=${VERBOSE}
     if [[ "${VERBOSITY}" = 'true' ]]
     then
	     echo "${@}"
     fi
}

# Function to validate a user if it exists

validate_user() {
      
    id -u "${@}" >/dev/null
    if [[ "${?}" -ne 0 ]]
    then
	   echo -e "\e[1;31mFailed\e[m: User does not exist" >&2 
	   exit 1
    fi

}

# Function to create an archive

create_archive() {
      if [[ "${CREATEARCHIVE}" = 'true' ]]
      then
           log "Creating archive for the user ${1}"
	   tar -czf /home/"${1}.tgz" -C /home ${1}  &>/dev/null 
      fi 
}


disable_delete() {
      if [[ "${DELETE}" = 'true' ]]
      then
	  log "Deleting the user ${1}"
	  if [[ "${REMOVEDIR}" = 'true' ]]
	  then
	       log "Removing the directory"
	       userdel -r ${1} &>/dev/null 
               if [[ "${?}" -ne 0 ]]
	       then
		      echo "Unable to delete the directory" >&2
		      exit 1
	       fi
	  else 
	       userdel ${1}
	  fi
      else
	      log "Disabling the user account"
	      chage -E 0 ${1}
	      if [[ "${?}" -ne 0 ]]
	      then
		      echo "Unable to disable the account" >&2
		      exit 1
	      fi
      fi

}

# Check if the script is run by root

USERID=$(id -u)
if [[ "${USERID}" -ne 0 ]]
then
	echo "Please run the script with root privileges" >&2
	exit 1
fi

# Parse the command line arguments

while getopts vard OPTION
do
    case ${OPTION} in
        v)
	   VERBOSE='true'
	   log "Verbose mode on"
	   ;;
	r)
	   REMOVEDIR='true'
	   ;;
	a)
	   CREATEARCHIVE='true'
	   ;;
	d)
	   DELETE='true'
	   ;;
	?)
	   usage
	   exit 1
    esac
done

POSITION=$(( OPTIND-=1 ))
shift "${POSITION}"

# Check if username is specified 

if [[ "${#}" -eq 0 ]]
then
	echo -e "\e[1;31mError\e[m: Username needs to be provided" >&2
	usage
	exit 1
fi

if [[ "${REMOVEDIR}" = 'true' ]] && [[ "${DELETE}" != 'true' ]]
then
	echo "Cannot delete a directory when disabling an account" >&2
	exit 1
fi

validate_user "${@}"

# Loop over the username and delete/disable

for USER in "${@}"
do
  	create_archive "${USER}"
        disable_delete "${USER}"	
done




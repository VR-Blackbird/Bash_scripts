#!/bin/bash


# Display the usage when encountered an error

usage() {
     
     echo "USAGE: ${0} [-f] [FILE] [-nsv].. COMMAND"
     echo 
     echo "-f  [FILE]     Specify the file name which has the list of servers"
     echo "-n             Run as Dry run"
     echo "-s             Run the commands on server with superuser" 
     echo "-v             Enable verbose mode"
     exit 1    

}

# Display log message when running with verbose mode

verbose() {

        local MESSAGE="${@}"
	if [[ "${VERBOSE}" = 'true' ]]
	then
		echo "${MESSAGE}"
	fi

}


# Make sure the user does not run this script as root 

USERID=$(id -u)
if [[ "${USERID}" -eq 0 ]]
then
	echo "Cannot run as root" >&2
	exit 1
fi

# Check if the arguments are passed

if [[ "${#}" -eq 0 ]]
then
	usage
fi


# Iterate through the arguments that were passed

FILEPATH='./servers'

while getopts vnsf: OPTION
do
	case "${OPTION}" in
	    v)
		VERBOSE='true'
                verbose "Verbose mode turned on"
		;;
	    n)
		DRYRUN='true'
		;;
	    s)
		SUDOBIT='sudo'
		;;
	    f)
                FILEPATH="${OPTARG}"
		;;
	    ?)
		usage
		;;
	 esac
done
verbose "The host file chosen is ${FILEPATH}"

shift $((${OPTIND} - 1))

# Check if the host file exists

if [[ ! -e  "${FILEPATH}" ]]
then
	echo "Invalid host file ${FILEPATH}" >&2
	exit 1
fi
# Check if a command is specified

if [[ "${#}" -lt 1 ]]
then
      usage
fi


#  Loop through the hosts
COMMAND_STATUS=0
for SERVER in $(cat "${FILEPATH}")
do
	SERVERHOST=$(echo "${SERVER}" | cut -d '@' -f 2)
	ping  -c 1 "${SERVERHOST}" &>/dev/null
	if [[ "${?}" -ne 0 ]]
	then
		echo "Host ${SERVERHOST} not reachable" >&2
		continue
	fi

	# Check for DRY run
	SSH_STATEMENT="ssh -o ConnectTimeout=2 ${SERVER} ${SUDOBIT} ${@}"

	if [[ "${DRYRUN}" = 'true' ]]
	then  
	   echo "DRY RUN: ${SSH_STATEMENT}"
        else
	   echo "Server: ${SERVERHOST}"
	   echo 
           ${SSH_STATEMENT}  2> /dev/null
	   COMMAND_STATUS="${?}"
	   if [[ "${COMMAND_STATUS}" -ne 0 ]]
           then
		echo "Command did not run successfully on the remote device ${SERVER}" >&2
	   fi
	fi
done
exit "${COMMAND_STATUS}" 




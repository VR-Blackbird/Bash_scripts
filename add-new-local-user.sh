#!/bin/bash

# Check for privileged account

USERID=`id -u`
if [[ ${USERID} -ne 0 ]]
then
	echo "You don't have sufficient privileges"
	exit 1
fi

# Check if the arguments are passed

if [[ "${#}" -lt 2 ]]
then
	echo "Usage ${0}: USERNAME COMMENT [...]  "
        exit 1
fi

# Read the username and comment

USERNAME=${1}
shift
COMMENT=${*}

#Create a user account

useradd -c "${COMMENT}" -m "${USERNAME}" 2>/dev/null

#Check if user added successfully

if [[ ${?} -eq 9 ]]
then
	echo "User exists"
	exit 1
else
	echo "User successfully created"
fi


# Generate a completely random password for the user

DATE_TIME=$(date +%s%N)
SPECIAL_CHARS="~!@#$%^&*()_-+="
RANDOM_SPECIAL=$(echo ${SPECIAL_CHARS} | fold -w1 | shuf | head -c1)
PASSWORD="$(echo "${DATE_TIME}${RANDOM}" | sha256sum | head -c50)${RANDOM_SPECIAL}"


echo "${PASSWORD}" 

# Set the user password

echo "${USERNAME}:${PASSWORD}" | chpasswd

# Check if password creation was successfull

if [[ ${?} -ne 0 ]]
then
	echo "Unable to create password!"
	exit 1
else
	echo "Successfully updated the password"
fi

#Display everything to the user

HOSTNAME=`hostname`
echo "Username:"
echo $USERNAME
printf "\n"

echo "Full name:"
echo $COMMENT
printf "\n"

echo "Password:"
echo $PASSWORD
printf "\n"

echo "Hostname:"
echo $HOSTNAME





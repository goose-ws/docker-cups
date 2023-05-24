#!/usr/bin/env bash

function get_persistent_users {
usersRaw="$(getent group lpadmin)"
usersRaw="${usersRaw#*:*:*:}"
IFS="," read -r -a lpUsers <<<"${usersRaw}"
unset shadowArr
for i in "${lpUsers[@]}"; do
	while read -r ii; do
		if [[ "${ii%%:*}" == "${i}" ]]; then
			shadowArr+=("${ii}")
		fi
	done < "/etc/shadow"
done
}

function load_persistent_users {
if ! [[ -e "/etc/cups/users_persistent" ]]; then
	echo "No persistent user file found"
	exit 0
fi
shadowPrm="$(stat -c "%a" /etc/shadow)"
shadowOwn="$(stat -c "%u" /etc/shadow)"
shadowGrp="$(stat -c "%g" /etc/shadow)"
while read -r i; do
	if id "${newUser}" > /dev/null 2>&1; then
		echo "User ${i%%:*} already exists"
		break
	fi
	if useradd -M -s "/bin/false" "${i%%:*}"; then
		echo "User ${i%%:*} imported successfully"
	else
		echo "Unable to import user ${i%%:*}"
		exit 1
	fi
	if usermod -aG lpadmin "${i%%:*}"; then
		echo "User ${i%%:*} added to lpadmin group successfully"
	else
		echo "Unable to add user ${i%%:*} to lpadmin"
		exit 1
	fi
	while read -r ii; do
		if [[ "${i%%:*}" == "${ii%%:*}" ]]; then
			newShadowArr+=("${i}")
		else
			newShadowArr+=("${ii}")
		fi
	done < "/etc/shadow"
done < "/etc/cups/users_persistent"
cp "/etc/shadow" "/etc/shadow.old"
( for i in "${newShadowArr[@]}"; do echo "${i}"; done ) > "/etc/shadow"
chmod "${shadowPrm}" "/etc/shadow"
chown "${shadowOwn}:${shadowGrp}" "/etc/shadow"
importSuccess="0"
while read -r i; do
	while read -r ii; do
		if [[ "${i}" == "${ii}" ]]; then
			echo "Password for user ${i%%:*} imported successfully"
			importSuccess="1"
			break
		fi
	done < "/etc/shadow"
	if [[ "${importSuccess}" -eq "0" ]]; then
		echo "Unable to import password for user ${i%%:*}"
	fi
done < "/etc/cups/users_persistent"
}

function save_persistent_users {
get_persistent_users
( for i in "${shadowArr[@]}"; do echo "${i}"; done ) > "/etc/cups/users_persistent"
shadowPrm="$(stat -c "%a" /etc/shadow)"
shadowOwn="$(stat -c "%u" /etc/shadow)"
shadowGrp="$(stat -c "%g" /etc/shadow)"
chmod "${shadowPrm}" "/etc/cups/users_persistent"
chown "${shadowOwn}:${shadowGrp}" "/etc/cups/users_persistent"
for i in "${shadowArr[@]}"; do
	persistSave="0"
	while read -r ii; do
		if [[ "${i}" == "${ii}" ]]; then
			persistSave="1"
			break
		fi
	done < "/etc/cups/users_persistent"
	if [[ "${persistSave}" -eq "1" ]]; then
		echo "Verified user saved to persistent file: ${i%%:*}"
	else
		echo "Unable to save user to persistent file: ${i%%:*}"
	fi
done
}


function list_users {
get_persistent_users
echo ""
for i in "${lpUsers[@]}"; do
	echo "  ${i}"
done
}

function add_user {
echo "Please enter the username you would like to add"
read -r -p "> " newUser
if id "${newUser}" > /dev/null 2>&1; then
	echo "User already exists"
	exit 1
fi
echo ""
echo "Please enter the password for ${newUser} (shown in clear text)"
read -r -p "> " newPassword
if [[ -z "${newPassword}" ]]; then
	echo "No password detected"
	exit 1
fi
echo ""
echo "Attempting to add new user"
if useradd -M -s "/bin/false" "${newUser}"; then
	echo "User created successfully"
else
	echo "Unable to create user"
	exit 1
fi
if echo "${newUser}:${newPassword}" | chpasswd; then
	echo "User password set successfully"
else
	echo "Unable to set user password"
	exit 1
fi
if usermod -aG lpadmin "${newUser}"; then
	echo "User added to lpadmin group successfully"
else
	echo "Unable to add user to lpadmin"
	exit 1
fi
echo "User added successfully."
}

function pick_user {
echo ""
n="0"
for i in "${lpUsers[@]}"; do
	echo "  [${n}] ${i}"
	(( n++ ))
done
echo ""
echo "Please enter the user number"
read -r -p "> " userInput
}

function del_user {
pick_user
echo ""
if [[ -n "${lpUsers[${userInput}]}" ]]; then
	if deluser "${lpUsers[${userInput}]}"; then
		echo "User ${lpUsers[${userInput}]} removed successfully"
	else
		echo "Failed to remove user ${lpUsers[${userInput}]}"
	fi
else
	echo "Invald option"
fi
}

function change_pw {
pick_user
echo ""
if [[ -n "${lpUsers[${userInput}]}" ]]; then
	if passwd "${lpUsers[${userInput}]}"; then
		echo "Password succesfully changed for user ${lpUsers[${userInput}]}"
	else
		echo "Failed to change password for user ${lpUsers[${userInput}]}"
	fi
else
	echo "Invald option"
fi
}

function print_menu {
echo "Choose an option:"
echo ""
echo "  [0] Exit"
echo ""
echo "  [1] List printer users"
echo "  [2] Add a new user"
echo "  [3] Remove an existing user"
echo "  [4] Change an existing user's password"
echo ""
}

if [[ "${1}" == "--load-persistent-users" ]]; then
	load_persistent_users
	exit 0
elif [[ "${1}" == "--save-persistent-users" ]]; then
    save_persistent_users
    exit 0
fi

print_menu
while read -r -p "> " userInput; do
	case "${userInput}" in
		0)
		save_persistent_users
		exit 0
		;;
		1)
		list_users
		;;
		2)
		add_user
		;;
		3)
		del_user
		;;
		4)
		change_pw
		;;
		*)
		echo "Invalid option"
		;;
	esac
	echo ""
	read -r -p "Press [Enter] to return to main menu"
	clear
	print_menu
done

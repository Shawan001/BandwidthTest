# Purpose of this script is to test bandwidth of a link to our production servers ta and tb.

function checkSSHAbility () {
	echo "[+] Checking ssh-ability to $1"
	ssh $1 "echo -n" 2> /dev/null # $1 is either ta or tb
	if [[ $? -ne 0 ]]
	then
		err "ssh failed, please make sure you have added ssh-key to $1" "normal"
		err "Make sure you make entries for ta and tb in /etc/hosts"
		err "[+] Exiting..."
		exit
	else
		echo "[+] ssh success"
	fi
}

function createTestFile () { # A testfile is needed for testing upload and download
	echo "[+] Creating testfile" 
	fallocate -l $1 $downloadpath/testfile.img 2> /dev/null # $1 is the size of the test file and $2 is the name of the test file
	if [[ $? -eq 0 ]]
	then 
		echo "[+] testfile created"
	else
		err "Failed to create testfile" "critical"
	fi
}

function removeTestFile () { # testfile should be removed from local, ta and tb
	if [[ "$1" == "fromlocal" ]]
	then
		rm $downloadpath/testfile.img 2> /dev/null

		if [[ $? -eq 0 ]]
		then 
			echo "[+] testfile removed from local file system"
		else
			err "testfile could not be removed from local file system" "normal"
		fi
	else	
		ssh $1 "rm testfile.img" 2> /dev/null
		if [[ $? -eq 0 ]]
		then 
			echo "[+] testfile deleted from $1"
		else 
			err "testfile couldnot removed from $1" "normal"
		fi
	fi
}

function checkForExistingFile() { #check for any pre existing test file on any servers
	echo "[+] Checking for existing testfile in $1"
        ssh $1 "rm testfile.img" 1> /dev/null 2>&1
        if [[ $? -eq 0 ]]
        then
                echo "[+] testfile deleted from $1"
        else
                err "No testfile is previously existed in $1" # This is not actually an error
	fi
}

function uploadTestFile () {
	echo "[+] Uploading testfile to $1"
	rsync -v --progress $downloadpath/testfile.img $1: # $1 is either ta or tb
	if [[ $? -eq 0 ]]
	then
		echo "[+] Upload done to $1"
	else
		err "Upload failed to $1" "normal"
	fi
}

function downloadTestFile () {
	echo "[+] Downloading testfile from $1"
	rsync -v --progress $1:testfile.img $downloadpath/
	if [[ $? -eq 0 ]]
	then
		echo "[+] Download Completed from $1"
	else
		err "Download failed from $1" "normal"
	fi
}

function rest () {
	sleeptime=1m
	echo "[+] Sleeping for $sleeptime Mins"
	sleep $sleeptime
}

function help_ () {
	echo "Usage : ./bandwidthtest <[ta|tb]|[ta tb]> <testfilesize> "
	echo "usage : testfile size should be between 200M-2G"
}
function cleanup () {
removeTestFile fromlocal
rm -rf $downloadPath
}

function err () {
	echo "[-] $1"
	if [[ $2 == 'critical' || $2 == 'normal' ]]
	then
		notify-send -u $2 "BandwidthTest" "$1"
	fi
}

function performTest () {
	checkForExistingFile $1
	checkSSHAbility $1
        createTestFile $2
        uploadTestFile $1
        removeTestFile fromlocal
        rest
        downloadTestFile $1
        removeTestFile $1
	cleanup
}

downloadpath=/tmp/$(date | md5sum | awk '{print $1}') # testfile location

if [[ "$1" == "ta" && "$2" == "tb" ]] || [[ "$1" == "tb" && "$2" == "ta" ]] && [[ $(echo $3 | grep -E "([1-2]G|[2-9][0-9]{2}M)") ]]
then
	echo "[+] Creating temporary directory"
	mkdir $downloadpath
	# ***** ta ******#
	performTest $1 $3 #$1 = (ta|tb) and $3 = filesize
	# ****Sleep**** #
	rest
	# **** tb ******#	
	performTest $2 $3 #$2 = (ta|tb) and $3 = filesize
	echo "[+] Done"
elif [[ "$1" == "ta" || "$1" == "tb" ]] && [[ $(echo $2 | grep -E "([1-5]G|[2-9][0-9]{1,2}M)") ]]
then
	echo "[+] Creating temporary directory"
	mkdir $downloadpath
	performTest $1 $2
	echo "[+] Done"
elif [[ $1 == "--help" || $1 == "-h" ]]
then
	help_
else
	echo "[-] Check parameter please"
	#echo "[+] Expected parameters (ta||tb) && FileSize[1-5GB || 200-999MB]"
	help_
	echo "[+] Exiting..."
	exit
fi

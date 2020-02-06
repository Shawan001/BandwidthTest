The purpose of the script to perform bandwidth testing via the link you are currently online, to our production servers, ta and tb. 

rsync is used in the script to perform upload and download task as well as measuring the bandwidth.

Prerequisites:
1. You must have to add ssh key to the servers (ops01-ta and ops01-tb in this case)
2. Make sure you have entries in /etc/hosts for ta and tb.

Usage Examples:
./BandwidthTest.sh ta tb 1G or 
./BandwidthTest.sh tb 500M

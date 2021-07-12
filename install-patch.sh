#/bin/bash

user_home="$HOME"
workdir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
patched_file01="analyzemcast.sh"
patched_file02="processxml.sh"
patched_file03="details.js"
patched_file04="imageclass-client.py"

function rollback {
	echo "rollback"
	cp $workdir/backup/$patched_file01 $smdir/
	cp $workdir/backup/$patched_file02 $smdir/
	cp $workdir/backup/$patched_file03 $webdir/
	rm $smdir/$patched_file04
}

read -p "Please enter stream-monitor directory (Default: '$HOME/stream-monitor') : " smdir
if [ -z "$smdir" ]; then
    smdir="$HOME/stream-monitor"
else
    smdir=$(echo $smdir | sed -e 's,.*\~,'"$user_home"',')
fi

read -p "Please enter stream-monitor web directory (Default: '$HOME/stream-monitor/web') : " webdir
if [ -z "$webdir" ]; then
    webdir="$HOME/stream-monitor/web"
else
    webdir=$(echo $webdir | sed -e 's,.*\~,'"$user_home"',')
fi

if [ -f "$smdir/$patched_file01" ]; then
	echo "$patched_file01 exists and will be patched"
	cp $smdir/$patched_file01 $workdir/backup
	cp $workdir/patched/$patched_file01 $smdir/
else
	echo "$patched_file01 does not exists. Installation aborted."
	exit
fi

if [ -f "$smdir/$patched_file02" ]; then
	echo "$patched_file02 exists and will be patched"
	cp $smdir/$patched_file02 $workdir/backup
	cp $workdir/patched/$patched_file02 $smdir/
else
	echo "$patched_file02 does not exists. Installation aborted."
	exit
fi

if [ -f "$webdir/$patched_file03" ]; then
	echo "$patched_file03 exists and will be patched"
	cp $webdir/$patched_file03 $workdir/backup
	cp $workdir/patched/$patched_file03 $webdir/
else
	echo "$patched_file03 does not exists. Installation aborted."
	exit
fi

echo "$patched_file04 will be copied to $smdir"
cp $workdir/patched/$patched_file04 $smdir/

echo "Patch finished"

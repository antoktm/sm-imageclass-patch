#!/bin/bash
#########################################################
# Stream Monitor					#
# analyzemcast.sh - Called script for UDP monitoring	#
#							#
# (c) Tri Maryanto					#
# IPTV Development - MNC Play				#
# 2020 - Jakarta, Indonesia				#
#########################################################

[ $# -eq 0 ] && { echo "Usage: $0 address chid chname configfile"; exit 1; }
# Read the parameters and configuration file
address=$1
chid=$2
chname=$3
configfile=$4
configlines=$(sed 's/#.*//' $configfile)

inputeth=$(grep interface <<< "$configlines"|cut -d"=" -f2)
ckiface=$(ip -o -4 addr list $inputeth)
if [ "$?" == "0" ]
then
	inputip=$(echo $ckiface | awk '{print $4}' | cut -d"/" -f1)
else
	inputip="0.0.0.0"
fi
duration=$(grep monitorduration <<< "$configlines"|cut -d"=" -f2)
expectedcont=$(grep mincontinuityrate <<< "$configlines"|cut -d"=" -f2)
timeout=$(grep igmptimeout <<< "$configlines"|cut -d"=" -f2)

freezemode=$(grep freezedetect <<< "$configlines"|cut -d"=" -f2)
if [ "$freezemode" == "on"  ] 
then
	frznoise=$(grep freezenoisetolerance <<< "$configlines"|cut -d"=" -f2)
	frzsecs=$(grep freezenoticeseconds <<< "$configlines"|cut -d"=" -f2)
	frztol=$(grep freezedurationpercentage <<< "$configlines"|cut -d"=" -f2)
	thumbsdir=$(grep thumbnailsdir <<< "$configlines"|cut -d"=" -f2)
fi

tmpdir=$(grep tmpdir <<< "$configlines"|cut -d"=" -f2)
xmldir=$(grep xmldir <<< "$configlines"|cut -d"=" -f2)

if [[ $chid =~ "-" ]]
then
	chidbase=$(printf %03d $(echo $chid|cut -d'-' -f1))
	chidnorm=$(echo $chidbase-$(echo $chid|cut -d'-' -f2))
else
	chidnorm=$(printf %03d $chid)
	chidbase=$chidnorm
fi

save=$tmpdir/$chidnorm
savexml=$xmldir/$chidnorm.xml
savexmlbase=$xmldir/$chidbase.xml
savexmltmp=$tmpdir/$chidnorm.xml.tmp

# TSDuck command for UDP probing
if [ "$freezemode" == "on" ];
then
	dummyvar=$((tsp -d9 -I ip --receive-timeout $timeout -l $inputip $address -P analyze --normalize -o $save -P until -s $duration |ffmpeg -i pipe:0 -loglevel quiet -vf "freezedetect=n=$frznoise:d=$frzsecs,metadata=mode=print:file=$save.frz" -map 0:v:0 -acodec copy -f null - -vframes 1 -s 256x144 $save.png) 2>&1)
# imageclass-patch - add image classifier function and put the result into a variable
        thumbsstat=$(timeout 5s ./imageclass-client.py $save.png)
        echo "thumbstat:"$thumbsstat >> $save
else
	dummyvar=$((tsp -d9 -I ip --receive-timeout $timeout -l $inputip $address -P analyze --normalize -o $save -P until -s $duration -O drop) 2>&1)
fi

# get sources
if [ -s "$save" ]
then
	sources=$(echo $dummyvar|grep "received UDP"| sed -e "s/.*source: //" -e "s/, destination.*//"|sort|uniq|xargs|sed -e 's/ /,/g')
	echo "sources=$sources" >> $save
fi

# Reformat the output into xml
./processxml.sh $chidnorm "$chname" $address $configfile > $savexmltmp

if [ "$freezemode" == "on" ]
then
	rm $thumbsdir/$chidnorm.png
	rm $save.frz
	mv $save.png $thumbsdir
fi


if [ "$savexmlbase" = "$savexml" ]
then
	rm $xmldir/$chidbase*
fi

rm $savexmlbase
mv $savexmltmp $savexml
rm $save

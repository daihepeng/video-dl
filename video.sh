#!/bin/bash
# Video download script v3.1
# Created by Daniil Gentili (http://daniil.it)
# This program is licensed under the GPLv3 license.
# Changelog:
# v1 (and revisions): initial version.
# v2 (and revisions): added support for Rai Replay, support for multiple qualities, advanced video info and custom API server.
# v3 (and revisions): added support for Mediaset, Witty TV, La7, etc..
# v3.1 Included built in API engine, bug fixes
# v3.2 Added support for youtube and https

echo "This program is licensed under the GPLv3 license."
help() {
echo "Video download script
Created by Daniil Gentili
Supported websites: $(wget -q -O - http://api.daniil.it/?p=websites)
Usage: $(basename $0) [ -qabf --player=player ] [ URLS.TXT URLS2.TXT ] URL URL2 URL3 ...

Options:

-q		Quiet mode: useful for crontab jobs, automatically enables -a.

-a		Automatic mode: automatically download the video in the maximum quality.

-b		Uses built-in API engine: requires additional programs and may not work properly on some systems, may be faster than the API server.

-f		Reads URL(s) from specified text file(s). If specified, you cannot provide URLs as arguments.

--player=player	Play the video instead of downloading it using specified player, mplayer if none specified.

--help		Show this extremely helpful message.

"
exit
}
[ "$1" = "--help" ] && help
[ "$*" = "" ] && echo "No url specified." && help

lineclear() { echo -en "\r\033[K"; }

##### Self updating section #####
echo -n "Self-updating script..." && dl http://daniilgentili.magix.net/video.sh $0 $Q 2>/dev/null;chmod 755 $0 2>/dev/null; lineclear

##### Tools detection and selection #####
which smooth.sh &>/dev/null && smoothsh=y || smoothsh=n

which ffmpeg &>/dev/null && ffmpeg=y || ffmpeg=n

which wget &>/dev/null && {
dl() {
wget "$1" -O $2 $3
}
Q="-q"
} || {
dl() {
curl "$1" -o $2 $3
}
Q="-s"
}

##### URL format detection #####

urlformatcheck() {
case $urlformat in
  smooth\ streaming)
    queue="$queue
`[ "$smoothsh" = "y" ] && echo "smooth.sh \\"$url\\" \\"$title.mkv\\"" || echo "echo \"Manifest URL: $url\""`
    "
    ;;
  apple\ streaming)
    queue="$queue
`[ "$ffmpeg" = "y" ] && echo "ffmpeg -i \\"$url\\" -c copy \\"$title.mkv\\"" || echo "echo \"URL: $url\""`
    "
    ;;
  *)
    
    queue="$queue
dl \"$url\" $title.$ext $WOPT
    "
    ;;
esac
}
##### Default API #####

api() { dl "http://api.daniil.it/?url=$sane" - $Q; }

##### Option detection ##### 

while getopts qabf FLAG; do
case "$FLAG" in
  b)
    echo -n "Downloading latest version of the API engine..." && eval "$(dl http://daniil.magix.net/api.sh - $Q)" && lineclear && declare -f | grep -q replaytv || {
echo "Couldn't download the API engine, using built-in (maybe outdated) engine..." 
api() {
####################################################
####### Beginning of URL recognition section #######
####################################################

dl="$(echo "$1" | grep -q '^//' && echo http:$1 || echo $1)"

dl="$(echo "$dl" | sed 's/#.*//;s/https:\/\//http:\/\//g')"

urltype="$(curl -w "%{url_effective}\n" -L -s -I -S "$dl" -o /dev/null)"

echo "$urltype" | grep -qE 'http://www.*.rai..*/dl/RaiTV/programmi/media/.*|http://www.*.rai..*/dl/RaiTV/tematiche/*|http://www.*.rai..*/dl/.*PublishingBlock-.*|http://www.*.rai..*/dl/replaytv/replaytv.html.*|http://.*.rai.it/.*|http://www.rainews.it/dl/rainews/.*|http://mediapolisvod.rai.it/.*|http://*.akamaihd.net/*|http://www.video.mediaset.it/video/.*|http://www.video.mediaset.it/player/playerIFrame.*|http://.*wittytv.it/.*|http://la7.it/.*|http://.*.la7.it/.*|http://la7.tv/.*|http://.*.la7.tv/.*|http://.*vk.com/.*' || ptype=common

echo "$urltype" | grep -qE 'http://www.*.rai..*/dl/RaiTV/programmi/media/.*|http://www.*.rai..*/dl/RaiTV/tematiche/*|http://www.*.rai..*/dl/.*PublishingBlock-.*|http://www.*.rai..*/dl/replaytv/replaytv.html.*|http://.*.rai.it/.*|http://www.rainews.it/dl/rainews/.*|http://mediapolisvod.rai.it/.*|http://*.akamaihd.net/*' && ptype=rai


echo "$urltype" | grep -qE 'http://www.video.mediaset.it/video/.*|http://www.video.mediaset.it/player/playerIFrame.*' && ptype=mediaset

echo "$urltype" | grep -q 'http://.*wittytv.it/.*' && ptype=mediaset && witty=y

echo "$urltype" | grep -qE 'http://la7.it/.*|http://.*.la7.it/.*|http://la7.tv/.*|http://.*.la7.tv/.*' && ptype=lasette

echo "$urltype" | grep -q 'http.*://.*vk.com/.*' && ptype=vk

echo "$urltype" | grep -q 'http.*://.*mail.ru/.*' && ptype=mail


##############################################################################
####### End of URL recognition section, beginning of Functions section #######
##############################################################################

# Declare javascript variable

var() {
eval $*
}
# Get video information

getsize() {

info="($(echo "$(echo $a | sed "s/.*\.//;s/[^a-z|0-9].*//"), $(wget -S --spider $a 2>&1 | grep -E '^Length|^Lunghezza' | sed 's/.*(//;s/).*//')B, $(mplayer -vo null -ao null -identify -frames 0 $a 2>/dev/null | grep kbps | awk '{print $3}')" |
sed 's/\
//g;s/^, //g;s/, B,//g;s/, ,/,/g;s/^B,//g;s/, $//;s/ $//g'))"

}


# Check if URL exists and remove copies of the same URL

function checkurl() {
tbase="$(echo $base | sed 's/ /%20/g;s/%20http:\/\//\
http:\/\//g;s/%20$//' | awk '!x[$0]++')"

base=
for u in $tbase;do wget -S --tries=3 --spider $u 2>&1 | grep -q 'HTTP/1.1 200 OK' && base="$base
$u"; done
}


# Nicely format input

formatoutput() {

case $ptype in
  rai)
    {
four="$(echo "$unformatted" | grep .*_400.mp4)"
six="$(echo "$unformatted" | grep .*_600.mp4)"
eight="$(echo "$unformatted" | grep .*_800.mp4)"
twelve="$(echo "$unformatted" | grep .*_1200.mp4)"
fifteen="$(echo "$unformatted" | grep .*_1500.mp4)"
eighteen="$(echo "$unformatted" | grep .*_1800.mp4)"
normal="$(echo "$unformatted" | grep -v .*_400.mp4 | grep -v .*_600.mp4 | grep -v .*_800.mp4 | grep -v .*_1200.mp4 | grep -v .*_1500.mp4 | grep -v .*_1800.mp4)"
    }
    ;;
  mediaset)
    {
mp4="$(echo "$unformatted" | grep ".mp4")"
smooth="$(echo "$unformatted" | grep -v "pl)" | grep "est")"
apple="$(echo "$unformatted" | grep "pl)")"
wmv="$(echo "$unformatted" | grep ".wmv")"
flv="$(echo "$unformatted" | grep ".flv")"
f4v="$(echo "$unformatted" | grep ".f4v")"
    }
    ;;
  lasette)
    lamp4="$(echo "$unformatted" | grep -v master | grep -v manifest | grep ".mp4")"
    ;;
  common)
    common="$unformatted"
    ;;
esac


formats="$(
[ "$common" != "" ] && for a in $common; do getsize
 info="$(echo "$info" | sed 's/[(]//;s/[)]//')"

 echo "$info $a";done

[ "$lamp4" != "" ] && for a in $lamp4; do getsize

 echo "$info $a";done

[ "$normal" != "" ] && for a in $normal; do getsize

 echo "Normal quality $info $a";done

[ "$eighteen" != "" ] && for a in $eighteen; do getsize

 echo "Maximum quality $info $a";done


[ "$fifteen" != "" ] && for a in $fifteen; do getsize

 echo "Medium-high quality $info $a";done



[ "$twelve" != "" ] && for a in $twelve; do getsize

 echo "Medium quality $info $a";done

[ "$eight" != "" ] && for a in $eight; do getsize

 echo "Medium-low quality $info $a";done


[ "$six" != "" ] && for a in $six; do getsize
 
 echo "Low quality $info $a";done



[ "$four" != "" ] && for a in $four; do getsize
 echo "Minimum quality $info $a";done



[ "$smooth" != "" ] && for a in $smooth; do echo "High quality (smooth streaming) $a";done


[ "$mp4" != "" ] && for a in $mp4; do getsize
 echo "Medium-high quality $info $a";done



[ "$apple" != "" ] && for a in $apple; do echo "Medium-low quality  (apple streaming, pseudo-m3u8) $a";done


[ "$wmv" != "" ] && for a in $wmv; do getsize

 echo "Low quality $info $a";done


[ "$flv" != "" ] && for a in $flv; do getsize

 echo "Low quality $info $a";done


[ "$f4v" != "" ] && for a in $f4v; do getsize

 echo "Low quality $info $a";done



)"

formats="$(echo "$formats" | awk '!x[$0]++' | awk '{print $(NF-1), $0}' | sort -g | cut -d' ' -f2-)"



}



# Rai website 

rai_normal() {

# iframe check
echo "$file" | grep -q videoURL || { eval $(echo "$file" | grep 'content="ContentItem' | cut -d" " -f2) && file="$(wget http://www.rai.it/dl/RaiTV/programmi/media/"$content".html -qO-)"; }

# read and declare videoURL variables from javascript in page

eval "$(echo "$file" | grep videoURL | sed "s/var//g" | tr -d '[[:space:]]')"

# read and declare title variable from javascript in page
$(echo "$file" | grep videoTitolo)
}

# Rai replay function

replay() {
# Get the video id
v=$(echo $1 | sed 's/.*v=//;s/\&.*//')

# Get the day
day=$(echo $1 | sed 's/.*?day=//;s/\&.*//;s/-/_/g')

# Get the channel
case $(echo $1 | sed 's/.*ch=//;s/\&.*//') in
  1)
    ch=RaiUno
    ;;
  2)
    ch=RaiDue
    ;;
  3)
    ch=RaiTre
    ;;
  31)
    ch=RaiCinque
    ;;
  32)
    ch=RaiPremium
    ;;
  23)
    ch=RaiGulp
    ;;
  38)
    ch=RaiYoyo
    ;;
esac

# Get the json
tmpjson="$(wget http://www.rai.it/dl/portale/html/palinsesti/replaytv/static/"$ch"_$day.html -qO-)"

# Keep only section with correct video id and make it grepable
json="$(

echo "$tmpjson" | sed '/'$v'/,//d;s/\,/\
/g;s/\"/\
/g;s/\\//g' | tac | awk "flag != 1; /\}/ { flag = 1 }; " | tac


)"

# Get the relinkers
replay=$(echo "$json" | grep mediapolis | sort | awk '!x[$0]++')

# Get the title
videoTitolo=$(echo "$json" | grep -A 2 '^t$' | awk 'END{print}')


}


# Relinker function



function relinker_rai() {
# Resolve relinker


for f in $(echo $* | awk '{ while(++i<=NF) printf (!a[$i]++) ? $i FS : ""; i=split("",a); print "" }'); do
 
 dl=$(echo $f | grep -q http: && echo $f || echo http:$f)

 # 1st method

 url="$(wget -qO- "$dl&output=25")
$(wget "$dl&output=43" -q -O -)"
 
 [ "$url" != "" ] && tempbase=$(echo "$url" | sed 's/[>]/\
/g;s/[<]/\
/g' | grep '.*\.mp4\|.*\.wmv\|.*\.mov')
 
 base="$(echo "$tempbase"  | sed 's/\.mp4.*/\.mp4/;s/\.wmv.*/\.wmv/;s/\.mov.*/\.mov/')" && checkurl


 # 2nd method

 [ "$base" = "" ] && {
base="$(eval echo "$(for f in $(echo "$tempbase" | grep ","); do number="$(echo "$f" | sed 's/http\:\/\///g;s/\/.*//;s/[^0-9]//g')"; echo "$f" | sed 's/.*Italy/Italy/;s/^/http\:\/\/creativemedia'$number'\.rai\.it\//;s/,/{/;s/,\./}\./;s/\.mp4.*/\.mp4/'; done)")" && checkurl
 }
 

 # 3rd and 4th method
 [ "$base" = "" ] && {
url="$(wget "$dl&output=4" -q -O -)"
[ "$url" != "" ] && echo "$url" | grep -q creativemedia && base="$url" || base=$(curl -w "%{url_effective}\n" -L -s -I -S $dl -A "" -o /dev/null); checkurl
 }


 #[ "$base" = "" ] && base="$(curl -w "%{url_effective}\n" -L -s -I -S "$dl" -o /dev/null -A='')" && checkurl 


 TMPURLS="$TMPURLS
$base"

done

# Remove copies of the same url
base="$(echo $TMPURLS | sort | awk '!x[$0]++')"

# Find all qualities in every video
tbase=
for t in _400.mp4 _600.mp4 _800.mp4 _1200.mp4 _1500.mp4 _1800.mp4 .mp4; do for i in _400.mp4 _600.mp4 _800.mp4 _1200.mp4 _1500.mp4 _1800.mp4; do tbase="$tbase
$(echo "$base" | sed "s/$t/$i/")"; tbase="$(echo "$tbase" | awk '!x[$0]++')"; done;done


base="$tbase"

checkurl

unformatted="$base"
formatoutput


}

###########################################################################################
################## End of Rai relinker section, beginning of Rai section ##################
###########################################################################################


function rai() {

# Store the page in a variable
file=$(wget $1 -q -O -)

# Rai replay or normal rai website choice
echo $1 | grep -q http://www.*.rai..*/dl/replaytv/replaytv.html.* && replay $1 || rai_normal $1

title="${videoTitolo//[^a-zA-Z0-9 ]/}"
title=`echo $title | tr -s " "`
title=${title// /_}

# Resolve relinkers
relinker_rai $videoURL_M3U8 $videoURL_MP4 $videoURL_H264 $videoURL_WMV $videoURL $replay
}


###########################################################################################
##################### End of Rai section, beginning of Lasette section ####################
###########################################################################################


lasette() {
# Store the page in a variable
page="$(wget $1 -q -O -)"

# Get the javascript with the URLs
URLS="$(wget -q -O - $(echo "$page" | grep starter | sed 's/.*src\=\"//;s/\".*//') | grep -E 'src:.*|src_.*' | sed 's/.*\: \"//;s/\".*//')"

# Get the title
videoTitolo="$(echo $page | sed 's/.*<title>//;s/<\/title>.*//' | sed 's/^ //')"

title="${videoTitolo//[^a-zA-Z0-9 ]/}"
title=`echo $title | tr -s " "`
title=${title// /_}

unformatted="$URLS"
formatoutput


}



###########################################################################################
################## End of Lasette section, beginning of Mediaset section ##################
###########################################################################################



mediaset() {
# Store the page in a variable
page=$(wget $1 -q -O -)

# Witty tv recongition
[ "$witty" = "y" ] && {
# Get the video id
id=$(echo "$page" | grep '\<iframe id=\"playeriframe\" src=\"http\:\/\/www.video.mediaset.it\/player\/playerIFrame.shtml?id\=' | sed 's/.*\<iframe id=\"playeriframe\" src=\"http\:\/\/www.video.mediaset.it\/player\/playerIFrame.shtml?id\=//;s/\&.*//')

# Get the title
videoTitolo=$(echo "$page" | grep -o "<meta content=\".*\" property=\".*title\"/>" | sed 's/.*\<meta content\=\"//;s/\".*//g')

} || {
eval $(echo "$page" | grep "var videoMetadataId" | sed 's/var //' | tr -d '[[:space:]]')
id="$videoMetadataId"
videoTitolo=$(echo "$page" | grep -o "<meta content=\".*\" name=\"title\"/>" | sed 's/.*\<meta content\=\"//;s/\".*//g')

}

title="${videoTitolo//[^a-zA-Z0-9 ]/}"
title=`echo $title | tr -s " "`
title=${title// /_}

# Get the video URLs using the video id
URLS="$(wget "http://cdnselector.xuniplay.fdnames.com/GetCDN.aspx?streamid=$id" -O - -q -U="" | sed 's/</\
&/g' | grep http:// | sed 's/.*src=\"//;s/\".*//' |  sed '/^\s*$/d')"


unformatted="$URLS"
formatoutput

}


###########################################################################################
##################### End of Mediaset section, beginning of common section ################
###########################################################################################


common() {
# Store the page in a variable
page="$(wget -q -O - $1)"

# Get the video URLs
URLS="$(echo "$page" | egrep '\.mp4|\.mkv|\.flv|\.f4v|\.wmv|\.mov|\.3gp|\.avi|\.m4v|\.mpg|\.mpe|\.mpeg' | sed 's/.*http:\/\//http:\/\//;s/\".*//' | sed "s/'.*//" | sed 's/.mp4.*/.mp4/g;s/.mkv.*/.mkv/g;s/.flv.*/.flv/g;s/.f4v.*/.f4v/g;s/.wmv.*/.wmv/g;s/.mov.*/.mov/g;s/.3gp.*/.3gp/g;s/.avi.*/.avi/g;s/.m4v.*/.m4v/g;s/.mpg.*/.mpg/g;s/.mpe.*/.mpe/g;s/.mpeg.*/.mpeg/g' | awk '!x[$0]++')"


[ "$URLS" = "" ] && exit

# Get the title
videoTitolo="$(echo $page | sed 's/.*<title>//;s/<\/title>.*//' | sed 's/^ //')"


title="${videoTitolo//[^a-zA-Z0-9 ]/}"
title=`echo $title | tr -s " "`
title=${title// /_}

unformatted="$URLS"
formatoutput


}
$ptype $dl $2 $3
[ "$formats" = "" ] && exit || echo "$title $videoTitolo
$formats"
}

    }
    ;;
  q)
    WOPT="$Q" && A=y
    ;;
  a)
    A=y
    ;;
  f)
    F=y
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
esac
done

shift $((OPTIND-1))

##### Player option detection and choice #####

echo "$1" | grep -q "\--player" && player=$(echo "$1" | sed 's/ .*//;s/.*--player\=//') && play=y && shift


[ "$player" = "" ] && player=mplayer

[ "$play" = y ] && dlvideo() {
queue="$queue
$player $url
"
} || dlvideo() {
urlformatcheck
}
[ "$F" = "y" ] && URL="$(cat "$*")" || URL="$*"

##### To be automatic or to be selected by the user, that is the question. #####

[ "$A" = "y" ] && dlcmd() {
url="$(echo "$api" | awk 'END {print $NF}')"
ext=$(echo "$api" | awk 'END {print $NF}' | sed 's/.*[(]//g;s/, .*//g')
dlvideo
} || {
echo "Video(s) info:" &&
dlcmd() {
videoTitolo=$(echo "$titles" | cut -d' ' -f2- | sed 's/è/e/g;s/é/e/g;s/ì/i/g;s/í/i/g;s/ù/u/g;s/ú/u/g')

max="$(echo "$api" | awk 'END{print}' | grep -Eo '^[^ ]+')"

echo "Title: $videoTitolo

$(echo "$api" | sed 's/http:\/\/.*//g;s/https:\/\/.*//g')

"

until [ "$l" -le "$max" ] && [ "$l" -gt 0 ] ; do echo -n "What quality do you whish to download (number, enter q to skip this video)? "; read l; [ "$l" = "q" ] && break;done 2>/dev/null

[ "$l" = "q" ] && continue

selection=$(echo "$api" | sed "$l!d")

urlformat=$(echo "$selection" | sed 's/http:\/\/.*//;s/https:\/\/.*//g;s/.*[(]//;s/[)].*//')

url=$(echo "$selection" | awk 'NF>1{print $NF}')

ext=$(echo "$selection" | sed 's/.*[(]//g;s/, .*//g')
dlvideo
}
}


for u in $URL; do
 sane="$(echo "$u" | sed 's/#.*//;s/\&/%26/g;s/\=/%3D/g;s/\:/%3A/g;s/\//%2F/g;s/\?/%3F/g')"

 api="$(api "$u" | sed '/^\s*$/d')"


 [ "$api" = "" ] && echo "Couldn't download $u." && continue
 titles=$(echo "$api" | sed -n 1p)
 api=$(echo "$api" | sed '1d' | awk '{print NR, $0}')
 title=$(echo "$titles" | cut -d \  -f 1)

 dlcmd
done


[ "$queue" != "" ] && { 
[ "$play" != "y" ] && { echo "Downloading videos..." && eval "$queue" && echo "All downloads completed successfully."; } || { [ "$play" = "y" ] && eval $queue; }
} || { echo "ERROR: download list is empty."; exit 1; }

exit

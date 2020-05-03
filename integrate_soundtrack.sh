#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 directory [output_file]" >&2
    exit 1
fi

# base_dir should contain deskshare.webm and webcam.webm
base_dir=$1
video_webcam="$base_dir/webcams.webm"
video_slides="$base_dir/deskshare.webm"

if [ ! -e "$video_webcam" ];then
    echo "$video_webcam does not exit !" >&2
    exit 1
fi

if [ ! -e "$video_slides" ];then
    echo "$video_slides does not exit !" >&2
    exit 1
fi

logfile=bbb_downloader.log
output_webm="$base_dir/output.webm"
if [ $# -eq 2 ]; then
    output_webm=$2
fi

output_audio="$base_dir/output.opus"

rm -f "$output" "$output_audio"  2>/dev/null
echo "# Extracting sound from $video_webcam to $output_audio" |tee -a "$logfile"
echo "# running ffmpeg -i "$video_webcam" -vn -acodec copy "$output_audio" " |tee -a "$logfile"
if ! ffmpeg -i "$video_webcam" -vn -acodec copy "$output_audio" 2>>  "$logfile" ; then
    echo "Failed !" >&2
    exit 1
fi


echo "# Merging video ($video_slides) and audio ($output_audio) into $output_webm" |tee -a "$logfile"
echo "# Running ffmpeg -i "$video_slides" -i "$output_audio" -map 0:v -map 1:a -c copy -y "$output_webm" "|tee -a "$logfile"
if ! ffmpeg -i "$video_slides" -i "$output_audio" -map 0:v -map 1:a -c copy -y "$output_webm" 2>>  "$logfile" ; then
    echo "Failed !" >&2
    exit 1
fi

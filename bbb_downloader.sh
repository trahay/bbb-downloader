#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 URL [output_file]" >&2
    exit 1
fi

url=$1
logfile=bbb_downloader.log
output_webm=output.webm
if [ $# -eq 2 ]; then
    output_webm=$2
fi

# The URL has the following form:
# https://bbb.some.where/playback/presentation/2.0/playback.html?meetingId=xxx-yyy

# The videos are located in https://bbb.some.where/presentation/xxx-yyy/
meeting_id=$(echo $url|awk -F= '{print $NF}')
url_root=$(echo $url |awk 'BEGIN{FS=OFS="/"}{NF-=4; print}')
base_url="$url_root/presentation/$meeting_id"

echo "# Downloading $base_url/deskshare/deskshare.webm" |tee "$logfile"
if ! wget "$base_url/deskshare/deskshare.webm" 2>> "$logfile"; then
    echo "# Failed to download $base_url/deskshare/deskshare.webm" | tee -a "$logfile"
    exit 1
fi

echo "# Downloading $base_url/video/webcams.webm" |tee -a "$logfile"
if ! wget "$base_url/video/webcams.webm" 2>> "$logfile" ; then
    echo "# Failed to download $base_url/video/webcams.webm" |tee -a "$logfile"
    exit 1
fi

video_webcam=webcams.webm
video_slides=deskshare.webm
output_audio=output.opus

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

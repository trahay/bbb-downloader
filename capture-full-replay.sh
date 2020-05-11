#!/bin/bash

# progress_bar.sh copied from https://github.com/nachoparker/progress_bar.sh
. progress_bar.sh

# This will capture the replay, played in a controlled web browser,
# using a Docker container running Selenium

if [ $# -lt 1 ]; then
    echo "Usage: $0 URL [duration]" >&2
    exit
fi

url=$1

video_id=$(python3 bbb.py id "$url")

if [ $# -eq 2 ]; then
    seconds=$2
else
    # Extract duration from associate metadata file
    #seconds=$(python3 bbb.py duration "$url")
    python3 ./download_bbb_data.py "$url" "$video_id"
    seconds=$(ffprobe -i $video_id/Videos/webcams.webm -show_entries format=duration -v quiet -of csv="p=0")
    seconds=$( echo "($seconds+0.5)/1" | bc )
    if [ $? -ne 0 ]; then
	# bbb.py failed because of a wrong url
	exit 1
    fi
fi

# Add some delay for selenium to complete
seconds=$(expr $seconds + 3)

container_name=grid$$

# Startup Selenium server
#  -e VIDEO_FILE_EXTENSION="mkv" \
    #  -p 5920:25900 : we don't need to connect via VNC
docker run --rm -d --name=$container_name -P --expose 24444 \
  --shm-size=2g -e VNC_PASSWORD=hola \
  -e VIDEO=true -e AUDIO=true \
  -e SCREEN_WIDTH=1080 -e SCREEN_HEIGHT=720 \
  -e FFMPEG_DRAW_MOUSE=0 \
  -e FFMPEG_FRAME_RATE=24 \
  -e FFMPEG_CODEC_ARGS="-vcodec libx264 -preset ultrafast -pix_fmt yuv420p -strict -2 -acodec aac" \
  elgalu/selenium

bound_port=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "24444/tcp") 0).HostPort}}' $container_name)

docker exec $container_name wait_all_done 30s

echo 
echo "Please wait for $seconds seconds, while we capture the playback..."
echo

# Run selenium to capture video
node selenium-play-bbb-recording.js "$url" $seconds $bound_port &

sleep 10
progress_bar $(echo "$seconds - 10" | bc)

# Save the captured video
docker exec $container_name stop-video

output_dir=$(mktemp -d)

docker cp $container_name:/videos/. $output_dir
docker stop $container_name

captured_video=$(ls -1 $output_dir/*.mp4)
mv $captured_video $video_id.mp4
rm -fr $output_dir

echo
echo "DONE. Your video is ready in $video_id.mp4"

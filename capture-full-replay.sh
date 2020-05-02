#!/bin/bash

# This will capture the replay, played in a controlled web browser,
# using a Docker container running Selenium

if [ $# -ne 1 ]; then
    echo "Need a replay URL as argument" >&2
    exit
fi

url=$1

# Extract duration from associate metadata file
seconds=$(python3 bbb.py duration "$url")

# Add some delay for selenium to complete
seconds=$(expr $seconds + 3)

# Startup Selenium server
#  -e VIDEO_FILE_EXTENSION="mkv" \
docker run --rm -d --name=grid -p 4444:24444 -p 5920:25900 \
  --shm-size=2g -e VNC_PASSWORD=hola \
  -e VIDEO=true -e AUDIO=true \
  -e SCREEN_WIDTH=1080 -e SCREEN_HEIGHT=720 \
  -e FFMPEG_DRAW_MOUSE=0 \
  -e FFMPEG_FRAME_RATE=24 \
  -e FFMPEG_CODEC_ARGS="-vcodec libx264 -preset ultrafast -pix_fmt yuv420p -strict -2 -acodec aac" \
  elgalu/selenium

docker exec grid wait_all_done 30s

echo 
echo "Please wait for $seconds seconds, while we capture the playback..."
echo

# Run selenium to capture video
node selenium-play-bbb-recording.js "$url" $seconds

# Save the captured video
docker exec grid stop-video
docker cp grid:/videos/. videos
docker stop grid

echo
echo "DONE. Your video should be in 'video/'"

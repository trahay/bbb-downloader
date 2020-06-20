#!/bin/bash

scriptdir=$(dirname $(realpath $0))

# progress_bar.sh copied from https://github.com/nachoparker/progress_bar.sh
. $scriptdir/progress_bar.sh

# This will capture the replay, played in a controlled web browser,
# using a Docker container running Selenium

usage()
{
cat << EOF
usage: $0 [options] URL

OPTIONS:
   -?                               Show this message
   -s startup_duration              Remove the first startup_duration seconds of the video
   -e stop_duration                 Cut the video after stop_duration (from the start of the input video)
   -m   	       	            Only show the main screen (ie. remove the webcam)
   -c 				    Don't crop the output video
   -o output_file		    Select the output file
   -s 				    Save all the downloaded videos
EOF
}


startup_duration=5 # duration of firefox startup (that will be cut out of the video)
stop_duration=0
main_screen_only=n
crop=y
output_file=""
save=n
while getopts 's:e:mco:s' OPTION; do
    case $OPTION in
	s)
	    startup_duration=$OPTARG
	    ;;
	e)
	    stop_duration=$OPTARG
	    ;;
	m)
	    main_screen_only=y
	    ;;
	c)
	    crop=n
	    ;;
	o)
	    output_file=$OPTARG
	    ;;
	s)
	    save=y
	    ;;
	?)	usage
	exit 2
	;;
    esac
done


# remove the options from the command line
shift $(($OPTIND - 1))
if [ $# -lt 1 ]; then
    usage
    exit 2
fi

url=$1

video_id=$(python3 bbb.py id "$url")

if [ -z $output_file ]; then
    output_file=$video_id.mp4
fi

if [ $# -eq 2 ]; then
    seconds=$2
else
    # Extract duration from associate metadata file
    #seconds=$(python3 bbb.py duration "$url")
    python3 ./download_bbb_data.py -V "$url" "$video_id"
    seconds=$(ffprobe -i $video_id/Videos/webcams.webm -show_entries format=duration -v quiet -of csv="p=0")
    seconds=$( echo "($seconds+0.5)/1" | bc )
    if [ $? -ne 0 ]; then
	# bbb.py failed because of a wrong url
	exit 1
    fi
fi

# Add some delay for selenium to complete
seconds=$(expr $seconds + 5)

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

# First wait for making sure the playback is started
sleep 10

# Now wait for the duration of the recording, for the capture to happen

# Instead of waiting without any feedback to the user with a simple
# "sleep", we use the progress bar script.
# Use plain "sleep" if on MacOSX or other cases where progress_bar won't do.
#sleep $(echo "$seconds - 10" | bc)
progress_bar $(echo "$seconds - 10" | bc)

# Save the captured video
docker exec $container_name stop-video

output_dir=$(mktemp -d)

docker cp $container_name:/videos/. $output_dir/
docker stop $container_name

captured_video=$(ls -1 $output_dir/*.mp4)

if [ "$crop" = "y" ]; then
    if [ "$main_screen_only" = y ]; then
	OPTIONS=-m
    else
	OPTIONS=""
    fi
    . crop_video.sh -s "$startup_duration" -e "$stop_duration" $OPTIONS $captured_video $output_file
else
    mv $captured_video $output_file
fi
rm -fr $output_dir

if [ "$save" = n ]; then
    rm -r $video_id
fi

echo
echo "DONE. Your video is ready in $output_file"

#!/bin/bash


if [ $# -ne 2 ]; then
    echo "Usage: $0 input_file output_file" >&2
    exit 1
fi

input=$1
output=$2

video_size=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 $input )
height=$(echo $video_size |awk -Fx '{print $2}')
width=$(echo $video_size |awk -Fx '{print $1}')

echo "height=$height, width=$width"

upper_window=144 # height of the upper part of the firefox window
lower_window=56 # height of the lower part of the firefox window

startup_duration=11 # duration of firefox startup (that will be cut out of the video)

#out_w is the width of the output rectangle
out_w=$width
#out_h is the height of the output rectangle
out_h=$(echo "$height - $upper_window - $lower_window"|bc)

#x and y specify the top left corner of the output rectangle
x=0
y=$upper_window


ffmpeg -ss $startup_duration -i "$input" -filter:v "crop=$out_w:$out_h:$x:$y" "$output"

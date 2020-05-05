#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 video_file" >&2
    exit 1
fi

input=$1

duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input")

# duration is something like 21.59100, we need to return an integer, so let's round up
upper_round=$(LANG=C printf "%.0f\n" "$(echo $duration + 0.5|bc )")

echo  $upper_round

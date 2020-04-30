#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 input [output]" >&2
    exit 1
fi

input=$1
if [ $# -eq 2 ]; then
    output=$2
else
    output=$(echo "$input"|sed 's/\.webm$/\.mp4/')
fi

echo "Transcoding $input into $output"
ffmpeg -i "$input" "$output"

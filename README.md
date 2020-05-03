# bbb-downloader
A few scripts for downloading BBB videos


## Downloading BBB data

To download BBB videos and slides, simply pass its URL to the `download_bbb_data.py`:
```
$ ./bbb_downloader.sh URL [output_file]
```

The script downloads the following files:

- `Videos/deskshare.webm`: contains the video of the deskshare

- `Videos/webcam.webm`: contains the video of the webcam with the recorded sound track

- `Slides/`: contains the slides

- `Thumbnails/`: contains the thumbnails


### Adding the sound track to the deskshare video


The recorded sound track is stored in the webcam video, and the
deskshare does not contain any sound. To integrate the sound track to
the deskshare video, run the `integrate_soundtrack.sh` script:

```./integrate_soundtrack.sh Videos [output_file]```


The script creates two files:

- `output.opus`: contains the recorded sound track extracted from `webcam.webm`

- output_file (by default: `output.webm`): contains the video of the deskshare with the sound track.


### Converting a video to MP4

By default, BBB records videos in the `webm` format. You can convert it using `webm_to_mp4.sh`:

```$ ./webm_to_mp4.sh output.webm output.mp4```

## Capturing the full playback with the elgalu/selenium Docker image

This will play the recording in a browser running inside a Docker
container, and will capture the video and sound of that browser windows.

See https://github.com/elgalu/docker-selenium for more details on the
docker image that pilots a web browser.

Assembled in a the run.sh script

1. npm install
2. bash capture-full-replay.sh URL

Wait until the full playback is done, and get the resulting MP4 video
in the 'videos/' subdir.

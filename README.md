# bbb-downloader
A few scripts for downloading BigBlueButton (BBB) recordings as
videos.

BBB allows recording sessions, and will allow replaying the recordings
in its Web playback page.

For recordings made for BBB's greenlight sessions, the playback page's
URL will typically look like
`https://bbb.example.com/playback/presentation/2.0/playback.html?meetingId=375240faa7265529b58e0efe9f5fe793-b8b2b763a50993de7dfd0`

The tools provided here will work with such a URL passed in argument.

## A note about the slides and video playback

A nice feature of BBB is the fact that, to present a slides deck, you
don’t need to share your screen (as a video stream), but just have to
upload your file, which is then auto-converted to *images*, that are
sent to participants, in sync with your next/previous browsing of the
slides.

This is great for an attendance with low bandwidth, which can receive
the slides (as “static” images) without problems, instead of having to
receive a much heavier full screen video stream.

But a side effect is that the playback of a recording, is
done by replaying the slides, just as it was done live: displaying
*images* one after the other.

While it is easy to retrieve the audio, webcams of participants, or
screen sharings as video streams, which are directly available from the
playback web app, it is thus not the same for the slides, which
don’t come directly as a video.

Let's first see the easiest tool `download_bbb_data.py`, which can be used to download
everything but slides, which may be your first option.

## Downloading already available recordings

First download and install python and required dependencies for it:
```
sudo apt update
sudo apt install python3 python3-pip
pip3 install -r python-requirements.txt
```

To download the videos and slides which are already available to view
in the BBB playback page, simply pass its URL to the
`download_bbb_data.py`:
```
$ ./download_bbb_data.py URL
```

The script downloads the following files:

- `Videos/deskshare.[webm|mp4]`: contains the video of the deskshare

- `Videos/webcam.[webm|mp4]`: contains the video of the webcam with the recorded sound track

- `Slides/`: contains the slides, downloaded as *images*

- `Thumbnails/`: contains the thumbnails


### Adding the sound track to the deskshare video

For this to work we need to install ffmpeg and bc:
```
sudo apt update
sudo apt install ffmpeg bc
```

The recorded sound track is stored in the webcam video, and the
deskshare does not contain any sound. To integrate the sound track to
the deskshare video, run the `integrate_soundtrack.sh` script:

```./integrate_soundtrack.sh Videos [output_file]```


The script creates two files:

- `output.opus`: contains the recorded sound track extracted from `webcam.webm`

- `output_file` (by default: `output.webm`): contains the video of the deskshare with the sound track.


### Selecting video format

For this to work we need to install ffmpeg and bc:
```
sudo apt update
sudo apt install ffmpeg bc
```

Depending on the configuration of your BBB instance, the recorded
videos will be available on the server directly in `mp4` or `webm`
format. By default, the script will try to download in webm format,
and tries to fallback to mp4 if webm is not available. You can select
the desired format with the `-f webm` or `-f mp4`
option. Unfortunately, there doesn't seem to be a way to auto-detect
which format is available on a prticular server.

In case you downloaded the webm and want mp4, you can convert it using
`webm_to_mp4.sh`:

```$ ./webm_to_mp4.sh output.webm output.mp4```


## Capturing the full playback with the elgalu/selenium Docker image

This is your next option, if you want to capture, in a single video,
the contents of the *slides* or *whiteboard* area of the playback.

This second tool will play the recording in a browser running inside a Docker
container, and will capture the video and sound of that browser window
(see https://github.com/elgalu/docker-selenium for more details on the
docker image that pilots the web browser).

The `capture-full-replay.sh` will require some tools (Docker, ffmpeg,
Python 3,...).

Install some dependencies, before launching it:
```
sudo apt update
sudo apt install bc ffmpeg docker.io python3 npm python3-pip docker.io
npm install
pip3 install -r python-requirements.txt
```
You're now ready to capture the replay of a recording, by issuing:

```
bash capture-full-replay.sh URL
```
where URL is the address of the playback page (see above).

Now, be patient. The execution takes a little bit more than the full
playback of the recording...

Wait until the full playback is done, and get the resulting MP4 video.

Its recommended (but not necessary) to pull the elgalu/selenium docker image before running the script for the first time:
```
docker pull elgalu/selenium:latest
```

More options are available with `./capture-full-replay.sh --help`

See this video for an explanation of how the tool works, and a demo:

[<img src="https://i.vimeocdn.com/video/895688106.jpg" width="50%">](https://player.vimeo.com/video/420302036)


### Cropping a captured video

By default, the script captures a firefox window that displays the BBB stream, you remove the firefox window  by cropping the video with `crop_video.sh`:

```
./crop_video.sh [OPTION] input.mp4 output.mp4
OPTIONS:
   -?                               Show this message
   -s startup_duration              Remove the first startup_duration seconds of the video
   -e stop_duration                 Cut the video after stop_duration (from the start of the input video)
   -m                               Only show the main screen (ie. remove the webcam)

```

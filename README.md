# bbb-downloader
A few scripts for downloading BBB videos


## Downloading a video

To download a BBB video, simply pass its URL to the bbb_downloader.sh script
```
$ ./bbb_downloader.sh URL [output_file]
```


It saves the video as `output_file` ( by default: `output.webm`)

## Converting a video to MP4

By default, BBB records videos in the `webm` format. You can convert it using `webm_to_mp4.sh`:

```$ ./webm_to_mp4.sh output.webm output.mp4```
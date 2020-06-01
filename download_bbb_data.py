#!/usr/bin/env python3
# coding: utf-8

import sys
import os
import bbb
import requests
import time
import numpy as np
import progressbar
import argparse
#import pprint

# Borrowed from https://stackoverflow.com/a/37574635 adjusting the buffer size to 10Mb
def download_file(url, filename, n_chunk=1):
    r = requests.get(url, stream=True)
    # Estimates the number of bar updates
    block_size = 10*1024*1024
    content_length = r.headers.get('Content-Length', None)
    if r.status_code != 404 :
        file_size = int(content_length)
        num_bars = np.ceil(file_size / (n_chunk * block_size))
        bar =  progressbar.ProgressBar(maxval=num_bars).start()
        with open(filename, 'wb') as f:
            for i, chunk in enumerate(r.iter_content(chunk_size=n_chunk * block_size)):
                f.write(chunk)
                bar.update(i+1)
                # Add a little sleep so you can see the bar progress
                time.sleep(0.05)
        print("")
    return r.status_code


if __name__ == '__main__' :
    download_slides = False
    download_videos = False
    download_thumbnails = False
    
    parser = argparse.ArgumentParser()
    parser.add_argument('url', 
                        help='the URL of a BBB recording replay page')
    parser.add_argument('-s', '--slides', action='store_true',
                        help='download only slides')
    parser.add_argument('-V', '--videos', action='store_true',
                        help='download only videos')
    parser.add_argument('-t', '--thumbnails', action='store_true',
                        help='download only thumbnails')
    parser.add_argument('output_dir', nargs='?',
                        help='output dir')
    args = parser.parse_args()
    url = args.url

    if args.slides:
        download_slides = True

    if args.videos:
        download_videos = True

    if args.thumbnails:
        download_thumbnails = True

    if not (args.slides or args.videos or args.thumbnails):
        download_slides = True
        download_videos = True
        download_thumbnails = True

    extractor = bbb.BigBlueButtonExtractor()
    extractor._real_extract(url)

    website=getattr(extractor, "website")
    meeting_id=getattr(extractor, "id")

    if args.output_dir :
        output_dir=args.output_dir+"/"
    else :
        os.makedirs(meeting_id, exist_ok=True)
        os.chdir(meeting_id)
        output_dir="./"

    output_slides_dir=output_dir+"/Slides/"
    output_thumbnails_dir=output_dir+"/Thumbnails/"
    output_videos_dir=output_dir+"/Videos/"

    if download_slides:
        # download slides in Slides
        print("Downloading Slides")
        i=1
        os.makedirs(output_slides_dir, exist_ok=True)
        for slide in extractor.slides:
            print("["+str(i)+"/"+str(len(extractor.slides))+"]  "+slide)
            i=i+1

            slide_url=website + "/presentation/"+meeting_id+"/"+slide
            slide_name=output_slides_dir+slide.split('/')[-1]

            r = requests.get(slide_url)
            open(slide_name , 'wb').write(r.content)

    if download_thumbnails:
        # download thummbnails in Thumbnails
        print("Downloading Thumbnails")
        i=1
        os.makedirs(output_thumbnails_dir, exist_ok=True)
        for thumbnail in extractor.thumbnails:
            print("["+str(i)+"/"+str(len(extractor.thumbnails))+"]  "+thumbnail['url'])
            i=i+1

            thumbnail_name=output_thumbnails_dir+thumbnail['url'].split('/')[-1]
            r = requests.get(thumbnail['url'])
            open(thumbnail_name , 'wb').write(r.content)

    if download_videos:
        # download videos in Videos
        print("Downloading Videos")
        i=1
        os.makedirs(output_videos_dir, exist_ok=True)
        for formats in extractor.formats:
            video_name=output_videos_dir+formats['url'].split('/')[-1]

            status_code = download_file(formats['url'], video_name)
            if status_code != 404 :
                print("["+str(i)+"/"+str(len(extractor.formats))+"]  saved '"+formats['format_id']+ "' ("+formats['url']+").")
            else :
                print("["+str(i)+"/"+str(len(extractor.formats))+"]  no '" + formats['format_id'] + "' recording could be found at " + formats['url'] + " (" + str(status_code) + ").")

            i += 1
        
    print("Everyting was downloaded into '" + meeting_id + "/'.")

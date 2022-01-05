#!/usr/bin/env python3
# coding: utf-8

# This file originally contributed by Olivier Berger <olivier.berger@telecom-sudparis.eu> for youtube-dl, and adapted for our needs

# BigBlueButton records multiple videos :
#  - webcams feed : sound & webcam views : useful for extracting sound
#  - deskshare captures : screensharing, but not the slides

# For slides, annotations, polls and other stuff displayed to the
# audience the playback app typically renders them on the fly upon
# playback (SVG) so it may not be easy to capture that with youtube-dl

from __future__ import unicode_literals

import sys
import re
import urllib
import urllib.request
import xml.etree.ElementTree as ET
from pprint import pprint

import time
from datetime import datetime, timedelta, timezone

#        import pytz

# from .common import InfoExtractor

# from ..utils import (
#     xpath_text,
#     xpath_with_ns,
# )

def xpath_with_ns(path, ns_map):
    components = [c.split(':') for c in path.split('/')]
    replaced = []
    for c in components:
        if len(c) == 1:
            replaced.append(c[0])
        else:
            ns, tag = c
            replaced.append('{%s}%s' % (ns_map[ns], tag))
    return '/'.join(replaced)

_s = lambda p: xpath_with_ns(p, {'svg': 'http://www.w3.org/2000/svg'})
_x = lambda p: xpath_with_ns(p, {'xlink': 'http://www.w3.org/1999/xlink'})


class BigBlueButtonExtractor:
    _VALID_URL = r'(?P<website>https?://[^/]+)/playback/presentation/(?P<version>[0-9.]+)/playback.html\?meetingId=(?P<id>[0-9a-f\-]+)'
    _VALID_URL2 = r'(?P<website>https?://[^/]+)/playback/presentation/(?P<version>[0-9.]+)/(?P<id>[0-9a-f\-]+).*'

    _TIMESTAMP_UNIT = 30000

    def _real_extract(self, url):
        self._VALID_URL_RE = re.compile(self._VALID_URL)
        m = self._VALID_URL_RE.match(url)
        if m is None:
            self._VALID_URL_RE = re.compile(self._VALID_URL2)
            m = self._VALID_URL_RE.match(url)
            if m is None:
                sys.stderr.write(url + " is not a BBB video\n")
                sys.exit(1);

        self.website = m.group('website')

        video_id = m.group('id')

        # Extract basic metadata (more available in metadata.xml)
        self.metadata_url = self.website + '/presentation/' + video_id + '/metadata.xml'

        metadata = urllib.request.urlopen(self.metadata_url).read().decode()
        root = ET.fromstring(metadata)

        # id = xpath_text(metadata, 'id')
        self.id = root.find('id').text
        meta = root.find('./meta')
        self.meeting_name = meta.find('meetingName').text
        self.start_time = int(root.find('start_time').text)

        self.end_time = int(root.find('end_time').text)

        self.duration = int(float(self.end_time-self.start_time)/self._TIMESTAMP_UNIT)

        # This code unused : have to grasp what to do with thumbnails
        self.thumbnails = []
        images = root.find('./playback/extensions/preview/images')
        if not images is None:

            for image in images:
                self.thumbnails.append({
                    'url': image.text.strip(),
                    'width': image.get('width'),
                    'height': image.get('height')
                })

        # This code mostly useless unless one know how to process slides
        shapes_url = self.website + '/presentation/' + video_id + '/shapes.svg'
        #print(shapes_url)
        shapes_text = urllib.request.urlopen(shapes_url).read().decode()
        shapes = ET.fromstring(shapes_text)
        images = shapes.findall(_s("./svg:image[@class='slide']"))
        self.slides = []
        for image in images:
            self.slides.append(image.get(_x('xlink:href')))
        
        # We produce 2 formats :
        # - the 'webcams.webm' one, for webcams (can be used for merging its audio)
        # - the 'deskshare.webm' one, for screen sharing (can be used
        #   for merging its video) - it lacks the slides, unfortunately
        self.formats = []
        sources = {
            'webcams': '/video/webcams.webm',
            'deskshare': '/deskshare/deskshare.webm'
        }
        for format_id, source in sources.items():
            video_url = self.website + '/presentation/' + video_id + source
            self.formats.append({
                'url': video_url,
                'format_id': format_id
            })


if __name__ == '__main__' :
    if len(sys.argv) == 2 :
        url=sys.argv[1]
    else:
        url=sys.argv[2]

    extractor = BigBlueButtonExtractor()
    extractor._real_extract(url)

    if len(sys.argv) == 2 :
        pprint(extractor.__dict__)
    else:
        attrval = getattr(extractor, sys.argv[1])
        print(attrval)

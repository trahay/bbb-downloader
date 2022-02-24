FROM debian:11

LABEL Author="François Trahay <francois.trahay@telecom-sudparis.eu>"
LABEL Title="BBB-downloader in Docker"

ENV BBB_PATH "/opt/bbb-downloader"
ENV PATH "$PATH:$BBB_PATH"

# Install build tools
RUN apt update \
  && apt install -y \
  python3 \
  python3-pip\
  ffmpeg\
  bc\
  docker.io\
  npm\
  git

RUN git clone https://github.com/trahay/bbb-downloader.git ${BBB_PATH}
RUN cd ${BBB_PATH} && npm install
RUN cd ${BBB_PATH} && pip3 install -r python-requirements.txt

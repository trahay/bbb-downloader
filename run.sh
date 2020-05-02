# Startup Selenium server
docker run --rm -d --name=grid -p 4444:24444 -p 5920:25900 \
  --shm-size=2g -e VNC_PASSWORD=hola \
  -e VIDEO=true -e AUDIO=true \
  -e SCREEN_WIDTH=1080 -e SCREEN_HEIGHT=720 \
  elgalu/selenium

docker exec grid wait_all_done 30s

# Run selenium to capture video
node record-bbb-example.js

# Save the captured video
docker exec grid stop-video
docker cp grid:/videos/. videos
docker stop grid

echo "Your video should be in video/"

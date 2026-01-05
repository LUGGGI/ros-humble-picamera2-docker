# ros-humble-picamera2-docker
This adds picamera2 (and its dependencies) to a ROS Humble repository. It uses libcamera v0.5.0+59-d83ff0a.  
https://hub.docker.com/repository/docker/lugggi/ros-humble-picamera2/

## Connecting the Picamera

To give  the container to access to the Picamera run the container with the following arguments:

```bash
-v /run/udev/data:/run/udev/data:ro -v /dev/:/dev/ --device /dev
```
For ROS, it is recommended to also add `--net=host` to allow communication.

If the program that is using picamera2 is running with user privileges, that user needs to be added to the video group (GID should be 44) . There are two options:

* Add the user to the video group when running the container by adding the argument: `--group-add 44`.
* Add it when creating the user in the Dockerfile:
  ```bash
  RG USERNAME=ubuntu
  ARG HOST_VIDEO_GID=44  # Matches host 'video' group GID
  # Add the user to the video group to access camera devices
  RUN usermod -aG $(getent group $HOST_VIDEO_GID | cut -d: -f1) $USERNAME 
  ```

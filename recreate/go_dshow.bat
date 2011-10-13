@rem work ffmpeg -y -t 10 -f dshow -r 5 -i video="USB Video Device"  -vcodec mpeg4 dshow.mp4

@rem work ffmpeg -y -t 10 -f dshow -s 640x480 -r 5 -i video="USB Video Device"  -vcodec mpeg4 -r 1 dshow.mp4 # drops 40 like it should

@rem work ffmpeg -y -t 10 -f dshow -s 640x480 -r 5 -i video="USB Video Device" -vcodec mpeg4 -r 1 yo.mp4

@rem work ffmpeg -y -f dshow -s 640x480 -video_device_number 0 -r 6 -i video="USB Video Device" -vcodec mpeg4 -r 1 yo

@rem work ffmpeg -y -f dshow -s 640x480 -r 6 -i video="USB Video Device" -vcodec mpeg4 -r 6 yo.mp4

@rem work/fail but still seems to give too many fps? ffmpeg -y -f dshow -s 640x480 -framerate 6 -i video="USB Video Device" -vcodec mpeg4 -r 6 yo.mp4

@rem fail ffmpeg -y -f dshow -s 640x480 -r 6 -i video="USB Video Device" -vcodec mpeg4 yo.mp4
@rem fail ffmpeg -y -f dshow -s 1280x1024 -r 6 -i video="USB Video Device" -vcodec mpeg4 yo.mp4
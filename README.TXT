This aims to be a camera surveillance system (open source, cross platform) that is actually
user friendly, and runs on windows.

What it does do:

Saves off a directshow capture device, splitting the video each hour, into its own folder.
Good performance via ffmpeg mpegv4 codec, doesn't hog RAM.  Doesn't use too much disk space.
Does work with various resolutions coming from the camera.

Why?

The existing solutions for windows seemed to totally be cpu and memory hogs (yawcam), or not be
totally open source (iSpy, yawcam).

Also they weren't too user friendly.

How to use:
install avisynth 32-bit
install windows SDK, which has graphedt.exe
edit tee.GRF, replace the capture device with your own, right click on the output pin to set capture properties.
also connect it the "tee" box in there.
Now run ruby go.rb (install ruby if needed, too, any version will do).

It will create nicely packaged capture files for you in captured_files/day/hour-minute.mp4

Ping me if you are interested in this project, or feature requests et al.

rogerdpack@gmail.com
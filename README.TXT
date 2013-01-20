= Dirt Simple Surveillance =

Turns your (Windows) PC into a rockin' surveillance system!

It can record multiple cameras, and doesn't use much cpu
compared to other solutions!

Dirt Simple Surveillance aims to be a camera surveillance system that is simple, user friendly, easy to use, 
and that doesn't use many system resources (cpu), so doesn't get in your way.

Since it records with a quality encoder, it can record *days* video.  Put your computer to use for you!

Free!

Usage =

Basically start it up ("Dirt Simple Surveillance" icon on your desktop, or Start button/windows orb ball -> programs -> Dirt Simple Surveillance)
then click "add" to add some cameras, then click "start recording" and let it record.

It will create multiple video files in your "My Movies/dirt simple surveillance/date" folder, one every half an hour.

It will delete the oldest recordings when the disk starts to get "close to full" (currently when the disk has 10 GB free).

Why? =

The existing solutions for windows seemed to totally be cpu and memory hogs, or not be
totally open source/free.
Also they weren't too user friendly, at least for me.  These things should be simple.

Features =

Records using FFmpeg, one of the most efficient recorders on the planet.
Can record from attached Webcams, USB Cameras, some (most?) capture cards, and network IP cameras
(any network camera).

If there are any features you think you want, or that you lack, ping me, there's a reasonable chance
I can add it!  (for instance, being able to record the desktop, streaming...)

FAQ =

Q. Is it good/ok to use USB Webcams for surveillance?  Won't they over heat or something?
A. I have had great luck using them 24/7.  They seem to work splendidly, and most of them can capture at high resolution,
like 1024x768 et al.  And don't even seem to use much cpu/electricity.
Q. Can I use it with an android camera, to record that?
A. Quite possibly, ping me on details! :)

How =

Basically it wraps ffmpeg, which receives lots of different types of input, including local attached cameras
(via directshow), etc.

Feedback =

Ping me with any feature requests/feedback at all, anytime!
I'd even be happy to add a "network out" option so that you can stream your cameras to places like ustream.tv, et al. 

roger-projects@googlegroups.com

or web-based browseable feedback

https://groups.google.com/forum/?fromgroups#!forum/roger-projects

Installation =

Download and run the latest installer from here: 
http://code.google.com/p/dirt-simple-usb-surveillance/downloads/list

Related =
yawcam: didn't have an option to record more than 1 frame per second (last time I tried it),
  and super confusing.
ispy: not entirely free.  Ping me if you want added to this project the ability to "view your cameras online"
  I can add it.  Also seemed to use too many system resources, when I tried it.
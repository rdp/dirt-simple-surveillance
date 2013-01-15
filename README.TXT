= Dirt Simple Surveillance =

This aims to be a camera surveillance system that is user friendly and easy to use, 
and that doesn't use many system resources (cpu).

Turn your PC into a full blown surveillance system!

It can record from multiple attached cameras, and doesn't use much cpu!

Free and open source!

Usage =

Basically start it up (start menu -> programs -> Dirt Simple Surveillance, or Dirt Simple USB Surveillance picture on your desktop)
then click "add" to add some cameras, then click "start recording".

It will create multiple video files in your "My Movies/dirt simple surveillance/date" folder, one every half an hour.

It will delete the oldest recordings when the disk starts to get full (currently when the disk used reaches 10 GB free).

Why? =

The existing solutions for windows seemed to totally be cpu and memory hogs, or not be
totally open source/free.
Also they weren't too user friendly, at least for me.  These things should be simple.

FAQ =

Q. Is it good/ok to use USB Webcams for surveillance?  Won't they over heat or something?
A. I have had great luck using them 24/7.  They seem to work splendidly, and most of them can capture at high resolution,
like 1024x768 et al.

How =

Basically it wraps ffmpeg, which receives lots of different types of input, including local attached cameras
(via directshow), etc.

Feedback =

Ping me with any feature requests/feedback at all, anytime!
I'd even be happy to add a "network out" option so that you can stream your cameras to places like ustream.tv, et al. 

roger-projects@googlegroups.com

or web-based browseable

https://groups.google.com/forum/?fromgroups#!forum/roger-projects

Installation =

Download and run the latest installer from here: 
http://code.google.com/p/dirt-simple-usb-surveillance/downloads/list
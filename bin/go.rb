require 'shared'

require 'fileutils'
require 'java' # require jruby <sigh>

def generate_preview_image from_this
   to_file = from_this + '.preview.jpg'
   command = "ffmpeg.exe -y -i \"#{from_this}\" -vcodec mjpeg -vframes 1 -f image2 \"#{to_file}\" 2>&1" # seems to make a matching size jpeg.
    `#{command}`
    raise command unless $?.exitstatus == 0
	raise unless File.size(to_file) > 1000
end

require 'sane'
require 'thread'

$thread_start = Mutex.new # don't let 2 deletes happen at once...

def set_all_ffmpegs_as_lowest_prio
            # avoid win32ole which apparently leaks in jruby...
            piddys = `tasklist`.lines.select{|l| l =~ /ffmpeg.exe/}.map{|l| l.split[1].to_i} # just pid's
            for pid in piddys
              system(c = "SetPriority -BelowNormal #{pid} > NUL 2>&1") # uses PID for the command line
              if $?.exitstatus != 0
			    p c + ' failed? ignoring... [race condition for process dying?]'
	          end
            end
end

class Numeric
  # meaning "gigs" :)
  def g
    "%.02fG" % (self/1_000_000_000.0)
  end
  def gig
    self*1e9
  end
end

Delete_if_we_have_less_than_this_much_free_space = 10.gig # TODO ...
free_space = java.io.File.new('.').freeSpace

p "deleting old days when you have less than #{Delete_if_we_have_less_than_this_much_free_space.g} free, you currently have #{free_space.g} free"

def delete_if_out_of_disk_space
    free_space = java.io.File.new('.').freeSpace
  
    if free_space < Delete_if_we_have_less_than_this_much_free_space
	  # lodo email instead? compact?
	  $thread_start.synchronize {
		  $deletor_thread ||= Thread.new {
			oldest_day_dir =  get_sorted_day_dirs.first
			p "deleting old day dir #{oldest_day_dir} because free #{free_space.g} < #{Delete_if_we_have_less_than_this_much_free_space.g}"
			FileUtils.rm_rf oldest_day_dir
			p "done deleting " + oldest_day_dir
			$deletor_thread = nil # let next guy through delete if more should be deleted...
		  }
	  }
  else
    #puts "have enough free space #{free_space.g} > #{Delete_if_we_have_less_than_this_much_free_space.g}"
  end
end

all_cameras = UsbStorage['devices_to_record']
def kill
  system("taskkill /f /im ffmpeg* > NUL 2>&1")
end

kill() # kill old ffmpeg's...during testing this helps :)

if all_cameras.empty?
 p 'not recording anything, no devices specified'
 exit 1
end

all_cameras.each{|device_name, camera_name, index, resolution, framerate|
  Thread.new {
  loop {

  framerate = "-framerate #{framerate}" if framerate
  resolution = "-s #{resolution}" if resolution
  index = "-video_device_number #{index}" if index
  input = "-f dshow #{index} #{framerate} #{resolution} -i video=\"#{device_name}\""
  
  if ARGV.detect{|a| a == '--preview'}
    c = %!ffmpeg\\ffplay #{input}!
	puts c
    system c
    raise 'die this thread, you\'re done!' # smelly...
  end
  delete_if_out_of_disk_space
  current = Time.now
  sixty_minutes = 60*60
  #sixty_minutes = 10 #seconds
  raise 'unexpected space in camera human name?' if camera_name =~ / / # why is this a problem? LODO allow...
  bucket_day_dir = UsbStorage['storage_dir'] + '/' + camera_name + '/' + current.strftime("%Y-%m-%d")
  FileUtils.mkdir_p bucket_day_dir
  
  current_file_timestamp = current.strftime "%Hh-%Mm.mp4"
  filename = "#{bucket_day_dir}/#{current_file_timestamp}"
  p "doing #{filename} for #{sixty_minutes/60}m" # debug :)
    
  # LODO no -y, yes prompt the user maybe?...
  c = %!ffmpeg -y #{input} -vcodec mpeg4 -t #{sixty_minutes} -r #{framerate} "#{filename}" ! # I guess we don't "need" the trailing -r 5 anymore...oh wait except it bugs on multiples of 15 fps or something...
  # -vcodec libx264 ?
  p "running", c
  out_handle = IO.popen(c)
  set_all_ffmpegs_as_lowest_prio
  output = out_handle.read # is this too much data after 60 minutes? prolly not... :P
  raise c + " failed? #{output}" unless $?.exitstatus == 0 # don't generate preview if failed...
  generate_preview_image filename
 }
 }
}

sleep 1 # make this show up lower on the display console
puts 'touch stop to quit/cancel current vid'
while !File.exist?('stop')
 sleep 1
end
FileUtils.rm 'stop'
kill()

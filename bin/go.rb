require 'fileutils'
require 'java' # require jruby <sigh>

require 'simple_gui_creator'


def generate_preview_image from_this

   to_file = from_this + '.preview.jpg'
   command = "vendor\\ffmpeg\\ffmpeg.exe -y -i \"#{from_this}\" -vcodec mjpeg -vframes 1 -f image2 \"#{to_file}\" 2>&1" # seems to make a matching size jpeg.
    `#{command}`
    raise command unless $?.exitstatus == 0
	raise unless File.size(to_file) > 1000
end

Thread.abort_on_exception=true # sanity...
require 'thread'

ENV['PATH'] = 'vendor\\ffmpeg;vendor;' + ENV['PATH'] # put our ffmpeg first, see jruby#6211

$thread_start = Mutex.new

def set_all_ffmpegs_as_lowest_prio
            # avoid win32ole which apparently leaks in jruby...
            piddys = `tasklist`.lines.select{|l| l =~ /ffmpeg.exe/}.map{|l| l.split[1].to_i} # just pid's
            for pid in piddys
              system(c = "SetPriority -BelowNormal #{pid} > NUL") # uses PID for the command line
              if $?.exitstatus != 0
			    p c + ' failed!' # race condition ?
	       end
            end
end

class Numeric
  # meaning "gigs" :)
  def g
    "%.02fG" % (self/1_000_000_000.0)
  end
end

require 'shared'
Delete_if_we_have_less_than_this_much_free_space = 20e9#gig
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

all_cameras = {
  'eyeball' => [0, '1280x1024'], 
  'thin_camera' => [1,'1280x960']
}
def kill
  system("taskkill /f /im ffmpeg*")
end
kill()

all_cameras.each{|camera_name, (index, resolution)|
  Thread.new {
  loop {

  # todo motion detect :P
  # todo smallify x days worth
  # todo make config ridiculously easy LOL
  framerate = 5
  input = "-f dshow -video_device_number #{index} -framerate #{framerate}  -i video=\"USB Video Device\" -s #{resolution}"
  # -vf hqdn3d=4:4:4:4:4
  # -vcodec libx264 ?
  #input = "-i tee.avs"
  
  if ARGV.detect{|a| a == '--preview'}
    c = %!ffmpeg\\ffplay #{input}!
	puts c
    system c
    raise 'die thread, die'
  end
  delete_if_out_of_disk_space
  current = Time.now
  current_file_timestamp = current.strftime "%Hh-%Mm.mp4"
  sixty_minutes = 60*60
  #sixty_minutes = 10 #seconds
  raise 'unexpected space in camera human name?' if camera_name =~ / /
  bucket_day_dir = 'captured_video/' + camera_name + '/' + current.strftime("%Y-%m-%d")
  FileUtils.mkdir_p bucket_day_dir
  p "doing #{bucket_day_dir}/#{current_file_timestamp} for #{sixty_minutes/60}m"
  filename = "#{bucket_day_dir}/#{current_file_timestamp}"
    
  # TODO no -y, yes prompt ...
  c = %!ffmpeg -y #{input} -vcodec mpeg4 -t #{sixty_minutes} -r #{framerate} "#{filename}" 2>NUL! # I guess we don't "need" the trailing -r 5 anymore...oh wait except it bugs on multiples of 15 fps or something...
  
  out_handle = IO.popen(c)
  set_all_ffmpegs_as_lowest_prio
  output = out_handle.read
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

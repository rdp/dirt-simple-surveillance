require 'fileutils'
require 'java' # require jruby <sigh>

def generate_preview_image from_this

   to_file = from_this + '.preview.jpg'
   `ffmpeg\\ffmpeg.exe -y -i "#{from_this}" -vcodec mjpeg -vframes 1 -f image2 "#{to_file}" 2>&1` # seems to make a matching size jpeg.
   
    raise unless $?.exitstatus == 0
    p 'made thumbnail ' + to_file
	raise unless File.exist? to_file
end

require 'fileutils'
Thread.abort_on_exception=true # sanity
require 'thread'

ENV['PATH'] = 'ffmpeg;' + ENV['PATH'] # put our ffmpeg first, see jruby#6211

$thread_start = Mutex.new
$: << "./vendor/ruby-wmi-0.2.2/lib"
require 'ruby-wmi'

def set_all_ffmpegs_as_lowest_prio
 piddys = ::WMI::Win32_Process.find(:all,  :conditions => {'Name' => 'ffmpeg.exe'})
            for piddy in piddys
              # piddy.SetPriority low_prio # this call can seg fault at times...JRUBY-5422
              pid = piddy.ProcessId # this doesn't seg fault, tho
			  p pid
              system("SetPriority -lowest #{pid} > NUL") # uses PID for the command line
              raise unless $?.exitstatus == 0
            end
end


def delete_if_out_of_disk_space
    free_space = java.io.File.new('.').freeSpace
  
    delete_if_we_have_less_than_this_much_free_space = 55e9
    if free_space < delete_if_we_have_less_than_this_much_free_space
	  # lodo email instead? compact?
	  $thread_start.synchronize {
		  $deletor_thread ||= Thread.new {
			
			dirs = Dir['captured_video/*/*']
			oldest_dir = dirs.min_by{|name| name.split('/')[2]}
			p "deleting old day dir #{oldest_dir} because free #{free_space} < #{delete_if_we_have_less_than_this_much_free_space}"
			FileUtils.rm_rf oldest_dir
			p "done deleting"
			$deletor_thread = nil # let next guy through delete if more should be deleted...
		  }
	  }
  else
    puts "have enough free space #{free_space/1_000_000_000}G > #{delete_if_we_have_less_than_this_much_free_space/1_000_000_000}G"
  end
end

all_cameras = {'eyeball' => [0, '1280x1024'], 'thin_camera' => [1,'1280x960']}

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
  current_file_timestamp = current.strftime "%H-%Mm"
  sixty_minutes = 60*60
  #sixty_minutes = 10 #seconds
  raise 'unexpected space in camera human name?' if camera_name =~ / /
  bucket_day_dir = 'captured_video/' + camera_name + '/' + current.strftime("%Y-%m-%d")
  FileUtils.mkdir_p bucket_day_dir
  p "doing #{bucket_day_dir}/#{current_file_timestamp}"
  filename = "#{bucket_day_dir}/#{current_file_timestamp}.mp4"
    
  # TODO no -y, prompt ...
  c = %!ffmpeg -y #{input} -vcodec mpeg4 -t #{sixty_minutes} -r #{framerate} "#{filename}" 2>NUL! # I guess we don't "need" the trailing -r 5 anymore...oh wait except it bugs on multiples of 15 fps or something...
   
  puts c
  out_handle = IO.popen(c)
  set_all_ffmpegs_as_lowest_prio
  output = out_handle.read
  generate_preview_image filename
 }
 }
}

at_exit {
system("taskkill /y /IM ffmpeg*")
}
# sleep basically forever
Thread.list.each{|t| 
unless t == Thread.current
 begin
  t.join
 rescue RuntimeError => ignore
 end
end
}
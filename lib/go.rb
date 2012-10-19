require 'shared'

require 'fileutils'
require 'java' # require jruby <sigh>

def generate_preview_image from_this
   to_file = from_this + '.still_frame.jpg'
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
			oldest_day_dir = get_sorted_day_dirs.first
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

@all_processes_since_inception = []

def do_something just_preview = false, video_take_time = 60*60 # 60 minutes

all_cameras = UsbStorage['devices_to_record']

@keep_going = true

@all_threads = all_cameras.map{|device_name, (camera_english_name, options)|
  Thread.new {
  
  framerate = options[:fps] # else "timebase not supported by mpeg4" hmm...LODO fix in FFmpeg if I can...TODO allow specifying/force them to choose it here, too...
  framerate_text = "-framerate #{framerate}"
  output_framerate_text = "-r #{framerate}"
  resolution = "-s #{options[:x]}x#{options[:y]}"
  index = "-video_device_number #{index}" if index # TODO
  p options
  pixel_format = options[:video_type] == 'vcodec' ? "-vcodec #{options[:video_type_name]}" : "-pixel_format #{options[:video_type_name]}"
  
  input = "-f dshow #{pixel_format} #{index} #{framerate_text} #{resolution} -i video=\"#{device_name}\" -vf drawtext=fontcolor=white:shadowcolor=black:shadowx=1:shadowy=1:fontfile=vendor/arial.ttf:text=\"%m/%d/%y %Hh %Mm %Ss\" "
  if just_preview
    c = %!ffplay #{input.gsub(/-vcodec [^ ]+/, '')} -window_title "#{camera_english_name}"! # ffplay can't take vcodec?
	puts c
    system c
    raise 'die this thread, you\'re done!' # smelly...
  end
  
  while(@keep_going)
  
  delete_if_out_of_disk_space
  current = Time.now
  bucket_day_dir = UsbStorage['storage_dir'] + '/' + camera_english_name + '/' + current.strftime("%Y-%m-%d")
  FileUtils.mkdir_p bucket_day_dir
  
  current_file_timestamp = current.strftime "%Hh-%Mm.mp4"
  filename = "#{bucket_day_dir}/#{current_file_timestamp}"
  if File.exist? filename
    current_file_timestamp = current.strftime "%Hh-%Mm-%Ss.mp4"
    filename = "#{bucket_day_dir}/#{current_file_timestamp}"
  end
  
  p "recording #{camera_english_name} #{current_file_timestamp} for #{video_take_time/60}m#{video_take_time%60}s" # debug :)
    
  c = %!ffmpeg -y #{input} -vcodec mpeg4 -t #{video_take_time} #{output_framerate_text} -f mp4 "#{filename}.partial" ! # I guess we don't "need" the trailing -r 5 anymore...oh wait except it bugs on multiples of 15 fps or something... 
  # -vcodec libx264 ?
  p 'running'
  puts c
  out_handle = IO.popen(c, "w") 
  @all_processes_since_inception << out_handle
  set_all_ffmpegs_as_lowest_prio
  FFmpegHelpers.wait_for_ffmpeg_close out_handle
  raise c + " failed?" unless $?.exitstatus == 0 # don't generate preview if failed...
  File.rename(filename + ".partial", filename)
  generate_preview_image filename
  end
 }
}

end

def shutdown_current
    @keep_going = false
	@all_processes_since_inception.each{|p|
	  p.puts 'q' rescue nil # does this work after first has finished? with closed processes?
	}
	@all_threads.each &:join
end

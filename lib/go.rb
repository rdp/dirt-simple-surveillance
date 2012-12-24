require 'shared'

require 'fileutils'
require 'java' # requires jruby <sigh>
require 'sane'
require 'thread'

def save_preview_image from_this, camera_dir
 to_file = from_this + '.still_frame.jpg'
 FileUtils.cp camera_dir + '/latest.jpg', to_file
end

$thread_start = Mutex.new # disallow 2 deletes from happening at once...

def set_all_ffmpegs_as_lowest_prio
	# avoid win32ole which apparently leaks in jruby...though I could probably fix it...
	piddys = `tasklist`.lines.select{|l| l =~ /ffmpeg.exe/}.map{|l| l.split[1].to_i} # get just pid's
	for pid in piddys
	  system(c = "SetPriority -BelowNormal #{pid} > NUL 2>&1") # uses PID for the command line
	  if $?.exitstatus != 0
		p c + ' failed? ignoring... [race condition for process dying?]'
	  end
	end
end

def delete_if_out_of_disk_space
    free_space = java.io.File.new(base_storage_dir).freeSpace
  
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

def do_something all_cameras, just_preview_and_block, video_take_time = 60*60 # 60 minutes

@keep_going = true

@all_threads = all_cameras.map{|device, (camera_english_name, options)|

  framerate = options[:fps] # else "timebase not supported by mpeg4" hmm...LODO fix in FFmpeg if I can...TODO allow specifying/force them to choose it here, too...
  framerate_text = "-framerate #{framerate}"
  output_framerate_text = "-r #{framerate}"  # avoid it bugging out sometimes on multiples of 15 fps or something weird like that...LODO
  resolution = "-s #{options[:x]}x#{options[:y]}"
  index = "-video_device_number #{index}" if index # TODO actually use :)
  pixel_format = options[:video_type] == 'vcodec' ? "-vcodec #{options[:video_type_name]}" : "-pixel_format #{options[:video_type_name]}"
  
  ffmpeg_input = "-f dshow #{pixel_format} #{index} #{framerate_text} #{resolution} -i video=\"#{device[0]}\" -video_device_number #{device[1]} -vf drawtext=fontcolor=white:shadowcolor=black:shadowx=1:shadowy=1:fontfile=vendor/arial.ttf:text=\"%m/%d/%y %Hh %Mm %Ss\" "
  if just_preview_and_block
    c = %!ffplay -probesize 32 #{ffmpeg_input.gsub(/-vcodec [^ ]+/, '')} -window_title "#{camera_english_name} [capture preview--close when ready to move on]"! # ffplay can't take vcodec?
	puts c
    system c
    return
  end

  Thread.new {
  
  while(@keep_going)
  
   delete_if_out_of_disk_space
   current_time = Time.now
   camera_dir = UsbStorage['storage_dir'] + '/' + camera_english_name
   bucket_day_dir =  camera_dir + '/' + current_time.strftime("%Y-%m-%d")
   FileUtils.mkdir_p bucket_day_dir
  
   current_file_timestamp = current_time.strftime "%Hh-%Mm.mp4"
   filename = "#{bucket_day_dir}/#{current_file_timestamp}"
   if File.exist? filename
     # quick repeat/stop and start...maybe should just override here...
     current_file_timestamp = current_time.strftime "%Hh-%Mm-%Ss.mp4"
     filename = "#{bucket_day_dir}/#{current_file_timestamp}"
   end
  
   p "recording #{camera_english_name} #{current_file_timestamp} for #{video_take_time/60}m#{video_take_time%60}s" # debug :)
    
   # -vcodec libx264 ?
   output_1 = "-vcodec mpeg4 -b:v 500k -f mp4 \"#{filename}.partial\""
   output_2 = "-updatefirst 1 -r 1/10 \"#{camera_dir}/latest.jpg\"" # once every 10 seconds
   c = %!ffmpeg #{ffmpeg_input} -t #{video_take_time} #{output_framerate_text} #{output_1} #{output_2}!
   
   print 'running ', c
   out_handle = IO.popen(c, "w") 
   $thread_start.synchronize {
     @all_processes_since_inception << out_handle
   }
   set_all_ffmpegs_as_lowest_prio
   
   begin
     FFmpegHelpers.wait_for_ffmpeg_close out_handle, 15 # should never exit in like 15 seconds...should it?
   rescue Exception => exited_early
     if @current_state == :running
       SimpleGuiCreator.show_non_blocking_message_dialog "appears an ffmpeg recording process exited early (within 15s)?\nplease kill any rogue ffmpeg processes, or make sure you don't try and capture it twice at the same time!\n#{c} #{exited_early}"
	   raise
	 else
	   puts "I hope they just hit stop quickly...should be safe..."
	 end
   end
   File.rename(filename + ".partial", filename)
   save_preview_image filename, camera_dir
  end
 }
}

end

def shutdown_current
    @keep_going = false
	$thread_start.synchronize {
	  @all_processes_since_inception.each{|p|
	    puts 'sending q string'
	    p.puts 'q' rescue nil # does this work after first has finished? with closed processes?
	  }
	  @all_processes_since_inception = []
	}
	# might still be some race condition here...
	@all_threads.each &:join
end

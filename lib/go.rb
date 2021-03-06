require 'shared'

require 'fileutils'
require 'java' # requires jruby <sigh>
require 'sane'
require 'thread'

@jpeg_out_name = 'latest_snapshot.jpg'

def save_preview_image from_this, camera_dir
 to_file = from_this + '.snapshot.jpg'
 FileUtils.cp camera_dir + '/' + @jpeg_out_name, to_file
end

$thread_start = Mutex.new # disallow 2 deletes from happening at once...

def get_all_ffmpeg_pids
  # avoid win32ole which apparently leaks in jruby...though I could probably fix it...
  piddys = `tasklist`.lines.select{|l| l =~ /ffmpeg_dirt_simple.exe/}.map{|l| l.split[1].to_i} # get just pid's
end

def set_all_ffmpegs_as_lowest_prio
	piddys = get_all_ffmpeg_pids
	for pid in piddys
	  system(c = "SetPriority -BelowNormal #{pid} > NUL 2>&1") # uses PID for the command line
	  if $?.exitstatus != 0
		p c + ' failed setting priority? ignoring... [possible race condition for process dying?]'
	  end
	end
end

def delete_if_out_of_disk_space
    free_space = java.io.File.new(base_storage_dir).freeSpace
  
    if free_space < free_space_requested
	  # lodo email instead? compact?
	  $thread_start.synchronize {
		  $deletor_thread ||= Thread.new {
			oldest_day_dir = get_sorted_day_dirs.first
			date = oldest_day_dir.split('/')[-1]
			if date == current_year_month_day(Time.now)
			  # LODO cleanup because it will just keep prompting them forever?
			  # at least show stats or something?
			  show_message "warning, maybe disk space is low?\nwant to delete #{oldest_day_dir} to keep disk space low, but that's today, not deleting it\nrecommend installing and using windirstat to examine and free up some disk space"
			else
			  p "deleting old day dir #{oldest_day_dir} because free #{free_space.g} < #{free_space_requested.g}"
			  FileUtils.rm_rf oldest_day_dir
			  p "done deleting " + oldest_day_dir
			end
			$deletor_thread = nil # let next guy through delete if more should be deleted...
		  }
	  }
  else
    #puts "have enough free space #{free_space.g} > #{free_space_requested.g}"
  end
end


$start_time = Time.now

@all_currently_runnng_processes = []

def current_year_month_day time
  time.strftime("%Y-%m-%d")
end

def do_something all_cameras, just_preview_and_block, video_take_time = 60*60 # 60 minutes

@keep_going = true

@all_threads = all_cameras.map{|device, (camera_english_name, options)|

  if options[:url]
    ffmpeg_input = "-analyzeduration 5k -i " + options[:url]
  else
    resolution = "-video_size #{options[:x]}x#{options[:y]}"
    index = "-video_device_number #{index}" if index # TODO actually use :)
    pixel_format = options[:video_type] == 'vcodec' ? "-vcodec #{options[:video_type_name]}" : "-pixel_format #{options[:video_type_name]}"
    ffmpeg_input = "-f dshow #{pixel_format} #{index} #{resolution} -i video=\"#{device[0]}\" "
  end
  
  if options[:fps]
    framerate = options[:fps] # else "timebase not supported by mpeg4" hmm...LODO fix in FFmpeg if I can...TODO allow specifying/force them to choose it here, too...
    framerate_text = "-framerate #{framerate}"
    output_framerate_text = "-r #{framerate}"  # avoid it bugging out sometimes on multiples of 15 fps or something weird like that...LODO investigate (used later...)
	ffmpeg_input = "#{framerate_text} #{ffmpeg_input}"
  end
    
  filters = "-filter_complex \"drawtext=fontcolor=white:shadowcolor=black:shadowx=1:shadowy=1:fontfile=vendor/arial.ttf:text=%m/%d/%y %Hh %Mm %SsSPLIT\"  "
  camera_dir = UsbStorage['storage_dir'] + '/' + camera_english_name
  FileUtils.mkdir_p camera_dir
  ffmpeg_input = "#{ffmpeg_input} #{filters}"
  
  if just_preview_and_block
    ffmpeg_input.gsub!(/-vcodec [^ ]+/, '') # it can't take this [?] LODO ask them
	ffmpeg_input.gsub!('SPLIT', '') # don't want any splits for ffplay, it's single input only :)
	ffmpeg_input.gsub!('filter_complex', 'vf') # it doesn't like filter_complex with -i [?]
    c = %!ffplay_dirt_simple #{ffmpeg_input} -analyzeduration 1k -window_title "#{camera_english_name} capture preview--[close when ready to move on]"!
	puts c
    # system c # avoid JRUBY-7042 yikes!
	a = IO.popen(c)
	a.read # blocks :)
	a.close
    return
  else
  	ffmpeg_input.gsub!('SPLIT', ',split=2 [out1] [out2]')
  end

  Thread.new {
  
  while(@keep_going)
  
   delete_if_out_of_disk_space
   current_time = Time.now
   bucket_day_dir = camera_dir + '/' + current_year_month_day(current_time)
   FileUtils.mkdir_p bucket_day_dir
  
   current_file_timestamp = current_time.strftime "%Hh-%Mm.mp4.partial"
   filename = "#{bucket_day_dir}/#{current_file_timestamp}"

   p "recording #{camera_english_name} #{current_file_timestamp} for #{video_take_time/60}m#{video_take_time%60}s" # debug :)
    
   # -vcodec libx264 ?
   output_1 = "-map \"[out1]\" -t #{video_take_time} -vcodec mpeg4 -b:v #{encoding_bitrate_with_k} -f mp4 \"#{filename}\""
   output_2 = "-map \"[out2]\" -t #{video_take_time} -q:v 1 -updatefirst 1 -r 1/10 \"#{camera_dir}/#{@jpeg_out_name}\"" # once every 10 seconds
   c = %!ffmpeg_dirt_simple -y #{ffmpeg_input} #{output_framerate_text} #{output_1} #{output_2}! # needs -y to clobber previous .partial's...
   
   puts "running at #{Time.now}", c
   out_handle = nil
   $thread_start.synchronize {
     # synchronize the ENV usage, too, yikes :P
     ENV['FFREPORT'] = "file=#{camera_dir.gsub(':', "\\:")}/capture_log.txt"
     out_handle = IO.popen(c, "w") 
     @all_currently_runnng_processes << out_handle
   }
   set_all_ffmpegs_as_lowest_prio   
   begin
     FFmpegHelpers.wait_for_ffmpeg_close out_handle, [15, video_take_time].min # should never exit in less than 15 seconds...should it?
   rescue Exception => exited_early
     if @current_state == :recording
       SimpleGuiCreator.show_non_blocking_message_dialog "appears an ffmpeg recording process exited early (within 15s at #{Time.now})?\nplease kill any rogue ffmpeg processes, or make sure you don't try and run it twice at the same time!\n#{c}\nexited #{exited_early}\nstarted #{$start_time}"
	   @current_state = :confused
	   setup_ui # global state has changed :)
	   raise
	 else
	   puts "I hope they just hit stop quickly...should be safe..."
	 end
   ensure
      $thread_start.synchronize { @all_currently_runnng_processes.delete(out_handle) } # this one's done...
   end
   if File.exist? filename
     renamed = filename.sub('.partial', '')
     File.rename(filename, renamed)
     save_preview_image renamed, camera_dir
   else
     show_message "ffmpeg did not create file #{filename}?"
   end
  end
 }
}

end

def shutdown_current
    @keep_going = false
	$thread_start.synchronize {
	  @all_currently_runnng_processes.each{|p|
	    puts 'sending q string'
	    p.puts 'q' rescue nil # does this work after first has finished? with closed processes?
	  }
	  @all_currently_runnng_processes = []
	}
	# might still be some race condition here tho...
	@all_threads.each &:join
	puts 'detected all ffmpegs done'
	@all_threads = []
end

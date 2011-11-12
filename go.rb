require 'fileutils'
require 'java' # force jruby

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

$thread_start = Mutex.new

def delete_if_out_of_disk_space
    require 'java' # jruby <sigh>
  
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
    puts "have enough free space #{free_space/1_000_000_000}G"
  end
end

all_cameras = {'eyeball' => [0, '1280x1024'], 'thin_camera' => [1,'1280x960']}

all_cameras.each{|camera_name, (index, resolution)|
  Thread.new {
  loop {

  # todo motion detect :P
  # todo smallify x days worth
  # todo make config ridiculously easy LOL
  
  input = "-f dshow -r 5  -video_device_number #{index} -i video=\"USB Video Device\" -s #{resolution}"
  # -vf hqdn3d=4:4:4:4:4
  # -vcodec libx264 ?
  #input = "-i tee.avs"
  
  if ARGV.detect{|a| a == '--preview'}
    c = %!ffmpeg\\ffplay #{input}!
	puts c
    system c
    exit
  end
  delete_if_out_of_disk_space
  current = Time.now
  current_file_timestamp = current.strftime "%H-%Mm"
  sixty_minutes = 60*60
  #sixty_minutes = 10 #seconds
  raise 'unexpected' if camera_name =~ / /
  bucket_day_dir = 'captured_video/' + camera_name + '/' + current.strftime("%Y-%m-%d")
  FileUtils.mkdir_p bucket_day_dir
  p "doing #{bucket_day_dir}/#{current_file_timestamp}"
  filename = "#{bucket_day_dir}/#{current_file_timestamp}.mp4"
    
  # TODO no -y ...
  c = %!ffmpeg\\ffmpeg -y #{input} -vcodec mpeg4 -t #{sixty_minutes} -r 5 "#{filename}"  2>&1!
  
  #puts c
  out_handle = IO.popen(c)
  `.\\SetPriority.exe -lowest #{out_handle.pid}`
  raise unless $?.exitstatus == 0
  output = out_handle.read
  generate_preview_image filename
 }
 }
}

sleep # forever :)
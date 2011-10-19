require 'fileutils'

def generate_preview_image from_this

   to_file = from_this + '.preview.jpg'
   `ffmpeg\\ffmpeg.exe -y -i "#{from_this}" -vcodec mjpeg -vframes 1 -f image2 "#{to_file}" 2>&1` # seems to make a matching size jpeg.
   
    raise unless $?.exitstatus == 0
    p 'made ' + to_file
	raise unless File.exist? to_file
end

all_cameras = {'eyeball' => [0, '1280x1024'], 'thin_camera' => [1,'1280x960']}

all_cameras.each{|camera_name, (index, resolution)|
  Thread.new {
  loop {
  
  current = Time.now
  current_file_timestamp = current.strftime "%H-%Mm"
  p "doing #{current_file_timestamp} #{camera_name}"
  sixty_minutes = 60*60
  #sixty_minutes = 20 #seconds
  raise 'unexpected' if camera_name =~ / /
  bucket_day_dir = 'captured_video/' + camera_name + '/' + current.strftime("%Y-%m-%d")
  FileUtils.mkdir_p bucket_day_dir
  
  # todo motion detect :P
  # todo smallify x days worth
  # todo make config ridiculously easy LOL
  
  input = "-f dshow -r 5  -video_device_number #{index} -i video=\"USB Video Device\" -s #{resolution}"
  # -vf hqdn3d=4:4:4:4:4
  # -vcodec libx264 ?
  #input = "-i tee.avs"
  
  if ARGV.detect{|a| a == '--preview'}
    c = %!ffmpeg\\ffplay #{input}!
    system c
    exit
  end
  filename = "#{bucket_day_dir}/#{current_file_timestamp}.mp4"
    
  # TODO no -y ...
  c = %!ffmpeg\\ffmpeg -y #{input} -vcodec mpeg4 -t #{sixty_minutes} -r 5 "#{filename}"  2>&1!
  
  puts c
  out_handle = IO.popen(c)
  `.\\SetPriority.exe -lowest #{out_handle.pid}`
  raise unless $?.exitstatus == 0
  stdout = out_handle.read
  generate_preview_image filename
  
 }
 }
}

sleep # forever :)
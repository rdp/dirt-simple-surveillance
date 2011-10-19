require 'fileutils'

def generate_preview_image from_this
  raise unless system (%!ffmpeg\\ffmpeg.exe -y -i "#{from_this}" -vcodec mjpeg -vframes 1 -f image2 "#{from_this}.preview.jpg"!)
end

loop {
  
  current = Time.now
  current_file_timestamp = current.strftime "%H-%Mm"
  p "doing #{current_file_timestamp}"
  sixty_minutes = 60*60
  #sixty_minutes=10#seconds
  bucket_dir = 'captured_video/' + current.strftime("%Y-%m-%d")
  FileUtils.mkdir_p bucket_dir
  
  # todo motion detect :P
  # todo smallify x days worth
  # todo make config ridiculously easy LOL
  
  input = "-f dshow -r 5 -i video=\"USB Video Device\" -video_device_number 0 -s 1280x1024"
  # -vf hqdn3d=4:4:4:4:4
  # -vcodec libx264 ?
  
  if ARGV.detect{|a| a == '--preview'}
    c = %!ffmpeg\\ffplay #{input}!
    system c
    exit
  end
  filename = "#{bucket_dir}/#{current_file_timestamp}.mp4"
    
  # TODO no -y ...
  c = %!ffmpeg\\ffmpeg.exe -y #{input} -vcodec mpeg4 -t #{sixty_minutes} -r 2 "#{filename}"  2>&1!
  
  puts c
  out_handle = IO.popen(c)
  `.\\SetPriority.exe -lowest #{out_handle.pid}`
  raise unless $?.exitstatus == 0
  stdout = out_handle.read
  generate_preview_image filename
}
require 'fileutils'

def generate_preview_image for_this
  raise unless system (%!ffmpeg\\ffmpeg.exe -y -i "#{for_this}" -vcodec mjpeg -vframes 1 -f image2 "#{for_this}.preview.jpg"!)
end

loop {
  
  current = Time.now
  current_file_timestamp = current.strftime "%H-%Mm"
  p "doing #{current_file_timestamp}"
  sixty_minutes = 60*60
  #sixty_minutes=10#seconds
  bucket_dir = 'captured_video/' + current.strftime("%Y-%m-%d")
  FileUtils.mkdir_p bucket_dir
  
  # default is %Y-%m-%d %H:%M:%S %z’
  
  # todo better than 640x480 hmm...
  # todo better encoding codec [what am I even using?]
  # todo motion detect :P
  # todo delete old 7 days worth + bucketize by day
  # todo make config ridiculously easy LOL
  
  input = "-f dshow -i video=\"USB Video Device\""
  input = "tee.avs" # test 
  # -vf hqdn3d=4:4:4:4:4
  # -vcodec libx264 ?
  if ARGV.detect{|a| a == '--preview'}
    c = %!ffmpeg\\ffplay #{input}!
    system c
    exit
  end
  filename = "#{bucket_dir}/#{current_file_timestamp}.mp4"
    
  c = %!ffmpeg\\ffmpeg.exe -i #{input} "#{filename}" -t #{sixty_minutes} 2>&1!
  
  puts c
  out_handle = IO.popen(c)
  `.\\SetPriority.exe -lowest #{out_handle.pid}`
  raise unless $?.exitstatus == 0
  out = out_handle.read
  generate_preview_image filename
  }
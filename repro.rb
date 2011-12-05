$count = 1
def lowify
  # avoid WMI which apparently leaks
  piddys = `tasklist`

end

Thread.new { 

  out_handle = IO.popen('ls')

loop { lowify } 

}


sleep 1 # make this show up lower on the display console
puts 'hit enter to quit/cancel current vid'
gets
system("taskkill /f /im ffmpeg*")
$count = 1
def lowify
  # avoid WMI which apparently leaks
  piddys = `tasklist`

end

Thread.new { 

loop { lowify } 

}


gets
system("taskkill /f /im ffmpeg*")
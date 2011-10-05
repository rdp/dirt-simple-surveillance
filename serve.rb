require 'webrick'
include WEBrick

s = HTTPServer.new(:Port => 9090,  :DocumentRoot => Dir.pwd + '/captured_video')
trap("INT"){ s.shutdown }
s.start
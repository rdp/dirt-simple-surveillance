$:.unshift "./vendor/simple_gui_creator/lib"
require 'simple_gui_creator'

ENV['PATH'] = 'vendor\\ffmpeg;vendor;' + ENV['PATH'] # put our ffmpeg first, see jruby#6211
require 'simple_gui_creator'

def get_sorted_day_dirs
			dirs = Dir['captured_video/*/*']
			dirs.sort_by{|name| name.split('/')[2]}
end

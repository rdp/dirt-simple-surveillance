Dir['./vendor/**/lib'].each{|lib_dir|
  $:.unshift lib_dir
}
require 'simple_gui_creator'
require 'fileutils'

ENV['PATH'] = 'vendor\\ffmpeg;vendor;' + ENV['PATH'] # put our ffmpeg first, see jruby#6211

UsbStorage = Storage.new('dirt_simple_storage')
UsbStorage.set_default('devices_to_record', {}) # empty default

# attempt to find the "my movies" dir...which apparently isn't easy? yikes...
dir = ENV['HOMEPATH'] + '/Videos'
dir = File.expand_path(dir) # expand_path for jruby bugz' sake :)
if !File.directory? File.expand_path(dir)
  dir = ENV['HOMEPATH'] + '/My Documents/My Videos'
  if !File.directory? File.expand_path(dir)
    puts 'unable to find a videos folder?'
    dir = ENV['APPDATA']  # punt!
  end
end

dir = File.expand_path(dir + '/dirt_simple_surveillance')
Dir.mkdir dir unless File.directory?(dir)
UsbStorage.set_default('storage_dir', dir)

def base_storage_dir
  UsbStorage['storage_dir']
end

def get_sorted_day_dirs
	dirs = Dir[UsbStorage['storage_dir'] + '/*/*'] # camera_name/day
	dirs.sort_by{|name| name.split('/')[2]}
end

class Numeric
  # meaning "gigs" :)
  def g
    "%.02fG" % (self/1_000_000_000.0)
  end
  def gig
    self*1e9
  end
end

Delete_if_we_have_less_than_this_much_free_space = 10.gig
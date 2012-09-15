$:.unshift "./vendor/simple_gui_creator/lib"
require 'simple_gui_creator'
require 'fileutils'

ENV['PATH'] = 'vendor\\ffmpeg;vendor;' + ENV['PATH'] # put our ffmpeg first, see jruby#6211
require 'simple_gui_creator'

UsbStorage = Storage.new('dirt_simple_usb_storage')
UsbStorage.set_default('devices_to_record', {})

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

dir = File.expand_path(dir + '/usb_surveillance')
Dir.mkdir dir unless File.directory?(dir)
UsbStorage.set_default('storage_dir', dir)

def get_sorted_day_dirs
	dirs = Dir[UsbStorage['storage_dir'] + '/*/*'] # camera_name/day
	dirs.sort_by{|name| name.split('/')[2]}
end

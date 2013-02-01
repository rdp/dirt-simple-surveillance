# add vendored gems
Dir[File.dirname(__FILE__) + '/../vendor/**/lib'].each{|lib_dir|
  $:.unshift lib_dir
}

require 'simple_gui_creator'
require 'fileutils'

ENV['PATH'] = 'vendor\\ffmpeg;vendor;' + ENV['PATH'] # put our ffmpeg first, see jruby#6211
FFmpegHelpers::FFmpegNameToUse.gsub(/.*/, "ffmpeg_dirt_simple.exe")

UsbStorage = Storage.new('dirt_simple_storage')
UsbStorage.set_default('devices_to_record', {}) # empty default

# attempt to find a "my movies" dir...which apparently isn't easy?

dir = ENV['HOMEPATH'] + '/Videos'
dir = File.expand_path(dir) # expand_path for jruby bugz' sake :)
if !File.directory? File.expand_path(dir)
  dir = ENV['HOMEPATH'] + '/My Documents/My Videos'
  if !File.directory? File.expand_path(dir)
    puts 'unable to find a videos folder?'
    dir = ENV['APPDATA'] # punt!
  end
end
dir = File.expand_path(dir + '/dirt_simple_surveillance')
Dir.mkdir dir unless File.directory?(dir)
UsbStorage.set_default('storage_dir', dir)

def base_storage_dir
  UsbStorage['storage_dir']
end

def get_sorted_day_dirs
  dirs = Dir[base_storage_dir + '/*/*'] # camera_name/day
  dirs.reject{|d| File.file? d}.sort_by{|name| date = name.split('/')[-1]} # only directories, sort
end

def current_devices
  UsbStorage['devices_to_record']
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

UsbStorage.set_default('delete_if_we_have_less_than_this_much_free_space', 10.gig)
def free_space_requested
  UsbStorage['delete_if_we_have_less_than_this_much_free_space']
end

def set_free_space_requested to_this
  UsbStorage['delete_if_we_have_less_than_this_much_free_space'] = to_this
end

UsbStorage.set_default('encoding_bitrate', 500_000)

def encoding_bitrate_with_k
  (UsbStorage['encoding_bitrate']/1000).to_s + 'k'
end



def days_left_to_record
    free_space = java.io.File.new(base_storage_dir).freeSpace
	free_space -= free_space_requested
	device_count = [current_devices.length, 1].max # avoid divide by zero in the math below :)
    out = free_space/device_count/(UsbStorage['encoding_bitrate']/8*60*60*24)
	out.round(2)
end
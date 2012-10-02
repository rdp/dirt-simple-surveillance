require 'shared'
currently_running_filename =  UsbStorage['storage_dir'] + '/currently_running'
currently_hidden_filename =  UsbStorage['storage_dir'] + '/currently_hidden'
wakeup_filename = UsbStorage['storage_dir'] + '/wake_up'
p currently_running_filename, currently_hidden_filename, wakeup_filename
if File.exist? currently_running_filename
  if File.exist? currently_hidden_filename
    require 'fileutils'
    FileUtils.touch wakeup_filename
    puts 'it should be coming up, if running at all...'
    exit 0
  else
    if SimpleGuiCreator.show_select_buttons_prompt("possibly already running in other window, run anyway?") == :yes
	  FileUtils.rm_rf currently_running_filename
	else
	  exit 1
	end
  end
end
require File.dirname(__FILE__) + '/../lib/setup.rb'
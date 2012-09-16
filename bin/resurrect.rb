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
  else
    SimpleGuiCreator.show_text "already running in other window, use that instead..."
  end
else
 require File.dirname(__FILE__) + '/setup.rb'
end

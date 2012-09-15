require 'shared'
      wakeup_filename = UsbStorage['storage_dir'] + '/wake_up'
require 'fileutils'
FileUtils.touch wakeup_filename
puts 'it should be coming up, if running at all...'

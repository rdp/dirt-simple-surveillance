require 'shared'
a = SimpleGuiCreator::ParseTemplate.new.parse_setup_filename('lib\\setup.sgc')

a.elements[:add_new_url].on_clicked {
  puts 'clicked url'
  SimpleGuiCreator.display_text "not implemented yet!"
}

a.elements[:add_new_local].on_clicked {
 devices = FfmpegHelpers.enumerate_directshow_devices[:video]
 p devices
}

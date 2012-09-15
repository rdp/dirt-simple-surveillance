require 'shared'
Storage
include SimpleGuiCreator
a = ParseTemplate.new.parse_setup_filename('lib\\setup.sgc')

old_existing = UsbStorage['devices_to_record']
incoming_string = "Currently recording to the following devices:"
p old_existing

if(old_existing.size == 0) # TODO something like 'add_text_at_current_spot' I guess...
 incoming_string += " (none yet, add one!):"
end

def add_device device_name, english_name, to_this
  to_this.add_setup_string_at_bottom %! "#{device_name} => #{english_name}" !
  to_this.set_size 350,500 # TODO not have to do this...
end
a.set_size 350,500 # TODO not have to do this...

a.add_setup_string_at_bottom  '"' + incoming_string + '"'
old_existing.each{|device_name, name|
  add_device device_name, name, a
}

a.elements[:add_new_url].on_clicked {
  SimpleGuiCreator.display_text "not implemented yet!"
}

a.elements[:add_new_local].on_clicked {
 video_devices = FfmpegHelpers.enumerate_directshow_devices[:video]
 new_name = DropDownSelector.new(nil, video_devices, "Select video device to capture").go_selected_value
 english_name = SimpleGuiCreator.get_input "Please enter the 'alias' name you'd like to have (human friendly name) for #{new_name}:", new_name
 UsbStorage['devices_to_record'][new_name] =  UsbStorage['devices_to_record'][new_name] || english_name
 UsbStorage['devices_to_record'] =  UsbStorage['devices_to_record'] # force save [hmm...]
 add_device new_name, english_name, a
 # TODO frame rate/size etc. options :)
}

a.elements[:reveal_recordings].on_clicked {
  SimpleGuiCreator.show_in_explorer UsbStorage['storage_dir']
}

require './lib/go.rb'

a.elements[:preview_capture].on_clicked {
  do_something true
}

modes = ['start', 'stop']
current_mode_idx = 0
a.elements[:start_stop_capture].on_clicked {
  current_mode = modes[current_mode_idx % 2]
  if current_mode == 'start'
    do_something
	a.elements[:start_stop_capture].text = 'Stop capturing'
  else
    shutdown_current
	a.elements[:start_stop_capture].text = 'Start capturing'
  end
  current_mode_idx += 1
}
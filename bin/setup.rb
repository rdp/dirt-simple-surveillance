require 'shared'

include SimpleGuiCreator
a = ParseTemplate.new.parse_setup_filename('lib\\setup.sgc')

old_existing = UsbStorage['devices_to_record']

if(old_existing.size == 0) # TODO something like 'add_text_at_current_spot' I guess...
 a.elements[:device_list_header].text += " (none yet, add one!):"
end

@device_count = 0

def add_device device_name, english_name, to_this
  init_string = "#{english_name}"
  if device_name != english_name
    init_string += " (#{device_name})"
  end

  init_string = '"' + init_string + '"'
  my_remove_button_name = "remove_#{@device_count += 1}"
  init_string += "[Remove:#{my_remove_button_name}]"
  to_this.add_setup_string_at_bottom init_string
  to_this.elements[my_remove_button_name.to_sym].on_clicked {
    UsbStorage['devices_to_record'].delete(device_name)
	UsbStorage['devices_to_record'] = UsbStorage['devices_to_record'] # force save
	SimpleGuiCreator.display_text "please run it again to refresh the list"
	to_this.close
  }
  to_this.set_size 350,450 # TODO not have to do this...
end

old_existing.each{|device_name, name|
  add_device device_name, name, a
}
a.set_size 350,450 # TODO not have to do this...

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
  assert_have_record_devices_setup
  SimpleGuiCreator.show_in_explorer Dir[UsbStorage['storage_dir'] + '/*'][0]
}

require './lib/go.rb'

a.elements[:preview_capture].on_clicked {
  do_something true
}

def assert_have_record_devices_setup
    if UsbStorage['devices_to_record'].length == 0
	  SimpleGuiCreator.display_text "you cannot start recording you don't have anything setup to record just yet\nadd something first"
	  raise 'add something'
	end
end

modes = ['start', 'stop']
current_mode_idx = 0
a.elements[:start_stop_capture].on_clicked {
  current_mode = modes[current_mode_idx % 2]
  if current_mode == 'start'
    assert_have_record_devices_setup
	video_size_time = 60*60
	if ARGV[0] == '--small-videos'
	  video_size_time = 30 # seconds
	end
    do_something false, video_size_time
	a.elements[:start_stop_capture].text = 'Stop recording'
	a.elements[:start_recording_text].text = "Recording started!"
	Thread.new { sleep 2.5; a.elements[:start_recording_text].text = ""; }
  else
    shutdown_current
	a.elements[:start_stop_capture].text = 'Start recording'
  end
  current_mode_idx += 1
}

a.elements[:reveal_snapshots].on_clicked {
  require './lib/show_last_images.rb'
  show_recent_snapshot_images
}
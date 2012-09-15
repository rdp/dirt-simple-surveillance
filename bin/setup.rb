require 'shared'

include SimpleGuiCreator
a = ParseTemplate.new.parse_setup_filename('lib\\setup.sgc')

old_existing = UsbStorage['devices_to_record']

if(old_existing.size == 0) # TODO something like 'add_text_at_current_spot' I guess...
 a.elements[:device_list_header].text += " (none yet, add one!):"
end

@device_count = 0

def add_device device_name, english_name, to_this
  UsbStorage['devices_to_record'][device_name] = english_name
  UsbStorage['devices_to_record'] = UsbStorage['devices_to_record'] # force save [hmm...]
  
  init_string = "#{english_name}"
  if device_name != english_name
    init_string += " (#{device_name})"
  end

  unique_number = @device_count += 1
  init_string = '"' + init_string + ":name_string_#{unique_number}\""
  my_remove_button_name = "remove_#{unique_number}"
  init_string += "[Remove:#{my_remove_button_name}]"
  to_this.add_setup_string_at_bottom init_string
  to_this.elements[my_remove_button_name.to_sym].on_clicked {
    UsbStorage['devices_to_record'].delete(device_name)
	UsbStorage['devices_to_record'] = UsbStorage['devices_to_record'] # force save
	to_this.elements[:"name_string_#{unique_number}"].text = 'removed it!'
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
 video_devices.reject!{|name| UsbStorage['devices_to_record'][name]} # avoid re-adding same camera...
 new_name = DropDownSelector.new(nil, video_devices, "Select video device to capture").go_selected_value
 english_name = SimpleGuiCreator.get_input "Please enter the 'alias' name you'd like to have (human friendly name) for #{new_name}:", new_name

 video_fps_options = FfmpegHelpers.get_options_video_device new_name
 # like  {:video_type=>"vcodec", :video_type_name=>"mjpeg", :min_x=>"800", :max_x=>"800", :max_y=>"600", "30"=>"30"}
 require 'ruby-debug'
 #debugger
 # now for a huge list...
 displayable = []
 video_fps_options.each{|original| (original[:min_fps]..original[:max_fps]).step(5).each{|real_fps| displayable << original.dup.merge(:fps => real_fps, :x => original[:max_x], :y => original[:max_y])} }
 english_names = displayable.map{|options| "#{options[:x]}x#{options[:y]} #{options[:fps]}fps (#{options[:video_type_name]})"}
 idx = DropDownSelector.new(nil, ['default'] + english_names, "Select frame rate if desired").go_selected_index
 selected = displayable[idx - 1]
 p 'got', selected
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
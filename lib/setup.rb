require 'shared'
require './lib/go.rb'

include SimpleGuiCreator
a = ParseTemplate.new.parse_setup_filename('lib\\setup.sgc')

def current_devices
  UsbStorage['devices_to_record']
end

@a = a
def setup_ui
 @a.elements[:currently_have].text = "currently have #{current_devices.length}"
 if current_devices.length == 0
   @a.elements[:start_stop_capture].disable!
 else
   @a.elements[:start_stop_capture].enable!
 end
end

setup_ui

if(current_devices.size == 0)
 a.elements[:device_list_header].text += " (none yet, add one!):"
end

@device_count = 0

def save_devices!
  UsbStorage['devices_to_record'] = UsbStorage['devices_to_record'] # force save [hmm...]
  setup_ui
end

def get_descriptive_line device_name, english_name
  init_string = "#{english_name}"
  if device_name != english_name
    init_string += " (#{device_name})"
  end
  init_string

end

def add_device device_name, english_name, options, to_this
  current_devices[device_name] = [english_name, options]
  save_devices!
  
  init_string = get_descriptive_line device_name, english_name
  
  unique_number = @device_count += 1
  init_string = '"' + init_string + ":name_string_#{unique_number}\""
  init_string += "[Remove:remove_#{unique_number}] [Configure:configure_#{unique_number}]"
  to_this.add_setup_string_at_bottom init_string
  to_this.elements[:"remove_#{unique_number}"].on_clicked {
    current_devicess.delete(device_name)
	save_devices!
	to_this.elements[:"name_string_#{unique_number}"].text = 'removed it!'
  }
  to_this.elements[:"configure_#{unique_number}"].on_clicked {
    options, english_name = configure_device_options device_name, english_name
	to_this.elements[:"name_string_#{unique_number}"].text = get_descriptive_line device_name, english_name
	current_devices[device_name] = [english_name, options]
	save_devices!
  }
  
  setup_ui
  
#  to_this.set_size 400,450 # TODO not have to do this...
end

current_devices.each{|device_name, (name, options)|
  add_device device_name, name, options, a
}

a.set_size 400,450 # TODO not have to do this...

a.elements[:add_new_url].on_clicked {
  SimpleGuiCreator.display_text "not implemented yet!"
}

def prettify_number n
  if n % 1 != 0
    n
  else
    n.to_i
  end
end

def configure_device_options device_name, english_name
 video_fps_options = FFmpegHelpers.get_options_video_device device_name
 # like  {:video_type=>"vcodec", :video_type_name=>"mjpeg", :min_x=>"800", :max_x=>"800", :max_y=>"600", "30"=>"30"}
 displayable = []
 
 video_fps_options.each{|original| 
   step = 5
   step = 2.5 if (original[:max_fps] % 5) == 2.5
   (original[:min_fps]..original[:max_fps]).step(step).each{|real_fps| 
     displayable << original.dup.merge(:fps => real_fps, :x => original[:max_x], :y => original[:max_y])
   } 
 }
 english_names = displayable.map{|options| "#{options[:x]}x#{options[:y]} #{prettify_number options[:fps]}fps (#{options[:video_type_name]})"}
 idx = DropDownSelector.new(nil, ['default'] + english_names, "Select frame rate if desired").go_selected_index
 if idx == 0
   idx = 1 # reasonable default I guess, though starts with low fps...
 end
 english_name = SimpleGuiCreator.get_input "Please enter the 'alias' name you'd like to have (human friendly name) for #{device_name}:", english_name || device_name
 selected_options = displayable[idx - 1]
 [selected_options, english_name]
end

a.elements[:add_new_local].on_clicked {
 video_devices = FFmpegHelpers.enumerate_directshow_devices[:video].map{|name, idx| name}
 video_devices.reject!{|name| current_devices[name]} # avoid re-adding same camera by including it in the dropdown...
 device_name = DropDownSelector.new(nil, video_devices, "Select video device to capture").go_selected_value
 options, english_name = configure_device_options device_name, nil
 add_device device_name, english_name, options, a
}

a.elements[:reveal_recordings].on_clicked {
  SimpleGuiCreator.show_in_explorer Dir[UsbStorage['storage_dir'] + '/*'][0]
}

a.elements[:preview_capture].on_clicked {
  do_something true
}

def assert_have_record_devices_setup
    if current_devices.length == 0
	  SimpleGuiCreator.display_text "you cannot start recording you don't have anything setup to record just yet\nadd something first"
	  raise 'add something'
	end
end

current_state = :stopped # :running
a.elements[:start_stop_capture].on_clicked {
  if current_state == :stopped
    assert_have_record_devices_setup
	video_size_time = 60*60
	if ARGV[0] == '--small-videos'
	  video_size_time = 30 # seconds
	end
    do_something false, video_size_time
	a.elements[:start_stop_capture].text = 'Stop recording'
	a.elements[:start_recording_text].text = "Recording started!"
	Thread.new { sleep 2.5; a.elements[:start_recording_text].text = ""; }
	current_state = :running
  else
    shutdown_current
	a.elements[:start_stop_capture].text = 'Start recording'
	current_state = :stopped
  end
}

a.after_closed {
  if current_state == :running
    SimpleGuiCreator.show_text "warning, shutting down recorder [hit disappear button to put continue recording...]"
	a.elements[:start_stop_capture].simulate_click
  end
}

a.elements[:reveal_snapshots].on_clicked {
  require './lib/show_last_images.rb'
  show_recent_snapshot_images current_devices.map{|dev_name, (english_name, options)| english_name}
}

currently_hidden_filename = UsbStorage['storage_dir'] + '/currently_hidden'
currently_running_filename = UsbStorage['storage_dir'] + '/currently_running'

a.elements[:disappear_window].on_clicked {
  if current_state == :stopped
    SimpleGuiCreator.show_text "you probably only want to do this [disappear the window] if you're already recording\n which you aren't yet!"
  else
    FileUtils.touch currently_hidden_filename
    a.visible=false
    Thread.new { 
      wakeup_filename = UsbStorage['storage_dir'] + '/wake_up'
      while(a.visible == false)
	    sleep 1
	    if File.exist?(wakeup_filename) 
		  a.visible=true
		  File.delete wakeup_filename
		  File.delete currently_hidden_filename
		end
	  end 
    }
  end
}

if ARGV.detect{|a| a == '--background-start'}
  a.elements[:disappear_window].simulate_click
end


FileUtils.touch currently_running_filename
a.after_closed {
  FileUtils.rm_rf currently_running_filename
  FileUtils.rm_rf currently_hidden_filename
}
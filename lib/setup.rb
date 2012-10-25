require 'shared'
require './lib/go.rb'

include SimpleGuiCreator
a = ParseTemplate.new.parse_setup_filename('lib\\setup.sgc')

def current_devices
  UsbStorage['devices_to_record']
end

@a = a
@current_state = :stopped # :running

def setup_ui
 @a.elements[:currently_have].text = "currently have #{current_devices.length}"
 if current_devices.length == 0
   @a.elements[:start_stop_capture].disable!
 else
   @a.elements[:start_stop_capture].enable!
 end
 if @current_state == :running
   @a.elements[:current_state].text = "Running!"
 else
   @a.elements[:current_state].text = "Stopped."
  end
 
end

setup_ui

if(current_devices.size == 0)
 a.elements[:device_list_header].text += " (none yet, add one!):"
end

@unique_line_number = 0

def save_devices!
  UsbStorage['devices_to_record'] = UsbStorage['devices_to_record'] # force save [hmm...]
  setup_ui
end

def get_descriptive_line device, english_name
  init_string = "#{english_name}"
  if device[0] != english_name || device[1] > 0
    init_string += " (#{device[0]} #{ device[1] if device[1] > 0})"
  end 
  init_string

end

def add_device device, english_name, options, to_this
  current_devices[device] = [english_name, options]
  save_devices!
  
  init_string = get_descriptive_line device, english_name
  
  unique_number = @unique_line_number += 1
  init_string = '"' + init_string + ":name_string_#{unique_number}\""
  init_string += "[Remove:remove_#{unique_number}] [Configure:configure_#{unique_number}]"
  init_string += "[Preview:preview_#{unique_number}]"
  
  to_this.add_setup_string_at_bottom init_string
  to_this.elements[:"remove_#{unique_number}"].on_clicked {
    current_devices.delete(device)
	save_devices!
	to_this.elements[:"name_string_#{unique_number}"].text = 'removed it!'
  }
  
  to_this.elements[:"configure_#{unique_number}"].on_clicked {
    english_name, options = configure_device_options device, english_name, options
	to_this.elements[:"name_string_#{unique_number}"].text = get_descriptive_line device, english_name
	current_devices[device] = [english_name, options]
	save_devices!
  }
  
  to_this.elements[:"preview_#{unique_number}"].on_clicked {
    do_something current_devices.select{|d| d == device}, true    
  }
  
end

current_devices.each{|device, (name, options)|
  add_device device, name, options, a
}

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

def configure_device_options device, english_name, old_options
 video_fps_options = FFmpegHelpers.get_options_video_device device[0], device[1]
 # like  {:video_type=>"vcodec", :video_type_name=>"mjpeg", :min_x=>"800", :max_x=>"800", :max_y=>"600", "30"=>"30"}
 displayable = []
 frame_rates = []
 
 video_fps_options.each{|original|
   step = 5
   step = 2.5 if (original[:max_fps] % 5) == 2.5
   (original[:min_fps]..original[:max_fps]).step(step).each{|real_fps| 
     displayable << original.dup.merge(:fps => real_fps, :x => original[:max_x], :y => original[:max_y])
   } 
 }
 displayable.sort_by!{|hash| hash[:max_x]*hash[:max_y]}
 if old_options
   # add it to the top
   displayable = [old_options] + displayable
 end
 english_names = displayable.map{|options| "#{options[:x]}x#{options[:y]} #{prettify_number options[:fps]}fps (#{options[:video_type_name]})"}
 idx = DropDownSelector.new(nil, ['default'] + english_names, "Select frame rate/output type if desired").go_selected_index
 if idx == 0
   idx = 1 # LODO somewhat wrong now...way too low fps on init...
 end
 selected_options = displayable[idx - 1]
 if SimpleGuiCreator.show_select_buttons_prompt('would you like to preview it/view it?') == :yes
   do_something({device => [english_name, selected_options]}, true) # conveniently, we have settings now so can preview it...
 end
 english_name = SimpleGuiCreator.get_input "Please enter the 'alias' name you'd like to have (human friendly name) for #{device[0]}:", english_name || device[0]
 [english_name, selected_options]
end

a.elements[:add_new_local].on_clicked {
  video_devices = FFmpegHelpers.enumerate_directshow_devices[:video]
  video_devices.reject!{|name_idx| current_devices[name_idx]} # avoid re-adding same camera by including it in the dropdown...
  idx = DropDownSelector.new(nil, video_devices.map{|name, idx| name}, "Select video device to capture").go_selected_idx
  device = video_devices[idx]
  if device[1] > 0
    SimpleGuiCreator.show_text "this is a device with a name that matches another device on the system\n not supported yet, ask me to fix it and I will try.\nIn the meantime you can edit your registry for a FriendlyName\nentry that matches that one, and modify that."
	raise
  end
  english_name, options = configure_device_options device, nil
  add_device device, english_name, options, a
  SimpleGuiCreator.show_text "Added it #{english_name}"
}

a.elements[:reveal_recordings].on_clicked {
  SimpleGuiCreator.show_in_explorer Dir[UsbStorage['storage_dir'] + '/*'][0]
}

a.elements[:preview_capture].on_clicked {
  do_something current_devices, true
}

def assert_have_record_devices_setup
    if current_devices.length == 0
	  SimpleGuiCreator.display_text "you cannot start recording you don't have anything setup to record just yet\nadd something first"
	  raise 'add something'
	end
end

a.elements[:start_stop_capture].on_clicked {
  if @current_state == :stopped
    assert_have_record_devices_setup
	video_size_time = 60*60
	if ARGV[0] == '--small-videos'
	  video_size_time = 30 # seconds
	end
    do_something current_devices, false, video_size_time
	a.elements[:start_stop_capture].text = 'Stop recording'
	a.elements[:start_recording_text].text = "Recording started!"
	Thread.new { sleep 2.5; a.elements[:start_recording_text].text = ""; }
	@current_state = :running
  else
    shutdown_current
	a.elements[:start_stop_capture].text = 'Start recording'
	@current_state = :stopped
  end
  setup_ui
}

a.after_closed {
  if @current_state == :running
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
  if @current_state == :stopped
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
  a.elements[:start_stop_capture].click!
#  a.minimize! # lodo
  # ffmpeg's can't stop?
  # a.elements[:disappear_window].click!
end

FileUtils.touch currently_running_filename
a.after_closed {
  FileUtils.rm_rf currently_running_filename
  FileUtils.rm_rf currently_hidden_filename
}
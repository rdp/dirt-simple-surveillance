require 'shared'
require './lib/go.rb'

include SimpleGuiCreator
a = ParseTemplate.new.parse_setup_filename('lib\\setup.sgc')

def current_devices
  UsbStorage['devices_to_record']
end

@a = a
@current_state = :stopped # :running
@a.set_icon_image java.awt.Toolkit::default_toolkit.get_image('vendor/webcam-clipart.png')

def setup_ui
 @a.elements[:currently_have].text = "currently have #{current_devices.length} setup"
 if current_devices.length == 0
   @a.elements[:start_stop_capture].disable!
   @a.elements[:disappear_window].disable!
 else
   @a.elements[:start_stop_capture].enable!
   @a.elements[:disappear_window].enable!
 end
 
 if @current_state == :running 
   @a.set_icon_image java.awt.Toolkit::default_toolkit.get_image('vendor/webcam-clipart-enabled.png')
   @a.elements[:current_state].text = "Currently Recording!"
   @a.title = @a.original_title + " [running]"
 else
   @a.set_icon_image java.awt.Toolkit::default_toolkit.get_image('vendor/webcam-clipart.png')
   @a.elements[:current_state].text = "Currently Stopped."
   @a.title = @a.original_title + " [stopped]"
  end  
  
  free_space = java.io.File.new(base_storage_dir).freeSpace
  @a.elements[:options_message].text = "Will record to #{base_storage_dir.split('/')[-4..-1].join('/')} at 500 kb/s/camera until there is #{Delete_if_we_have_less_than_this_much_free_space.g} free"
  
  if(current_devices.size == 0)
    @a.elements[:current_state].text += " (no devices yet, add one first!):"
	@a.elements[:start_stop_capture].text = "add a device first!"
  else
    @a.elements[:start_stop_capture].text = @a.elements[:start_stop_capture].original_text
  end
  
end

setup_ui

@unique_line_number = 0

def save_devices!
  UsbStorage['devices_to_record'] = UsbStorage['devices_to_record'] # force a save [hmm...]
  setup_ui
end

def get_descriptive_line device, english_name
  output = "#{english_name}"
  if device[0] != english_name || device[1] > 0
    output += " (#{device[0]} #{device[1] if device[1] > 0})"
  end 
  output
end

def add_device device, english_name, options, to_this
  current_devices[device] = [english_name, options]
  save_devices!
  
  init_string = get_descriptive_line device, english_name
  
  unique_number = @unique_line_number += 1
  init_string = '"' + init_string + ":name_string_#{unique_number}\" \"at #{options[:x]}x#{options[:y]}:\""
  init_string += "\n  \"      \" " # add an empty spacer in it...
  init_string += "[Remove:remove_#{unique_number}]"
  init_string += "[Configure:configure_#{unique_number}]"
  init_string += "[View Files:view_files_#{unique_number}]"
  init_string += "[Preview capture:preview_#{unique_number}]"
  init_string += "\n  \"      \" " # add an empty spacer in it...
  init_string += "[Preview save quality:preview_recording_#{unique_number}]"
  init_string += "[Show recent image:snapshot_#{unique_number}]"
  
  to_this.add_setup_string_at_bottom init_string
  
  # TODO make these sensitive...
  to_this.elements[:"preview_recording_#{unique_number}"].on_clicked {
    SimpleGuiCreator.show_non_blocking_message_dialog "ok recording for 20 seconds, then will reveal the saved file....
	This will allow you to see what the encode quality is like
	Also sometimes it starts out very poor quality grainy but improves with time, so meter it by how it becomes, not how it starts."
    do_something current_devices.select{|d| d == device}, false
	SimpleGuiCreator.run_later(20) {
	  shutdown_current
	  last_day = Dir[base_storage_dir + '/' + english_name + '/*'].sort[-1]
      last_file = Dir[last_day + '/*.mp4'].sort_by{|f| File.mtime(f)}[-1]
      SimpleGuiCreator.show_in_explorer last_file
	}
  }
  
  to_this.elements[:"snapshot_#{unique_number}"].on_clicked {
    show_recent_snapshot_image english_name
  }
  
  to_this.elements[:"remove_#{unique_number}"].on_clicked {
    current_devices.delete(device)
	save_devices!
	show_message "ok removed it, please restart app..."	
	to_this.close!
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
  
  to_this.elements[:"view_files_#{unique_number}"].on_clicked {
    SimpleGuiCreator.show_in_explorer Dir[base_storage_dir + '/' + english_name + '/*'].sort[-1] # latest day..
  }
  
end

def show_message message
  SimpleGuiCreator.show_message message
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

def configure_device_options device, english_name, old_options = nil
 english_name ||= device[0]
 video_fps_options = FFmpegHelpers.get_options_video_device device[0], device[1]
 # like  {:video_type=>"vcodec", :video_type_name=>"mjpeg", :min_x=>"800", :max_x=>"800", :max_y=>"600", "30"=>"30"}
 displayable = []
 frame_rates = []
 
 video_fps_options.each{|original|
   step = 5
   step = 2.5 if (original[:max_fps] % 5) == 2.5 # some only have from 7.5 to 10, so accomodate...
   (original[:min_fps]..original[:max_fps]).step(step).each{|real_fps| 
     displayable << original.dup.merge(:fps => real_fps, :x => original[:max_x], :y => original[:max_y])
   } 
 }
 
 displayable.sort_by!{|hash| hash[:max_x]*hash[:max_y]}
 if old_options
   # add it to the top
   displayable = [old_options] + displayable
 else
   good_default = displayable.sort_by{|settings| settings[:video_type]}.sort_by{|settings| - settings[:max_x] * settings[:max_y]}[0] # is pixel type, biggest, lowest fps [I think]
   displayable = [good_default] + displayable
 end
 english_names = displayable.map{|options| "#{options[:x]}x#{options[:y]} #{prettify_number options[:fps]}fps (#{options[:video_type_name]})"}
 idx = DropDownSelector.new(nil, ["default"] + english_names, "Select frame rate/output type if desired").go_selected_index
 if idx == 0
   idx = 1 # skip from english 'default' to the top listed default in our local array :)
 end
 selected_options = displayable[idx - 1]
 if SimpleGuiCreator.show_select_buttons_prompt('would you like to preview it/view it?') == :yes
   do_something({device => [english_name, selected_options]}, true) # conveniently, we have settings now so can use our existing preview code to preview it...
 end
 english_name = SimpleGuiCreator.get_input "Please enter the 'alias' name you'd like to have (human friendly name) for #{device[0]}:", english_name
 [english_name, selected_options]
 
end

a.elements[:add_new_local].on_clicked {
  video_devices = FFmpegHelpers.enumerate_directshow_devices[:video]
  video_devices.reject!{|name_idx| current_devices[name_idx]} # avoid re-adding same camera by including it in the dropdown...
  idx = DropDownSelector.new(nil, video_devices.map{|name, idx| name}, "Select new video device to capture").go_selected_idx
  device = video_devices[idx]
  if device[1] > 0
    SimpleGuiCreator.show_text "this is a device with a name that matches another device on the system\n not supported yet, ask me to fix it and I will try.\nIn the meantime you can edit your registry for a FriendlyName\nentry that matches that one, and modify that."
	raise
  end
  english_name, options = configure_device_options device, nil
  add_device device, english_name, options, a
  SimpleGuiCreator.show_text "Added it as: #{english_name}\nClick start recording to start recording!"
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
    a.elements[:disappear_window].click! # auto minimize on start...
  else
    shutdown_current
	a.elements[:start_stop_capture].text = 'Start recording'
	@current_state = :stopped
  end
  setup_ui
}

a.after_closed {
  if @current_state == :running
    SimpleGuiCreator.show_text "warning, shutting down current recordings... [hit disappear button next time if what you wanted is to continue recording...]"
	a.elements[:start_stop_capture].simulate_click
  end
}

require './lib/show_last_images.rb'

# couldn't figure out how to make it pretty nuff...
#a.elements[:exit].on_clicked {
#  d = SimpleGuiCreator.show_non_blocking_message_dialog "Exiting [not recording!]"
#  SimpleGuiCreator.run_later(1.5) {
#    a.close
#	d.close
#  }
#}

a.elements[:disappear_window].on_clicked {
  a.minimize! # fake minimize to tray :)
  require 'sys_tray'
  if @current_state == :running
    tray = SysTray.new('surveillance [running]', 'vendor/webcam-clipart-enabled.png')
  else
    tray = SysTray.new('surveillance [running]', 'vendor/webcam-clipart-disabled.png')
  end
  tray.add_menu_item('Exit and close') do
    tray.close
    a.close
  end
  tray.add_menu_item('Reveal surveillance') do
    tray.close
	a.visible=true
  end
  
  tray.on_double_left_click do
    # restore from tray :)
	a.visible=true
	a.unminimize! 
    tray.close
  end  
  tray.display_balloon_message "Simple Surveillance", "Minimized it to tray! [currently #{@current_state}]"
  a.visible=false
}

if ARGV.detect{|a| a == '--background-start'}
  a.elements[:start_stop_capture].click! # start it
  a.elements[:disappear_window].click!
end

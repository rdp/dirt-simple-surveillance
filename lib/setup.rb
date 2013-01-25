require 'shared'
require './lib/go.rb'

include SimpleGuiCreator
background_start = ARGV.detect{|a| a == '--background-start'}

a = ParseTemplate.new(!background_start).parse_setup_filename('lib\\setup.sgc')

def current_devices
  UsbStorage['devices_to_record']
end

@a = a
@current_state = :stopped # or :recording or :confused

def recording?
  @current_state == :recording || @current_state == :confused
end

def setup_ui

 if current_devices.length == 0
   @a.elements[:start_stop_capture].disable!
   @a.elements[:disappear_window].disable!
 else
   @a.elements[:start_stop_capture].enable!
   @a.elements[:disappear_window].enable!
 end
 
 if recording?
   @a.set_icon_image java.awt.Toolkit::default_toolkit.get_image('vendor/webcam-clipart-enabled.png')
   @a.elements[:current_state].text = "Currently Recording!"
   @a.title = @a.original_title + " [#{@current_state}]"
   @a.elements[:minimize_message].disable!
 else
   @a.set_icon_image java.awt.Toolkit::default_toolkit.get_image('vendor/webcam-clipart.png')
   @a.elements[:current_state].text = "Currently Stopped."
   @a.title = @a.original_title + " [stopped]"
   @a.elements[:minimize_message].enable!
  end  
  
  free_space = java.io.File.new(base_storage_dir).freeSpace
  @a.elements[:options_message].text = "Will record to #{base_storage_dir.split('/')[-4..-1].join('/')} at 500 kb/s/camera until there is #{Delete_if_we_have_less_than_this_much_free_space.g} free"
  
  if(current_devices.size == 0)
	@a.elements[:start_stop_capture].text = "add a camera 1st!"
  else
    if @current_state == :stopped
      @a.elements[:start_stop_capture].text = 'Start recording'
	else
	  raise @current_state.to_s unless recording?
	  @a.elements[:start_stop_capture].text = 'Stop recording'
	end
  end
  set_proper_tray_icon
end


def set_proper_tray_icon
  if @current_state == :recording
    name= 'surveillance [recording]'
	icon= 'vendor/webcam-clipart-enabled.png'
  elsif @current_state == :stopped
    name = 'surveillance [stopped!]'
	icon = 'vendor/webcam-clipart-disabled.png'
  elsif @current_state == :confused
    name = 'surveillance [confused!]'
	icon = 'vendor/webcam-clipart-confused.png'
  else
    raise 'huh #{@current_state}'
  end
  if @tray
    @tray.set_icon icon
    @tray.set_name name
  end
end

setup_ui # so it looks good earlier :)

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

def add_device_to_saved_list device, english_name, options
  if current_devices.key?(device)
    show_message "warning, got an error trying to save #{device.inspect} \n it would have overriden one that already exists\nperhaps you need to delete an older device first?"
    raise	
  end
  current_devices[device] = [english_name, options]
  save_devices!
end

# device like ['name', idx], name may be a url...
def add_device_to_gui device, english_name, options
  to_this = @a  
  unique_number = @unique_line_number += 1
  init_string = get_descriptive_line device, english_name  
  init_string = '"' + init_string + ":name_string_#{unique_number}\" "
  if options[:x]
    init_string += "\"at #{options[:x]}x#{options[:y]}:\""
  end
  init_string += "\n  \"      \" " # add an empty spacer in it...
  init_string += "[Remove:remove_#{unique_number}]"
  init_string += "[Configure:configure_#{unique_number}]"
  init_string += "[View Files:view_files_#{unique_number}]"
  init_string += "[Preview camera angle:preview_#{unique_number}]"
  init_string += "\n  \"      \" " # add an empty spacer in it...
  init_string += "[Preview camera end save quality:preview_recording_#{unique_number}]"
  init_string += "[Show recent image:snapshot_#{unique_number}]"
  
  to_this.add_setup_string_at_bottom init_string
  
  # TODO make these state sensitive...
  to_this.elements[:"preview_recording_#{unique_number}"].on_clicked {
    SimpleGuiCreator.show_non_blocking_message_dialog %!The "record" quality for a camera is different than the camera preview show,
	because it encodes the video into a video codec [mpeg4video] that then saves space on the hard drive.
	This button will record for 20 seconds, then will reveal the recorded file,
	which you can playback to see the end quality of your recordings will be like.
	NB that sometimes it starts out very poor quality (grainy) but improves with time,
	so meter it by how it becomes/ends, not how it starts.!
    do_something current_devices.select{|d| d == device}, false
	SimpleGuiCreator.run_later(20) {
	  shutdown_current
	  last_day = Dir[base_storage_dir + '/' + english_name + '/*'].select{|f| File.directory?(f) }.sort[-1]
      last_file = Dir[last_day + '/*.mp4'].sort_by{|f| File.mtime(f)}[-1]
      SimpleGuiCreator.show_in_explorer last_file
	}
  }
  
  to_this.elements[:"snapshot_#{unique_number}"].on_clicked {
    filename = base_storage_dir + '/' + english_name + '/latest.jpg'
    if File.exist? filename
	  seconds_old = (Time.now - File.mtime(filename)).to_i
	  if seconds_old > 60
	    show_message "warning, this image is a little bit out of date (#{seconds_old/3600}h#{(seconds_old%3600)/60}m#{seconds_old % 60}s old),\nsince an active recording isn't going on.  While recording it will be more up to date."
	  end
      show_image english_name + " recent still image", filename
    else
      SimpleGuiCreator.show_message "you can only see a recent image after first starting a recording, use preview instead until then"
    end
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

def setup_network_device old_url, old_english_name, old_fps
  url = get_input "Please enter the url of the device of the network enabled camera you wish to record\nTypically like http://xxx.xxx.xxx.xxx:8080/stream_name for instance (flv, mjpeg, etc. url's are ok)\nMore advanced options:\n    rtsp://login:password@xxx.xxx.xxx.xxx/videoinput_1/mjpeg/media.stm\n    rtsp://login:password@xxx.xxx.xxx.xxx/videoinput_1/mjpeg/media.stm?tcp\n    http://xxx.xxx.xxx.xxx:port/stream_name?password=x&username=y&width=300...", (old_url || "http://...")
  name = get_input "Enter an optional user friendly alias name for #{url}", (old_english_name || url)
  fps = get_input "Some network streams [for instance, some mjpeg incoming streams] don't advertise their speed
  (frames per second), which can cause recording to assume 25 fps, which can cause playback to appear much too fast
  If you encouner this, and know the frame speed your device will be recording at, enter it here to hard code specify it (like 2.5 or 30.0)
  (or leave blank for auto detect)", old_fps, true
  if fps
    fps = fps.to_f # XXX assert it looks like a float LOL
    if fps <= 3
      show_message "since your fps is < 3, as a note, VLC won't be able to play back the recordings properly, but other players might."
    end
	if fps <= 0
	  show_message "please enter value greater than 0"
	  raise
	end
  end
  [url, name, fps]
end

a.elements[:add_new_url].on_clicked {
  url, name, fps = setup_network_device nil, nil, nil
  # assume they'll only input once per "different network camera" for now though I suppose they could record twice from the same... :)
  uniqueish_name = [url.split('?')[0], -1]
  options = {:url => url, :fps => fps}
  add_device_to_saved_list  uniqueish_name, name, options
  add_device_to_gui uniqueish_name, name, options
}

def prettify_number n
  if n % 1 != 0
    n
  else
    n.to_i
  end
end

# device like [name, idx] or [url, -1]
def configure_device_options device, english_name, old_options
 english_name ||= device[0]
 
 if old_options && old_options[:url]
   url, name, fps = setup_network_device old_options[:url], english_name, old_options[:fps]
   english_name = name
   old_options[:url] = url
   old_options[:fps] = fps
   return [english_name, old_options]
 end
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
 if SimpleGuiCreator.show_select_buttons_prompt("would you like to preview it/view it with these settings?\n(Useful for figuring out which camera it is/seeing it with the resolution you selected)") == :yes
   do_something({device => [english_name, selected_options]}, true) # conveniently, we have settings now so can use our existing preview code to preview it...
 end
 english_name = get_input "Please enter the 'alias' name you'd like to have (human friendly name) for #{device[0]}:", english_name
 [english_name, selected_options]
 
end

def get_input title, default, cancel_or_blank_ok=false
  SimpleGuiCreator.get_input title, default, cancel_or_blank_ok
end

a.elements[:add_new_local].on_clicked {
  video_devices = FFmpegHelpers.enumerate_directshow_devices[:video] # like [["USB Video Device", 0]...]
  video_devices.reject!{|name_idx| current_devices[name_idx]} # avoid re-adding an already being recorded camera by including it in the dropdown...
  idx = DropDownSelector.new(nil, video_devices.map{|name, idx| name}, "Select new video device to capture").go_selected_idx
  device = video_devices[idx]
  if device[1] > 0
    SimpleGuiCreator.show_text "this is a device with a name that matches another device on the system\n not supported yet, ask me to fix it and I will try.\nIn the meantime you can edit your registry for a FriendlyName\nentry that matches that one, and modify that."
	raise
  end
  english_name, options = configure_device_options device, nil, nil
  add_device_to_saved_list device, english_name, options
  add_device_to_gui device, english_name, options
  SimpleGuiCreator.show_text "Added it as: #{english_name}\nClick start recording to start recording, or add device to add another device."
}

def assert_have_record_devices_setup
    if current_devices.length == 0
	  SimpleGuiCreator.display_text "you cannot start recording you don't have anything setup to record just yet\nadd something first"
	  raise 'add something'
	end
end

UsbStorage.set_default(:minimize_on_start, true)

if UsbStorage[:minimize_on_start] # init value :)
  a.elements[:minimize_checkbox].check!
else
  a.elements[:minimize_checkbox].uncheck!
end

a.elements[:minimize_checkbox].on_checked {
  UsbStorage[:minimize_on_start] = true
}
a.elements[:minimize_checkbox].on_unchecked {
  UsbStorage[:minimize_on_start] = false
}

def start_recordings time = 60*60 # 1 hr
  do_something current_devices, false, time
end

a.elements[:start_stop_capture].on_clicked {

  if @current_state == :stopped
    assert_have_record_devices_setup
    start_recordings
	a.elements[:start_recording_text].text = "Recording started!"
	Thread.new { sleep 2.5; a.elements[:start_recording_text].text = ""; }
	@current_state = :recording
	if(UsbStorage[:minimize_on_start])
      a.elements[:disappear_window].click!
	end
  else
	@current_state = :stopped # early so we skip ffmpeg early out warnings if they click stop too early
    shutdown_current
  end
  setup_ui
}


a.after_closed {
  if recording?    
    show_message "warning--shutting down current recording processes because exiting\n[perhaps next time you want to click minimize to tray, instead?"
	# click stop
	a.elements[:start_stop_capture].simulate_click
	
	# can't reset up the thing yet, and after_closed only runs once...
	#if SimpleGuiCreator.show_select_buttons_prompt("warning, currently running, would you like to:", :yes => "minimize and keep running", :no => "exit and stop recording") == :yes
    #  a.elements[:disappear_window].simulate_click # have to do this whether it was closed from the 'X' or the tray, as the tray will have closed itself, too
	#  raise 'early out of proc, don't want to exit!'
	#else
	#  # click stop
	#  a.elements[:start_stop_capture].simulate_click
	#end
  end
  SimpleGuiCreator.hard_exit! # case we're still running, for the closed pipe bug...
}

require './lib/show_last_images.rb'

# couldn't figure out how to make it pretty yet...
#a.elements[:exit].on_clicked {
#  d = SimpleGuiCreator.show_non_blocking_message_dialog "Exiting [not recording!]"
#  SimpleGuiCreator.run_later(1.5) {
#    a.close
#	d.close
#  }
#}


a.elements[:disappear_window].on_clicked {
  if !recording?
    show_message "minimizing it without it running--did you mean to click the start button first?"
  end
  a.minimize! # fake minimize to tray :)
  
  require 'sys_tray'
  tray = SysTray.new nil, nil
  tray.add_menu_item('Exit and close') do
    tray.close
    a.close
  end
  tray.add_menu_item('Reveal surveillance') do
    restore_from_tray
  end
  
  tray.on_double_left_click do
    restore_from_tray
  end
  tray.display_balloon_message "Simple Surveillance", "Minimized it to tray! [currently #{@current_state}]"
  a.visible=false
  @tray = tray
  set_proper_tray_icon
}

def restore_from_tray
   # restore from tray :)
	@a.visible=true
	@a.unminimize! 
    @tray.close
	setup_ui # just in case 
end

def in_gui_thread
  SimpleGuiCreator.invoke_in_gui_thread { yield }
end

if get_all_ffmpeg_pids.length > 0
  if SimpleGuiCreator.show_select_buttons_prompt("warning--some ffmpeg recording instances are currently already going\nmaybe they're left overs from a previous run, or maybe you're already running the program somewhere else?!\nDo you want to kill them?") == :yes
    system("taskkill /f /im ffmpeg_dirt_simple.exe")
  end
end

current_devices.each{|device, (name, options)|
  add_device_to_gui device, name, options
}

if ARGV[0]
  if background_start
    if current_devices.size == 0
	  show_message "need to add some devices first!"
	  exit 1
	end
	a.elements[:start_stop_capture].click!
    if !(UsbStorage[:minimize_on_start])
      a.elements[:disappear_window].click!
    end
	begin
	  sleep # hope to avoid the early closed pipe bug...
	rescue Exception => e
	  p e, e.backtrace
	ensure 
 	  puts 'should never see this'
	end
  else
    puts 'only current option is --background-start'
    exit 1
  end
  puts 'should never see this2'
end
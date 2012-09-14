require 'shared'
Storage
include SimpleGuiCreator
a = ParseTemplate.new.parse_setup_filename('lib\\setup.sgc')

old_existing = UsbStorage['devices_to_record']
incoming_string = %! "Currently recording to the following devices:" !
p old_existing
if(old_existing.size == 0)
 incoming_string += " (none yet, add one!):"
end

a.add_setup_string_at_bottom  incoming_string
old_existing.each{|device_name, name|
  add_device device_name, name, a
}

def add_device device_name, english_name, to_this
  to_this.add_setup_string_at_bottom %! "#{device_name} => #{name}" !
end

a.set_size 500,500 # TODO not have to do this...
a.elements[:add_new_url].on_clicked {
  SimpleGuiCreator.display_text "not implemented yet!"
}

a.elements[:add_new_local].on_clicked {
 video_devices = FfmpegHelpers.enumerate_directshow_devices[:video]
 new_name = DropDownSelector.new(nil, video_devices, "Select video device to capture").go_selected_value
 english_name = SimpleGuiCreator.get_input "Please enter the 'alias' name you'd like to have (human friendly name) for #{new_name}:", new_name
 UsbStorage['devices_to_record'][new_name] =  UsbStorage['devices_to_record'][new_name] || english_name
 add_device new_name, english_name, a
}

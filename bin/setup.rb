require 'rubygems'
require 'simple_gui_creator'
a = SimpleGuiCreator::ParseTemplate.new.parse_setup_filename('setup.tmpl')
a.elements[:add_new_url].on_clicked {
 puts 'clicked'
}

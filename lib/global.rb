require 'shared'
def do_global
  global = SimpleGuiCreator::ParseTemplate.new.parse_setup_filename('lib\\global_options.sgc')
  require 'win32/registry'
  require 'rbconfig'
  name = "Dirt Simple Surveillance auto-start"  
  b = Win32::Registry::HKEY_CURRENT_USER.open "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run", Win32::Registry::KEY_ALL_ACCESS # hope this gets garbage collected easily...
  if !b.entries.map(&:first).include? name # there is no values method, #entries is like ['name', type, value]
    global.elements[:run_at_startup].uncheck!
  end
  
  global.elements[:run_at_startup].on_checked {
    full_stuff = RbConfig::CONFIG['bindir'] # like "file:/C:/dev/ruby/dirt-simple-usb-surveillance/vendor/jruby-complete-1.7.0.jar!/META-INF/jruby.home/bin"
	if !full_stuff.start_with? 'file:/'
	  show_message "whoa there, not using jruby from a jar file? huh?"
	  raise	  
	end
	full_stuff =~ /file:\/(.*)!.*/
	jar_location = $1
	java_root = java.lang.System.getProperty("java.home") # see http://stackoverflow.com/a/9006281/32453
	if !jar_location || !java_root
	  show_message "huh? unable to get something for setting up start?"
	end
	# assume javaw, and bin\startup.rb :)
	# no splash...
	b.write_s name, "\"#{java_root}\\bin\\javaw.exe\" -jar \"#{jar_location}\" -C \"#{Dir.pwd}\" -Ilib bin/startup.rb --background-start" # avoid various jruby RbConfig.ruby bugz LOL
	p 'wrote it to registry'
  }
  
  global.elements[:run_at_startup].on_unchecked {
    b.delete_value(name)
  }

end

if $0 == __FILE__
  do_global
  puts 'ctrl+c to exit...'
  sleep
end
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
	b.write_s name, "#{Gem.ruby.gsub(' /', ' ')} -C \"#{Dir.pwd}\" -Ilib \"#{$0}\" --background-start" # various jruby bugz LOL
	p 'wrote it'
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
class SysTray

  import java.awt.TrayIcon
  import java.awt.event.MouseListener
  
  def initialize name = nil, icon_path = nil
    icon_path ||= '' # so it'll use the right get_image method...
    tray = java.awt.SystemTray::system_tray
	if icon_path
      image = java.awt.Toolkit::default_toolkit.get_image(icon_path)
    end
    popup = java.awt.PopupMenu.new
   
	@popup = popup
    trayIcon = TrayIcon.new(image, name, popup)
    trayIcon.image_auto_size = true

    #trayIcon.addActionListener do |evt|
      # occurs at double left click [also balloon clicked, too, unfortunately]
      # trayIcon.displayMessage("Action","Tray Action!", TrayIcon::MessageType::WARNING) 
    #end

    #trayIcon.addMouseListener() do |method|
      # all mouse clicks
	  # LODO on left click [release?], show menu too...
      # puts "mouse event #{method.to_s}"
    #end

    tray.add(trayIcon)
	@tray = tray
	@tray_icon = trayIcon
  end
  
  def set_icon to_this_image_path
    @tray_icon.set_image java.awt.Toolkit::default_toolkit.get_image(to_this_image_path)
  end
  
  def set_name to_this
    @tray_icon.set_tool_tip(to_this)
  end
  
  def on_double_left_click &block
  # unfortunately this also gets fired indistinguishably, on balloon "clicked" too?
  #  @tray_icon.addActionListener do |evt|
  #	  block.call
  #	end
    # http://stackoverflow.com/questions/12274370/how-to-detect-single-clicks-to-system-trayicon-for-java-app
    @tray_icon.add_mouse_listener do |mouse_evt|
	  if mouse_evt.click_count == 2 && (mouse_evt.id == java.awt.event.MouseEvent::MOUSE_CLICKED) # ignore mouse up, mouse down
	    block.call
	  end
	end
  end
  
  def display_balloon_message title, message
    @tray_icon.displayMessage(title, message, TrayIcon::MessageType::INFO) # WARNING 
  end
  
  def add_menu_item name, &block
    oraitem = java.awt.MenuItem.new(name)
    oraitem.addActionListener do
      block.call
    end
	@popup.add(oraitem)
  end
  
  def close
    @tray.remove @tray_icon # I...umm...uh...guess this is right...don't know how to "close" this really, per se...this seems to work...
  end
end

if $0 == __FILE__
  tray = SysTray.new 'test name', 'test icon'
  tray.add_menu_item('exit') {
    tray.close
  }
  tray.add_menu_item('Go to ORA') do
    java.awt.Desktop::desktop.browse(java.net.URI.new("http://www.ora.com"))
  end
  tray.add_menu_item('Show balloon') do
    tray.display_balloon_message 'a title', 'A balloon message!'
  end
  tray.display_balloon_message 'running!', 'its right here!'
  
  tray.on_double_left_click {
    puts 'double left click'
  }
  
  puts 'running...'
end
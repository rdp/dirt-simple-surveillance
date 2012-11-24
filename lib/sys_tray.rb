
class SysTray

  import java.awt.TrayIcon
  import java.awt.event.MouseListener
  def initialize name, icon_path
    tray = java.awt.SystemTray::system_tray
    image = java.awt.Toolkit::default_toolkit.get_image(icon_path)

    popup = java.awt.PopupMenu.new
   
	@popup = popup
    trayIcon = TrayIcon.new(image, name, popup)
    trayIcon.image_auto_size = true

    trayIcon.addActionListener do |evt|
      # occurs at double left click
      # trayIcon.displayMessage("Action","Tray Action!", TrayIcon::MessageType::WARNING) 
    end

    trayIcon.addMouseListener() do |method|
      # all mouse clicks
	  # LODO on left click [release?], show menu too...
      # puts "mouse event #{method.to_s}"
    end

    tray.add(trayIcon)
  end
  
  def add_menu_item name, &block
    oraitem = java.awt.MenuItem.new(name)
    oraitem.addActionListener do
      block.call
    end
	@popup.add(oraitem)
  end
end

if $0 == __FILE__
  tray = SysTray.new 'test name', 'test icon'
  tray.add_menu_item('exit') {
    java.lang.System::exit(0)
  }
  tray.add_menu_item('Go to ORA') do
    java.awt.Desktop::desktop.browse(java.net.URI.new("http://www.ora.com"))
  end
  puts 'running...'
end
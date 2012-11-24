
import java.awt.TrayIcon
import java.awt.event.MouseListener

  tray = java.awt.SystemTray::system_tray
  image = java.awt.Toolkit::default_toolkit.get_image("tray.gif")

  popup = java.awt.PopupMenu.new
  exititem = java.awt.MenuItem.new("Exit")
  exititem.addActionListener {java.lang.System::exit(0)}

  oraitem = java.awt.MenuItem.new("Go To ORA")
  oraitem.addActionListener do
    java.awt.Desktop::desktop.browse(java.net.URI.new("http://www.ora.com"))
  end

  popup.add(exititem)
  popup.add(oraitem)
  trayIcon = TrayIcon.new(image, "Tray Demo", popup)
  trayIcon.image_auto_size = true

  trayIcon.addActionListener do |evt|
    # double left click
    trayIcon.displayMessage("Action","Tray Action!",
    TrayIcon::MessageType::WARNING) 
  end

  trayIcon.addMouseListener() do |method|
    # all mouse clicks
	# LODO on left click, show menu too...
    puts "mouse event #{method.to_s}"
  end

  tray.add(trayIcon)
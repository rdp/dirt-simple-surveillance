require 'java'
require 'shared'
module M
  include_package "javax.swing"
  include_package "java.awt"
  include_package "java.awt.image" # BufferedImage
  include_package "javax.awt"
  include_package "javax.net"
  include_package 'javax.imageio'
  [BufferedImage, Font, Color, RenderingHints, ImageIO, ImageIcon, JLabel] 
  JFile = java.io.File
  class ShowImage < JFrame
    def initialize title, path
	  super title
	   @image = ImageIO.read(JFile.new(path));
	   set_size @image.width,@image.height
	   picLabel = JLabel.new(ImageIcon.new(@image))
       add( picLabel )
	   self.defaultCloseOperation = EXIT_ON_CLOSE
	end
   # def paint(g)
   #   g.drawImage(@image,0,0,self)
   # end
end
end

def get_sorted_dirs_by_camera

  dirs = get_sorted_day_dirs
  all = {}
dirs.each{|dir|
 # like captured_video/camera_name
 camera_name = dir.split('/')[-2]
 all[camera_name] ||= []
 all[camera_name] << dir
}
p 'got', all
 all
end

def show_recent_snapshot_images
start = 0
get_sorted_dirs_by_camera.each{|camera_name, days|
  last_image_day = days.last
  last_snapshot = Dir[last_image_day + "/*.jpg"].sort.last
  window = M::ShowImage.new(camera_name + ' ' + last_snapshot, last_snapshot).show
  start += 10
  # LODO window.set_location(start, start)
}
end
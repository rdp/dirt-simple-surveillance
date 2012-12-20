require 'java'
require 'shared'

# possibly unused now?
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
	end
    # def paint(g)
    #   g.drawImage(@image,0,0,self)
    # end
  end
end

# unused now?
def get_sorted_dirs_by_camera

  dirs = get_sorted_day_dirs
  all = {}
  dirs.each{|dir|
   # like captured_video/camera_name
   camera_name = dir.split('/')[-2]
   all[camera_name] ||= []
   all[camera_name] << dir
  }
  all  
end

def show_recent_snapshot_image camera_name
   filename = base_storage_dir + '/' + camera_name + '/latest.jpg'
   if File.exist? filename
     window = M::ShowImage.new(camera_name + ' recent still image', filename).show
   else
     SimpleGuiCreator.show_message "you can only see a recent image after starting a recording, use preview instead until then"
   end
end
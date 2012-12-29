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
	   content_pane.set_size @image.width+20, @image.height+20
	   picLabel = JLabel.new(ImageIcon.new(@image))
       add( picLabel )
	   pack
	end
    # def paint(g)
    #   g.drawImage(@image,0,0,self)
    # end
  end
  
end

def show_image window_title, filename
   SimpleGuiCreator.launch_file(filename)
   #M::ShowImage.new(window_title, filename).show # clips the top on small monitors [?]
end
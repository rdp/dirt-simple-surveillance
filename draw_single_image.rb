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
    def initialize path
	  super 'an image'
	   @image = ImageIO.read(JFile.new(path));
	   set_size 100,100
	   picLabel = JLabel.new(ImageIcon.new(@image))
       add( picLabel )
	end
   # def paint(g)
   #   g.drawImage(@image,0,0,self)
   # end
end
end
M::ShowImage.new(filename).show

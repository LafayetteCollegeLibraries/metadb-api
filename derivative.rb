
require_relative 'item'

module MetaDB
module Derivatives

  BRANDING_NONE = 0
  BRANDING_UNDER = 1
  BRANDING_OVER = 2

  IMAGE_WRITE_PATH = '/tmp'

  class Derivative

    attr_reader :output_image, :item

    def initialize(item, options = {})

      @item = item
      @branding = options.fetch :branding, BRANDING_UNDER

      @branding_text = options.fetch :branding_text, nil
      @bg_color = options.fetch :bg_color, 'White'
      @fg_color = options.fetch :fg_color, 'Black'

      @image_write_path = options.fetch :image_write_path, IMAGE_WRITE_PATH
      @input_image_path = options.fetch :input_image_path, item.file_path
    end

    def derive

      @input_image = MiniMagick::Image.open(@input_image_path)

      current_or_new_width = @width || @input_image.width
      @font_size = case current_or_new_width
                   when 300..500
                     4
                   when 500..1000
                     8
                   when 1000..1400
                     16
                   when 1400..2000
                     16
                   else
                     24
                   end

      # File name structure is unique for the Silk Road Instrument project
      if @item.project.name == SILK_ROAD
        output_image_name = "#{@item.derivative_base}-#{ '%06d' % @item.number}"
      else
        output_image_name = "#{@item.derivative_base}-#{ '%04d' % @item.number}"
      end

      output_image_name += "-#{@width}" unless @width.nil?
      output_image_name += ".jpg"
      output_image_path = "#{@image_write_path}/#{output_image_name}"

      MiniMagick::Tool::Convert.new do |convert|
        unless @width.nil? or @height.nil?
          convert << '-resize'
          convert << "#{@width}x"
        end

        convert << "#{@input_image_path}[0]"

        if not @branding_text.nil? and @branding != BRANDING_NONE
          convert << "-size"
          convert << "#{current_or_new_width}x"
          convert << "-gravity"
          convert << "Center"
          convert << "-font"
          convert << "Bitstream-Charter-Regular"

          unless @font_size.nil?
            convert << "-pointsize"
            convert << @font_size
          end
          
          convert << "caption:#{@branding_text}"
          convert << "+swap" if @branding == BRANDING_OVER
          convert << "-append"
        end

        convert << output_image_path
      end

      class_name_segments = self.class.name.match /Derivatives\:{2}(.+?)Derivative$/
      if class_name_segments
        class_name_type = class_name_segments[1]
      else
        class_name_type = 'fullsize'
      end

      @item.instance_variable_set "@#{class_name_type}_file_name", output_image_name
      @item.write

      @input_image.destroy!

      output_image_path
    end
  end

  class ThumbnailDerivative < Derivative

    def initialize(item, options = {})

      @width = options.fetch :width, 300
      @height = options.fetch :height, 300

      # Ensure that the thumbnails are not branded
      options[:branding] = BRANDING_NONE

      super item, options
    end
  end

  class FullSizeDerivative < Derivative

  end

  class LargeDerivative < Derivative

    def initialize(item, options = {})

      @width = options.fetch :width, 2000
      @height = options.fetch :height, 2000

      super item, options
    end
  end

  class CustomDerivative < Derivative

    def initialize(item, options = {})

      @width = options.fetch :width, 800
      @height = options.fetch :height, 800

      super item, options
    end
  end
end
end

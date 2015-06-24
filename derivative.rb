
require_relative 'item'

module Derivatives

  BRANDING_NONE = 0
  BRANDING_UNDER = 1
  BRANDING_OVER = 2

  IMAGE_WRITE_PATH = '/tmp'

  class Derivative

    attr_reader :output_image

    def initialize(item, options = {})

      @item = item
      
      # @todo Refactor
      @branding = options.fetch :branding, BRANDING_NONE
      @branding_text = options.fetch :branding_text, nil
#      @bg_color = options.fetch :bg_color, '#000000'
#      @fg_color = options.fetch :fg_color, '#FFFFFF'
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
                     8
                   when 500..1000
                     16
                   when 1000..1400
                     24
                   when 1400..1800
                     48
                   when 1800..2200
                     72
                   when 2200..3000
                     85
                   else
                     100
                   end

      output_image_name = "lc-spcol-#{@item.project.name}-#{ '%04d' % @item.number}"

      output_image_name += "-#{@width}" unless @width.nil?
      output_image_name += ".jpg"

      output_image_path = "#{@image_write_path}/#{output_image_name}"

      MiniMagick::Tool::Convert.new do |convert|

        unless @width.nil? or @height.nil?

          convert << '-resize'
          convert << "#{@width}x"
        end

        convert << @input_image_path

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
          
          convert << "caption:'#{@branding_text}'"

          convert << "+swap" if @branding == BRANDING_OVER
          convert << "-append"
        end

        convert << output_image_path
      end

      class_name_segments = self.class.name.match /\:{2}(.+?)Derivative$/
      if class_name_segments

        class_name_type = class_name_segments[1]
      else

        class_name_type = 'fullsize'
      end

      @item.instance_variable_set "@#{class_name_type}_file_name", output_image_name
      @item.write

      # @output_image_path = File.new(output_image_path)
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

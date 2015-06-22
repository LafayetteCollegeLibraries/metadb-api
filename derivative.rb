
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
      
      @branding = options.fetch :branding, BRANDING_NONE
      @branding_text = options.fetch :branding_text, nil
      @image_write_path = options.fetch :image_write_path, IMAGE_WRITE_PATH

      @input_image_path = options.fetch :input_image_path, item.file_name
      @input_image = MiniMagick::Image.open(@input_image_path)
    end

    def derive

      output_image_name = "lc-spcol-#{@item.project.name}-#{ '%04d' % @item.number}"

      output_image_name += "-#{@width}" unless @width.nil?
      output_image_name += ".jpg"

      output_image_path = "#{@image_write_path}/#{output_image_name}"

      if not @branding_text.nil? and @branding != BRANDING_NONE

        # @input_image.label
        MiniMagick::Tool::Convert.new do |convert|
          convert << @input_image_path
          convert << "#{@width}x#{@height}" unless @width.nil? or @height.nil?
          convert << "label:'#{@branding_text}'"
          convert << "+swap" if @branding == BRANDING_OVER
          convert << "-append"
          convert << output_image_path
        end
      else

        @input_image.resize "#{@width}x#{@height}" unless @width.nil? or @height.nil?
        @input_image.format "jpg"

        @input_image.write output_image_path
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

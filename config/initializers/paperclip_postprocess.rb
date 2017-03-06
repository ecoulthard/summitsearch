#Found this processor at http://www.ror-e.com/posts/6-optimize-your-images
#Runs jpegtran on paperclip generated images such as thumbs
module Paperclip
  class Thumbnail < Processor
    def make
    src = @file
    conv = Tempfile.new([@basename, @format ? ".#{@format}" : ''])
    conv.binmode
    dst = Tempfile.new([@basename, @format ? ".#{@format}" : ''])
    dst.binmode

  begin
    parameters = []
    parameters << source_file_options
    parameters << ":source"
    parameters << transformation_command
    parameters << convert_options
    parameters << ":dest"

    parameters = parameters.flatten.compact.join(" ").strip.squeeze(" ")

    success = Paperclip.run("convert", parameters, :source => "#{File.expand_path(src.path)}[0]", :dest => File.expand_path(conv.path))

    if conv.size > 0
      format = begin
        Paperclip.run("identify", "-format %m :file", :file => "#{File.expand_path(conv.path)}[0]")
      rescue PaperclipCommandLineError
        ""
      end

      case format.strip
      when 'JPEG'
        # Part of libjpeg-progs deb package
        success = Paperclip.run('jpegtran', "-copy all -optimize -perfect :source > :dest", :source => File.expand_path(conv.path), :dest => File.expand_path(dst.path))
      when 'PNG'
        success = Paperclip.run('pngcrush', "-rem alla -reduce -brute :source :dest", :source => File.expand_path(conv.path), :dest => File.expand_path(dst.path))
      else
        dst = conv
      end
    end
  rescue Exception => e
    Rails.logger.error "There was an error processing the thumbnail for #{@basename}. Check imagemagick, jpegtran and pngcrush installed."

    raise "Paperclip ERROR: #{e.message}"

    #HoptoadNotifier.notify(
    #  :error_class => "Paperclip - images optimization",
    #  :error_message => "Paperclip ERROR: #{e.message}"
    #)
  end

  dst.size > 0 ? dst : conv
    end
  end
end

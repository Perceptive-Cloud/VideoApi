require 'cgi'

# requires mime-types gem
require 'rubygems'
require 'mime/types'

module VideoApi

# taken from 
# http://stanislavvitvitskiy.blogspot.com/2008/12/multipart-post-in-ruby.html
# and modified slightly to accept test params in addition to the files
# and to determine the content type from the filepath
module Multipart

  class Multipart
    
    def initialize( file_names, params )
      @file_names = file_names
      @params = params
      @boundary = '----RubyMultipartClient' + rand(10000000000).to_s + 'ZZZZZ'
    end

    def boundary
      "--#{@boundary}\r\n"
    end

    def post( to_url, &stream_listener )

      # file params
      parts = []
      streams = []
      @file_names.each do |param_name, filepath|

        mod_filepath, filename = get_modified_filepath_and_filename(filepath)

        p_name    = get_param_name(param_name)
        str_part  = "#{boundary}Content-Disposition: form-data; name=\"#{p_name}\"; filename=\"#{filename}\"\r\n "
        str_part += "Content-Transfer-Encoding: binary\r\n Content-Type: #{content_type(filename)}\r\n\r\n"
        parts << StringPart.new(str_part)

        stream = File.open(mod_filepath, "rb")
        parts << StreamPart.new(stream, File.size(mod_filepath), &stream_listener)
        parts << StringPart.new("\r\n")
      end

      # text params
      @params.each do |key, data|
        next if key.to_s == 'image'
        parts << StringPart.new(boundary + 
                                "Content-Disposition: form-data; " + 
                                "name=\"#{CGI.escape(key.to_s) }\"\r\n" +
                                "\r\n" +
                                "#{data}\r\n")
      end

      # final boundary
      parts << StringPart.new(boundary)

      post_stream = MultipartStream.new( parts )      
      url = URI.parse( to_url )
      req = Net::HTTP::Post.new("#{url.path}?#{url.query}")
      req.content_length = post_stream.size
      req.content_type = "multipart/form-data; boundary=#{@boundary}"
      req.body_stream = post_stream

      res = Net::HTTP.new(url.host, url.port).start { |http| http.request(req) }
    end
    
    def content_type(filename)
      if MIME::Types.type_for(filename).empty?
        'application/octet-stream'
      else
        MIME::Types.type_for(filename)
      end
    end

    private

    def get_modified_filepath_and_filename(filepath)
        mod_filepath = filepath.respond_to?(:values) ? filepath.values.first : filepath
        pos      = mod_filepath.rindex('/')
        filename = pos ? (mod_filepath[pos + 1, mod_filepath.length - pos]) : mod_filepath
        [mod_filepath, filename]
    end

    def get_param_name(param_name)
      return param_name if param_name == 'image[original]' # Ugly hack. Not my proudest moment.
      CGI.escape(param_name.to_s)
    end

  end

  class StreamPart
    def initialize( stream, size, &progress_listener )
      @stream, @size, @progress_listener = stream, size, progress_listener
    end
    
    def size
      @size
    end
    
    def read( offset, how_much )
      
      data = @stream.read( how_much )
      if @stream.eof?
        @stream.close
      end

      if @progress_listener
        @progress_listener.call(data.length)
      end

      data
    end
  end

  class StringPart
    def initialize( str )
      @str = str
    end
    
    def size
      @str.length
    end
    
    def read( offset, how_much )
      @str[offset, how_much]
    end
  end

  class MultipartStream
    def initialize( parts )
      @parts = parts
      @part_no = 0;
      @part_offset = 0;
    end
    
    def size
      total = 0
      @parts.each do |part|
        total += part.size
      end
      total
    end
    
    def read( how_much )

      if @part_no >= @parts.size
        return nil;
      end
      
      how_much_current_part = @parts[@part_no].size - @part_offset
      
      how_much_current_part = if how_much_current_part > how_much
                                how_much
                              else
                                how_much_current_part
                              end
      
      how_much_next_part = how_much - how_much_current_part
      
      current_part = @parts[@part_no].read(@part_offset, how_much_current_part )

      if how_much_next_part > 0
        @part_no += 1
        @part_offset = 0
        next_part = read( how_much_next_part  )
        current_part + if next_part
                         next_part
                       else
                         ''
                       end
      else
        @part_offset += how_much_current_part
        current_part
      end
    end
  end

end

end # VideoApi module

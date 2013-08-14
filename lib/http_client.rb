require 'net/http'
require 'uri'
require 'cgi'
require 'open-uri'
require 'multipart'

module VideoApi

# Basic HTTP client class, used by VideoApi.
class HttpClient

  include Multipart

  @@trace = false

  attr_reader :server_host, :server_port
  attr_accessor :download_buffer_size  

  def initialize(server_host, server_port=80)
    @server_host = server_host
    @server_port = server_port
    @download_buffer_size = 8192
  end

  # if called, all calls to HttpClient methods will output the method and url
  def HttpClient.trace_on(on=true); @@trace = on; end
  def HttpClient.trace_off; HttpClient.trace_on(false); end
  def HttpClient.trace_on?; @@trace; end

  # performs an HTTP GET request, returning the response body.
  # raises HttpClientException if it can't connect correctly and in the case of invalid response codes.
  # sub_url:: the path to call on the server
  # params: optional hash of query string params, which will be url-encoded and appended to the URL.
  def get(sub_url, params={})
    get_response("GET", sub_url, params)
  end

  # performs an HTTP PUT request, returning the response body.
  # raises HttpClientException if it can't connect correctly and in the case of invalid response codes.
  # sub_url:: the path to call on the server
  # params: optional hash of query string params, which will be url-encoded and appended to the URL.
  def put(sub_url, params={})
    get_response("PUT", sub_url, params, nil, {'Content-length' => '0'})
  end

  # performs an HTTP DELETE request, returning the response body.
  # raises HttpClientException if it can't connect correctly and in the case of invalid response codes.
  # sub_url:: the path to call on the server
  # params: optional hash of query string params, which will be url-encoded and appended to the URL.
  def delete(sub_url, params={})
    get_response("DELETE", sub_url, params)
  end

  # performs an HTTP POST request, returning the response body.
  # raises HttpClientException if it can't connect correctly and in the case of invalid response codes.
  # sub_url:: the path to call on the server
  # params: optional hash of query string params, which will be url-encoded and appended to the URL.
  # data:: optional string of data to post
  # content_type:: optional content type header value, defaults to application/x-www-form-urlencoded
  def post(sub_url, params={}, data="", content_type="application/x-www-form-urlencoded")
    get_response("POST", sub_url, params, data, {'Content-type' => content_type})
  end

  # Performs a multipart form file upload, simulating one sent from a browser.
  # url:: the full (absolute) URL to post the file to.  Note that this is not relative to the server_host or server_port parameters provided to the constructor - calls to this method do not use those values.
  # filepath:: the path of the local file to upload.
  # params:: optional hash of params to include as other variables in the multipart request. 
  def post_multipart_file_upload(url, filepath, params={}, &stream_listener)
    trace("POST (multipart) #{create_url(url)}")
    multipart = Multipart::Multipart.new({'image[original]' => filepath}, params)
    url  = create_url(url).gsub(%r[//images], '/images')
    multipart.post(url, &stream_listener)
  end

  # Downloads a file on the server to the local hard drive.
  # path:: The path on the server of the file to download.
  # download_file_path:: the path (including filename) on the local hard drive to download the file as.
  def download_file(path, download_file_path)

    trace("GET http://#{server_host}:#{server_port}/#{path}")

    begin
      File.open(download_file_path, "w") do |output|
        open(create_url(path)) do |input|
          while(buffer = input.read(download_buffer_size))
            output.write(buffer)
          end
        end
      end
    rescue OpenURI::HTTPError => e
      raise HttpClientException.from_code(e.io.status[0].to_i, e.message)
    end
  end

  # Returns an absolute URL for the given path on the server and request vars, using the server_host and server_port provided to the constructor.
  # path:: the path on the server
  # params:: optional hash of request vars to include as the query string.  they will be url-encoded.
  def create_url(path, params={})
    "http://#{server_host}:#{server_port}/#{create_sub_url path, params}"
  end

  # Returns a URI relative to the server_host:server_port provided to the constructor, including the given optional params hash URL-encoded.
  def create_sub_url(path, params={}) 
    params.empty? ? path : "#{path}?#{HttpClient.create_query_string(params)}"
  end

  def HttpClient.create_query_string(params, joiner='&')
    params.map do |k,v|
      v.is_a?(Hash) ?
        self.create_sub_query_string(k, v, joiner) :
        "#{k.to_s}=#{CGI.escape(v.to_s)}"
    end.join(joiner)
  end

  def self.create_sub_query_string(outer_k, params, joiner)
    params.map do |k,v|
      v.is_a?(Hash) ?
        self.create_sub_query_string("#{outer_k.to_s}[#{k.to_s}]", v, joiner) :
        "#{outer_k.to_s}[#{k.to_s}]=#{CGI.escape(v.to_s)}"
    end.join(joiner)
  end

  protected

  def trace(s)
    if @@trace
      puts(s)
    end
  end

  def get_response(method, uri, params={}, data=nil, headers={})       
    begin
      sub_url  = create_sub_url(uri, params)
      response = send_request(method, sub_url, data, headers)
    rescue => e
      throw HttpClientException.from_exception e
    end

    code = response.code.to_i
    body = response.body

    trace("response code=#{code}, body=#{body}")

    if code < 200 or code >= 400      
      raise HttpClientException.from_code(code, body)
    else
      HttpResponse.new(body, code)
    end
  end
  
  def send_request(method, url, data, headers)
    trace("#{method} http://#{server_host}:#{server_port}/#{url}, data=#{data}, headers: #{headers.map{|k,v| k + '=' + v}.join(', ')}")
    http = Net::HTTP.new(server_host, server_port)
    # since we aren't sent the scheme, only thing we can check on is if the server port is 443
    http.use_ssl = true if server_port == 443
    http.send_request(method, "/#{url}", data, headers)
  end 

end

# Raised by HTTPClient in the case of exception conditions, like failing to connect to the server or in the case of an invalid response code.
class HttpClientException < Exception
  
  attr_reader :code
  
  def self.from_code(code, body)
    self.new(code, "HTTP response code=#{code}, body=#{body}")
  end
  
  def self.from_exception(exception)
    self.new(nil, exception.message)
  end

  protected

  def initialize(code, message)
    super(message)
    @code = code
  end

end

class HttpResponse < String
  
  attr_reader :http_response_code

  def initialize(body, code) 
    super(body)
    @http_response_code= code
  end

end

end # VideoApi module

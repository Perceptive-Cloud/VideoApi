require 'http_client'
require 'json'
require 'object_from_json'
require 'etc'
require 'tmpdir'

require 'rubygems'

require 'fileutils'

module VideoApi

# Base class for the wrapper classes around the 
# REST APIs and other features.
# 
# Authentication is managed automatically, including the management
# of duration-based signatures, which last a specified amount of time
# before expiring.  Authentication signatures are stored in a cache file
# in the user's home directory, to allow reuse across multiple
# instances/instantiations of this class.  
# 
# To make API calls that require authentication, you never need to 
# obtain or maintain the authentication signatures yourself - 
# the methods that need them will obtain them first, and this
# class will make sure API calls always use a valid authentication signature.
# 
# See new for details of instantiation.
#
class MediaApi

  attr_accessor :rss_auth_required, :auth_duration_in_minutes, :auth_required_for_download

  attr_reader :base_url, :company_id, :library_id, :http, :license_key

  def settings_trace_string
    <<-DOC
      base_url: #{base_url}
      company_id: #{company_id} 
      library_id: #{library_id}
      license_key: #{license_key}
DOC
  end

  # Returns a valid view (read-only) authentication signature string.
  # Methods requiring a view token will call this method automatically.
  # duration:: optional duration of the signature in minutes
  def authenticate_for_view(dur = nil)
    auth_signature(view_auth_token, dur || auth_duration_in_minutes)
  end

  # Returns a valid update authentication signature string.
  # Methods requiring an update token will call this method automatically.
  # duration:: optional duration of the signature in minutes
  def authenticate_for_update(dur = nil)
    auth_signature(update_auth_token, dur || auth_duration_in_minutes)
  end

  # Returns a valid ingest authentication signature string.
  #
  # Methods requiring a ingest token will call this method automatically.
  #
  # ::contributor the string to use as the media's contributor
  # ::params a hash containing other params to include.  currently the
  # only param to include is :ingest_profile, specifying the ingest profile 
  # to use when ingesting the media.
  #
  def authenticate_for_ingest(contributor, params={})
    media_api_result do

      if contributor.nil? || contributor.chop.length == 0
        raise MediaApiException.new("You must provide a non-blank contributor name to obtain an ingest authentication signature.")
      end
      
      if library_id.nil? || library_id.chop.length == 0
        raise MediaApiException.new "You must provide a non-blank library ID to obtain an ingest authentication signature."
      end
      
      # specify 0 duration so it always fetches a new signature
      auth_signature(ingest_auth_token, 0, params.merge({'userID' => contributor, 'library_id' => library_id}))

    end
  end

  # Returns true if the cached view authentication signature has expired, meaning that the nxt call to authenticate_for_view will call the REST API.
  def view_token_expired?
    view_auth_token.expired?
  end

  # returns true if the cached update authentication signature has expired, meaning that the nxt call to authenticate_for_view will call the REST API.
  def update_token_expired?
    update_auth_token.expired?
  end

  # Resets/invalidates the authentication token cache files, forcing a new API call the next time a view or update authentication token is needed.
  def reset_auth_token_cache
    view_auth_token.reset_cache
    update_auth_token.reset_cache
  end  

  # this is made public for testing purposes only
  # for a view auth token, call authenticate_for_view
  def view_auth_token
    @view_auth_token ||= AuthToken.new('view_key', license_key)
  end

  def import_media_items_from_xml_string(media_type, xml, contributor, params={})
    meth = { :track => :audio_api_result, :video => :video_api_result }[media_type]
    send(meth) do
      http.post("#{media_type}s/create_many",
                add_ingest_auth_param(contributor, params),
                xml,
                "text/xml")
    end
  end

  # Calls the Upload API, uploading a media file
  # from the local hard drive to your online account, 
  # putting the content into the library you provided in the 
  # constructor of this api object.
  # filename:: the filepath of the media file to upload to the account.
  # contributor:: the string to use as the content's contributor name.
  # params:: optional hash specifying metadata.  
  # See the online documentation for other allowed params.  
  # If not provided, the online entity's title will be its filename.
  #
  # To specify an ingest profile, include :ingest_profile 
  # in params.  It will be used in the call to authenticate_for_ingest.
  #
  def upload_media(filename, contributor, params={}, &progress_listener)

    signature = authenticate_for_ingest(contributor, 
                                        params.dup.delete_if {|k,v| ! ingest_auth_param_key?(k)})

    upload_uri = URI.parse(media_upload_open(signature, 
                                             params.dup.delete_if {|k,v| ingest_auth_param_key?(k)}))
    
    media_api_result do
      
      http = HttpClient.new(upload_uri.host, upload_uri.port)
      
      http.post_multipart_file_upload(upload_uri.path + "?" + upload_uri.query, 
                                      filename,
                                      {},
                                      &progress_listener)      
      
    end
    
    media_upload_close(signature).strip
    
  end

  # Calls the Tags API, returning all tags used on all media of the specified type.  If a library_id was provided to the constructor, only returns results for that library.                                                                             
  # format:: optional.  if omitted, this method returns the result as an Array of ruby objects, each with a name and count property - the name of the tag and the number of items it applies to within the library.
  # - 'xml': returns the results in xml format.
  # - 'json': returns the results in json format.
  #
  def get_tags(format=nil)
    structured_data_request("#{create_account_library_url}/tags",
                            add_view_auth_param({:applied_to => tag_media_type}),
                           format)
  end

  # Calls the Tags API, returning an Array of tag names.  If a library_id was provided to the constructor, constrains to that library.
  def get_tag_names
    get_tags.map {|x| x.name}
  end  

  protected  

  # params:: a hash containing the following keys:
  # base_url: the base url of the API server
  # company_id: the ID of your account (found in the console on the Account tab)
  # library_id: the ID of the library to act on, or nil if calls should be account-wide.  NOTE: to ingest or import media, you must specify a library_id.
  # license_key: the license key of a user either at the account level or library level for the specified account and library.
  # require_library:: if true and no library_id is specified, will throw an error
  def initialize(params, require_library=false)
    media_api_result do

      if require_library && (params['library_id'].nil? || params['library_id'].empty?)
        raise MediaApiException.new("MediaApi.initialize: library_id required.")
      end
      
      @base_url = params['base_url']
      @company_id = params['account_id'] || params['company_id']
      @library_id = params['library_id']
      @license_key = params['license_key']
      
      @rss_auth_required = false
      @auth_required_for_download = false
      @auth_duration_in_minutes = 15
      
      if base_url.nil? || base_url.empty?
        raise MediaApiException.new("base_url is required.")
      end
      
      if company_id.nil? || company_id.empty?
        raise MediaApiException.new("company_id is required.")
      end
      
      if license_key.nil? || license_key.empty?
        raise MediaApiException.new("license_key is required.")
      end
      
      uri = URI.parse(base_url)
      @http = HttpClient.new(uri.host, uri.port)

    end
  end

  # Creates a hash from the given YAML settings file.
  # YAML file should contain the following keys: base_url, company_id, license_key.  It should also contain a library_id key if you want to scope the MediaApi object to a specific library, or ingest/import media.
  #
  def self.settings_file_path_to_hash(path)
    YAML::load(File.read(path))
  end

  def self.create_settings_hash(base_url, company_id, library_id, license_key)
    {
      'base_url' => base_url,
      'company_id' => company_id,
      'library_id' => library_id,
      'license_key' => license_key
    }
  end

  def media_api_result(exception_class=MediaApiException)
    begin      
      yield
    rescue HttpClientException => e
      raise exception_class.new("Server returned code #{e.code} and message #{e.message}")
    ### FIXME: Probably add a rescue for timeouts, as well, to trap them at the system
    # spec level and cause the containing spec to pendingize instead of failing
    end
  end

  def media_upload_open(auth, params)
    media_api_result do
      http.get("upload_sessions/#{auth}/http_open",
               params)
    end
  end

  def media_upload_close(auth)
    media_api_result do
      http.get("upload_sessions/#{auth}/http_close")
    end
  end

  def search_media(params={}, format=nil)

    sub_url = create_search_sub_url(params, format || 'json')

    structured_data_request(sub_url, nil, format) do |result|
      cleanup_search_results!(get_search_page_media(result))
      result
    end
  end

  # if format is nil, will recall this method with format='json', and parse the json results into an object tree.  if a block is provided, will return the result of passing that tree to the block, otherwise the tree untouched.
  # if format is provided, calls the given sub_url.
  # - if params is nil, will call sub_url as is.
  # - if params non-nil, will append the format to sub_url
  def structured_data_request(sub_url, params, format)
    media_api_result do

      # no format given - restart with format='json' and
      # parse the json results into an object tree.      
      if format.nil?
        
        result = ObjectFromJson.from_json(structured_data_request(sub_url, params, 'json'))
                
        # let the caller clean up the object tree
        if block_given?
          yield result
        else
          result
        end
        
      # format provided - call the provided url
      else

        # if no prams provided, that's also a signal to use the url verbatim
        if params.nil?
          http.get(sub_url)
        else          
          http.get("#{sub_url}.#{format}", params)
        end

      end
    end
  end  

  def get_media_with_tag(media_type, tag, params={}, format=nil)
    structured_data_request("#{create_account_library_url}/tags/#{tag}/#{media_type}",
                            add_view_auth_param(params),
                            format)
  end

  def search_media_each_page(params={}, &block)

    params_copy = Hash.new.merge(params)

    # since you can provide it either as :page or 'page', clear both
    params_copy.delete('page')

    page = nil
    begin
      params_copy[:page] = (page.nil? ? 1 : page.page_info.page_number + 1)
      page = search_media(params_copy)
      result = block.call(page)
    end while not (page.page_info.is_last_page || result === false)
  end

  def search_media_each(params={}, &block) 
    search_media_each_page(params) do |page|
      result = true
      get_search_page_media(page).each do |object|
        result = block.call(object)
        if result === false
          break
        end
      end 
      result
    end
  end

  def wrap_update_params(params, wrapper) 
    new_params = Hash.new
    params.each do |k,v|
      key = k.to_s
      # not sure why, but double quotes with #{wrapper} doesn't work here
      if key.match('^' + wrapper + '\[.*\]')
        new_params[key] = params[k]
      else
        new_params["#{wrapper}[#{key}]"] = params[k]
      end
    end
    new_params
  end

  def create_full_account_library_url
    "http://#{http.server_url}/#{create_account_library_url}"
  end

  def create_account_library_url
    url = "companies/#{company_id}"
    if not (library_id.nil? || library_id.empty?)
      url << "/libraries/#{library_id}"
    end
    url
  end

  def create_search_media_sub_url(type, params, format)

    url = "#{create_account_library_url}/#{type}.#{format}"

    all_params = include_auth_in_search_call?(format) ? add_view_auth_param(params) : params

    http.create_sub_url(url, all_params)
  end

  def include_auth_in_search_call?(format) 
    # the only case that doesn't require it is rss when rss auth is not required
    ! (format.eql?('rss') && (! rss_auth_required))
  end

  # replaces the custom_fields property on each of the given media objects
  # (a list of the objects returned from the search APIs),
  # with a Hash of custom field name=>value
  def cleanup_search_results!(items)
    items.each do |item|
      cleanup_custom_fields(item)
    end
  end

  def cleanup_custom_fields(item) 
    if (item.instance_variable_defined?('@custom_fields'))
      item.custom_fields = search_media_custom_fields_as_hash(item)
    end
    item
  end

  # takes a media object as returned from the search APIs
  # and returns the item's custom fields as a Hash of name->value,
  # or an empty Hash if the item has no custom fields
  def search_media_custom_fields_as_hash(item)
    if not item.instance_variables.include?('@custom_fields')
      Hash.new
    else
      item.custom_fields.inject(Hash.new) do |hash,custom_field|
        hash[custom_field.name] = custom_field.value
        hash
      end
    end
  end

  # Produces an XML string appropriate to calling the 
  # create asset API for videos or audio tracks.
  # converts the given hash into an <asset> element
  def create_asset_xml_from_hash(entry)
    entry_xml = create_xml_from_value({:asset => entry})
    %Q(<?xml version="1.0" encoding="UTF-8"?>#{entry_xml})
  end

  def create_xml_from_value(value)
    if value.class.name.eql?("Hash")
      value.collect {|k,v| "<#{k}>#{create_xml_from_value(v)}</#{k}>"}.join("\n")
    elsif value.class.name.eql?("Array")
      value.map {|item| create_xml_from_value(item)}.join("")
    else
      value.to_s
    end
  end

  def auth_signature(token, duration, params={})    
    media_api_result do 
      if not token.expired?
        token.token
      else
        token.renew(fetch_auth_token(token.name, duration, params),
                    duration)        
      end
    end
  end

  def fetch_auth_token(name, duration, params)
    media_api_result(MediaApiAuthenticationFailedException) do
      http.get("api/#{name}", 
               params.merge({:licenseKey => license_key, :duration => duration}))
    end
  end

  def ingest_auth_param_key?(key)
    ["ingest_profile"].include?(key.to_s)
  end

  def add_view_auth_param(params={})
    add_param('signature', authenticate_for_view, params)
  end

  def add_update_auth_param(params={})
    add_param('signature', authenticate_for_update, params)
  end

  def add_ingest_auth_param(contributor, params={})
    add_param('signature', authenticate_for_ingest(contributor, params), params)
  end

  def add_param(key, value, params)
    params.merge({key => value})
  end

  def update_auth_token
    @update_auth_token ||= AuthToken.new('update_key', license_key)
  end

  def ingest_auth_token
    @ingest_auth_token ||= AuthToken.new('ingest_key', license_key)
  end  
end

# Used by MediaApi to manage duration-based auth token signatures using a local cache file.
class AuthToken

  attr_reader :name, :license_key, :token_file_dir

  # name:: the type of key.  This is used as a fragement of the API's URL, and as the name of the local cache file.  e.g. provide 'view_key' or 'update_key'.
  def initialize(name, license_key)
    
    @license_key = license_key
    @name = name

    if license_key.nil? || license_key.empty?
      raise MediaApiException.new("license_key required")
    end

    if name.nil? || name.empty?
      raise StandardError.new("AuthToken: name required")
    end

    # operating system temp directory, for the signature cache file
    @token_file_dir = Dir.tmpdir

  end  

  # Stores the given token as the cached signature, setting the given duration_in_minutes as the signature's duration, for comparison with the current time in later uses.
  def renew(token, duration_in_minutes)
    write_cache(AuthToken.assert_valid(token), duration_in_minutes, Time.new.to_i)
    reset
    token
  end

  # Resets the contents of the cache file.
  def reset_cache    
    write_cache(nil, 0, 0)
    reset
  end

  # Returns true if the signature in the cache file is expired according to the current time.
  def expired?
    token.nil? || elapsed_minutes >= duration_in_minutes
  end

  # Returns the current token in the cache file, or nil if the cache file doesn't exist yet.
  def token
    if HttpClient.trace_on?
      puts("token: license key=#{license_key}")
    end
    @token ||= (load_cache and @token)
  end

  # Returns the currently cached token's duration in minutes, or nil if the cache file doesn't exist yet.
  def duration_in_minutes
    @duration_in_minutes ||= (load_cache and @duration_in_minutes)
  end

  # Returns the current cached token's time of creation, for use in determining when it will expire, or nil if the cache file doesn't exist yet.
  def start_time
    @start_time ||= (load_cache and @start_time)
  end

  def AuthToken.assert_valid(sig)
    if sig.nil? or (sig.chop =~ /^[a-zA-Z0-9]+$/).nil?
      raise MediaApiAuthenticationFailedException.new("invalid signature: #{sig}")
    else
      sig
    end
  end

  # Returns the path of the local cache file.
  def cache_file_path
    "#{token_file_dir}/media_api.ruby.#{name}.#{license_key}.json"
  end

  protected

  def load_cache

    reset

    if cache_file_present?      
      begin
        json = cache_as_json     
        @token = json['token']
        @start_time = json['start_time']
        @duration_in_minutes = json['duration_in_minutes']
      rescue => e
        # if the file is corrupted, delete it to force a lazy-create next time
        File.unlink(cache_file_path)
        reset
      end
    end
    
    true
  end

  def reset
    @token = @start_time = @duration_in_minutes = nil
  end

  def cache_as_json
    JSON.parse(cache_file_contents)
  end

  def cache_file_contents
    File.read(cache_file_path)
  end

  def write_cache(token, duration_in_minutes, start_time)
    File.open(cache_file_path, 'w') do |f| 
      f.write({
         'token' => token, 
         'duration_in_minutes' => duration_in_minutes.to_i, 
         'start_time' => start_time.to_i
      }.to_json)
    end
  end

  def elapsed_minutes
    # pad by 30 seconds to avoid case of checking the token
    # just before it expires and then trying to use it
    (Time.new.to_i - start_time + 30).div 60
  end

  def cache_file_present?
    File.exist?(cache_file_path)
  end

end

# Raised whenever an exception condition is encountered when calling MediaApi methods, including exceptions stemming from HttpClient.
class MediaApiException < Exception
  
  def init(source)
    super(source)
  end

end

# Raised by MediaApi if it fails to obtain a valid authentication signature, most likely because the license key provided wasn't valid, or it has made more than the allowed number of authentication API calls per minute.
class MediaApiAuthenticationFailedException < MediaApiException

  def init(source)
    super(source)
  end

end

end # VideoApi module

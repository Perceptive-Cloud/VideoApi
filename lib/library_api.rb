require 'media_api'

module VideoApi

# Wrapper class for the REST library API and other features.
#
class LibraryApi < MediaApi

  # Creates a LibraryApi object scoped to the given library
  # within the given account.  
  #
  # base_url:: the service base url - see online documentation for this value.
  # company_id:: the account's ID
  # library_id:: the ID of the library within the account to work with
  # license_key:: the license key to use for all authorization requests.  it can be the license key of a user associated with the given library, or an account-wide user.  
  def self.for_library(base_url, company_id, library_id, license_key)
    self.new(MediaApi.create_settings_hash(base_url, company_id, library_id, license_key), true)
  end

  # Creates a LibraryApi object scoped to the entire account (i.e. not to a specific library within the account).
  #
  # base_url:: the service base url - see online documentation for this value.
  # company_id:: the account's ID
  # license_key:: the license key to use for all authorization requests.  it must be the license key for an account-level user, not a user assigned to a specific library.  
  #
  # Note: to call the library ingest or import methods, you must
  # call LibraryApi.for_library instead, or those methods will
  # raise an error.
  #
  def self.for_account(base_url, company_id, license_key)
    self.new(MediaApi.create_settings_hash(base_url, company_id, nil, license_key), false)
  end

  # Creates a new LibraryApi object from the given YAML settings file.
  # YAML file should contain the following keys: base_url, company_id, license_key.  It should also contain a library_id key if you want to scope the LibraryApi object to a specific library, or ingest/import libraries.
  #
  def self.from_settings_file(path, require_library=false)
    self.new(MediaApi.settings_file_path_to_hash(path), require_library)
  end

  # Create a LibraryApi object from the given hash of values.
  # must contain base_url, company_id, and license_key, and
  # optionally library_id.
  def self.from_props(props, require_library=false)
    self.new(props, require_library)
  end

  def initialize(props, require_library=false)
    super(props, require_library)
  end

  # Calls the Library Metadata API, returning the given library's metadata.
  # library_id:: the library's ID
  # format:: an optional string specifying the format of the returned metadata.  If omitted or nil, returns the metadata as a tree of ruby objects generated from the metadata obtained in json format.
  # - 'xml': returns the metadata as an xml string
  # - 'json': returns the metadata as a json string
  # options:: additional optional params to pass on to the API call
  #
  def get_library_metadata(library_id, format=nil, options={})
    params = add_view_auth_param.merge(options)
    structured_data_request("companies/#{company_id}/libraries/#{library_id}", params, format) { |library| cleanup_custom_fields(library) }
  end

  # Calls the Update Library API, modifying the given's library's metadata or stillframe.
  # library_id:: the Id of the library in question.
  # params:: a hash specifying how to update the library's metadata.  See the online documentation for details.
  #
  # As a convenience, this method will wrap any params in library[],
  # and also allows keyword params, meaning that you can specify each 
  # param key in the hash in one of three ways:
  #
  # {"library[title]" => "my new title"}
  #
  # {"title" => "my new title"}
  #
  # {:title => "my new title"}
  #
  # this method will convert them to the right format for the API call.
  #
  def update_library(library_id, params)
    library_api_result do
      the_params = wrap_update_params(params, "library")
      the_params = add_update_auth_param(the_params)
      http.put("companies/#{company_id}/libraries/#{library_id}", the_params)
    end
  end

  # Calls the Delete Library API, moving the given library to the Trash in the online account.  Libraries remain in the trash state for 7 days, after which they and their metadata are permanently deleted.
  def delete_library(library_id)
    library_api_result do
      http.delete("companies/#{company_id}/libraries/#{library_id}", add_update_auth_param)
    end
  end

=begin
  # Moves the library out of the trash, using a call to the Update Library API,
  # specifyng a blank deleted_at value.
  #
  # Libraries remain in the trash for 7 days.  During that 7-day period,
  # you can call this method to remove the library from the trash ("undelete" it).
  # After the library is permanently deleted (7 days later), this
  # method will raise an error because the library will no longer exist.
  #
  def undelete_library(library_id)
    update_library(library_id, {:deleted_at => ""})
  end
=end

  # Calls the Library Import API with an XML document created from the given Hash.
  #
  # for example:
  #
  # create_library_from_hash({:library => { 'name' => 'the_library_name' }})
  #
  # params:: params passed to authenticate_for_ingest.  to specify an ingest_profile, include an 'ingest_profile' or :ingest_profile parameter
  #
  def create_library_from_hash(lib_hash, params={})
    create_library_from_xml_string(create_library_xml_from_hash(lib_hash), params)
  end

  # Produces a Library Create API XML string.
  def create_library_xml_from_hash(lib_hash)
    entry_xml = create_xml_from_value(lib_hash)
    '<?xml version="1.0" encoding="UTF-8"?>' + entry_xml
  end

  # Calls the Library Asset Create API with the given XML string.
  def create_library_from_xml_string(xml, params)
    library_api_result do
      http.post("companies/#{company_id}/libraries",
                add_update_auth_param.merge(params),
                xml,
                "text/xml")              
    end
  end

  def media_api_result(exception_class=LibraryApiException, &block)
    begin
      super(exception_class, &block)
    rescue MediaApiAuthenticationFailedException => e
      raise LibraryApiAuthenticationFailedException.new(e)
    rescue LibraryApiException => e
      raise
    rescue MediaApiException => e
      raise LibraryApiException.new(e)
    end
  end

  def library_api_result(exception_class=LibraryApiException, &block) 
    media_api_result(exception_class, &block)
  end

end

# Raised whenever an exception condition is encountered when calling LibraryApi methods, including exceptions stemming from HttpClient.
class LibraryApiException < MediaApiException
  
  def init(source)
    super(source)
  end

end

# Raised by LibraryApi if it fails to obtain a valid authentication signature, most likely because the license key provided wasn't valid, or it has made more than the allowed number of authentication API calls per minute.
class LibraryApiAuthenticationFailedException < LibraryApiException
  def init(source)
    super(source)
  end
end

end # VideoApi module

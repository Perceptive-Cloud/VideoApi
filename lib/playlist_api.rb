require 'media_api'

module VideoApi

# Wrapper class for the REST playlist API and other features.
#
class PlaylistApi < MediaApi

  # Create a PlaylistApi object from the given hash of values.
  # must contain base_url, company_id, and license_key, and
  # optionally playlist_id.
  def self.from_props(props, require_playlist=false)
    self.new(props, require_playlist)
  end

  def initialize(props, require_playlist=false)
    super(props, require_playlist)
  end

  # Calls the Playlist Metadata API, returning the given playlist's metadata.
  # playlist_id:: the playlist's ID
  # format:: an optional string specifying the format of the returned metadata.  If omitted or nil, returns the metadata as a tree of ruby objects generated from the metadata obtained in json format.
  # - 'xml': returns the metadata as an xml string
  # - 'json': returns the metadata as a json string
  # options:: additional optional params to pass on to the API call
  #
  def get_playlist_metadata(playlist_id, format=nil, options={})
    params = add_view_auth_param.merge(options)
    structured_data_request("playlists/#{playlist_id}", params, format) { |playlist| cleanup_custom_fields(playlist) }
  end

  # Calls the Update Playlist API, modifying the given's playlist's metadata or stillframe.
  # playlist_id:: the Id of the playlist in question.
  # params:: a hash specifying how to update the playlist's metadata.  See the online documentation for details.
  #
  # As a convenience, this method will wrap any params in playlist[],
  # and also allows keyword params, meaning that you can specify each 
  # param key in the hash in one of three ways:
  #
  # {"playlist[title]" => "my new title"}
  #
  # {"title" => "my new title"}
  #
  # {:title => "my new title"}
  #
  # this method will convert them to the right format for the API call.
  #
  def update_playlist(playlist_id, params)
    playlist_api_result do
      the_params = wrap_update_params(params, "playlist")
      the_params = add_update_auth_param(the_params)
      http.put("playlists/#{playlist_id}", the_params)
    end
  end
  
  def create_playlist(company_id, params)
    playlist_api_result do
      the_params = wrap_update_params(params, "playlist")
      the_params = add_update_auth_param(the_params)
      http.post("companies/#{company_id}/playlists", the_params)
    end
  end

  # Calls the Delete Playlist API, permanently destroying the given playlist.
  def delete_playlist(playlist_id)
    playlist_api_result do
      http.delete("playlists/#{playlist_id}", add_update_auth_param)
    end
  end

  # Calls the Playlist Create API with parameters based on the given Hash.
  #
  # for example:
  #
  # create_playlist_from_hash({:playlist => { 'name' => 'the_playlist_name' }})
  #
  def create_playlist_from_hash(params)
    playlist_api_result do
      http.post("companies/#{company_id}/playlists", add_update_auth_param.merge(params))
    end
  end

  def media_api_result(exception_class=PlaylistApiException, &block)
    begin
      super(exception_class, &block)
    rescue MediaApiAuthenticationFailedException => e
      raise PlaylistApiAuthenticationFailedException.new(e)
    rescue PlaylistApiException => e
      raise
    rescue MediaApiException => e
      raise PlaylistApiException.new(e)
    end
  end

  def playlist_api_result(exception_class=PlaylistApiException, &block) 
    media_api_result(exception_class, &block)
  end

end

# Raised whenever an exception condition is encountered when calling PlaylistApi methods, including exceptions stemming from HttpClient.
class PlaylistApiException < MediaApiException

  def init(source)
    super(source)
  end

end

# Raised by PlaylistApi if it fails to obtain a valid authentication signature, most likely because the license key provided wasn't valid, or it has made more than the allowed number of authentication API calls per minute.
class PlaylistApiAuthenticationFailedException < PlaylistApiException
  def init(source)
    super(source)
  end
end

end # VideoApi module

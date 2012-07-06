require 'media_api'

module VideoApi

# Wrapper class for the REST video API and other features.
#
class VideoApi < MediaApi

  # Creates a VideoApi object scoped to the given library
  # within the given account.  
  #
  # base_url:: the service base url - see online documentation for this value.
  # company_id:: the account's ID
  # library_id:: the ID of the library within the account to work with
  # license_key:: the license key to use for all authorization requests.  it can be the license key of a user associated with the given library, or an account-wide user.  
  def self.for_library(base_url, company_id, library_id, license_key)
    self.new(MediaApi.create_settings_hash(base_url, company_id, library_id, license_key), true)
  end

  # Creates a VideoApi object scoped to the entire account (i.e. not to a specific library within the account).
  #
  # base_url:: the service base url - see online documentation for this value.
  # company_id:: the account's ID
  # license_key:: the license key to use for all authorization requests.  it must be the license key for an account-level user, not a user assigned to a specific library.  
  #
  # Note: to call the video ingest or import methods, you must
  # call VideoApi.for_library instead, or those methods will
  # raise an error.
  #
  def self.for_account(base_url, company_id, license_key)
    self.new(MediaApi.create_settings_hash(base_url, company_id, nil, license_key), false)
  end

  # Creates a new VideoApi object from the given YAML settings file.
  # YAML file should contain the following keys: base_url, company_id, license_key.  It should also contain a library_id key if you want to scope the VideoApi object to a specific library, or ingest/import videos.
  #
  def self.from_settings_file(path, require_library=false)
    self.new(MediaApi.settings_file_path_to_hash(path), require_library)
  end

  # Create a VideoApi object from the given hash of values.
  # must contain base_url, company_id, and license_key, and
  # optionally library_id.
  def self.from_props(props, require_library=false)
    self.new(props, require_library)
  end

  def initialize(props, require_library=false)
    super(props, require_library)
  end

  # Returns the HTTP (progressive-download) URL of the given video's source asset, i.e. the original video file uploaded to the account.
  def get_download_url_for_source_asset(video_id)
    get_download_url(video_id, {:ext => 'source'})
  end

  # Returns the HTTP (progressive-download) URL of one of the given video's assets, specified by params.
  # params:: an optional hash specifying one of the video's assets.  If empty or nil, this method returns the URL of the video's main asset.
  # - :asset_id specifies the asset by asset ID (a string)
  # - :format specifies the asset by format name
  # - :ext specifies the asset by file extension
  #
  # example:
  # 
  # url = api.get_download_url("ABCDE", {:format => "high_quality_ipod"})
  #
  def get_download_url(video_id, params=nil)
    http.create_url(get_download_sub_url(video_id, params))
  end      

  # returns the URL of the given video's stillframe.
  # video_id:: the video's ID
  # params:: an optional hash modifying the stillframe returned.
  # - :width the width of the rendered stillframe.
  # - :height the height of the rendered stillframe. 
  #
  # url = api.get_stillframe_url("ABCDE", {:width => 300, :height => 200})
  #
  def get_stillframe_url(video_id, params={})

    width = params[:width] || params['width'] || nil
    height = params[:height] || params['height'] || nil

    url = http.create_url("videos/#{video_id}/screenshots/")

    if width
      url << "#{width.to_s}w"
    end

    if height
      url << "#{height.to_s}h"
    end

    if width.nil? and height.nil?
      url << "original"
    end

    "#{url}.jpg"

  end

  # Calls the Video Metadata API, returning the given video's metadata.
  # video_id:: the video's ID
  # format:: an optional string specifying the format of the returned metadata.  If omitted or nil, returns the metadata as a tree of ruby objects generated from the metadata obtained in json format.
  # - 'xml': returns the metadata as an xml string
  # - 'json': returns the metadata as a json string
  # options:: additional optional params to pass on to the API call
  #
  def get_video_metadata(video_id, format=nil, options={})
    params = add_view_auth_param.merge(options)
    structured_data_request("videos/#{video_id}", params, format) { |video| cleanup_custom_fields(video) }
  end

  # Calls the Playlist Metadata API, returning the given playlist's metadata.
  # playlist_id:: the playlist's ID
  # format:: an optional string specifying the format of the returned metadata.  If omitted or nil, returns the metadata as a tree of ruby objects generated from the metadata obtained in json format.
  # - 'rss': returns the metadata as an rss string
  # - 'json': returns the metadata as a json string
  # options:: additional optional params to pass on to the API call
  #
  def get_playlist_metadata(playlist_id, format=nil, options={})
    params = add_view_auth_param.merge(options)
    structured_data_request("playlists/#{playlist_id}", params, format)
  end

  # Returns the URL of an RSS feed of the entire account or library's videos.
  # params:: optional hash, adds criteria to the RSS feed URL.  See the online documentation for details.
  #
  # url = api.get_rss_url {:from => '2009/01/01'}
  #
  def get_rss_url(params={})
    http.create_url(create_search_sub_url(params, 'rss'))
  end

  # Calls the Video Search API, constraining the search to only videos within the library if one was specified in the constructor.
  #
  # params:: (optional) hash specifying search criteria.  See the online documentation for details.  If omitted, the results will contain all videos in the library.
  # format:: optional format string.  if omitted, this method returns the metadata as a tree of ruby objects, generated by obtaining the search results in json format and parsing it.
  # - 'xml':: returns the search results as an xml string.
  # - 'json':: returns the search results as a json string.
  #
  # returns a page of Video Search API results.
  #
  # replaces the custom_fields and tags on each video with
  # a Hash containing one key per custom field or tag,
  # instead of the array returned in the JSON results
  #
  def search_videos(params={}, format=nil)
    search_media(params, format)
  end

  # Calls search_videos (Video Search API) with the given hash of params, 
  # paginating through the entire result set, 
  # yielding to the provided block with each page of search results
  # as it is obtained.  The provided block can break the loop
  # (stop calling for further pages of results) by returning
  # false.  Any other return value will continue the loop.
  # params:: a hash of params to pass to search_videos.
  #
  # example:
  # search_videos_each_page({:query => "balloons"}) do |page|
  #   puts "#{page.videos.length} more videos"
  # end
  #
  def search_videos_each_page(params={}, &block)
    search_media_each_page(params, &block)
  end

  # Calls search_videos_each_page (Video Search API) 
  # with the given hash of params, 
  # paginating through the entire result set, 
  # yielding to the provided block with each video in each page of results.
  # The provided block can abort the loop by returning
  # false.  Any other return value will continue the loop.
  # params:: a hash of params to pass to search_videos.
  #
  # example:
  # search_videos_each({:query => "balloons"}) do |video|
  #   puts "video: #{video.video_id}"
  #   if some_condition(video)
  #     false  # aborts pagination loop
  #   end
  # end
  #
  def search_videos_each(params={}, &block) 
    search_media_each(params, &block)
  end

  # NOTE: This method is deprecated.  Instead, use search_videos, 
  # specifying a value for the 'tags' parameter, which will return the same
  # results as this method.
  #
  # Calls the Tags API, returning the IDs of all videos tagged with the given tag.  If a library_id was provided in the constructor, only returns results for that library.
  # tag:: the tag to search for
  # format:: optional, specifies the format to return the results in.  If ommitted, this method just returns an Array of matching video's IDs.
  # - 'xml': returns the results as an xml string
  # - 'json': return the results as a json string.
  #
  def get_videos_with_tag(tag, params={}, format=nil)
    get_media_with_tag("videos", tag, params, format)
  end

  # Calls the Delivery Statistics API.  If a library_id was provided to the constructor, returning only results for that library.
  # params:: a hash specifying the criteria of the statistics report.  See the online documentation for details.
  # format:: an optional string specifying how to return the results.  If omitted, returns them as a ruby object tree, produced by parsing the JSON results.
  # - 'xml': returns the results in xml format.
  # - 'json': returns the results in json format.
  #
  def get_delivery_stats(params, format=nil)
    structured_data_request("#{create_account_library_url}/statistics/video_delivery", 
                           add_view_auth_param(params),
                           format)
  end

  # Calls the Video Delivery Statistics API, returning statistics for the given video.  Usage is otherwise identical to get_delivery_stats_for_library.
  # video_id:: the ID of the video in question.
  def get_delivery_stats_for_video(video_id, params, format=nil)
    structured_data_request("videos/#{video_id}/statistics", 
                           add_view_auth_param(params),
                           format)
  end

  # Calls the Video Statistics API, returning statistics for the given tag.  Note that due to the nature of the API, the returned data is for the entire account, not a specific library, even if this api object has a library ID set.
  # tag:: the tag in question.
  def get_delivery_stats_for_tag(tag, params, format=nil)
    structured_data_request("companies/#{company_id}/tags/#{tag}/statistics", 
                           add_view_auth_param(params),
                           format)
  end

  # deprecated - use get_ingest_stats_encode instead
  def get_ingest_stats(params, format=nil)
    structured_data_request("#{create_account_library_url}/statistics/video_publish", 
                           add_view_auth_param(params),
                           format)
  end

  # Calls the Ingest Statistics API, returning statistics about video encoding activity.  If library_id was provided in the constructor, only returns results for that library.  See online documentation for details.  
  # params:: hash specifying the criteria for statistics report.
  # format:: optional string specifying the result format.
  # - if omitted, returns the results as a ruby object tree.
  # - 'xml': returns the results in xml format.
  # - 'json': returns the results in JSON format.
  #
  def get_ingest_stats_encode(params, format=nil)
    structured_data_request("#{create_account_library_url}/statistics/video_publish/encode", 
                           add_view_auth_param(params),
                           format)
  end

  # Calls the Ingest Statistics API, returning statistics about video upload activity.  If library_id was provided in the constructor, only returns results for that library.  See online documentation for details.  
  # params:: hash specifying the criteria for statistics report.
  # format:: optional string specifying the result format.
  # - if omitted, returns the results as a ruby object tree.
  # - 'xml': returns the results in xml format.
  # - 'json': returns the results in JSON format.
  #
  def get_ingest_stats_source(params, format=nil)
    structured_data_request("#{create_account_library_url}/statistics/video_publish/source", 
                           add_view_auth_param(params),
                           format)
  end

  # Calls the Ingest Statistics API, returning a breakdown of video ingest statistics.  If library_id was provided in the constructor, only returns results for that library.  See online documentation for details.  
  # params:: hash specifying the criteria for statistics report.
  # format:: optional string specifying the result format.
  # - if omitted, returns the results as a ruby object tree.
  # - 'xml': returns the results in xml format.
  # - 'json': returns the results in JSON format.
  #
  def get_ingest_stats_breakdown(params, format=nil)
    structured_data_request("#{create_account_library_url}/statistics/video_publish/breakdown", 
                           add_view_auth_param(params),
                           format)
  end

  # Calls the Storage Statistics API, returning statistics about video storage.  If library_id was provided in the constructor, only returns results for that library.  See online documentation for details.  
  # params:: hash specifying the criteria for statistics report.
  # format:: optional string specifying the result format.
  # - if omitted, returns the results as a ruby object tree.
  # - 'xml': returns the results in xml format.
  # - 'json': returns the results in JSON format.
  # - 'csv': returns the tesults in CSV format
  def get_storage_stats(params, format=nil)
    structured_data_request("#{create_account_library_url}/statistics/video_publish/disk_usage", 
                            add_view_auth_param(params),
                            format)
  end

  # Calls the Update Video API, modifying the given's video's metadata or stillframe.
  # video_id:: the Id of the video in question.
  # params:: a hash specifying how to update the video's metadata.  See the online documentation for details.
  #
  # As a convenience, this method will wrap any params in video[],
  # and also allows keyword params, meaning that you can specify each 
  # param key in the hash in one of three ways:
  #
  # {"video[title]" => "my new title"}
  #
  # {"title" => "my new title"}
  #
  # {:title => "my new title"}
  #
  # this method will convert them to the right format for the API call.
  #
  def update_video(video_id, params)
    video_api_result do
      http.put("videos/#{video_id}", add_update_auth_param(wrap_update_params(params, "video")))
    end
  end

  # Calls the Video Update API, setting the given video to visible or hidden.  
  def set_video_visibility(video_id, visible)
    update_video(video_id, {'video[hidden]' => visible ? 'false' : 'true'})
  end

  def delete_asset(asset_id, media_item_id)
    video_api_result do
      http.delete("videos/#{media_item_id}/assets/#{asset_id}", add_update_auth_param())
    end
  end

  # Calls the Delete Video API, moving the given video to the Trash in the online account.  Videos remain in the trash state for 7 days, after which they and their metadata are permanently deleted.
  def delete_video(video_id)
    video_api_result do
      http.delete("videos/#{video_id}", add_update_auth_param)
    end
  end

  # Moves the video out of the trash, using a call to the Update Video API,
  # specifyng a blank deleted_at value.
  #
  # Videos remain in the trash for 7 days.  During that 7-day period,
  # you can call this method to remove the video from the trash ("undelete" it).
  # After the video is permanently deleted (7 days later), this
  # method will raise an error because the video will no longer exist.
  #
  def undelete_video(video_id)
    update_video(video_id, {:deleted_at => ""})
  end

  # Calls the Video Import API, letting you import videos from a remote webserver into your video account.  
  # xml:: a string of XML specifying the videos to import.  See the online documentation for an example of this XML string.
  # contributor:: the string to use as the contributor name for the imported videos.
  # params:: params passed to authenticate_for_ingest.  to specify an ingest_profile, include an 'ingest_profile' or :ingest_profile parameter
  #
  def import_videos_from_xml_string(xml, contributor, params={})
    import_media_items_from_xml_string(:video, xml, contributor, params)
  end

  # Calls the Video Import API with the XML read from the given file path.
  # path:: the path of the file containing the video import XML.  See the online documentation for details of the XML format.
  # contributor:: the string to use as a the contributor name for the imported videos.
  # params:: params passed to authenticate_for_ingest.  to specify an ingest_profile, include an 'ingest_profile' or :ingest_profile parameter
  #
  def import_videos_from_xml_file(path, contributor, params={})
    import_videos_from_xml_string(File.read(path), contributor, params)
  end

  # Calls the Video Import API with an XML document created from the
  # given array of Hash objects, each representing
  # one of the <entry> elements in the import.
  # nested elements like <customdata> should represented by
  # a nested Hash.
  #
  # for example:
  #
  # import_videos_from_entries([{:src => "http://www.mywebsite.com/videos/1",
  #                        :title => "video 1",
  #                        :tags => [{:tag => 'balloons'}]
  #                       },
  #                       {:src => "http://www.mywebsite.com/videos/2",
  #                        :title => "video 2",
  #                        :customdata => {:my_custom_field => true}
  #                       }
  #                      ])
  #
  # params:: params passed to authenticate_for_ingest.  to specify an ingest_profile, include an 'ingest_profile' or :ingest_profile parameter
  #
  def import_videos_from_entries(entries, contributor, params={})
    import_videos_from_xml_string(create_video_import_xml_from_hashes(entries),
                                  contributor,
                                  params)
  end
  
  # Produces a Video Import API XML string.
  def create_video_import_xml_from_hashes(entries)

    entry_xmls = entries.map {|entry| create_xml_from_value({:entry => entry})}

    '<?xml version="1.0" encoding="UTF-8"?><add><list>' + entry_xmls.join("\n") + '</list></add>'

  end

  # Calls the Video Asset Create API with the given XML string.
  def create_video_asset_from_xml_string(video_id, xml)
    video_api_result do
      http.post("videos/#{video_id}/assets.xml",
                add_update_auth_param(),
                xml,
                "text/xml")              
    end
  end
  
  # Calls the Video Asset Create API with the XML string
  # in the file at the given path.
  def create_video_asset_from_xml_file(video_id, path)
    create_video_asset_from_xml_string(video_id, File.read(path))
  end

  # Calls the Video Asset Create API with XML created
  # from the given entry.
  #
  # example:
  #
  # Example 1: Create a new asset for an existing video
  # api.create_video_asset_from_entry('ABCDE', {:format_name => 'medium-h-264'})
  #
  # Example 2: Add an asset to an existing video
  # api.create_video_asset_from_entry('ABCDE', {:url => 'http://blahblah.com/12345'})
  #
  # Example 3: Add a remote asset to an existing video
  # the_metadata = { :container_type => 'flv', :video_codec => 'h263', :audio_codec => 'mp3' } And other options, see online docs
  # api.create_video_asset_from_entry('ABCDE', {:metadata => the_metadata, :process => false, :url => 'http://blahblah.com/12345'})
  #
  def create_video_asset_from_entry(video_id, entry)
    create_video_asset_from_xml_string(video_id, create_asset_xml_from_hash(entry))
  end

  # Calls the Progressive Download API, downloading one of the given video's assets into a file on the local hard drive.
  # video_id:: the ID of the video to download.
  # file_path:: the path of the local file to create (to download the video asset as)
  # params:: optional hash specifying which asset to download.  Usage here is identical to that of get_download_url.  If omitted, downloads the video's main asset.
  def download_video_asset(video_id, file_path, params=nil)
    video_api_result do
      http.download_file(get_download_sub_url(video_id, params), 
                         file_path)
    end
  end

  # Calls the Progressive Download API, downloading the given video's source asset into a local file.  Calling this method will download the original video file you uploaded to the account for this video.  Usage is otherwise identical to download_video_asset.
  # video_id:: the ID of the video to download.
  # file_path:: the path on the local hard drive to download the file as.
  def download_video_source_asset(video_id, file_path)
    video_api_result do
      http.download_file(get_download_sub_url(video_id, {:ext => 'source'}),
                         file_path)
    end
  end

  # synonym for upload_media
  def upload_video(filename, contributor, params={}, &progress_listener)
    upload_media(filename, contributor, params, &progress_listener)
  end

  # Calls the Video Slice API
  # video_id:: the video to slice
  # contributor:: the string to use as the new segment videos' contributor
  # xml:: the xml to upload detailing the slices
  # format:: (optional) the asset to slice, specified using its video format name.  If omitted, slices the video's source asset.
  def slice_video(video_id, contributor, xml, format='source')
    video_api_result do
      http.post("videos/#{video_id}/formats/#{format}/slice.xml", 
                add_ingest_auth_param(contributor), 
                xml, 
                "text/xml")
    end
  end

  protected

  def tag_media_type
    "videos"
  end

  def get_track_api_media_object_id(video)
    video.video_id
  end

  def create_search_sub_url(params, format)
    create_search_media_sub_url("videos", params, format)
  end

  def get_search_page_media(page)
    page.videos
  end

  def get_download_sub_url(video_id, params=nil)
    url = get_download_sub_url_no_auth(video_id, params)
    if auth_required_for_download
      "#{url}?signature=#{authenticate_for_view}"
    else
      url
    end
  end

  def get_download_sub_url_no_auth(video_id, params=nil)
    if params.nil? || params.empty?
      "videos/#{video_id}/file"
    elsif params[:asset_id]
      "videos/#{video_id}/assets/#{params[:asset_id]}/file"      
    elsif params[:format]
      "videos/#{video_id}/formats/#{params[:format]}/file"      
    elsif params[:ext]
      "videos/#{video_id}/file.#{params[:ext]}"
    else
      raise VideoApiException.new("params contains unrecognized key(s):" + params.keys.join(','))
    end
  end

  def media_api_result(exception_class=VideoApiException, &block)
    begin
      super(exception_class, &block)
    rescue MediaApiAuthenticationFailedException => e
      raise VideoApiAuthenticationFailedException.new(e)
    rescue VideoApiException => e
      raise
    rescue MediaApiException => e
      raise VideoApiException.new(e)
    end
  end

  def video_api_result(exception_class=VideoApiException, &block) 
    media_api_result(exception_class, &block)
  end

end

# Raised whenever an exception condition is encountered when calling VideoApi methods, including exceptions stemming from HttpClient.
class VideoApiException < MediaApiException
  
  def init(source)
    super(source)
  end

end

# Raised by VideoApi if it fails to obtain a valid authentication signature, most likely because the license key provided wasn't valid, or it has made more than the allowed number of authentication API calls per minute.
class VideoApiAuthenticationFailedException < VideoApiException
  def init(source)
    super(source)
  end
end

end # VideoApi module

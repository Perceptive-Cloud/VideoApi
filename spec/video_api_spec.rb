require File.expand_path('../spec_helper', __FILE__)
require 'video_api'

describe VideoApi::VideoApi do
  let(:klass) { VideoApi::VideoApi }
  let(:obj) { klass.new({ 'base_url' => 'http://example.com', 'company_id' => 'CoID', 'license_key' => 'the_key' }) }

  describe "automatic access to component API classes" do
    it "should require/have access to AlbumApi" do
      lambda { VideoApi::AlbumApi }.should_not raise_error
    end
    it "should require/have access to AudioApi" do
      lambda { VideoApi::AudioApi }.should_not raise_error
    end
    it "should require/have access to ImageApi" do
      lambda { VideoApi::ImageApi }.should_not raise_error
    end
    it "should require/have access to LibraryApi" do
      lambda { VideoApi::LibraryApi }.should_not raise_error
    end
    it "should require/have access to MediaApi" do
      lambda { VideoApi::MediaApi }.should_not raise_error
    end
    it "should require/have access to PlaylistApi" do
      lambda { VideoApi::PlaylistApi }.should_not raise_error
    end
  end

  describe "Constants"

  describe ".for_account" do
    let(:meth)        { :for_account }
    let(:base_url)    { :the_base_url }
    let(:company_id)  { :the_co_id }
    let(:license_key) { :the_lk }
    context "when given base_url, company_id, license_key" do
      it "should call new(MediaApi.create_settings_hash(base_url, company_id, nil, license_key), false)" do
        VideoApi::MediaApi.should_receive(:create_settings_hash).with(base_url, company_id, nil, license_key).and_return(:created_media_api)
        klass.should_receive(:new).with(:created_media_api, false)
        klass.send(meth, base_url, company_id, license_key)
      end
    end
  end

  describe ".for_library" do
    let(:meth)        { :for_library }
    let(:base_url)    { :the_base_url }
    let(:company_id)  { :the_co_id }
    let(:library_id)  { :the_lb_id }
    let(:license_key) { :the_lk }
    context "when given base_url, company_id, library_id, license_key" do
      it "should call new(MediaApi.create_settings_hash(base_url, company_id, library_id, license_key), true)" do
        VideoApi::MediaApi.should_receive(:create_settings_hash).with(base_url, company_id, library_id, license_key).and_return(:created_media_api)
        klass.should_receive(:new).with(:created_media_api, true)
        klass.send(meth, base_url, company_id, library_id, license_key)
      end
    end
  end

  describe ".from_props" do
    let(:meth)  { :from_props }
    let(:props) { :the_props  }
    let(:require_playlist) { :the_rp }
    context "when given props and require_playlist" do
      it "should call new(props, require_playlist)" do
        klass.should_receive(:new).with(props, require_playlist)
        klass.send(meth, props, require_playlist)
      end
    end
    context "when given props alone" do
      it "should call new(props, false)" do
        klass.should_receive(:new).with(props, false)
        klass.send(meth, props)
      end
    end
  end

  describe ".from_settings_file" do
    let(:meth) { :from_settings_file }
    let(:path) { :the_path  }
    let(:require_library) { :the_rl }
    context "when given path and require_library" do
      it "should call new(MediaApi.settings_file_path_to_hash(path), require_library)" do
        VideoApi::MediaApi.should_receive(:settings_file_path_to_hash).with(path).and_return(:created_media_api)
        klass.should_receive(:new).with(:created_media_api, require_library)
        klass.send(meth, path, require_library)
      end
    end
    context "when given props alone" do
      it "should call new(MediaApi.settings_file_path_to_hash(path), false)" do
        VideoApi::MediaApi.should_receive(:settings_file_path_to_hash).with(path).and_return(:created_media_api)
        klass.should_receive(:new).with(:created_media_api, false)
        klass.send(meth, path)
      end
    end
  end

  describe "#create_search_sub_url" do
    let(:meth) { :create_search_sub_url }
    context "when given params, format" do
      let(:params) { mock(Symbol) }
      let(:format) { mock(Symbol) }
      it "should return create_search_media_sub_url('videos', params, format)" do
        obj.should_receive(:create_search_media_sub_url).with('videos', params, format).and_return(:expected)
        obj.send(meth, params, format).should == :expected
      end
    end
  end

  describe "#create_video_asset_from_entry" do
    let(:meth) { :create_video_asset_from_entry }
    context "when given video_id, entry" do
      let(:video_id) { mock(Symbol) }
      let(:entry) { mock(Symbol) }
      it "should create_asset_xml_from_hash(entry)" do
        obj.should_receive(:create_asset_xml_from_hash).with(entry)
        obj.stub!(:create_video_asset_from_xml_string)
        obj.send(meth, video_id, entry)
      end
      it "should create_video_asset_from_xml_string(track_id, the_created_xml)" do
        obj.stub!(:create_asset_xml_from_hash).with(entry).and_return(:the_created_xml)
        obj.should_receive(:create_video_asset_from_xml_string).with(video_id, :the_created_xml)
        obj.send(meth, video_id, entry)
      end
    end
  end

  describe "#create_video_asset_from_xml_file" do
    let(:meth)     { :create_video_asset_from_xml_file }
    let(:xml)      { :the_xml }
    let(:path)     { :the_path }
    let(:video_id) { :the_video_id }
    context "when given video_id, path" do
      it "should File.read(path) -> xml" do
        File.should_receive(:read).with(path).and_return(xml)
        obj.stub!(:create_video_asset_from_xml_string).with(video_id, xml)
        obj.send(meth, video_id, path)
      end
      it "should create_video_asset_from_xml_string(video_id, xml)" do
        File.stub!(:read).with(path).and_return(xml)
        obj.should_receive(:create_video_asset_from_xml_string).with(video_id, xml)
        obj.send(meth, video_id, path)
      end
    end
  end

  describe "#create_video_asset_from_xml_string" do
    let(:meth)      { :create_video_asset_from_xml_string }
    let(:xml)       { :the_xml }
    let(:video_id)  { :the_video_id }
    let(:mock_http) { mock(Symbol) }
    before(:each) do
      obj.stub!(:add_update_auth_param).and_return(:authed_params)
      obj.stub!(:http).and_return(mock_http)
      mock_http.stub!(:post)
    end
    context "when given video_id, xml" do
      it "should access its http object" do
        obj.should_receive(:http).and_return(mock_http)
        obj.send(meth, video_id, xml)
      end
      it "should add_update_auth_param" do
        obj.should_receive(:add_update_auth_param).and_return(:authed_params)
        obj.send(meth, video_id, xml)
      end
      it 'should http.post(("videos/#{video_id}/assets.xml", authed_params, xml, "text/xml")' do
        mock_http.should_receive(:post).with("videos/#{video_id}/assets.xml", :authed_params, xml, 'text/xml')
        obj.send(meth, video_id, xml)
      end
    end
  end

  describe "#create_video_import_xml_from_hashes" do
    let(:meth)      { :create_video_import_xml_from_hashes }
    let(:entries)   { (0..3).to_a }
    let(:video_id)  { :the_video_id }
    let(:mock_http) { mock(Symbol) }
    context "when entries" do
      it "should map create_xml_from_value onto entries and embed in an XML wrapper" do
        def obj.create_xml_from_value(opts); opts[:entry]; end
        entries_xml = entries.map { |e| obj.create_xml_from_value({ :entry => e}) }
        obj.send(meth, entries).should == %Q[<?xml version="1.0" encoding="UTF-8"?><add><list>#{entries_xml.join("\n")}</list></add>]
      end
    end
  end

  describe "#delete_asset" do
    let(:meth) { :delete_asset }
    context "when given asset_id, media_item_id" do
      let(:asset_id)      { :the_asset_id }
      let(:media_item_id) { :the_media_item_id }
      let(:mock_http) { mock(Symbol) }
      it 'should call http.delete("videos/#{media_item_id}/assets/#{asset_id}", add_update_auth_param())' do
        obj.should_receive(:add_update_auth_param).and_return(:auth_params)
        obj.should_receive(:http).and_return(mock_http)
        mock_http.should_receive(:delete).with("videos/#{media_item_id}/assets/#{asset_id}", :auth_params)
        obj.send(meth, asset_id, media_item_id)
      end
    end
  end

  describe "#delete_video" do
    let(:meth) { :delete_video }
    context "when given video_id" do
      let(:video_id)  { :the_vid_id }
      let(:mock_http) { mock(Symbol) }
      it 'should call http.delete("videos/#{video_id}", add_update_auth_param())' do
        obj.should_receive(:add_update_auth_param).and_return(:auth_params)
        obj.should_receive(:http).and_return(mock_http)
        mock_http.should_receive(:delete).with("videos/#{video_id}", :auth_params)
        obj.send(meth, video_id)
      end
    end
  end

  describe "#get_delivery_stats" do
    let(:meth)   { :get_delivery_stats }
    let(:params) { :the_params }
    let(:format) { :the_format }
    before(:each) do
      obj.stub!(:add_view_auth_param).and_return(:modified_params)
      obj.stub!(:structured_data_request)
    end
    context "when given params, format" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, params, format)
      end
      it 'should return structured_data_request("#{create_account_library_url}/statistics/video_delivery", modified_params, format' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/video_delivery", :modified_params, format)
        obj.send(meth, params, format)
      end
    end
    context "when given params" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, params)
      end
      it 'should return structured_data_request("#{create_account_library_url}/statistics/video_delivery", modified_params, nil' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/video_delivery", :modified_params, nil)
        obj.send(meth, params)
      end
    end
  end

  describe "#get_delivery_stats_for_tag" do
    let(:meth)   { :get_delivery_stats_for_tag }
    let(:tag)    { :the_tag }
    let(:params) { :the_params }
    let(:format) { :the_format }
    before(:each) do
      obj.stub!(:add_view_auth_param).and_return(:modified_params)
      obj.stub!(:structured_data_request)
    end
    context "when given tag, params, format" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, tag, params, format)
      end
      it 'should return structured_data_request("companies/CoID/tags/the_tag/statistics", modified_params, format' do
        obj.should_receive(:structured_data_request).with("companies/CoID/tags/the_tag/statistics", :modified_params, format)
        obj.send(meth, tag, params, format)
      end
    end
    context "when given tag, params" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, tag, params)
      end
      it 'should return structured_data_request("companies/CoID/tags/the_tag/statistics", modified_params, nil' do
        obj.should_receive(:structured_data_request).with("companies/CoID/tags/the_tag/statistics", :modified_params, nil)
        obj.send(meth, tag, params)
      end
    end
  end

  describe "#get_delivery_stats_for_video" do
    let(:meth)     { :get_delivery_stats_for_video }
    let(:video_id) { :the_vid_id }
    let(:params)   { :the_params }
    let(:format)   { :the_format }
    before(:each) do
      obj.stub!(:add_view_auth_param).and_return(:modified_params)
      obj.stub!(:structured_data_request)
    end
    context "when given video_id, params, format" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, video_id, params, format)
      end
      it 'should return structured_data_request("videos/the_vid_id/statistics", modified_params, format' do
        obj.should_receive(:structured_data_request).with("videos/the_vid_id/statistics", :modified_params, format)
        obj.send(meth, video_id, params, format)
      end
    end
    context "when given video_id, params" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, video_id, params)
      end
      it 'should return structured_data_request("videos/the_vid_id/statistics", modified_params, nil' do
        obj.should_receive(:structured_data_request).with("videos/the_vid_id/statistics", :modified_params, nil)
        obj.send(meth, video_id, params)
      end
    end
  end

  describe "#get_download_url" do
    let(:meth) { :get_download_url }
    let(:mock_http) { mock(Symbol) }
    before(:each) do
      obj.should_receive(:http).and_return(mock_http = mock(Symbol))
      mock_http.should_receive(:create_url).with(:download_sub_url).and_return(:expected)
    end
    context "when given video_id, params" do
      it "should return http.create_url(get_download_sub_url(video_id, params)))" do
        obj.should_receive(:get_download_sub_url).with(:video_id, :params).and_return(:download_sub_url)
        obj.send(meth, :video_id, :params).should == :expected
      end
    end
    context "when given video_id alone" do
      it "should return http.create_url(get_download_sub_url(video_id, nil)))" do
        obj.should_receive(:get_download_sub_url).with(:video_id, nil).and_return(:download_sub_url)
        obj.send(meth, :video_id).should == :expected
      end
    end
  end

  describe "#get_download_url_for_source_asset" do
    let(:meth) { :get_download_url_for_source_asset }
    context "when given video_id" do
      it "should return get_download_url(video_id, {:ext => 'source'})" do
        obj.should_receive(:get_download_url).with(:video_id, {:ext => 'source'}).and_return(:expected)
        obj.send(meth, :video_id).should == :expected
      end
    end
  end

  describe "#get_ingest_stats" do
    let(:meth)   { :get_ingest_stats }
    let(:params) { :the_params }
    let(:format) { :the_format }
    before(:each) do
      obj.stub!(:add_view_auth_param).and_return(:modified_params)
      obj.stub!(:structured_data_request)
    end
    context "when given params, format" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, params, format)
      end
      it 'should return structured_data_request("#{create_account_library_url}/statistics/video_publish", modified_params, format' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/video_publish", :modified_params, format)
        obj.send(meth, params, format)
      end
    end
    context "when given params" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, params)
      end
      it 'should return structured_data_request("#{create_account_library_url}/statistics/video_publish", modified_params, nil' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/video_publish", :modified_params, nil)
        obj.send(meth, params)
      end
    end
  end

  describe "#get_ingest_stats_breakdown" do
    let(:meth)   { :get_ingest_stats_breakdown }
    let(:params) { :the_params }
    let(:format) { :the_format }
    before(:each) do
      obj.stub!(:add_view_auth_param).and_return(:modified_params)
      obj.stub!(:structured_data_request)
    end
    context "when given params, format" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, params, format)
      end
      it 'should return structured_data_request("#{create_account_library_url}/statistics/video_publish/breakdown", modified_params, format' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/video_publish/breakdown", :modified_params, format)
        obj.send(meth, params, format)
      end
    end
    context "when given params" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, params)
      end
      it 'should return structured_data_request("#{create_account_library_url}/statistics/video_publish/breakdown", modified_params, nil' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/video_publish/breakdown", :modified_params, nil)
        obj.send(meth, params)
      end
    end
  end

  describe "#get_ingest_stats_encode" do
    let(:meth)   { :get_ingest_stats_encode }
    let(:params) { :the_params }
    let(:format) { :the_format }
    before(:each) do
      obj.stub!(:add_view_auth_param).and_return(:modified_params)
      obj.stub!(:structured_data_request)
    end
    context "when given params, format" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, params, format)
      end
      it 'should return structured_data_request("#{create_account_library_url}/statistics/video_publish/encode", modified_params, format' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/video_publish/encode", :modified_params, format)
        obj.send(meth, params, format)
      end
    end
    context "when given params" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, params)
      end
      it 'should return structured_data_request("#{create_account_library_url}/statistics/video_publish/encode", modified_params, nil' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/video_publish/encode", :modified_params, nil)
        obj.send(meth, params)
      end
    end
  end

  describe "#get_ingest_stats_source" do
    let(:meth)   { :get_ingest_stats_source }
    let(:params) { :the_params }
    let(:format) { :the_format }
    before(:each) do
      obj.stub!(:add_view_auth_param).and_return(:modified_params)
      obj.stub!(:structured_data_request)
    end
    context "when given params, format" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, params, format)
      end
      it 'should return structured_data_request("#{create_account_library_url}/statistics/video_publish/source", modified_params, format' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/video_publish/source", :modified_params, format)
        obj.send(meth, params, format)
      end
    end
    context "when given params" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, params)
      end
      it 'should return structured_data_request("#{create_account_library_url}/statistics/video_publish/source", modified_params, nil' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/video_publish/source", :modified_params, nil)
        obj.send(meth, params)
      end
    end
  end

  describe "#get_storage_stats" do
    let(:meth)   { :get_storage_stats }
    let(:params) { :the_params }
    let(:format) { :the_format }
    before(:each) do
      obj.stub!(:add_view_auth_param).and_return(:modified_params)
      obj.stub!(:structured_data_request)
    end
    context "when given params, format" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, params, format)
      end
      it 'should return structured_data_request("#{create_account_library_url}/statistics/video_publish/disk_usage", modified_params, format' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/video_publish/disk_usage", :modified_params, format)
        obj.send(meth, params, format)
      end
    end
    context "when given params" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, params)
      end
      it 'should return structured_data_request("#{create_account_library_url}/statistics/video_publish/disk_usage", modified_params, nil' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/video_publish/disk_usage", :modified_params, nil)
        obj.send(meth, params)
      end
    end
  end

  describe "#get_rss_url" do
    let(:meth)      { :get_rss_url }
    let(:mock_http) { mock(VideoApi::HttpClient) }
    before(:each) do
      obj.stub!(:create_search_sub_url).and_return(:the_created_rss_url)
      obj.stub!(:http).and_return(mock_http)
      mock_http.stub!(:create_url)
    end
    context "when given params" do
      let(:params) { :the_params }
      it "should create_search_sub_url(params, 'rss')" do
        obj.should_receive(:create_search_sub_url).with(params, 'rss')
        obj.send(meth, params)
      end
      it "should access its http instance" do
        obj.should_receive(:http).and_return(mock_http)
        obj.send(meth, params)
      end
      it "should return http.create_url(the_created_rss_url)" do
        mock_http.should_receive(:create_url).with(:the_created_rss_url).and_return(:expected)
        obj.send(meth, params).should == :expected
      end
    end
  end

  describe "#get_search_page_media" do
    let(:meth) { :get_search_page_media }
    context "when given page" do
      let(:page) { mock(Symbol) }
      it "should return page.videos" do
        page.should_receive(:videos).and_return(:expected)
        obj.send(meth, page).should == :expected
      end
    end
  end

  describe "#get_stillframe_url" do
    let(:meth) { :get_stillframe_url }
    let(:mock_http) { mock(Symbol, :create_url => '') }
    before(:each) do obj.should_receive(:http).and_return(mock_http) end
    shared_examples_for "creates base stillframe URL" do
      it "should create the base stillframe URL" do
        mock_http.should_receive(:create_url).with('videos/video_id/screenshots/').and_return('base_ss_URL')
        obj.send(meth, :video_id, params)
      end
    end
    context "when given video_id alone" do
      it "should create the base stillframe URL" do
        mock_http.should_receive(:create_url).with('videos/video_id/screenshots/').and_return('base_ss_URL')
        obj.send(meth, :video_id)
      end
      it "should return 'original.jpg'" do obj.send(meth, :video_id).should == 'original.jpg' end
    end
    context "when given video_id, {}" do
      let(:params) { {} }
      it_should_behave_like "creates base stillframe URL"
      it "should return 'original.jpg'" do obj.send(meth, :video_id, params).should == 'original.jpg' end
    end
    context "when given video_id, { :width => :the_w }}" do
      let(:params) { { :width => :the_w } }
      it_should_behave_like "creates base stillframe URL"
      it "should return 'the_ww.jpg'" do obj.send(meth, :video_id, params).should == 'the_ww.jpg' end
    end
    context "when given video_id, { 'width' => :the_w }}" do
      let(:params) { { 'width' => :the_w } }
      it_should_behave_like "creates base stillframe URL"
      it "should return 'the_ww.jpg'" do obj.send(meth, :video_id, params).should == 'the_ww.jpg' end
    end
    context "when given video_id, { :height => :the_h }}" do
      let(:params) { { :height => :the_h } }
      it_should_behave_like "creates base stillframe URL"
      it "should return 'the_hh.jpg'" do obj.send(meth, :video_id, params).should == 'the_hh.jpg' end
    end
    context "when given video_id, { 'height' => :the_h }}" do
      let(:params) { { 'height' => :the_h } }
      it_should_behave_like "creates base stillframe URL"
      it "should return 'the_hh.jpg'" do obj.send(meth, :video_id, params).should == 'the_hh.jpg' end
    end
    context "when given video_id, { :height => :the_h, :width => :the_w }}" do
      let(:params) { { :height => :the_h, :width => :the_w } }
      it_should_behave_like "creates base stillframe URL"
      it "should return 'the_wwthe_hh.jpg'" do obj.send(meth, :video_id, params).should == 'the_wwthe_hh.jpg' end
    end
    context "when given video_id, { :height => :the_h, 'width' => :the_w }}" do
      let(:params) { { :height => :the_h, 'width' => :the_w } }
      it_should_behave_like "creates base stillframe URL"
      it "should return 'the_wwthe_hh.jpg'" do obj.send(meth, :video_id, params).should == 'the_wwthe_hh.jpg' end
    end
    context "when given video_id, { 'height' => :the_h, :width => :the_w }}" do
      let(:params) { { 'height' => :the_h, :width => :the_w } }
      it_should_behave_like "creates base stillframe URL"
      it "should return 'the_wwthe_hh.jpg'" do obj.send(meth, :video_id, params).should == 'the_wwthe_hh.jpg' end
    end
    context "when given video_id, { 'height' => :the_h, 'width' => :the_w }}" do
      let(:params) { { 'height' => :the_h, 'width' => :the_w } }
      it_should_behave_like "creates base stillframe URL"
      it "should return 'the_wwthe_hh.jpg'" do obj.send(meth, :video_id, params).should == 'the_wwthe_hh.jpg' end
    end
  end

  describe "#get_video_metadata" do
    let(:meth) { :get_video_metadata }
    let(:video_id)      { :the_vid_id }
    let(:format)        { :the_format }
    let(:options)       { :the_opts }
    let(:modified_opts) { mock(Symbol) }
    before(:each) do
      obj.stub!(:add_view_auth_param).and_return(modified_opts)
      obj.stub!(:structured_data_request)
      modified_opts.stub!(:merge).and_return(modified_opts)
    end
    context "when given video_id, format, options" do
      it "should add_view_auth_param to options" do
        obj.should_receive(:add_view_auth_param).and_return(modified_opts)
        modified_opts.should_receive(:merge).with(options)
        obj.send(meth, video_id, format, options)
      end
      it "should call structured_data_request('videos/the_vid_id', params, format)" do
        obj.should_receive(:structured_data_request).with('videos/the_vid_id', modified_opts, format).and_return([])
        obj.send(meth, video_id, format, options)
      end
    end
    context "when given video_id, format" do
      it "should add_view_auth_param to {}" do
        obj.should_receive(:add_view_auth_param).and_return(modified_opts)
        modified_opts.should_receive(:merge).with({})
        obj.send(meth, video_id, format)
      end
      it "should call structured_data_request('videos/the_vid_id', params, format)" do
        obj.should_receive(:structured_data_request).with('videos/the_vid_id', modified_opts, format).and_return([])
        obj.send(meth, video_id, format)
      end
    end
    context "when given video_id" do
      it "should add_view_auth_param to {}" do
        obj.should_receive(:add_view_auth_param).and_return(modified_opts)
        modified_opts.should_receive(:merge).with({})
        obj.send(meth, video_id)
      end
      it "should call structured_data_request('videos/the_vid_id', params, nil)" do
        obj.should_receive(:structured_data_request).with('videos/the_vid_id', modified_opts, nil).and_return([])
        obj.send(meth, video_id)
      end
    end
  end

  describe "#get_videos_with_tag" do
    let(:meth) { :get_videos_with_tag }
    let(:tag)  { :the_tag }
    let(:params) { :the_params }
    let(:format) { :the_format }
    context "when given tag, params, format" do
      it "should return get_media_with_tag('videos', tag, params, format)" do
        obj.should_receive(:get_media_with_tag).with('videos', tag, params, format).and_return(:expected)
        obj.send(meth, tag, params, format)
      end
    end
    context "when given tag, params" do
      it "should return get_media_with_tag('videos', tag, params, nil)" do
        obj.should_receive(:get_media_with_tag).with('videos', tag, params, nil).and_return(:expected)
        obj.send(meth, tag, params)
      end
    end
    context "when given tag" do
      it "should return get_media_with_tag('videos', tag, {}, nil)" do
        obj.should_receive(:get_media_with_tag).with('videos', tag, {}, nil).and_return(:expected)
        obj.send(meth, tag)
      end
    end
  end

  describe "#import_videos_from_entries" do
    let(:meth)        { :import_videos_from_entries }
    let(:xml)         { :the_xml }
    let(:entries)     { :the_entries }
    let(:contributor) { :the_contributor }
    let(:params)      { :the_params }
    context "when given entries, contributor, params" do
      it "should call create_video_import_xml_from_hashes(entries)" do
        obj.should_receive(:create_video_import_xml_from_hashes).with(entries).and_return(xml)
        obj.stub!(:import_videos_from_xml_string)
        obj.send(meth, entries, contributor, params)
      end
      it "should import_videos_from_xml_string(xml, contributor, params)" do
        obj.stub!(:create_video_import_xml_from_hashes).with(entries).and_return(xml)
        obj.should_receive(:import_videos_from_xml_string).with(xml, contributor, params)
        obj.send(meth, entries, contributor, params)
      end
    end
    context "when given entries, contributor" do
      it "should call create_video_import_xml_from_hashes(entries)" do
        obj.should_receive(:create_video_import_xml_from_hashes).with(entries).and_return(xml)
        obj.stub!(:import_videos_from_xml_string)
        obj.send(meth, entries, contributor)
      end
      it "should import_videos_from_xml_string(xml, contributor, {})" do
        obj.stub!(:create_video_import_xml_from_hashes).with(entries).and_return(xml)
        obj.should_receive(:import_videos_from_xml_string).with(xml, contributor, {})
        obj.send(meth, entries, contributor)
      end
    end
  end

  describe "#import_videos_from_xml_file" do
    let(:meth)        { :import_videos_from_xml_file }
    let(:xml)         { :the_xml }
    let(:path)        { :the_path }
    let(:contributor) { :the_contributor }
    let(:params)      { :the_params }
    context "when given path, contributor, params" do
      it "should call import_videos_from_xml_string(File.read(path), contributor, params)" do
        File.should_receive(:read).with(path).and_return(xml)
        obj.should_receive(:import_videos_from_xml_string).with(xml, contributor, params)
        obj.send(meth, path, contributor, params)
      end
    end
    context "when given path, contributor" do
      it "should call import_videos_from_xml_string(File.read(path), contributor, {})" do
        File.should_receive(:read).with(path).and_return(xml)
        obj.should_receive(:import_videos_from_xml_string).with(xml, contributor, {})
        obj.send(meth, path, contributor)
      end
    end
  end

  describe "#import_videos_from_xml_string" do
    let(:meth)        { :import_videos_from_xml_string }
    let(:xml)         { :the_xml }
    let(:contributor) { :the_contributor }
    let(:params)      { :the_params }
    context "when given xml, contributor, params" do
      it "should call import_media_items_from_xml_string(:video, xml, contributor, params)" do
        obj.should_receive(:import_media_items_from_xml_string).with(:video, xml, contributor, params)
        obj.send(meth, xml, contributor, params)
      end
    end
    context "when given xml, contributor" do
      it "should call import_media_items_from_xml_string(:video, xml, contributor, {})" do
        obj.should_receive(:import_media_items_from_xml_string).with(:video, xml, contributor, {})
        obj.send(meth, xml, contributor)
      end
    end
  end

  describe "#media_api_result" do
    let(:meth) { :media_api_result }
    let(:exception_class) { RuntimeError }
    context "when given exception_class, &block" do
      context "and the block raises a MediaApiAuthenticationFailedException" do
        let(:block) { lambda { raise VideoApi::MediaApiAuthenticationFailedException.new } }
        it "should raise a VideoApiAuthenticationFailedException" do
          lambda { obj.send(meth, exception_class, &block) }.should raise_error(VideoApi::VideoApiAuthenticationFailedException)
        end
      end
      context "and the block raises a VideoApiException" do
        let(:block) { lambda { raise VideoApi::VideoApiException.new } }
        it "should raise a VideoApiException" do
          lambda { obj.send(meth, exception_class, &block) }.should raise_error(VideoApi::VideoApiException)
        end
      end
      context "and the block raises a MediaApiException" do
        let(:block) { lambda { raise VideoApi::MediaApiException.new } }
        it "should raise a VideoApiException" do
          lambda { obj.send(meth, exception_class, &block) }.should raise_error(VideoApi::VideoApiException)
        end
      end
    end
    context "when given just &block" do
      context "and the block raises a MediaApiAuthenticationFailedException" do
        let(:block) { lambda { raise VideoApi::MediaApiAuthenticationFailedException.new } }
        it "should raise a VideoApiAuthenticationFailedException" do
          lambda { obj.send(meth, &block) }.should raise_error(VideoApi::VideoApiAuthenticationFailedException)
        end
      end
      context "and the block raises a VideoApiException" do
        let(:block) { lambda { raise VideoApi::VideoApiException.new } }
        it "should raise a VideoApiException" do
          lambda { obj.send(meth, &block) }.should raise_error(VideoApi::VideoApiException)
        end
      end
      context "and the block raises a MediaApiException" do
        let(:block) { lambda { raise VideoApi::MediaApiException.new } }
        it "should raise a VideoApiException" do
          lambda { obj.send(meth, &block) }.should raise_error(VideoApi::VideoApiException)
        end
      end
    end
  end

  describe "#search_videos" do
    let(:meth) { :search_videos }
    let(:params) { :the_params }
    let(:format) { :the_format }
    context "when given params, format" do
      it "should call search_media(params, format)" do
        obj.should_receive(:search_media).with(params, format)
        obj.send(meth, params, format)
      end
    end
    context "when given params" do
      it "should call search_media(params, nil)" do
        obj.should_receive(:search_media).with(params, nil)
        obj.send(meth, params)
      end
    end
    context "when given neither params nor format" do
      it "should call search_media({}, nil)" do
        obj.should_receive(:search_media).with({}, nil)
        obj.send(meth)
      end
    end
  end

  describe "#search_videos_each" do
    let(:meth) { :search_videos_each }
    let(:params) { :the_params }
    let(:block)  { lambda { "I'm a block" } }
    context "when given params, &block" do
      it "should call search_media_each(params, &block)" do
        obj.should_receive(:search_media_each).with(params, &block)
        obj.send(meth, params, &block)
      end
    end
    context "when given params" do
      it "should call search_media_each(params)" do
        obj.should_receive(:search_media_each).with(params)
        obj.send(meth, params)
      end
    end
    context "when given &block" do
      it "should call search_media_each({}, &block)" do
        obj.should_receive(:search_media_each).with({}, &block)
        obj.send(meth, &block)
      end
    end
    context "when given neither params nor a&block" do
      it "should call search_media_each({})" do
        obj.should_receive(:search_media_each).with({})
        obj.send(meth)
      end
    end
  end

  describe "#search_videos_each_page" do
    let(:meth) { :search_videos_each_page }
    let(:params) { :the_params }
    let(:block)  { lambda { "I'm a block" } }
    context "when given params, &block" do
      it "should call search_media_each_page(params, &block)" do
        obj.should_receive(:search_media_each_page).with(params, &block)
        obj.send(meth, params, &block)
      end
    end
    context "when given params" do
      it "should call search_media_each_page(params)" do
        obj.should_receive(:search_media_each_page).with(params)
        obj.send(meth, params)
      end
    end
    context "when given &block" do
      it "should call search_media_each_page({}, &block)" do
        obj.should_receive(:search_media_each_page).with({}, &block)
        obj.send(meth, &block)
      end
    end
    context "when given neither params nor a&block" do
      it "should call search_media_each_page({})" do
        obj.should_receive(:search_media_each_page).with({})
        obj.send(meth)
      end
    end
  end

  describe "#set_video_visibility" do
    let(:meth)     { :set_video_visibility }
    let(:video_id) { :the_vid_id }
    context "when given video_id, visible" do
      context "and visible is truthy" do
        let(:visible) { :something_truthy }
        it "should perform update_video(video_id, { 'video[hidden]' => 'false' })" do
          obj.should_receive(:update_video).with(video_id, { 'video[hidden]' => 'false' })
          obj.send(meth, video_id, visible)
        end
      end
      [ nil, false ].each do |falsey_visible|
        context "and visible is #{falsey_visible.inspect}" do
          it "should perform update_video(video_id, { 'video[hidden]' => 'true' })" do
            obj.should_receive(:update_video).with(video_id, { 'video[hidden]' => 'true' })
            obj.send(meth, video_id, falsey_visible)
          end
        end
      end
    end
  end

  describe "#tag_media_type" do
    let(:meth) { :tag_media_type }
    it "should be 'videos'" do obj.send(meth).should == 'videos' end
  end

  describe "#undelete_video" do
    let(:meth)     { :undelete_video }
    let(:video_id) { :the_video_id }
    context "when given video_id" do
      it "should call update_video(video_id, {:deleted_at => ''})" do
        obj.should_receive(:update_video).with(video_id, {:deleted_at => ''})
        obj.send(meth, video_id)
      end
    end
  end

  describe "#update_video" do
    let(:meth)      { :update_video }
    let(:video_id)  { :the_vid_id }
    let(:params)    { :params }
    let(:mock_http) { mock(VideoApi::HttpClient, :put => nil) }
    context "when given video_id, params" do
      before(:each) do
        obj.stub!(:wrap_update_params).with(params, 'video').and_return(:the_wrapped_params)
        obj.stub!(:add_update_auth_param).and_return(:the_authed_params)
        obj.stub!(:http).and_return(mock_http)
      end
      it "should wrap_update_params(params, 'video')" do
        obj.should_receive(:wrap_update_params).with(params, 'video').and_return(:the_wrapped_params)
        obj.send(meth, video_id, params)
      end
      it "should add_update_auth_param(the_wrapped_params)" do
        obj.should_receive(:add_update_auth_param).with(:the_wrapped_params)
        obj.send(meth, video_id, params)
      end
      it 'should http.put("videos/#{video_id}", the_authed_params)' do
        mock_http.should_receive(:put).with("videos/the_vid_id", :the_authed_params).and_return(:expected)
        obj.send(meth, video_id, params).should == :expected
      end
    end
  end

end

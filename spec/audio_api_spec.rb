require File.expand_path('../spec_helper', __FILE__)
require 'audio_api'

describe VideoApi::AudioApi do
  let(:klass) { VideoApi::AudioApi }
  let(:obj) { klass.new({ 'base_url' => 'http://example.com', 'company_id' => 'CoID', 'license_key' => 'the_key' }) }

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
      it "should return create_search_media_sub_url('tracks', params, format)" do
        obj.should_receive(:create_search_media_sub_url).with('tracks', params, format).and_return(:expected)
        obj.send(meth, params, format).should == :expected
      end
    end
  end

  describe "#create_track_asset_from_entry" do
    let(:meth)     { :create_track_asset_from_entry }
    context "when given track_id, entry" do
      let(:track_id) { :the_track_id }
      let(:entry)    { :the_entry }
      it "should create_track_asset_from_xml_string(track_id, create_asset_xml_from_hash(entry))" do
        obj.should_receive(:create_asset_xml_from_hash).with(entry).and_return(:created_asset_xml)
        obj.should_receive(:create_track_asset_from_xml_string).with(track_id, :created_asset_xml)
        obj.send(meth, track_id, entry)
      end
    end
  end

  describe "#create_track_asset_from_xml_file" do
    let(:meth)     { :create_track_asset_from_xml_file }
    let(:xml)      { :the_xml }
    let(:path)     { :the_path }
    let(:track_id) { :the_track_id }
    context "when given track_id, path" do
      it "should File.read(path) -> xml" do
        File.should_receive(:read).with(path).and_return(xml)
        obj.stub!(:create_track_asset_from_xml_string).with(track_id, xml)
        obj.send(meth, track_id, path)
      end
      it "should create_track_asset_from_xml_string(track_id, xml)" do
        File.stub!(:read).with(path).and_return(xml)
        obj.should_receive(:create_track_asset_from_xml_string).with(track_id, xml)
        obj.send(meth, track_id, path)
      end
    end
  end

  describe "#create_track_asset_from_xml_string" do
    let(:meth)      { :create_track_asset_from_xml_string }
    let(:xml)       { :the_xml }
    let(:track_id)  { :the_track_id }
    let(:mock_http) { mock(Symbol) }
    before(:each) do
      obj.stub!(:add_update_auth_param).and_return(:authed_params)
      obj.stub!(:http).and_return(mock_http)
      mock_http.stub!(:post)
    end
    context "when given track_id, xml" do
      it "should access its http object" do
        obj.should_receive(:http).and_return(mock_http)
        obj.send(meth, track_id, xml)
      end
      it "should add_update_auth_param" do
        obj.should_receive(:add_update_auth_param).and_return(:authed_params)
        obj.send(meth, track_id, xml)
      end
      it 'should http.post(("tracks/#{track_id}/assets.xml", authed_params, xml, "text/xml")' do
        mock_http.should_receive(:post).with("tracks/#{track_id}/assets.xml", :authed_params, xml, 'text/xml')
        obj.send(meth, track_id, xml)
      end
    end
  end

  describe "#create_track_import_xml_from_hashes" do
    let(:meth)      { :create_track_import_xml_from_hashes }
    let(:entries)   { (0..3).to_a }
    let(:track_id)  { :the_track_id }
    let(:mock_http) { mock(Symbol) }
    context "when entries" do
      it "should map create_xml_from_value onto entries and embed in an XML wrapper" do
        def obj.create_xml_from_value(opts); opts[:entry]; end
        entries_xml = entries.map { |e| obj.create_xml_from_value({ :entry => e}) }
        obj.send(meth, entries).should == %Q[<?xml version="1.0" encoding="UTF-8"?><add><list>#{entries_xml.join("\n")}</list></add>]
      end
    end
  end

  describe "#create_track_asset_from_entry" do
    let(:meth) { :create_track_asset_from_entry }
    context "when given track_id, entry" do
      let(:track_id) { mock(Symbol) }
      let(:entry) { mock(Symbol) }
      it "should create_asset_xml_from_hash(entry)" do
        obj.should_receive(:create_asset_xml_from_hash).with(entry)
        obj.stub!(:create_track_asset_from_xml_string)
        obj.send(meth, track_id, entry)
      end
      it "should create_track_asset_from_xml_string(track_id, the_created_xml)" do
        obj.stub!(:create_asset_xml_from_hash).with(entry).and_return(:the_created_xml)
        obj.should_receive(:create_track_asset_from_xml_string).with(track_id, :the_created_xml)
        obj.send(meth, track_id, entry)
      end
    end
  end

  describe "#delete_asset" do
    let(:meth) { :delete_asset }
    context "when given asset_id, media_item_id" do
      let(:asset_id)      { :the_asset_id }
      let(:media_item_id) { :the_media_item_id }
      let(:mock_http) { mock(Symbol) }
      it 'should call http.delete("tracks/#{media_item_id}/assets/#{asset_id}", add_update_auth_param())' do
        obj.should_receive(:add_update_auth_param).and_return(:auth_params)
        obj.should_receive(:http).and_return(mock_http)
        mock_http.should_receive(:delete).with("tracks/#{media_item_id}/assets/#{asset_id}", :auth_params)
        obj.send(meth, asset_id, media_item_id)
      end
    end
  end

  describe "#delete_track" do
    let(:meth) { :delete_track }
    context "when given track_id" do
      let(:track_id)  { :the_track_id }
      let(:mock_http) { mock(Symbol) }
      it 'should call http.delete("tracks/#{track_id}", add_update_auth_param())' do
        obj.should_receive(:add_update_auth_param).and_return(:auth_params)
        obj.should_receive(:http).and_return(mock_http)
        mock_http.should_receive(:delete).with("tracks/#{track_id}", :auth_params)
        obj.send(meth, track_id)
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
      it 'should return structured_data_request("#{create_account_library_url}/statistics/track_delivery", modified_params, format' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/track_delivery", :modified_params, format)
        obj.send(meth, params, format)
      end
    end
    context "when given params" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, params)
      end
      it 'should return structured_data_request("#{create_account_library_url}/statistics/track_delivery", modified_params, nil' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/track_delivery", :modified_params, nil)
        obj.send(meth, params)
      end
    end
  end

### This does not yet exist. Add it?
=begin
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
=end

### This does not yet exist. Add it?
=begin
  describe "#get_delivery_stats_for_track" do
    let(:meth)     { :get_delivery_stats_for_track }
    let(:track_id) { :the_vid_id }
    let(:params)   { :the_params }
    let(:format)   { :the_format }
    before(:each) do
      obj.stub!(:add_view_auth_param).and_return(:modified_params)
      obj.stub!(:structured_data_request)
    end
    context "when given track_id, params, format" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, track_id, params, format)
      end
      it 'should return structured_data_request("tracks/the_vid_id/statistics", modified_params, format' do
        obj.should_receive(:structured_data_request).with("tracks/the_vid_id/statistics", :modified_params, format)
        obj.send(meth, track_id, params, format)
      end
    end
    context "when given track_id, params" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, track_id, params)
      end
      it 'should return structured_data_request("tracks/the_vid_id/statistics", modified_params, nil' do
        obj.should_receive(:structured_data_request).with("tracks/the_vid_id/statistics", :modified_params, nil)
        obj.send(meth, track_id, params)
      end
    end
  end
=end

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
      it 'should return structured_data_request("#{create_account_library_url}/statistics/track_ingest", modified_params, format' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/track_ingest", :modified_params, format)
        obj.send(meth, params, format)
      end
    end
    context "when given params" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, params)
      end
      it 'should return structured_data_request("#{create_account_library_url}/statistics/track_ingest", modified_params, nil' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/track_ingest", :modified_params, nil)
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
      it 'should return structured_data_request("#{create_account_library_url}/statistics/track_publish/disk_usage", modified_params, format' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/track_publish/disk_usage", :modified_params, format)
        obj.send(meth, params, format)
      end
    end
    context "when given params" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, params)
      end
      it 'should return structured_data_request("#{create_account_library_url}/statistics/track_publish/disk_usage", modified_params, nil' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/track_publish/disk_usage", :modified_params, nil)
        obj.send(meth, params)
      end
    end
  end

  describe "#get_search_page_media" do
    let(:meth) { :get_search_page_media }
    context "when given page" do
      let(:page) { mock(Symbol) }
      it "should return page.tracks" do
        page.should_receive(:tracks).and_return(:expected)
        obj.send(meth, page).should == :expected
      end
    end
  end

  describe "#get_stats_for_track" do
    let(:meth)     { :get_stats_for_track }
    let(:track_id) { :the_track_id }
    let(:params)   { :the_params }
    let(:format)   { :the_format }
    before(:each) do
      obj.stub!(:add_view_auth_param).and_return(:modified_params)
      obj.stub!(:structured_data_request)
    end
    context "when given track_id, params, format" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, track_id, params, format)
      end
      it 'should return structured_data_request("tracks/#{track_id}/statistics", modified_params, format' do
        obj.should_receive(:structured_data_request).with("tracks/#{track_id}/statistics", :modified_params, format)
        obj.send(meth, track_id, params, format)
      end
    end
    context "when given params" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, track_id, params)
      end
      it 'should return structured_data_request("tracks/#{track_id}/statistics", modified_params, nil' do
        obj.should_receive(:structured_data_request).with("tracks/#{track_id}/statistics", :modified_params, nil)
        obj.send(meth, track_id, params)
      end
    end
  end

  describe "#get_track_metadata" do
    let(:meth) { :get_track_metadata }
    let(:track_id)      { :the_track_id }
    let(:format)        { :the_format }
    let(:options)       { :the_opts }
    let(:modified_opts) { mock(Symbol) }
    before(:each) do
      obj.stub!(:add_view_auth_param).and_return(modified_opts)
      obj.stub!(:structured_data_request)
      modified_opts.stub!(:merge).and_return(modified_opts)
    end
    context "when given track_id, format, options" do
      it "should add_view_auth_param to options" do
        obj.should_receive(:add_view_auth_param).and_return(modified_opts)
        modified_opts.should_receive(:merge).with(options)
        obj.send(meth, track_id, format, options)
      end
      it "should call structured_data_request('tracks/the_track_id', params, format)" do
        obj.should_receive(:structured_data_request).with('tracks/the_track_id', modified_opts, format).and_return([])
        obj.send(meth, track_id, format, options)
      end
    end
    context "when given track_id, format" do
      it "should add_view_auth_param to {}" do
        obj.should_receive(:add_view_auth_param).and_return(modified_opts)
        modified_opts.should_receive(:merge).with({})
        obj.send(meth, track_id, format)
      end
      it "should call structured_data_request('tracks/the_track_id', params, format)" do
        obj.should_receive(:structured_data_request).with('tracks/the_track_id', modified_opts, format).and_return([])
        obj.send(meth, track_id, format)
      end
    end
    context "when given track_id" do
      it "should add_view_auth_param to {}" do
        obj.should_receive(:add_view_auth_param).and_return(modified_opts)
        modified_opts.should_receive(:merge).with({})
        obj.send(meth, track_id)
      end
      it "should call structured_data_request('tracks/the_track_id', params, nil)" do
        obj.should_receive(:structured_data_request).with('tracks/the_track_id', modified_opts, nil).and_return([])
        obj.send(meth, track_id)
      end
    end
  end

  describe "#get_tracks_rss_url" do
    let(:meth)      { :get_tracks_rss_url }
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

  describe "#get_tracks_with_tag" do
    let(:meth) { :get_tracks_with_tag }
    let(:tag)  { :the_tag }
    let(:params) { :the_params }
    let(:format) { :the_format }
    context "when given tag, params, format" do
      it "should return get_media_with_tag('tracks', tag, params, format)" do
        obj.should_receive(:get_media_with_tag).with('tracks', tag, params, format).and_return(:expected)
        obj.send(meth, tag, params, format)
      end
    end
    context "when given tag, params" do
      it "should return get_media_with_tag('tracks', tag, params, nil)" do
        obj.should_receive(:get_media_with_tag).with('tracks', tag, params, nil).and_return(:expected)
        obj.send(meth, tag, params)
      end
    end
    context "when given tag" do
      it "should return get_media_with_tag('tracks', tag, {}, nil)" do
        obj.should_receive(:get_media_with_tag).with('tracks', tag, {}, nil).and_return(:expected)
        obj.send(meth, tag)
      end
    end
  end

  describe "#import_tracks_from_entries" do
    let(:meth)        { :import_tracks_from_entries }
    let(:xml)         { :the_xml }
    let(:entries)     { :the_entries }
    let(:contributor) { :the_contributor }
    let(:params)      { :the_params }
    context "when given entries, contributor, params" do
      it "should call create_track_import_xml_from_hashes(entries)" do
        obj.should_receive(:create_track_import_xml_from_hashes).with(entries).and_return(xml)
        obj.stub!(:import_tracks_from_xml_string)
        obj.send(meth, entries, contributor, params)
      end
      it "should import_tracks_from_xml_string(xml, contributor, params)" do
        obj.stub!(:create_track_import_xml_from_hashes).with(entries).and_return(xml)
        obj.should_receive(:import_tracks_from_xml_string).with(xml, contributor, params)
        obj.send(meth, entries, contributor, params)
      end
    end
    context "when given entries, contributor" do
      it "should call create_track_import_xml_from_hashes(entries)" do
        obj.should_receive(:create_track_import_xml_from_hashes).with(entries).and_return(xml)
        obj.stub!(:import_tracks_from_xml_string)
        obj.send(meth, entries, contributor)
      end
      it "should import_tracks_from_xml_string(xml, contributor, {})" do
        obj.stub!(:create_track_import_xml_from_hashes).with(entries).and_return(xml)
        obj.should_receive(:import_tracks_from_xml_string).with(xml, contributor, {})
        obj.send(meth, entries, contributor)
      end
    end
  end

  describe "#import_tracks_from_xml_file" do
    let(:meth)        { :import_tracks_from_xml_file }
    let(:xml)         { :the_xml }
    let(:path)        { :the_path }
    let(:contributor) { :the_contributor }
    let(:params)      { :the_params }
    context "when given path, contributor, params" do
      it "should call import_tracks_from_xml_string(File.read(path), contributor, params)" do
        File.should_receive(:read).with(path).and_return(xml)
        obj.should_receive(:import_tracks_from_xml_string).with(xml, contributor, params)
        obj.send(meth, path, contributor, params)
      end
    end
    context "when given xml, contributor" do
      it "should call import_tracks_from_xml_string(File.read(path), contributor, {})" do
        File.should_receive(:read).with(path).and_return(xml)
        obj.should_receive(:import_tracks_from_xml_string).with(xml, contributor, {})
        obj.send(meth, path, contributor)
      end
    end
  end

  describe "#import_tracks_from_xml_string" do
    let(:meth)        { :import_tracks_from_xml_string }
    let(:xml)         { :the_xml }
    let(:contributor) { :the_contributor }
    let(:params)      { :the_params }
    context "when given xml, contributor, params" do
      it "should call import_media_items_from_xml_string(:track, xml, contributor, params)" do
        obj.should_receive(:import_media_items_from_xml_string).with(:track, xml, contributor, params)
        obj.send(meth, xml, contributor, params)
      end
    end
    context "when given xml, contributor" do
      it "should call import_media_items_from_xml_string(:track, xml, contributor, {})" do
        obj.should_receive(:import_media_items_from_xml_string).with(:track, xml, contributor, {})
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
        it "should raise an AudioApiAuthenticationFailedException" do
          lambda { obj.send(meth, exception_class, &block) }.should raise_error(VideoApi::AudioApiAuthenticationFailedException)
        end
      end
      context "and the block raises an AudioApiException" do
        let(:block) { lambda { raise VideoApi::AudioApiException.new } }
        it "should raise an AudioApiException" do
          lambda { obj.send(meth, exception_class, &block) }.should raise_error(VideoApi::AudioApiException)
        end
      end
      context "and the block raises a MediaApiException" do
        let(:block) { lambda { raise VideoApi::MediaApiException.new } }
        it "should raise a AudioApiException" do
          lambda { obj.send(meth, exception_class, &block) }.should raise_error(VideoApi::AudioApiException)
        end
      end
    end
    context "when given just &block" do
      context "and the block raises a MediaApiAuthenticationFailedException" do
        let(:block) { lambda { raise VideoApi::MediaApiAuthenticationFailedException.new } }
        it "should raise an AudioApiAuthenticationFailedException" do
          lambda { obj.send(meth, &block) }.should raise_error(VideoApi::AudioApiAuthenticationFailedException)
        end
      end
      context "and the block raises an AudioApiException" do
        let(:block) { lambda { raise VideoApi::AudioApiException.new } }
        it "should raise an AudioApiException" do
          lambda { obj.send(meth, &block) }.should raise_error(VideoApi::AudioApiException)
        end
      end
      context "and the block raises a MediaApiException" do
        let(:block) { lambda { raise VideoApi::MediaApiException.new } }
        it "should raise an AudioApiException" do
          lambda { obj.send(meth, &block) }.should raise_error(VideoApi::AudioApiException)
        end
      end
    end
  end

  describe "#search_tracks" do
    let(:meth) { :search_tracks }
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

  describe "#search_tracks_each" do
    let(:meth) { :search_tracks_each }
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

  describe "#search_tracks_each_page" do
    let(:meth) { :search_tracks_each_page }
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

  describe "#set_track_visibility" do
    let(:meth)     { :set_track_visibility }
    let(:track_id) { :the_track_id }
    context "when given track_id, visible" do
      context "and visible is truthy" do
        let(:visible) { :something_truthy }
        it "should perform update_track(track_id, { 'track[hidden]' => 'false' })" do
          obj.should_receive(:update_track).with(track_id, { 'track[hidden]' => 'false' })
          obj.send(meth, track_id, visible)
        end
      end
      [ nil, false ].each do |falsey_visible|
        context "and visible is #{falsey_visible.inspect}" do
          it "should perform update_track(track_id, { 'track[hidden]' => 'true' })" do
            obj.should_receive(:update_track).with(track_id, { 'track[hidden]' => 'true' })
            obj.send(meth, track_id, falsey_visible)
          end
        end
      end
    end
  end

  describe "#tag_media_type" do
    let(:meth) { :tag_media_type }
    it "should be 'tracks'" do obj.send(meth).should == 'tracks' end
  end

  describe "#undelete_track" do
    let(:meth)     { :undelete_track }
    let(:track_id) { :the_track_id }
    context "when given track_id" do
      it "should call update_track(track_id, {:deleted_at => ''})" do
        obj.should_receive(:update_track).with(track_id, {:deleted_at => ''})
        obj.send(meth, track_id)
      end
    end
  end

  describe "#update_track" do
    let(:meth) { :update_track }
    let(:track_id)  { :the_track_id }
    let(:params)    { :params }
    let(:mock_http) { mock(VideoApi::HttpClient, :put => nil) }
    context "when given track_id, params" do
      before(:each) do
        obj.stub!(:wrap_update_params).with(params, 'track').and_return(:the_wrapped_params)
        obj.stub!(:add_update_auth_param).and_return(:the_authed_params)
        obj.stub!(:http).and_return(mock_http)
      end
      it "should wrap_update_params(params, 'track')" do
        obj.should_receive(:wrap_update_params).with(params, 'track').and_return(:the_wrapped_params)
        obj.send(meth, track_id, params)
      end
      it "should add_update_auth_param(the_wrapped_params)" do
        obj.should_receive(:add_update_auth_param).with(:the_wrapped_params)
        obj.send(meth, track_id, params)
      end
      it 'should http.put("tracks/#{track_id}", the_authed_params)' do
        mock_http.should_receive(:put).with("tracks/the_track_id", :the_authed_params).and_return(:expected)
        obj.send(meth, track_id, params).should == :expected
      end
    end
  end

  describe "#upload_track" do
    let(:meth)        { :upload_track }
    let(:filename)    { :the_filename }
    let(:contributor) { :contributor }
    let(:params)      { { :key1 => :value1, :key2 => :value2 } }
    let(:progress_listener) { lambda { "I'm the progress listener" } }
    context "when given filename, contributor, params, &progress_listener" do
      it "should upload_media(filename, contributor, params, &progress_listener)" do
        obj.should_receive(:upload_media).with(filename, contributor, params, &progress_listener)
        obj.send(meth, filename, contributor, params, &progress_listener)
      end
    end
    context "when given filename, contributor, params" do
      it "should upload_media(filename, contributor, params, &progress_listener)" do
        obj.should_receive(:upload_media).with(filename, contributor, params, &progress_listener)
        obj.send(meth, filename, contributor, params)
      end
    end
    context "when given filename, contributor, &progress_listener" do
      it "should upload_media(filename, contributor, {}, &progress_listener)" do
        obj.should_receive(:upload_media).with(filename, contributor, {}, &progress_listener)
        obj.send(meth, filename, contributor, &progress_listener)
      end
    end
    context "when given filename, contributor" do
      it "should upload_media(filename, contributor, {})" do
        obj.should_receive(:upload_media).with(filename, contributor, {})
        obj.send(meth, filename, contributor)
      end
    end
  end
end

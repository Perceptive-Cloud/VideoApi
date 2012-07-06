require File.expand_path('../spec_helper', __FILE__)
require 'image_api'

describe VideoApi::ImageApi do
  let(:klass) { VideoApi::ImageApi }
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
      it "should return create_search_media_sub_url('images', params, format)" do
        obj.should_receive(:create_search_media_sub_url).with('images', params, format).and_return(:expected)
        obj.send(meth, params, format).should == :expected
      end
    end
  end

  describe "#delete_image" do
    let(:meth) { :delete_image }
    let(:image_id)  { :the_image_id }
    let(:mock_http) { mock(VideoApi::HttpClient) }
    context "when given image_id" do
      it 'should http.delete("images/#{image_id}", add_update_auth_param)' do
        obj.should_receive(:http).and_return(mock_http)
        obj.should_receive(:add_update_auth_param).and_return(:the_authed_params)
        mock_http.should_receive(:delete).with("images/the_image_id", :the_authed_params).and_return(:expected)
        obj.send(meth, image_id).should == :expected
      end
    end
  end

  describe "#delete_many_images" do
    let(:meth) { :delete_many_images }
    let(:image_ids) { [:image_id1, :image_id2] }
    let(:mock_http) { mock(VideoApi::HttpClient) }
    before(:each) do
      obj.stub!(:authenticate_for_update).and_return(:the_sig)
    end
    context "when given image_ids" do
      it "should authenticate_for_update -> signature" do
        obj.should_receive(:authenticate_for_update).and_return(:the_sig)
        obj.send(meth, image_ids)
      end
      it "should image_api_result" do
        obj.should_receive(:image_api_result)
        obj.send(meth, image_ids)
      end
      the_params = {:delete=>{:image_id=>"image_id1,image_id2"}, :image_id=>:image_id1, :signature=>:the_sig}
      it %Q[should http.post("images/delete_many", #{the_params.inspect})] do
        obj.should_receive(:http).and_return(mock_http)
        mock_http.should_receive(:post).with("images/delete_many", the_params).and_return(:expected)
        obj.send(meth, image_ids).should == :expected
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
      it 'should return structured_data_request("#{create_account_library_url}/statistics/image_delivery", modified_params, format' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/image_delivery", :modified_params, format)
        obj.send(meth, params, format)
      end
    end
    context "when given params" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, params)
      end
      it 'should return structured_data_request("#{create_account_library_url}/statistics/image_delivery", modified_params, nil' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/image_delivery", :modified_params, nil)
        obj.send(meth, params)
      end
    end
  end

  describe "#get_image_metadata" do
    let(:meth) { :get_image_metadata }
    let(:image_id)      { :the_image_id }
    let(:format)        { :the_format }
    let(:authed_params) { mock(Symbol) }
    before(:each) do
      obj.stub!(:add_view_auth_param).and_return(authed_params)
      obj.stub!(:structured_data_request)
    end
    context "when given image_id, format" do
      it "should add_view_auth_param" do
        obj.should_receive(:add_view_auth_param).and_return(authed_params)
        obj.send(meth, image_id, format)
      end
      it "should call structured_data_request('images/the_image_id', params, format)" do
        obj.should_receive(:structured_data_request).with('images/the_image_id', authed_params, format).and_return([])
        obj.send(meth, image_id, format)
      end
    end
    context "when given image_id" do
      it "should add_view_auth_param" do
        obj.should_receive(:add_view_auth_param).and_return(authed_params)
        obj.send(meth, image_id)
      end
      it "should call structured_data_request('images/the_image_id', params, nil)" do
        obj.should_receive(:structured_data_request).with('images/the_image_id', authed_params, nil).and_return([])
        obj.send(meth, image_id)
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
      it 'should return structured_data_request("#{create_account_library_url}/statistics/image_ingest", modified_params, format' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/image_ingest", :modified_params, format)
        obj.send(meth, params, format)
      end
    end
    context "when given params" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, params)
      end
      it 'should return structured_data_request("#{create_account_library_url}/statistics/image_ingest", modified_params, nil' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/image_ingest", :modified_params, nil)
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
      it 'should return structured_data_request("#{create_account_library_url}/statistics/image_publish/disk_usage", modified_params, format' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/image_publish/disk_usage", :modified_params, format)
        obj.send(meth, params, format)
      end
    end
    context "when given params" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, params)
      end
      it 'should return structured_data_request("#{create_account_library_url}/statistics/image_publish/disk_usage", modified_params, nil' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/statistics/image_publish/disk_usage", :modified_params, nil)
        obj.send(meth, params)
      end
    end
  end

  describe "#get_images_rss_url" do
    let(:meth)      { :get_images_rss_url }
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

  describe "#get_images_with_tag" do
    let(:meth) { :get_images_with_tag }
    let(:tag)  { :the_tag }
    let(:params) { :the_params }
    let(:format) { :the_format }
    context "when given tag, params, format" do
      it "should return get_media_with_tag('images', tag, params, format)" do
        obj.should_receive(:get_media_with_tag).with('images', tag, params, format).and_return(:expected)
        obj.send(meth, tag, params, format)
      end
    end
    context "when given tag, params" do
      it "should return get_media_with_tag('images', tag, params, nil)" do
        obj.should_receive(:get_media_with_tag).with('images', tag, params, nil).and_return(:expected)
        obj.send(meth, tag, params)
      end
    end
    context "when given tag" do
      it "should return get_media_with_tag('images', tag, {}, nil)" do
        obj.should_receive(:get_media_with_tag).with('images', tag, {}, nil).and_return(:expected)
        obj.send(meth, tag)
      end
    end
  end

  describe "#get_search_page_media" do
    let(:meth) { :get_search_page_media }
    context "when given page" do
      let(:page) { mock(Symbol) }
      it "should return page.images" do
        page.should_receive(:images).and_return(:expected)
        obj.send(meth, page).should == :expected
      end
    end
  end

  describe "#get_stats_for_image" do
    let(:meth)     { :get_stats_for_image }
    let(:image_id) { :the_image_id }
    let(:params)   { :the_params }
    let(:format)   { :the_format }
    before(:each) do
      obj.stub!(:add_view_auth_param).and_return(:modified_params)
      obj.stub!(:structured_data_request)
    end
    context "when given image_id, params, format" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, image_id, params, format)
      end
      it 'should return structured_data_request("images/#{image_id}/statistics", modified_params, format' do
        obj.should_receive(:structured_data_request).with("images/#{image_id}/statistics", :modified_params, format)
        obj.send(meth, image_id, params, format)
      end
    end
    context "when given params" do
      it "should add_view_auth_param to params" do
        obj.should_receive(:add_view_auth_param).with(params).and_return(:modified_params)
        obj.send(meth, image_id, params)
      end
      it 'should return structured_data_request("images/#{image_id}/statistics", modified_params, nil' do
        obj.should_receive(:structured_data_request).with("images/#{image_id}/statistics", :modified_params, nil)
        obj.send(meth, image_id, params)
      end
    end
  end

  describe "#media_api_result" do
    let(:meth) { :media_api_result }
    let(:exception_class) { RuntimeError }
    context "when given exception_class, &block" do
      context "and the block raises a MediaApiAuthenticationFailedException" do
        let(:block) { lambda { raise VideoApi::MediaApiAuthenticationFailedException.new } }
        it "should raise an ImageApiAuthenticationFailedException" do
          lambda { obj.send(meth, exception_class, &block) }.should raise_error(VideoApi::ImageApiAuthenticationFailedException)
        end
      end
      context "and the block raises an ImageApiException" do
        let(:block) { lambda { raise VideoApi::ImageApiException.new } }
        it "should raise an ImageApiException" do
          lambda { obj.send(meth, exception_class, &block) }.should raise_error(VideoApi::ImageApiException)
        end
      end
      context "and the block raises a MediaApiException" do
        let(:block) { lambda { raise VideoApi::MediaApiException.new } }
        it "should raise an ImageApiException" do
          lambda { obj.send(meth, exception_class, &block) }.should raise_error(VideoApi::ImageApiException)
        end
      end
    end
    context "when given just &block" do
      context "and the block raises a MediaApiAuthenticationFailedException" do
        let(:block) { lambda { raise VideoApi::MediaApiAuthenticationFailedException.new } }
        it "should raise an ImageApiAuthenticationFailedException" do
          lambda { obj.send(meth, &block) }.should raise_error(VideoApi::ImageApiAuthenticationFailedException)
        end
      end
      context "and the block raises an ImageApiException" do
        let(:block) { lambda { raise VideoApi::ImageApiException.new } }
        it "should raise an ImageApiException" do
          lambda { obj.send(meth, &block) }.should raise_error(VideoApi::ImageApiException)
        end
      end
      context "and the block raises a MediaApiException" do
        let(:block) { lambda { raise VideoApi::MediaApiException.new } }
        it "should raise an ImageApiException" do
          lambda { obj.send(meth, &block) }.should raise_error(VideoApi::ImageApiException)
        end
      end
    end
  end

  describe "#search_images" do
    let(:meth) { :search_images }
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

  describe "#search_images_each" do
    let(:meth) { :search_images_each }
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

  describe "#search_images_each_page" do
    let(:meth) { :search_images_each_page }
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

  describe "#tag_media_type" do
    let(:meth) { :tag_media_type }
    it "should be 'images'" do obj.send(meth).should == 'images' end
  end

  describe "#undelete_image" do
    let(:meth)     { :undelete_image }
    let(:image_id) { :the_image_id }
    context "when given image_id" do
      it "should call update_image(image_id, {:deleted_at => ''})" do
        obj.should_receive(:update_image).with(image_id, {:deleted_at => ''})
        obj.send(meth, image_id)
      end
    end
  end

  describe "#update_image" do
    let(:meth) { :update_image }
    let(:image_id)  { :the_image_id }
    let(:params)    { :params }
    let(:mock_http) { mock(VideoApi::HttpClient, :put => nil) }
    context "when given image_id, params" do
      before(:each) do
        obj.stub!(:wrap_update_params).with(params, 'image').and_return(:the_wrapped_params)
        obj.stub!(:add_update_auth_param).and_return(:the_authed_params)
        obj.stub!(:http).and_return(mock_http)
      end
      it "should wrap_update_params(params, 'image')" do
        obj.should_receive(:wrap_update_params).with(params, 'image').and_return(:the_wrapped_params)
        obj.send(meth, image_id, params)
      end
      it "should add_update_auth_param(the_wrapped_params)" do
        obj.should_receive(:add_update_auth_param).with(:the_wrapped_params)
        obj.send(meth, image_id, params)
      end
      it 'should http.put("images/#{image_id}", the_authed_params)' do
        mock_http.should_receive(:put).with("images/#{image_id}", :the_authed_params).and_return(:expected)
        obj.send(meth, image_id, params).should == :expected
      end
    end
    context "when given image_id, params, false" do
      before(:each) do
        obj.stub!(:wrap_update_params).with(params, 'image').and_return(:the_wrapped_params)
        obj.stub!(:add_update_auth_param).and_return(:the_authed_params)
        obj.stub!(:http).and_return(mock_http)
      end
      it "should wrap_update_params(params, 'image')" do
        obj.should_receive(:wrap_update_params).with(params, 'image').and_return(:the_wrapped_params)
        obj.send(meth, image_id, params, false)
      end
      it "should add_update_auth_param(the_wrapped_params)" do
        obj.should_receive(:add_update_auth_param).with(:the_wrapped_params)
        obj.send(meth, image_id, params, false)
      end
      it 'should http.put("images/#{image_id}", the_authed_params)' do
        mock_http.should_receive(:put).with("images/#{image_id}", :the_authed_params).and_return(:expected)
        obj.send(meth, image_id, params, false).should == :expected
      end
    end
    context "when given image_id, params, true" do
      before(:each) do
        obj.stub!(:add_update_auth_param).and_return(:the_authed_params)
        obj.stub!(:http).and_return(mock_http)
      end
      it "should NOT wrap_update_params(params, 'image')" do
        obj.should_not_receive(:wrap_update_params).with(params, 'image')
        obj.send(meth, image_id, params, true)
      end
      it "should add_update_auth_param(params)" do
        obj.should_receive(:add_update_auth_param).with(params)
        obj.send(meth, image_id, params, true)
      end
      it 'should http.put("images/#{image_id}", the_authed_params)' do
        mock_http.should_receive(:put).with("images/#{image_id}", :the_authed_params).and_return(:expected)
        obj.send(meth, image_id, params, true).should == :expected
      end
    end
  end

  describe "#upload_image" do
    let(:meth)       { :upload_image }
    let(:filename)   { :the_filename }
    let(:album_id)   { :the_album_id }
    let(:params)     { { :key1 => :value1, :key2 => :value2 } }
    let(:mock_uri)   { mock(Symbol, :host => 'the_host', :path => 'the_path', :port => 'the_port', :query => 'the_query') }
    let(:mock_http)  { mock(Symbol, :get => '', :post_multipart_file_upload => '') }
    let(:mock_close) { mock(Symbol, :strip => nil) }
    let(:progress_listener) { lambda { "I'm the progress listener" } }
    before(:each) do
      obj.stub!(:authenticate_for_update).and_return(:the_signature)
      obj.stub!(:base_url).and_return('base_url/')
      URI.stub!(:parse).and_return(mock_uri)
      VideoApi::HttpClient.stub!(:new).and_return(mock_http)
    end
    context "when given filename, album_id, params, &progress_listener" do
      it "should gather a signature from authenticate_for_update" do
        obj.should_receive(:authenticate_for_update)
        obj.send(meth, filename, album_id, params, &progress_listener)
      end
      it "should URI.parse an images URL with album_id & signature" do
        URI.should_receive(:parse).with("base_url/images?album_id=the_album_id&signature=the_signature")
        obj.send(meth, filename, album_id, params, &progress_listener)
      end
      it "should instantiate a new HttpClient with the host and port" do
      VideoApi::HttpClient.should_receive(:new).with('the_host', 'the_port').and_return(mock_http)
        obj.send(meth, filename, album_id, params, &progress_listener)
      end
      it "should post to the new HttpClient instance" do
        mock_http.should_receive(:post_multipart_file_upload).with('the_path?the_query', filename, {}, &progress_listener)
        obj.send(meth, filename, album_id, params, &progress_listener)
      end
    end
    context "when given filename, album_id, &progress_listener" do
      it "should gather a signature from authenticate_for_update" do
        obj.should_receive(:authenticate_for_update)
        obj.send(meth, filename, album_id, &progress_listener)
      end
      it "should URI.parse an images URL with album_id & signature" do
        URI.should_receive(:parse).with("base_url/images?album_id=the_album_id&signature=the_signature")
        obj.send(meth, filename, album_id, params, &progress_listener)
      end
      it "should instantiate a new HttpClient with the host and port" do
      VideoApi::HttpClient.should_receive(:new).with('the_host', 'the_port').and_return(mock_http)
        obj.send(meth, filename, album_id, &progress_listener)
      end
      it "should post to the new HttpClient instance" do
        mock_http.should_receive(:post_multipart_file_upload).with('the_path?the_query', filename, {}, &progress_listener)
        obj.send(meth, filename, album_id, &progress_listener)
      end
    end
  end
end

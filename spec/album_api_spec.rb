require File.expand_path('../spec_helper', __FILE__)
require 'album_api'

describe VideoApi::AlbumApi do
  let(:klass) { VideoApi::AlbumApi }
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

  describe "#create_album_from_hash" do
    let(:meth) { :create_album_from_hash }
    let(:company_id) { :the_co_id }
    let(:params)     { mock(Symbol) }
    let(:mock_auth)  { mock(Symbol) }
    let(:mock_http)  { mock(VideoApi::HttpClient) }
    before(:each) do
      obj.should_receive(:http).and_return(mock_http)
      obj.should_receive(:add_update_auth_param).and_return(mock_auth)
      obj.should_receive(:company_id).and_return(company_id)
      mock_auth.should_receive(:merge).with(params).and_return(:the_authed_params)
    end
    context "when given params" do
      context "and params[:format] is 'json'" do
        before(:each) do params.stub!(:delete).with(:format).and_return('json') end
        it 'should http.post("companies/#{company_id}/albums.json", add_update_auth_param.merge(params))' do
          mock_http.should_receive(:post).with("companies/#{company_id}/albums.json", :the_authed_params).and_return(:expected)
          obj.send(meth, params).should == :expected
        end
      end
      [ nil, 'xml' ].each do |the_format|
        context "and params[:format] is #{the_format}" do
          before(:each) do params.stub!(:delete).with(:format).and_return(the_format) end
          it 'should http.post("companies/#{company_id}/albums.xml", add_update_auth_param.merge(params))' do
            mock_http.should_receive(:post).with("companies/#{company_id}/albums.xml", :the_authed_params).and_return(:expected)
            obj.send(meth, params).should == :expected
          end
        end
      end
    end
  end


  describe "#delete_album" do
    let(:meth) { :delete_album }
    let(:album_id)  { :the_album_id }
    let(:mock_http) { mock(VideoApi::HttpClient) }
    context "when given album_id" do
      it 'should http.delete("albums/#{album_id}", add_update_auth_param)' do
        obj.should_receive(:http).and_return(mock_http)
        obj.should_receive(:add_update_auth_param).and_return(:the_authed_params)
        mock_http.should_receive(:delete).with("albums/the_album_id", :the_authed_params).and_return(:expected)
        obj.send(meth, album_id).should == :expected
      end
    end
  end

  describe "#media_api_result" do
    let(:meth) { :media_api_result }
    let(:exception_class) { RuntimeError }
    context "when given exception_class, &block" do
      context "and the block raises a MediaApiAuthenticationFailedException" do
        let(:block) { lambda { raise VideoApi::MediaApiAuthenticationFailedException.new } }
        it "should raise a AlbumApiAuthenticationFailedException" do
          lambda { obj.send(meth, exception_class, &block) }.should raise_error(VideoApi::AlbumApiAuthenticationFailedException)
        end
      end
      context "and the block raises a AlbumApiException" do
        let(:block) { lambda { raise VideoApi::AlbumApiException.new } }
        it "should raise a AlbumApiException" do
          lambda { obj.send(meth, exception_class, &block) }.should raise_error(VideoApi::AlbumApiException)
        end
      end
      context "and the block raises a MediaApiException" do
        let(:block) { lambda { raise VideoApi::MediaApiException.new } }
        it "should raise a AlbumApiException" do
          lambda { obj.send(meth, exception_class, &block) }.should raise_error(VideoApi::AlbumApiException)
        end
      end
    end
    context "when given just &block" do
      context "and the block raises a MediaApiAuthenticationFailedException" do
        let(:block) { lambda { raise VideoApi::MediaApiAuthenticationFailedException.new } }
        it "should raise a AlbumApiAuthenticationFailedException" do
          lambda { obj.send(meth, &block) }.should raise_error(VideoApi::AlbumApiAuthenticationFailedException)
        end
      end
      context "and the block raises a AlbumApiException" do
        let(:block) { lambda { raise VideoApi::AlbumApiException.new } }
        it "should raise a AlbumApiException" do
          lambda { obj.send(meth, &block) }.should raise_error(VideoApi::AlbumApiException)
        end
      end
      context "and the block raises a MediaApiException" do
        let(:block) { lambda { raise VideoApi::MediaApiException.new } }
        it "should raise a AlbumApiException" do
          lambda { obj.send(meth, &block) }.should raise_error(VideoApi::AlbumApiException)
        end
      end
    end
  end

  describe "#search_albums_each" do
    let(:meth) { :search_albums_each }
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

  describe "#search_albums_each_page" do
    let(:meth) { :search_albums_each_page }
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
    it "should be 'albums'" do obj.send(meth).should == 'albums' end
  end

  describe "#update_album" do
    let(:meth) { :update_album }
    let(:album_id) { :the_album_id }
    let(:params)      { :params }
    let(:mock_http)   { mock(VideoApi::HttpClient, :put => nil) }
    context "when given album_id, params" do
      before(:each) do
        obj.stub!(:wrap_update_params).with(params, 'album').and_return(:the_wrapped_params)
        obj.stub!(:add_update_auth_param).and_return(:the_authed_params)
        obj.stub!(:http).and_return(mock_http)
      end
      it "should wrap_update_params(params, 'album')" do
        obj.should_receive(:wrap_update_params).with(params, 'album').and_return(:the_wrapped_params)
        obj.send(meth, album_id, params)
      end
      it "should add_update_auth_param(the_wrapped_params)" do
        obj.should_receive(:add_update_auth_param).with(:the_wrapped_params)
        obj.send(meth, album_id, params)
      end
      it 'should http.put("albums/#{album_id}", the_authed_params)' do
        mock_http.should_receive(:put).with("albums/#{album_id}", :the_authed_params).and_return(:expected)
        obj.send(meth, album_id, params).should == :expected
      end
    end
  end
end

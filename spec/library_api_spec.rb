require File.expand_path('../spec_helper', __FILE__)
require 'library_api'

describe VideoApi::LibraryApi do
  let(:klass) { VideoApi::LibraryApi }
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

  describe "#delete_library" do
    let(:meth) { :delete_library }
    let(:company_id) { :the_co_id }
    let(:library_id) { :the_lib_id }
    let(:mock_http)  { mock(VideoApi::HttpClient) }
    context "when given library_id" do
      it 'should http.delete("companies/#{company_id}/libraries/#{library_id}", add_update_auth_param)' do
        obj.should_receive(:http).and_return(mock_http)
        obj.should_receive(:add_update_auth_param).and_return(:the_authed_params)
        obj.stub!(:company_id).and_return(company_id)
        mock_http.should_receive(:delete).with("companies/#{company_id}/libraries/#{library_id}", :the_authed_params).and_return(:expected)
        obj.send(meth, library_id).should == :expected
      end
    end
  end

  describe "#get_library_metadata" do
    let(:meth) { :get_library_metadata }
    let(:library_id)    { :the_lib_id }
    let(:format)        { :the_format }
    let(:options)       { :the_opts }
    let(:modified_opts) { mock(Symbol) }
    before(:each) do
      obj.should_receive(:company_id).and_return(:the_co_id)
      obj.stub!(:add_view_auth_param).and_return(modified_opts)
      obj.stub!(:structured_data_request)
      modified_opts.stub!(:merge).and_return(modified_opts)
    end
    context "when given library_id, format, options" do
      it "should add_view_auth_param to options" do
        obj.should_receive(:add_view_auth_param).and_return(modified_opts)
        modified_opts.should_receive(:merge).with(options)
        obj.send(meth, library_id, format, options)
      end
      it "should call structured_data_request('companies/the_co_id/libraries/the_lib_id', params, format)" do
        obj.should_receive(:structured_data_request).with('companies/the_co_id/libraries/the_lib_id', modified_opts, format).and_return([])
        obj.send(meth, library_id, format, options)
      end
    end
    context "when given library_id, format" do
      it "should add_view_auth_param to {}" do
        obj.should_receive(:add_view_auth_param).and_return(modified_opts)
        modified_opts.should_receive(:merge).with({})
        obj.send(meth, library_id, format)
      end
      it "should call structured_data_request(playlists/playlist_id, params, format)" do
        obj.should_receive(:structured_data_request).with('companies/the_co_id/libraries/the_lib_id', modified_opts, format).and_return([])
        obj.send(meth, library_id, format)
      end
    end
    context "when given library_id" do
      it "should add_view_auth_param to {}" do
        obj.should_receive(:add_view_auth_param).and_return(modified_opts)
        modified_opts.should_receive(:merge).with({})
        obj.send(meth, library_id)
      end
      it "should call structured_data_request(playlists/playlist_id, params, nil)" do
        obj.should_receive(:structured_data_request).with('companies/the_co_id/libraries/the_lib_id', modified_opts, nil).and_return([])
        obj.send(meth, library_id)
      end
    end
  end

  describe "#library_api_result" do
    let(:meth) { :library_api_result }
    let(:block) { lambda { "I'm a block!" } }
    context "when given exception_class, &block" do
      let(:exception_class) { RuntimeError }
      it "should return media_api_result(exception_class, &block)" do
        obj.should_receive(:media_api_result).with(exception_class, &block).and_return(:expected)
        obj.send(meth, exception_class, &block).should == :expected
      end
    end
    context "when given just a &block" do
      it "should return media_api_result(LibraryApiException, &block)" do
        obj.should_receive(:media_api_result).with(VideoApi::LibraryApiException, &block).and_return(:expected)
        obj.send(meth, &block).should == :expected
      end
    end
  end

  describe "#media_api_result" do
    let(:meth) { :media_api_result }
    let(:exception_class) { RuntimeError }
    context "when given exception_class, &block" do
      context "and the block raises a MediaApiAuthenticationFailedException" do
        let(:block) { lambda { raise VideoApi::MediaApiAuthenticationFailedException.new } }
        it "should raise a LibraryApiAuthenticationFailedException" do
          lambda { obj.send(meth, exception_class, &block) }.should raise_error(VideoApi::LibraryApiAuthenticationFailedException)
        end
      end
      context "and the block raises a LibraryApiException" do
        let(:block) { lambda { raise VideoApi::LibraryApiException.new } }
        it "should raise a LibraryApiException" do
          lambda { obj.send(meth, exception_class, &block) }.should raise_error(VideoApi::LibraryApiException)
        end
      end
      context "and the block raises a MediaApiException" do
        let(:block) { lambda { raise VideoApi::MediaApiException.new } }
        it "should raise a LibraryApiException" do
          lambda { obj.send(meth, exception_class, &block) }.should raise_error(VideoApi::LibraryApiException)
        end
      end
    end
    context "when given just &block" do
      context "and the block raises a MediaApiAuthenticationFailedException" do
        let(:block) { lambda { raise VideoApi::MediaApiAuthenticationFailedException.new } }
        it "should raise a LibraryApiAuthenticationFailedException" do
          lambda { obj.send(meth, &block) }.should raise_error(VideoApi::LibraryApiAuthenticationFailedException)
        end
      end
      context "and the block raises a LibraryApiException" do
        let(:block) { lambda { raise VideoApi::LibraryApiException.new } }
        it "should raise a LibraryApiException" do
          lambda { obj.send(meth, &block) }.should raise_error(VideoApi::LibraryApiException)
        end
      end
      context "and the block raises a MediaApiException" do
        let(:block) { lambda { raise VideoApi::MediaApiException.new } }
        it "should raise a LibraryApiException" do
          lambda { obj.send(meth, &block) }.should raise_error(VideoApi::LibraryApiException)
        end
      end
    end
  end

  search_methods = [ :search_libraries, :search_sites ]
  search_methods.each do |meth|
    describe "##{meth}" do
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
  end

  describe "#update_library" do
    let(:meth) { :update_library }
    let(:company_id) { :the_co_id }
    let(:library_id) { :the_lib_id }
    let(:params)     { :params }
    let(:mock_http)  { mock(VideoApi::HttpClient, :put => nil) }
    context "when given library_id, params" do
      before(:each) do
        obj.stub!(:wrap_update_params).with(params, 'library').and_return(:the_wrapped_params)
        obj.stub!(:add_update_auth_param).and_return(:the_authed_params)
        obj.stub!(:http).and_return(mock_http)
        obj.stub!(:company_id).and_return(company_id)
      end
      it "should wrap_update_params(params, 'library')" do
        obj.should_receive(:wrap_update_params).with(params, 'library').and_return(:the_wrapped_params)
        obj.send(meth, library_id, params)
      end
      it "should add_update_auth_param(the_wrapped_params)" do
        obj.should_receive(:add_update_auth_param).with(:the_wrapped_params)
        obj.send(meth, library_id, params)
      end
      it 'should http.put("companies/#{company_id}libraries/#{library_id}", the_authed_params)' do
        mock_http.should_receive(:put).with("companies/#{company_id}/libraries/#{library_id}", :the_authed_params).and_return(:expected)
        obj.send(meth, library_id, params).should == :expected
      end
    end
  end
end

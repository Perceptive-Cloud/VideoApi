require File.expand_path('../spec_helper', __FILE__)
require 'playlist_api'

describe VideoApi::PlaylistApi do
  let(:klass) { VideoApi::PlaylistApi }
  let(:obj) { klass.new({ 'base_url' => 'http://example.com', 'company_id' => 'CoID', 'license_key' => 'the_key' }) }

  describe "Constants"

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

  describe "#get_playlist_metadata" do
    let(:meth) { :get_playlist_metadata }
    let(:playlist_id)   { :the_pl_id }
    let(:format)        { :the_format }
    let(:options)       { :the_opts }
    let(:modified_opts) { mock(Symbol) }
    before(:each) do
      obj.stub!(:add_view_auth_param).and_return(modified_opts)
      obj.stub!(:structured_data_request)
      modified_opts.stub!(:merge).and_return(modified_opts)
    end
    context "when given playlist_id, format, options" do
      it "should add_view_auth_param to options" do
        obj.should_receive(:add_view_auth_param).and_return(modified_opts)
        modified_opts.should_receive(:merge).with(options)
        obj.send(meth, playlist_id, format, options)
      end
      it "should call structured_data_request(playlists/playlist_id, params, format)" do
        obj.should_receive(:structured_data_request).with('playlists/the_pl_id', modified_opts, format).and_return([])
        obj.send(meth, playlist_id, format, options)
      end
    end
    context "when given playlist_id, format" do
      it "should add_view_auth_param to {}" do
        obj.should_receive(:add_view_auth_param).and_return(modified_opts)
        modified_opts.should_receive(:merge).with({})
        obj.send(meth, playlist_id, format)
      end
      it "should call structured_data_request(playlists/playlist_id, params, format)" do
        obj.should_receive(:structured_data_request).with('playlists/the_pl_id', modified_opts, format).and_return([])
        obj.send(meth, playlist_id, format)
      end
    end
    context "when given playlist_id" do
      it "should add_view_auth_param to {}" do
        obj.should_receive(:add_view_auth_param).and_return(modified_opts)
        modified_opts.should_receive(:merge).with({})
        obj.send(meth, playlist_id)
      end
      it "should call structured_data_request(playlists/playlist_id, params, nil)" do
        obj.should_receive(:structured_data_request).with('playlists/the_pl_id', modified_opts, nil).and_return([])
        obj.send(meth, playlist_id)
      end
    end
  end

  describe "#create_playlist_from_hash" do
    let(:meth) { :create_playlist_from_hash }
    let(:params)    { :the_params }
    let(:mock_auth) { mock(Symbol) }
    let(:mock_http) { mock(VideoApi::HttpClient) }
    context "when given params" do
      it 'should http.post("companies/company_id/playlists", add_update_auth_param.merge(params))' do
        obj.should_receive(:http).and_return(mock_http)
        obj.should_receive(:add_update_auth_param).and_return(mock_auth)
        obj.should_receive(:company_id).and_return(:the_co_id)
        mock_auth.should_receive(:merge).with(params).and_return(:the_authed_params)
        mock_http.should_receive(:post).with("companies/the_co_id/playlists", :the_authed_params).and_return(:expected)
        obj.send(meth, params).should == :expected
      end
    end
  end

  describe "#delete_playlist" do
    let(:meth) { :delete_playlist }
    let(:playlist_id) { :the_pl_id }
    let(:mock_http)   { mock(VideoApi::HttpClient) }
    context "when given playlist_id" do
      it 'should http.delete("playlists/#{playlist_id}", add_update_auth_param)' do
        obj.should_receive(:http).and_return(mock_http)
        obj.should_receive(:add_update_auth_param).and_return(:the_authed_params)
        mock_http.should_receive(:delete).with("playlists/the_pl_id", :the_authed_params).and_return(:expected)
        obj.send(meth, playlist_id).should == :expected
      end
    end
  end

  describe "#playlist_api_result" do
    let(:meth) { :playlist_api_result }
    let(:playlist_id) { :the_pl_id }
    let(:mock_block)  { lambda { "I'm a mock block" } }
    let(:mock_http)   { mock(VideoApi::HttpClient) }
    context "when given exception_class, &block" do
      it "should call media_api_result(exception_class, &block" do
        obj.should_receive(:media_api_result).with(:exception_class, &mock_block).and_return(:expected)
        obj.send(meth, :exception_class, &mock_block)
      end
    end
    context "when given &block" do
      it "should call media_api_result(PlaylistApiException, &block" do
        obj.should_receive(:media_api_result).with(VideoApi::PlaylistApiException, &mock_block).and_return(:expected)
        obj.send(meth, &mock_block)
      end
    end
  end

  describe "#update_playlist" do
    let(:meth) { :update_playlist }
    let(:playlist_id) { :the_pl_id }
    let(:params)      { :params }
    let(:mock_http)   { mock(VideoApi::HttpClient, :put => nil) }
    context "when given playlist_id, params" do
      before(:each) do
        obj.stub!(:wrap_update_params).with(params, 'playlist').and_return(:the_wrapped_params)
        obj.stub!(:add_update_auth_param).and_return(:the_authed_params)
        obj.stub!(:http).and_return(mock_http)
      end
      it "should wrap_update_params(params, 'playlist')" do
        obj.should_receive(:wrap_update_params).with(params, 'playlist').and_return(:the_wrapped_params)
        obj.send(meth, playlist_id, params)
      end
      it "should add_update_auth_param(the_wrapped_params)" do
        obj.should_receive(:add_update_auth_param).with(:the_wrapped_params)
        obj.send(meth, playlist_id, params)
      end
      it 'should http.put("playlists/#{playlist_id}", the_authed_params)' do
        mock_http.should_receive(:put).with("playlists/the_pl_id", :the_authed_params).and_return(:expected)
        obj.send(meth, playlist_id, params).should == :expected
      end
    end
  end

end

require File.expand_path('../spec_helper', __FILE__)
%w(http_client media_api yaml).each { |f| require(f) }

describe VideoApi::MediaApi do
  let(:klass) { VideoApi::MediaApi }
  let(:obj) { klass.new({ 'base_url' => 'http://example.com', 'company_id' => 'CoID', 'license_key' => 'the_key' }) }

  describe "Constants"

  describe ".create_settings_hash" do
    let(:meth) { :create_settings_hash }
    let(:base_url) { :the_base_url }
    let(:company_id)  { :the_co_id }
    let(:library_id)  { :the_lib_id }
    let(:license_key) { :the_lk }
    let(:output) { klass.send(meth, base_url, company_id, library_id, license_key) }
    it "should include the base_url"    do output['base_url'].should == base_url end
    it "should include the company_id"  do output['company_id'].should == company_id end
    it "should include the library_id"  do output['library_id'].should == library_id end
    it "should include the license_key" do output['license_key'].should == license_key end
  end

  describe ".settings_file_path_to_hash" do
    let(:meth) { :settings_file_path_to_hash }
    context "when given a path" do
      let(:path) { :the_path }
      it "should File.read(path)" do
        File.should_receive(:read).with(path)
        YAML.stub!(:load)
        klass.send(meth, path)
      end
      it "should load the contents via YAML::load" do
        File.stub!(:read).with(path).and_return(:file_contents)
        YAML.should_receive(:load).with(:file_contents)
        klass.send(meth, path)
      end
    end
  end

  describe "#add_ingest_auth_param" do
    let(:meth) { :add_ingest_auth_param }
    let(:contributor) { :the_contributor }
    context "when given contributor and either {} or { :key1 => :value1 }" do
      [ {}, { :key1 => :value1 } ].each do |params|
        it "should authenticate_for_ingest(contributor, params)" do
          obj.should_receive(:authenticate_for_ingest).with(contributor, params)
          obj.send(meth, contributor, params)
        end
        it "should call add_param('signature', authenticate_for_ingest, params)" do
          obj.stub!(:authenticate_for_ingest).and_return(:the_ingest_auth)
          obj.should_receive(:add_param).with('signature', :the_ingest_auth, params)
          obj.send(meth, contributor, params)
        end
      end
    end
    context "when given just a contributor" do
      it "should authenticate_for_ingest" do
        obj.should_receive(:authenticate_for_ingest)
        obj.send(meth, contributor)
      end
      it "should call add_param('signature', authenticate_for_ingest, {})" do
        obj.stub!(:authenticate_for_ingest).and_return(:the_ingest_auth)
        obj.should_receive(:add_param).with('signature', :the_ingest_auth, {})
        obj.send(meth, contributor)
      end
    end
  end

  describe "#add_param" do
    let(:meth)   { :add_param }
    let(:key)    { :the_key }
    let(:value)  { :the_value }
    let(:params) { mock(Symbol) }
    context "when given key, value, params" do
      it "should return params.merge({:key => value})" do
        params.should_receive(:merge).with({key => value}).and_return(:expected)
        obj.send(meth, key, value, params).should == :expected
      end
    end
  end

  describe "#add_update_auth_param" do
    let(:meth) { :add_update_auth_param }
    context "when given {} or { :key1 => :value1 }" do
      [ {}, { :key1 => :value1 } ].each do |params|
        it "should authenticate_for_update" do
          obj.should_receive(:authenticate_for_update)
          obj.send(meth, params)
        end
        it "should call add_param('signature', authenticate_for_update, params)" do
          obj.stub!(:authenticate_for_update).and_return(:the_update_auth)
          obj.should_receive(:add_param).with('signature', :the_update_auth, params)
          obj.send(meth, params)
        end
      end
    end
    context "when given no arg" do
      it "should authenticate_for_update" do
        obj.should_receive(:authenticate_for_update)
        obj.send(meth)
      end
      it "should call add_param('signature', authenticate_for_update, {})" do
        obj.stub!(:authenticate_for_update).and_return(:the_update_auth)
        obj.should_receive(:add_param).with('signature', :the_update_auth, {})
        obj.send(meth)
      end
    end
  end

  describe "#add_view_auth_param" do
    let(:meth) { :add_view_auth_param }
    context "when given {} or { :key1 => :value1 }" do
      [ {}, { :key1 => :value1 } ].each do |params|
        it "should authenticate_for_view" do
          obj.should_receive(:authenticate_for_view)
          obj.send(meth, params)
        end
        it "should call add_param('signature', authenticate_for_view, params)" do
          obj.stub!(:authenticate_for_view).and_return(:the_view_auth)
          obj.should_receive(:add_param).with('signature', :the_view_auth, params)
          obj.send(meth, params)
        end
      end
    end
    context "when given no arg" do
      it "should authenticate_for_view" do
        obj.should_receive(:authenticate_for_view)
        obj.send(meth)
      end
      it "should call add_param('signature', authenticate_for_view, {})" do
        obj.stub!(:authenticate_for_view).and_return(:the_view_auth)
        obj.should_receive(:add_param).with('signature', :the_view_auth, {})
        obj.send(meth)
      end
    end
  end

  describe "ingest_auth_token" do
    let(:meth) { :ingest_auth_token }
    context "when there is a truthy @ingest_auth_token already in place" do
      before(:each) do obj.instance_variable_set(:@ingest_auth_token, :something_truthy) end
      it "should NOT call AuthToken.new" do
        VideoApi::AuthToken.should_not_receive(:new)
        obj.send(meth)
      end
      it "should NOT change @ingest_auth_token" do
        obj.send(meth)
        obj.instance_variable_get(:@ingest_auth_token).should == :something_truthy
      end
    end
    context "when there is NOT a truthy @ingest_auth_token already in place" do
      before(:each) do obj.instance_variable_set(:@ingest_auth_token, false) end
      let(:license_key) { :the_lk }
      it "should call AuthToken.new('ingest_key', license_key)" do
        obj.should_receive(:license_key).and_return(license_key)
        VideoApi::AuthToken.should_receive(:new).with('ingest_key', license_key)
        obj.send(meth)
      end
      it "should change @ingest_auth_token" do
        VideoApi::AuthToken.stub!(:new).and_return(:the_new_at)
        obj.send(meth)
        obj.instance_variable_get(:@ingest_auth_token).should == :the_new_at
      end
    end
  end

  describe "update_auth_token" do
    let(:meth) { :update_auth_token }
    context "when there is a truthy @update_auth_token already in place" do
      before(:each) do obj.instance_variable_set(:@update_auth_token, :something_truthy) end
      it "should NOT call AuthToken.new" do
        VideoApi::AuthToken.should_not_receive(:new)
        obj.send(meth)
      end
      it "should NOT change @update_auth_token" do
        obj.send(meth)
        obj.instance_variable_get(:@update_auth_token).should == :something_truthy
      end
    end
    context "when there is NOT a truthy @update_auth_token already in place" do
      before(:each) do obj.instance_variable_set(:@update_auth_token, false) end
      let(:license_key) { :the_lk }
      it "should call AuthToken.new('update_key', license_key)" do
        obj.should_receive(:license_key).and_return(license_key)
        VideoApi::AuthToken.should_receive(:new).with('update_key', license_key)
        obj.send(meth)
      end
      it "should change @update_auth_token" do
        VideoApi::AuthToken.stub!(:new).and_return(:the_new_at)
        obj.send(meth)
        obj.instance_variable_get(:@update_auth_token).should == :the_new_at
      end
    end
  end

  describe "#authenticate_for_ingest" do
    let(:meth) { :authenticate_for_ingest }
    expected_exception = VideoApi::MediaApiException
    contributor_msg = 'You must provide a non-blank contributor name to obtain an ingest authentication signature.'
    library_id_msg  = 'You must provide a non-blank library ID to obtain an ingest authentication signature.'
    context "when given contributor, params" do
      let(:params) { mock(Hash) }
      context "and contributor is nil" do
        let(:contributor) { nil }
        it "should raise a MediaApiException about the blank contributor" do
          lambda { obj.send(meth, contributor, params) }.should raise_error(expected_exception, contributor_msg)
        end
      end
      context "and contributor is ''" do
        let(:contributor) { '' }
        it "should raise a MediaApiException about the blank contributor" do
          lambda { obj.send(meth, contributor, params) }.should raise_error(expected_exception, contributor_msg)
        end
      end
      context "and contributor is NOT nil" do
        let(:contributor) { 'TheContributor' }
        context "and library_id is nil" do
          before(:each) do obj.should_receive(:library_id).at_least(1).times.and_return(nil) end
          it "should raise a MediaApiException about the blank library ID" do
            lambda { obj.send(meth, contributor, params) }.should raise_error(expected_exception, library_id_msg)
          end
        end
        context "and library_id is ''" do
          before(:each) do obj.should_receive(:library_id).at_least(1).times.and_return('') end
          it "should raise a MediaApiException about the blank library ID" do
            lambda { obj.send(meth, contributor, params) }.should raise_error(expected_exception, library_id_msg)
          end
        end
        context "and library_id is 'the_lib_id'" do
          before(:each) do obj.should_receive(:library_id).at_least(1).times.and_return('the_lib_id') end
          it "should call auth_signature('ingest_auth_token, 0, params.merge({'userID' => contributor, 'library_id' => library_id}))" do
            obj.should_receive(:ingest_auth_token).and_return(:the_ingest_auth_token)
            params.should_receive(:merge).with({'userID' => contributor, 'library_id' => 'the_lib_id'}).and_return(:the_merged_params)
            obj.should_receive(:auth_signature).with(:the_ingest_auth_token, 0, :the_merged_params).and_return(:expected)
            obj.send(meth, contributor, params).should == :expected
          end
        end
      end
    end
    context "when given contributor alone" do
      context "and contributor is nil" do
        let(:contributor) { nil }
        it "should raise a MediaApiException about the blank contributor" do
          lambda { obj.send(meth, contributor) }.should raise_error(expected_exception, contributor_msg)
        end
      end
      context "and contributor is ''" do
        let(:contributor) { '' }
        it "should raise a MediaApiException about the blank contributor" do
          lambda { obj.send(meth, contributor) }.should raise_error(expected_exception, contributor_msg)
        end
      end
      context "and contributor is NOT nil" do
        let(:contributor) { 'TheContributor' }
        context "and library_id is nil" do
          before(:each) do obj.should_receive(:library_id).at_least(1).times.and_return(nil) end
          it "should raise a MediaApiException about the blank library ID" do
            lambda { obj.send(meth, contributor) }.should raise_error(expected_exception, library_id_msg)
          end
        end
        context "and library_id is ''" do
          before(:each) do obj.should_receive(:library_id).at_least(1).times.and_return('') end
          it "should raise a MediaApiException about the blank library ID" do
            lambda { obj.send(meth, contributor) }.should raise_error(expected_exception, library_id_msg)
          end
        end
        context "and library_id is 'the_lib_id'" do
          before(:each) do obj.should_receive(:library_id).at_least(1).times.and_return('the_lib_id') end
          it "should call auth_signature('ingest_auth_token, 0, {}.merge({'userID' => contributor, 'library_id' => library_id}))" do
            obj.should_receive(:ingest_auth_token).and_return(:the_ingest_auth_token)
            the_merged_params = {'userID' => contributor, 'library_id' => 'the_lib_id'}
            obj.should_receive(:auth_signature).with(:the_ingest_auth_token, 0, the_merged_params).and_return(:expected)
            obj.send(meth, contributor).should == :expected
          end
        end
      end
    end
  end

  describe "#authenticate_for_view" do
    let(:meth) { :authenticate_for_view }
    it "should accept 1 optional duration argument" do
      lambda { obj.send(meth)     }.should_not raise_error(ArgumentError)
      lambda { obj.send(meth,1)   }.should_not raise_error(ArgumentError)
      lambda { obj.send(meth,1,2) }.should     raise_error(ArgumentError)
    end
    it "should call auth_signature(view_auth_token, dur_arg || auth_duration_in_minutes)" do
      obj.should_receive(:view_auth_token).and_return(:the_token)
      obj.should_receive(:auth_signature).with(:the_token, :the_arg).and_return(:expected)
      obj.send(meth, :the_arg).should == :expected
      obj.should_receive(:view_auth_token).and_return(:the_token)
      obj.should_receive(:auth_duration_in_minutes).and_return(:the_internal_dur)
      obj.should_receive(:auth_signature).with(:the_token, :the_internal_dur).and_return(:expected)
      obj.send(meth).should == :expected
    end
  end

  describe "#authenticate_for_update" do
    let(:meth) { :authenticate_for_update }
    it "should accept 1 optional duration argument" do
      lambda { obj.send(meth)     }.should_not raise_error(ArgumentError)
      lambda { obj.send(meth,1)   }.should_not raise_error(ArgumentError)
      lambda { obj.send(meth,1,2) }.should     raise_error(ArgumentError)
    end
    it "should call auth_signature(update_auth_token, dur_arg || auth_duration_in_minutes)" do
      obj.should_receive(:update_auth_token).and_return(:the_token)
      obj.should_receive(:auth_signature).with(:the_token, :the_arg).and_return(:expected)
      obj.send(meth, :the_arg).should == :expected
      obj.should_receive(:update_auth_token).and_return(:the_token)
      obj.should_receive(:auth_duration_in_minutes).and_return(:the_internal_dur)
      obj.should_receive(:auth_signature).with(:the_token, :the_internal_dur).and_return(:expected)
      obj.send(meth).should == :expected
    end
  end

  describe "#create_account_library_url" do
    let(:meth) { :create_account_library_url }
    [ nil, '', [] ].each do  |empty_lib_id|
      context "when library_id is #{empty_lib_id}" do
        it "should return 'companies/CoID'" do
          obj.send(meth).should == 'companies/CoID'
        end
      end
      library_id = :the_lib_id
      context "when library_id is #{library_id}" do
        before(:each) do obj.stub!(:library_id).and_return(library_id) end
        it "should return 'companies/CoID/libraries/#{library_id}'" do
          obj.send(meth).should == "companies/CoID/libraries/#{library_id}"
        end
      end
    end
  end

  describe "#create_asset_xml_from_hash" do
    let(:meth)      { :create_asset_xml_from_hash }
    let(:entry)     { :the_entry }
    let(:video_id)  { :the_video_id }
    let(:mock_http) { mock(Symbol) }
    context "when given an entry" do
      it "should create_xml_from_value(:asset => entry) and prepend an XML declaration" do
        def obj.create_xml_from_value(opts); opts[:entry]; end
        entry_xml = obj.create_xml_from_value({ :asset => entry})
        obj.send(meth, entry).should == %Q[<?xml version="1.0" encoding="UTF-8"?>#{entry_xml}]
      end
    end
  end

  describe "#create_search_media_sub_url" do
    let(:meth) { :create_search_media_sub_url }
    context "when given type, params, format" do
      let(:type)   { mock(Symbol) }
      let(:params) { mock(Symbol) }
      let(:format) { mock(Symbol) }
      let(:mock_http) { mock(Symbol, :create_sub_url => nil) }
      let(:create_account_library_url) { mock(Symbol) }
      before(:each) do
        obj.stub!(:add_view_auth_param).and_return(:all_params)
        obj.stub!(:create_account_library_url).and_return(create_account_library_url)
        obj.stub!(:http).and_return(mock_http)
      end
      it "should pass format into include_auth_in_search_call?" do
        obj.should_receive(:include_auth_in_search_call?).with(format)
        obj.send(meth, type, params, format)
      end
      context "when include_auth_in_search_call? is truthy" do
        before(:each) do obj.stub!(:include_auth_in_search_call?).and_return(:something_truthy) end
        it "should pass params into add_view_auth_param -> all_params" do
          obj.should_receive(:add_view_auth_param).with(params)
          obj.send(meth, type, params, format)
        end
        it "should access its http" do
          obj.should_receive(:http).and_return(mock_http)
          obj.send(meth, type, params, format)
        end
        it 'should http.create_sub_url("#{create_account_library_url}/#{type}.#{format}", all_params)' do
          mock_http.should_receive(:create_sub_url).with("#{create_account_library_url}/#{type}.#{format}", :all_params)
          obj.send(meth, type, params, format)
        end
      end
      context "when include_auth_in_search_call? is falsey" do
        before(:each) do obj.stub!(:include_auth_in_search_call?).and_return(false) end
        it "should NOT pass params into add_view_auth_param -> all_params" do
          obj.should_not_receive(:add_view_auth_param)
          obj.send(meth, type, params, format)
        end
        it "should access its http" do
          obj.should_receive(:http).and_return(mock_http)
          obj.send(meth, type, params, format)
        end
        it 'should http.create_sub_url("#{create_account_library_url}/#{type}.#{format}", params)' do
          mock_http.should_receive(:create_sub_url).with("#{create_account_library_url}/#{type}.#{format}", params)
          obj.send(meth, type, params, format)
        end
      end
    end
  end

  describe "#get_media_with_tag" do
    let(:meth) { :get_media_with_tag }
    let(:media_type) { :the_media_type }
    let(:tag)        { :the_tag }
    let(:params)     { :the_params }
    let(:format)     { :the_format }
    let(:create_account_library_url) { :the_alu }
    context "when given media_type, tag, params, format" do
      before(:each) do
        obj.stub!(:add_view_auth_param).and_return(:auth_params)
        obj.stub!(:create_account_library_url).and_return(create_account_library_url)
        obj.stub!(:structured_data_request).with("#{create_account_library_url}/tags/#{tag}/#{media_type}", :auth_params, format)
      end
      it "should add_view_auth_param(params) -> auth_params" do
        obj.stub!(:media_api_result)
        obj.should_receive(:add_view_auth_param).with(params).and_return(:auth_params)
        obj.send(meth, media_type, tag, params, format)
      end
      it "should get a URL via create_account_library_url" do
        obj.should_receive(:create_account_library_url).and_return(create_account_library_url)
        obj.send(meth, media_type, tag, params, format)
      end
      it 'should call structured_data_request("#{create_account_library_url}/tags/#{tag}/#{media_type}", auth_params, format)' do
        obj.should_receive(:structured_data_request).with("#{create_account_library_url}/tags/#{tag}/#{media_type}", :auth_params, format)
        obj.send(meth, media_type, tag, params, format)
      end
    end
  end

  describe "#get_tag_names" do
    let(:meth) { :get_tag_names }
    let(:the_tags) { (1..3).to_a.map { |x| mock(Symbol, :name => "tag_name#{x}") } }
    it "should return get_tags.map(&:name)" do
      obj.should_receive(:get_tags).and_return(the_tags)
      obj.send(meth).should == %w(tag_name1 tag_name2 tag_name3)
    end
  end

  describe "#get_tags" do
    let(:meth)   { :get_tags }
    let(:format) { :the_format }
    before(:each) do
      obj.stub!(:add_view_auth_param).and_return(:modified_params)
      obj.stub!(:tag_media_type).and_return(:the_tag_media_type)
      obj.stub!(:structured_data_request)
    end
    context "when given format" do
      it "should add_view_auth_param to {:applied_to => tag_media_type}" do
        obj.should_receive(:tag_media_type).and_return(:the_tag_media_type)
        obj.should_receive(:add_view_auth_param).with({:applied_to => :the_tag_media_type}).and_return(:modified_params)
        obj.send(meth, format)
      end
      it 'should return structured_data_request("#{create_account_library_url}/tags", modified_params, format' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/tags", :modified_params, format)
        obj.send(meth, format)
      end
    end
    context "when given nothing" do
      it "should add_view_auth_param to {:applied_to => tag_media_type}" do
        obj.should_receive(:tag_media_type).and_return(:the_tag_media_type)
        obj.should_receive(:add_view_auth_param).with({:applied_to => :the_tag_media_type}).and_return(:modified_params)
        obj.send(meth)
      end
      it 'should return structured_data_request("#{create_account_library_url}/tags", modified_params, nil' do
        obj.should_receive(:create_account_library_url).and_return(:the_account_library_url)
        obj.should_receive(:structured_data_request).with("the_account_library_url/tags", :modified_params, nil)
        obj.send(meth)
      end
    end
  end

  describe "#import_media_items_from_xml_string" do
    let(:meth)        { :import_media_items_from_xml_string }
    let(:xml)         { :the_xml }
    let(:contributor) { :the_contributor }
    let(:params)      { :the_params }
    let(:mock_http)   { mock(VideoApi::HttpClient, :post => nil) }
    before(:each) do
      obj.stub!(:add_ingest_auth_param).and_return(:modified_params)
      obj.stub!(:http).and_return(mock_http)
    end
    context "when given :track, xml, contributor, params" do
      before(:each) do def obj.audio_api_result; yield; end end
      let(:media_type) { :track }
      it "should call audio_api_result" do
        obj.should_receive(:audio_api_result)
        obj.send(meth, media_type, xml, contributor, params)
      end
      it "should access its http" do
        obj.should_receive(:http).and_return(mock_http)
        obj.send(meth, media_type, xml, contributor, params)
      end
      it "should call add_ingest_auth_param(contributor, params)" do
        obj.should_receive(:add_ingest_auth_param).with(contributor, params).and_return(:modified_params)
        obj.send(meth, media_type, xml, contributor, params)
      end
      it "should http.post('tracks/create_many', add_ingest_auth_param(contributor, params), xml, 'text/xml')" do
        mock_http.should_receive(:post).with('tracks/create_many', :modified_params, xml, 'text/xml')
        obj.send(meth, media_type, xml, contributor, params)
      end
    end
    context "when given :video, xml, contributor, params" do
      before(:each) do def obj.video_api_result; yield; end end
      let(:media_type) { :video }
      it "should call video_api_result" do
        obj.should_receive(:video_api_result)
        obj.send(meth, media_type, xml, contributor, params)
      end
      it "should call video_api_result" do
        obj.should_receive(:video_api_result)
        obj.send(meth, media_type, xml, contributor, params)
      end
      it "should access its http" do
        obj.should_receive(:http).and_return(mock_http)
        obj.send(meth, media_type, xml, contributor, params)
      end
      it "should call add_ingest_auth_param(contributor, params)" do
        obj.should_receive(:add_ingest_auth_param).with(contributor, params).and_return(:modified_params)
        obj.send(meth, media_type, xml, contributor, params)
      end
      it "should http.post('videos/create_many', add_ingest_auth_param(contributor, params), xml, 'text/xml')" do
        mock_http.should_receive(:post).with('videos/create_many', :modified_params, xml, 'text/xml')
        obj.send(meth, media_type, xml, contributor, params)
      end
    end
    context "when given :track, xml, contributor" do
      before(:each) do def obj.audio_api_result; yield; end end
      let(:media_type) { :track }
      it "should call audio_api_result" do
        obj.should_receive(:audio_api_result)
        obj.send(meth, media_type, xml, contributor)
      end
      it "should access its http" do
        obj.should_receive(:http).and_return(mock_http)
        obj.send(meth, media_type, xml, contributor)
      end
      it "should call add_ingest_auth_param(contributor, {})" do
        obj.should_receive(:add_ingest_auth_param).with(contributor, {}).and_return(:modified_params)
        obj.send(meth, media_type, xml, contributor)
      end
      it "should http.post('tracks/create_many', add_ingest_auth_param(contributor, params), xml, 'text/xml')" do
        mock_http.should_receive(:post).with('tracks/create_many', :modified_params, xml, 'text/xml')
        obj.send(meth, media_type, xml, contributor)
      end
    end
    context "when given :video, xml, contributor" do
      before(:each) do def obj.video_api_result; yield; end end
      let(:media_type) { :video }
      it "should call video_api_result" do
        obj.should_receive(:video_api_result)
        obj.send(meth, media_type, xml, contributor)
      end
      it "should call video_api_result" do
        obj.should_receive(:video_api_result)
        obj.send(meth, media_type, xml, contributor)
      end
      it "should access its http" do
        obj.should_receive(:http).and_return(mock_http)
        obj.send(meth, media_type, xml, contributor)
      end
      it "should call add_ingest_auth_param(contributor, {})" do
        obj.should_receive(:add_ingest_auth_param).with(contributor, {}).and_return(:modified_params)
        obj.send(meth, media_type, xml, contributor)
      end
      it "should http.post('videos/create_many', add_ingest_auth_param(contributor, params), xml, 'text/xml')" do
        mock_http.should_receive(:post).with('videos/create_many', :modified_params, xml, 'text/xml')
        obj.send(meth, media_type, xml, contributor)
      end
    end
  end

  describe "#ingest_auth_param_key?" do
    let(:meth) { :ingest_auth_param_key? }
    [ :ingest_profile, 'ingest_profile' ].each do |key_arg|
      context "when given #{key_arg}" do
        it "should return true" do obj.send(meth, key_arg).should == true end
      end
    end
    context "when given 'image_profile'" do
      it "should return false" do obj.send(meth, 'image_profile').should == false end
    end
  end

  describe "#initialize" do
    let(:meth) { :new }
    context "when given params, true" do
      let(:params) { { :library_id => 'the_lib_id' } }
      let(:require_library) { true }
      [ nil, '', [] ].each do |bad_val|
        context "and params[:library_id] is #{bad_val.inspect}" do
          before(:each) do params.merge!({ :library_id => bad_val }) end
          it "should raise a MediaApiException stating that a library_id is required" do
            lambda { klass.send(meth, params, require_library) }.should raise_error(VideoApi::MediaApiException, "MediaApi.initialize: library_id required.")
          end
        end
      end
    end
    ### FIXME: clean up MediaApi#initialize, make base_url, company_id, license_key checks follow the example for library_id
    # 1. Check incoming params
    # 2. Do it before assigning into instance variables
=begin
    context "when given params, false" do
      [ nil, '', [] ].each do |bad_val|
        let(:params) { { :library_id => 'the_lib_id', :base_url => 'the_base_url', :company_id => 'the_co_id', :license_key => 'the_lk' } }
        let(:require_library) { false }
        context "and params[:base_url] is #{bad_val.inspect}" do
          before(:each) do params.merge!({ :base_url => bad_val }) end
          it "should raise a MediaApiException stating that a base_url is required" do
            lambda { klass.send(meth, params, require_library) }.should raise_error(VideoApi::MediaApiException, "base_url required.")
          end
        end
        context "and params[:company_id] is #{bad_val.inspect}" do
          before(:each) do params.merge!({ :company_id => bad_val }) end
          it "should raise a MediaApiException stating that a company_id is required" do
            lambda { klass.send(meth, params, require_library) }.should raise_error(VideoApi::MediaApiException, "company_id required.")
          end
        end
        context "and params[:license_key] is #{bad_val.inspect}" do
          before(:each) do params.merge!({ :license_key => bad_val }) end
          it "should raise a MediaApiException stating that a license_key is required" do
            lambda { klass.send(meth, params, require_library) }.should raise_error(VideoApi::MediaApiException, "license_key required.")
          end
        end
      end
    end
=end
  end

  describe "#media_api_result" do
    let(:meth) { :media_api_result }
    context "when given a NoMethodError arg" do
      let(:exception_arg) { NoMethodError }
      context "and the block raises an HttpClientException" do
        let(:block) { lambda { raise(VideoApi::HttpClientException.from_code(:the_code, :the_body) ) } }
        it "should raise a new NoMethodError" do
          lambda { obj.send(meth, exception_arg, &block) }.should raise_error(NoMethodError)
        end
      end
      context "and the block raises a RuntimeError" do
        let(:block) { lambda { raise(RuntimeError ) } }
        it "should raise a RuntimeError" do
          lambda { obj.send(meth, exception_arg, &block) }.should raise_error(RuntimeError)
        end
      end
    end
    context "when given a MediaApiException arg" do
      let(:exception_arg) { VideoApi::MediaApiException }
      context "and the block raises an HttpClientException" do
        let(:block) { lambda { raise(VideoApi::HttpClientException.from_code(:the_code, :the_body) ) } }
        it "should raise a new MediaApiException stating the code and message raised from the server" do
          exception_msg = "Server returned code the_code and message HTTP response code=the_code, body=the_body"
          lambda { obj.send(meth, exception_arg, &block) }.should raise_error(exception_arg, exception_msg)
        end
      end
      context "and the block raises a RuntimeError" do
        let(:block) { lambda { raise(RuntimeError ) } }
        it "should raise a RuntimeError" do
          lambda { obj.send(meth, exception_arg, &block) }.should raise_error(RuntimeError)
        end
      end
    end
    context "when given no arg" do
      context "and the block raises an HttpClientException" do
        let(:block) { lambda { raise(VideoApi::HttpClientException.from_code(:the_code, :the_body) ) } }
        it "should raise a new MediaApiException stating the code and message raised from the server" do
          exception_msg = "Server returned code the_code and message HTTP response code=the_code, body=the_body"
          lambda { obj.send(meth, &block) }.should raise_error(VideoApi::MediaApiException, exception_msg)
        end
      end
      context "and the block raises a RuntimeError" do
        let(:block) { lambda { raise(RuntimeError ) } }
        it "should raise a RuntimeError" do
          lambda { obj.send(meth, &block) }.should raise_error(RuntimeError)
        end
      end
    end
  end

  describe "#media_upload_close" do
    let(:meth) { :media_upload_close }
    let(:mock_http) { mock(Symbol, :get => '', :post_multipart_file_upload => '') }
    context "when given auth" do
      let(:auth)   { :the_auth }
      it "should call http.get('upload_sessions/auth/http_close')" do
        obj.should_receive(:http).and_return(mock_http)
        mock_http.should_receive(:get).with("upload_sessions/#{auth}/http_close").and_return(:expected)
        obj.send(meth, auth).should == :expected
      end
    end
  end

  describe "#media_upload_open" do
    let(:meth) { :media_upload_open }
    let(:mock_http) { mock(Symbol, :get => '', :post_multipart_file_upload => '') }
    context "when given auth, params" do
      let(:auth)   { :the_auth }
      let(:params) { :the_params }
      it "should call http.get('upload_sessions/auth/http_open', params)" do
        obj.should_receive(:http).and_return(mock_http)
        mock_http.should_receive(:get).with("upload_sessions/#{auth}/http_open", params).and_return(:expected)
        obj.send(meth, auth, params).should == :expected
      end
    end
  end

  describe "#reset_auth_token_cache" do
    let(:meth) { :reset_auth_token_cache }
    let(:mock_view_token)   { mock(Symbol, :reset_cache => nil) }
    let(:mock_update_token) { mock(Symbol, :reset_cache => nil) }
    before(:each) do
      obj.stub!(:view_auth_token).and_return(mock_view_token)
      obj.stub!(:update_auth_token).and_return(mock_update_token)
    end
    it "should call view_auth_token.reset_cache" do
      obj.should_receive(:view_auth_token).and_return(mock_view_token)
      mock_view_token.should_receive(:reset_cache)
      obj.send(meth)
    end
    it "should call update_auth_token.reset_cache" do
      obj.should_receive(:update_auth_token).and_return(mock_update_token)
      mock_update_token.should_receive(:reset_cache)
      obj.send(meth)
    end
  end

  describe "#search_media" do
    let(:meth) { :search_media }
    let(:params) { :the_params }
    let(:format) { :the_format }
    context "when given params, format" do
      it "should create_search_sub_url(params, format)" do
        obj.should_receive(:create_search_sub_url).with(params, format)
        obj.send(meth, params, format)
      end
      it "should do a structured_data_request(sub_url, nil, format)" do
        obj.stub!(:create_search_sub_url).and_return(:sub_url)
        obj.should_receive(:structured_data_request).with(:sub_url, nil, format)
        obj.send(meth, params, format)
      end
      it "should get_search_page_media(result)"
      it "should cleanup_search_results! on the search page media"
    end
    context "when given just params" do
      it "should create_search_sub_url(params, 'json')" do
        obj.should_receive(:create_search_sub_url).with(params, 'json')
        obj.stub!(:media_api_result)
        obj.send(meth, params)
      end
      it "should do a structured_data_request(sub_url, nil, nil)" do
        obj.stub!(:create_search_sub_url).and_return(:sub_url)
        obj.should_receive(:structured_data_request).with(:sub_url, nil, nil)
        obj.send(meth, params)
      end
      it "should get_search_page_media(result)"
      it "should cleanup_search_results! on the search page media"
    end
    context "when given no args" do
      it "should create_search_sub_url({}, 'json')" do
        obj.should_receive(:create_search_sub_url).with({}, 'json')
        obj.stub!(:media_api_result)
        obj.send(meth)
      end
      it "should do a structured_data_request(sub_url, nil, nil)" do
        obj.stub!(:create_search_sub_url).and_return(:sub_url)
        obj.should_receive(:structured_data_request).with(:sub_url, nil, nil)
        obj.send(meth)
      end
      it "should get_search_page_media(result)"
      it "should cleanup_search_results! on the search page media"
    end
  end

  describe "#search_media_each" do
    let(:meth)   { :search_media_each }
    let(:params) { :the_params }
    let(:block)  { lambda { |x| false } }
    context "when given params, &block" do
      context "and params = {}" do
        let(:params) { {} }
        let(:page1_info) { mock(Symbol, :is_last_page => false, :page_number => 1) }
        let(:page2_info) { mock(Symbol, :is_last_page => true) }
        let(:page1) { mock(Symbol, :page_info => page1_info) }
        let(:page2) { mock(Symbol, :page_info => page2_info) }
        it "should call search_media_each_page(params)" do
          obj.should_receive(:search_media_each_page).with(params)
          obj.send(meth, params, &block)
        end
        it "should get_search_page_media" do
          obj.stub!(:search_media).with({:page => 1}).and_return(page1)
          obj.should_receive(:get_search_page_media).with(page1).and_return([:object])
          obj.send(meth, params, &block)
        end
      end
    end
  end

  describe "#search_media_each_page" do
    let(:meth)   { :search_media_each_page }
    let(:params) { :the_params }
    let(:block)  { lambda { |x| "block received #{x}" } }
    let(:false_block_for_page2) { lambda { |x| x == page1 } }
    context "when given params, &block" do
      context "and params = {}" do
        let(:params) { {} }
        let(:page1_info) { mock(Symbol, :page_number => 1) }
        let(:page2_info) { mock(Symbol, :is_last_page => true) }
        let(:page1) { mock(Symbol, :page_info => page1_info) }
        let(:page2) { mock(Symbol, :page_info => page2_info) }
        context "when page1 is the last page" do
          before(:each) do page1_info.stub!(:is_last_page).and_return(true) end
          it "should search_media(params_copy) -> page" do
            obj.should_receive(:search_media).with({:page => 1}).and_return(page1)
            obj.send(meth, params, &block)
          end
        end
        context "when page1 is NOT the last page" do
          before(:each) do page1_info.stub!(:is_last_page).and_return(false) end
          it "should search_media({:page => [1|2]}) -> page" do
            obj.should_receive(:search_media).with({:page => 1}).and_return(page1)
            obj.should_receive(:search_media).with({:page => 2}).and_return(page2)
            obj.send(meth, params, &block)
          end
          context "and page2 is NOT the last page, either, but the block returns false for page2" do
            before(:each) do page2_info.stub!(:is_last_page).and_return(false) end
            it "should search_media({:page => [1|2]}) -> page" do
              obj.should_receive(:search_media).with({:page => 1}).and_return(page1)
              obj.should_receive(:search_media).with({:page => 2}).and_return(page2)
              obj.send(meth, params, &false_block_for_page2)
            end
          end
        end
      end
    end
  end

  describe "#settings_trace_string" do
    let(:meth) { :settings_trace_string }
    it "should include the base_url" do
      obj.should_receive(:base_url).and_return(:the_base_url)
      obj.send(meth).should include('base_url: the_base_url')
    end
    it "should include the company_id" do
      obj.should_receive(:company_id).and_return(:the_co_id)
      obj.send(meth).should include('company_id: the_co_id')
    end
    it "should include the library_id" do
      obj.should_receive(:library_id).and_return(:the_lib_id)
      obj.send(meth).should include('library_id: the_lib_id')
    end
    it "should include the license_key" do
      obj.should_receive(:license_key).and_return(:the_key)
      obj.send(meth).should include('license_key: the_key')
    end
  end

  describe "#structured_data_request" do
    let(:meth) { :structured_data_request }
    let(:sub_url) { :the_sub_url }
    let(:params)  { :the_params }
    let(:format)  { :the_format }
    let(:mock_http) { mock(Symbol, :get => '', :post_multipart_file_upload => '') }
    context "when given sub_url, params, format" do
      context "and format is nil" do
        let(:format) { nil }
        it "should return ObjectFromJson.from_json, raw" do
          VideoApi::ObjectFromJson.should_receive(:from_json).and_return(:expected)
          obj.stub!(:http).and_return(mock_http)
          mock_http.stub!(:get)
          obj.send(meth, sub_url, params, format).should == :expected
        end
      end
      context "and format is NOT nil" do
        it "should return http.get(sub_url.format, params)" do
          obj.should_receive(:http).and_return(mock_http)
          mock_http.should_receive(:get).with("#{sub_url}.#{format}", params).and_return(:expected)
          obj.send(meth, sub_url, params, format).should == :expected
        end
      end
    end
    context "when given sub_url, params, format, &block" do
      let(:block) { lambda { |x| "I received #{x.inspect}" } }
      context "and format is nil" do
        let(:format) { nil }
        it "should return ObjectFromJson.from_json, yielded to the &block" do
          VideoApi::ObjectFromJson.should_receive(:from_json).and_return(:expected)
          obj.stub!(:http).and_return(mock_http)
          mock_http.stub!(:get)
          obj.send(meth, sub_url, params, format, &block).should == block.call(:expected)
        end
      end
      context "and format is NOT nil" do
        it "should return http.get(sub_url.format, params)" do
          obj.should_receive(:http).and_return(mock_http)
          mock_http.should_receive(:get).with("#{sub_url}.#{format}", params).and_return(:expected)
          obj.send(meth, sub_url, params, format, &block).should == :expected
        end
      end
    end
  end

  describe "#update_token_expired?" do
    let(:meth) { :update_token_expired? }
    let(:mock_token) { mock(Symbol) }
    it "should return update_auth_token.expired?" do
      obj.should_receive(:update_auth_token).and_return(mock_token)
      mock_token.should_receive(:expired?).and_return(:expected)
      obj.send(meth).should == :expected
    end
  end

  describe "#view_token_expired?" do
    let(:meth) { :view_token_expired? }
    let(:mock_token) { mock(Symbol) }
    it "should return view_auth_token.expired?" do
      obj.should_receive(:view_auth_token).and_return(mock_token)
      mock_token.should_receive(:expired?).and_return(:expected)
      obj.send(meth).should == :expected
    end
  end

  describe "#upload_media" do
    let(:meth)        { :upload_media }
    let(:filename)    { :the_filename }
    let(:contributor) { :the_contributor }
    let(:params)      { { :key1 => :value1, :key2 => :value2 } }
    let(:mock_uri)    { mock(Symbol, :host => 'the_host', :path => 'the_path', :port => 'the_port', :query => 'the_query') }
    let(:mock_http)   { mock(Symbol, :get => '', :post_multipart_file_upload => '') }
    let(:mock_close)  { mock(Symbol, :strip => nil) }
    let(:progress_listener) { lambda { "I'm the progress listener" } }
    before(:each) do
      obj.stub!(:authenticate_for_ingest).and_return(:the_signature)
      obj.stub!(:ingest_auth_param_key?).with(:key1).and_return(false)
      obj.stub!(:ingest_auth_param_key?).with(:key2).and_return(true)
      obj.stub!(:media_upload_open).and_return(:media_upload_url)
      URI.stub!(:parse).and_return(mock_uri)
      VideoApi::HttpClient.stub!(:new).and_return(mock_http)
    end
    context "when given filename, contributor, params, &progress_listener" do
      it "should gather a signature from authenticate_for_ingest with the ingest params pairs" do
        obj.should_receive(:authenticate_for_ingest).with(contributor, { :key2 => :value2 })
        obj.send(meth, filename, contributor, params, &progress_listener)
      end
      it "should strip params keys via ingest_auth_param_key?" do
        obj.should_receive(:ingest_auth_param_key?).with(:key1).at_least(1).times.and_return(false)
        obj.should_receive(:ingest_auth_param_key?).with(:key2).at_least(1).times.and_return(true)
        obj.send(meth, filename, contributor, params, &progress_listener)
      end
      it "should media_upload_open with the non-ingest params pairs" do
        obj.should_receive(:media_upload_open).with(:the_signature, {:key1 => :value1})
        obj.send(meth, filename, contributor, params, &progress_listener)
      end
      it "should URI.parse the media_upload_open URL" do
        URI.should_receive(:parse).with(:media_upload_url)
        obj.send(meth, filename, contributor, params, &progress_listener)
      end
      it "should instantiate a new HttpClient with the host and port" do
      VideoApi::HttpClient.should_receive(:new).with('the_host', 'the_port').and_return(mock_http)
        obj.send(meth, filename, contributor, params, &progress_listener)
      end
      it "should post to the new HttpClient instance" do
        mock_http.should_receive(:post_multipart_file_upload).with('the_path?the_query', filename, {}, &progress_listener)
        obj.send(meth, filename, contributor, params, &progress_listener)
      end
      it "should close the media upload with the signature, strip it, and return it" do
        obj.should_receive(:media_upload_close).with(:the_signature).and_return(mock_close)
        mock_close.should_receive(:strip).and_return(:expected)
        obj.send(meth, filename, contributor, params, &progress_listener).should == :expected
      end
    end
    context "when given filename, contributor, &progress_listener" do
      it "should gather a signature from authenticate_for_ingest with {}" do
        obj.should_receive(:authenticate_for_ingest).with(contributor, {})
        obj.send(meth, filename, contributor, &progress_listener)
      end
      it "should NOT strip params keys via ingest_auth_param_key?, since there are no param keys to strip" do
        obj.should_not_receive(:ingest_auth_param_key?)
        obj.send(meth, filename, contributor, &progress_listener)
      end
      it "should media_upload_open with {}" do
        obj.should_receive(:media_upload_open).with(:the_signature, {})
        obj.send(meth, filename, contributor, &progress_listener)
      end
      it "should URI.parse the media_upload_open URL" do
        URI.should_receive(:parse).with(:media_upload_url)
        obj.send(meth, filename, contributor, &progress_listener)
      end
      it "should instantiate a new HttpClient with the host and port" do
      VideoApi::HttpClient.should_receive(:new).with('the_host', 'the_port').and_return(mock_http)
        obj.send(meth, filename, contributor, &progress_listener)
      end
      it "should post to the new HttpClient instance" do
        mock_http.should_receive(:post_multipart_file_upload).with('the_path?the_query', filename, {}, &progress_listener)
        obj.send(meth, filename, contributor, &progress_listener)
      end
      it "should close the media upload with the signature, strip it, and return it" do
        obj.should_receive(:media_upload_close).with(:the_signature).and_return(mock_close)
        mock_close.should_receive(:strip).and_return(:expected)
        obj.send(meth, filename, contributor, &progress_listener).should == :expected
      end
    end
  end

  describe "#wrap_update_params" do
    let(:meth)    { :wrap_update_params }
    let(:params)  { :the_params }
    let(:wrapper) { 'the_wrapper' }
    context "when given params, wrapper" do
      context "and params is {}" do
        let(:params) { {} }
        it "should return {}" do
          obj.send(meth, params, wrapper).should == {}
        end
      end
      context "and params is { :key1 => :value1 }" do
        let(:params) { { :key1 => :value1 } }
        it "should return { 'the_wrapper[key1]' => :value1}" do
          obj.send(meth, params, wrapper).should == { "the_wrapper[key1]" => :value1 }
        end
      end
      context "and params is { :key1 => :value1, :key2 => :value2 }" do
        let(:params) { { :key1 => :value1, :key2 => :value2 } }
        it "should return { 'the_wrapper[key1]' => :value1, 'the_wrapper[key2]' => :value2 }" do
          obj.send(meth, params, wrapper).should == { "the_wrapper[key1]" => :value1, "the_wrapper[key2]" => :value2 }
        end
      end
      context "and params is { :key1 => :value1, 'the_wrapper[key2]' => :value2 }" do
        let(:params) { { :key1 => :value1, 'the_wrapper[key2]' => :value2 } }
        it "should return { 'the_wrapper[key1]' => :value1, 'the_wrapper[key2]' => :value2 }" do
          obj.send(meth, params, wrapper).should == { "the_wrapper[key1]" => :value1, "the_wrapper[key2]" => :value2 }
        end
      end
    end
  end

end

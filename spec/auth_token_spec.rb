require File.expand_path('../spec_helper', __FILE__)
%w(media_api).each { |f| require(f) }

describe VideoApi::AuthToken do
  let(:klass) { VideoApi::AuthToken }

  describe "Constants"

  describe "#initialize" do
    let(:meth) { :new }
    [ nil, '', [] ].each do |bad_val|
      context "when given #{bad_val}, license_key" do
        it "should raise a StandardError about the name key" do
          ### FIXME: MediaApiException here too?
          lambda { klass.send(meth, bad_val, :any_lk) }.should raise_error(StandardError, 'AuthToken: name required')
        end
      end
      context "when given name, #{bad_val}" do
        it "should raise a MediaApiException about the license key" do
          lambda { klass.send(meth, :any_name, bad_val) }.should raise_error(VideoApi::MediaApiException, 'license_key required')
        end
      end
    end
  end

  describe "an instance" do
    let(:name)        { mock(Symbol, :empty? => false) }
    let(:license_key) { mock(Symbol, :empty? => false) }
    let(:obj) { klass.new(name, license_key) }

    describe "#cache_as_json" do
      let(:meth) { :cache_as_json }
      it "should return JSON.parse(cache_file_contents)" do
        obj.should_receive(:cache_file_contents).and_return(:to_be_parsed)
        JSON.should_receive(:parse).with(:to_be_parsed).and_return(:parsed_as_json)
        obj.send(meth).should == :parsed_as_json
      end
    end

    describe "#cache_file_contents" do
      let(:meth) { :cache_file_contents }
      it "should return File.read(cache_file_path)" do
        obj.should_receive(:cache_file_path).and_return(:to_be_read)
        File.should_receive(:read).with(:to_be_read).and_return(:read_as_file)
        obj.send(meth).should == :read_as_file
      end
    end

    describe "#duration_in_minutes" do
      let(:meth) { :duration_in_minutes }
      context "when @duration_in_minutes is truthy" do
        before(:each) do obj.instance_variable_set(:@duration_in_minutes, :something_truthy) end
        it "should NOT load_cache" do
          obj.should_not_receive(:load_cache)
          obj.send(meth)
        end
        it "should return @duration_in_minutes" do obj.send(meth).should == :something_truthy end
      end
      context "when @duration_in_minutes is false" do
        before(:each) do obj.instance_variable_set(:@duration_in_minutes, false) end
        it "should load_cache" do
          obj.should_receive(:load_cache)
          obj.send(meth)
        end
        it "should return false" do
          obj.stub!(:load_cache).and_return(:results_of_load_cache)
          obj.send(meth).should == false
        end
      end
      context "when @duration_in_minutes is nil" do
        before(:each) do obj.instance_variable_set(:@duration_in_minutes, nil) end
        it "should load_cache" do
          obj.should_receive(:load_cache)
          obj.send(meth)
        end
        it "should return nil" do
          obj.stub!(:load_cache).and_return(:results_of_load_cache)
          obj.send(meth).should == nil
        end
      end
    end

    describe "#elapsed_minutes" do
      let(:meth) { :elapsed_minutes }
      ### FIXME: This is messier than it should ideally be
      it "should return (Time.new.to_i - start_time + 30).div 60" do
        Time.should_receive(:new).and_return(new_time = mock(Symbol))
        new_time.should_receive(:to_i).and_return(time_as_int = mock(Symbol))
        obj.should_receive(:start_time).and_return(start_time = mock(Symbol))
        time_as_int.should_receive(:-).with(start_time).and_return(lessened_time = mock(Symbol))
        lessened_time.should_receive(:+).with(30).and_return(within_parens = mock(Symbol))
        within_parens.should_receive(:div).with(60).and_return(:expected)
        obj.send(meth).should == :expected
      end
    end

    describe "#load_cache" do
      let(:meth) { :load_cache }
      it "should reset" do
        obj.should_receive(:reset)
        obj.send(meth)
      end
      it "should return true" do obj.send(meth).should == true end
      context "when cache_file_present? is truthy" do
        let(:mock_json) { mock(Symbol, :[] => nil) }
        before(:each) do
          obj.stub!(:cache_file_present?).and_return(:something_truthy)
          obj.stub!(:cache_as_json).and_return(mock_json)
        end
        it "should cache_as_json -> json" do
          obj.should_receive(:cache_as_json).and_return(mock_json)
          obj.send(meth)
        end
        it "should json['token'] -> @token" do
          mock_json.should_receive(:[]).with('token').and_return(:token_from_json)
          obj.send(meth)
          obj.instance_variable_get(:@token).should == :token_from_json
        end
        it "should json['start_time'] -> @start_time" do
          mock_json.should_receive(:[]).with('start_time').and_return(:start_time_from_json)
          obj.send(meth)
          obj.instance_variable_get(:@start_time).should == :start_time_from_json
        end
        it "should json['duration_in_minutes'] -> @duration_in_minutes" do
          mock_json.should_receive(:[]).with('duration_in_minutes').and_return(:duration_in_minutes_from_json)
          obj.send(meth)
          obj.instance_variable_get(:@duration_in_minutes).should == :duration_in_minutes_from_json
        end
        context "and cache_as_json raises an exception" do
          before(:each) do obj.should_receive(:cache_as_json).and_raise(RuntimeError) end
          it "should File.unlink(cache_file_path)" do
            obj.should_receive(:cache_file_path).and_return(cache_file_path = mock(Symbol))
            File.should_receive(:unlink).with(cache_file_path)
            obj.send(meth)
          end
        end
        %w(token start_time duration_in_minutes).each do |k|
          context "and json['#{k}'] raises an exception" do
            before(:each) do mock_json.should_receive(:[]).with(k).and_raise(RuntimeError) end
            it "should File.unlink(cache_file_path)" do
              obj.should_receive(:cache_file_path).and_return(cache_file_path = mock(Symbol))
              File.should_receive(:unlink).with(cache_file_path)
              obj.send(meth)
            end
            it "should reset again" do
              File.stub!(:unlink)
              obj.should_receive(:reset).exactly(2).times
              obj.send(meth)
            end
          end
        end
      end
      context "when cache_file_present? is falsey"
        it "should NOT cache_as_json" do
          obj.should_not_receive(:cache_as_json)
          obj.send(meth)
        end
    end

    describe "#renew" do
      let(:meth) { :renew }
      context "when given token, duration_in_minutes" do
        let(:duration_in_minutes) { mock(Symbol) }
        let(:timestamp) { mock(Symbol) }
        let(:new_time)  { mock(Symbol, :to_i => timestamp) }
        let(:token)     { mock(Symbol, :chop => 'somesig') }
        before(:each) do obj.stub!(:write_cache) end
        it "should write_cache(AuthToken.assert_valid(token), duration_in_minutes, Time.new.to_i)" do
          klass.should_receive(:assert_valid).with(token).and_return(:token_assertion)
          Time.should_receive(:new).and_return(new_time)
          new_time.should_receive(:to_i).and_return(timestamp)
          obj.send(meth, token, duration_in_minutes)
        end
        it "should reset" do
          obj.should_receive(:reset)
          obj.send(meth, token, duration_in_minutes)
        end
        it "should return token" do
          obj.send(meth, token, duration_in_minutes).should == token
        end
      end
    end

    describe "#reset_cache" do
      let(:meth) { :reset_cache }
      it "should write_cache(nil, 0, 0)" do
        obj.should_receive(:write_cache).with(nil, 0, 0)
        obj.send(meth)
      end
      it "should reset" do
        obj.should_receive(:reset)
        obj.send(meth)
      end
    end

    describe "#start_time" do
      let(:meth) { :start_time }
      context "when @start_time is truthy" do
        before(:each) do obj.instance_variable_set(:@start_time, :something_truthy) end
        it "should NOT load_cache" do
          obj.should_not_receive(:load_cache)
          obj.send(meth)
        end
        it "should return @start_time" do obj.send(meth).should == :something_truthy end
      end
      context "when @start_time is false" do
        before(:each) do obj.instance_variable_set(:@start_time, false) end
        it "should load_cache" do
          obj.should_receive(:load_cache)
          obj.send(meth)
        end
        it "should return false" do
          obj.stub!(:load_cache).and_return(:results_of_load_cache)
          obj.send(meth).should == false
        end
      end
      context "when @start_time is nil" do
        before(:each) do obj.instance_variable_set(:@start_time, nil) end
        it "should load_cache" do
          obj.should_receive(:load_cache)
          obj.send(meth)
        end
        it "should return nil" do
          obj.stub!(:load_cache).and_return(:results_of_load_cache)
          obj.send(meth).should == nil
        end
      end
    end

    describe "#token" do
      let(:meth) { :token }
      context "when HttpClient.trace_on? is truthy" do
        before(:each) do VideoApi::HttpClient.stub!(:trace_on?).and_return(:something_truthy) end
        it 'should puts("token: license key=#{license_key}")' do
          obj.should_receive(:puts).with("token: license key=#{license_key}")
          obj.send(meth)
        end
      end
      context "when HttpClient.trace_on? is falsey" do
        before(:each) do VideoApi::HttpClient.stub!(:trace_on?).and_return(false) end
        it 'should NOT puts' do
          obj.should_not_receive(:puts)
          obj.send(meth)
        end
      end
      context "when @token is truthy" do
        before(:each) do obj.instance_variable_set(:@token, :something_truthy) end
        it "should NOT load_cache" do
          obj.should_not_receive(:load_cache)
          obj.send(meth)
        end
        it "should return @token" do obj.send(meth).should == :something_truthy end
      end
      context "when @token is false" do
        before(:each) do obj.instance_variable_set(:@token, false) end
        it "should load_cache" do
          obj.should_receive(:load_cache)
          obj.send(meth)
        end
        it "should return false" do
          obj.stub!(:load_cache).and_return(:results_of_load_cache)
          obj.send(meth).should == false
        end
      end
      context "when @token is nil" do
        before(:each) do obj.instance_variable_set(:@token, nil) end
        it "should load_cache" do
          obj.should_receive(:load_cache)
          obj.send(meth)
        end
        it "should return nil" do
          obj.stub!(:load_cache).and_return(:results_of_load_cache)
          obj.send(meth).should == nil
        end
      end
    end

  end

end

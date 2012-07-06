require File.expand_path('../spec_helper', __FILE__)
require 'media_api'

describe VideoApi::Multipart::Multipart do

  let(:klass) { VideoApi::Multipart::Multipart }

  describe "Constants"

  describe "an instance" do
    let(:obj)  { klass.new('file_names_arg', 'params_arg') }

    describe "#initialize" do
      let(:meth) { :initialize }
      it "should assign the 1st arg to @file_names" do obj.instance_variable_get(:@file_names).should == 'file_names_arg' end
      it "should assign the 2nd arg to @params"     do obj.instance_variable_get(:@params).should     == 'params_arg'     end
      it "should assign a @boundary" do obj.instance_variable_get(:@boundary).should match(/----RubyMultipartClient\d+ZZZZZ/) end
    end

    describe "#boundary" do
      let(:meth) { :boundary }
      it 'should return "--@boundary\r\n"' do
        obj.instance_variable_set(:@boundary, 'the_boundary_var')
        obj.send(meth).should == "--the_boundary_var\r\n"
      end
    end

    describe "#content_type" do
      let(:meth) { :content_type }
      let(:mock_type) { mock(Symbol) }
      before(:each) { MIME::Types.stub!(:type_for).with(:the_filename).and_return(mock_type) }
      context "when given filename" do
        let(:filename) { :the_filename }
        context "and MIME::Types.type_for(filename) is empty" do
          before(:each) { mock_type.stub!(:empty?).and_return(true) }
          it "should return 'application/octet-stream'" do obj.send(meth, filename).should == 'application/octet-stream' end
        end
        context "and MIME::Types.type_for(filename) is NOT empty" do
          before(:each) { mock_type.stub!(:empty?).and_return(false) }
          it "should return that non-empty type" do obj.send(meth, filename).should == mock_type end
        end
      end
    end

    describe "#post" do
      let(:meth) { :post }
      let(:params) { { :key1 => :value1, :key2 => :value2, :image => :ignore_me } }
      let(:to_url) { :the_to_url }
      let(:stream_listener) { lambda { "I am the stream listener" } }
      let(:mock_stream) { mock(Symbol, :size => 0) }
      let(:mock_url)    { mock(Symbol, :host => :the_url_host, :query => :the_url_query, :path => :the_url_path, :port => :the_url_port) }
      let(:mock_http)   { mock(Symbol, :start => nil) }
      let(:mock_req)    { mock(Symbol, :body_stream= => nil, :content_length= => nil, :content_type= => nil) }
      let(:obj) { klass.new([%w(filename1 filepath1), %w(filename2 filepath2)], params) }
      context "when given to_url, &stream_listener" do
        before(:each) do
          obj.stub!(:get_modified_filepath_and_filename).with('filepath1').and_return([])
          obj.stub!(:get_modified_filepath_and_filename).with('filepath2').and_return([])
          obj.stub!(:content_type).and_return('')
          File.stub!(:open)
          File.stub!(:size)
          VideoApi::Multipart::StreamPart.stub!(:new).and_return(mock_stream)
          Net::HTTP.stub!(:new).and_return(mock_http)
        end
        context "for each item in @file_names" do
          it "should get_modified_filepath_and_filename" do
            obj.should_receive(:get_modified_filepath_and_filename).with('filepath1').and_return([])
            obj.should_receive(:get_modified_filepath_and_filename).with('filepath2').and_return([])
            obj.send(meth, to_url, &stream_listener)
          end
          it "should get_param_name(param_name)" do
            obj.should_receive(:get_param_name).with('filename1')
            obj.should_receive(:get_param_name).with('filename2')
            obj.send(meth, to_url, &stream_listener)
          end
          it "should append content into parts" do
            obj.stub!(:get_modified_filepath_and_filename).with('filepath1').and_return(['mod_filepath1',:discard])
            obj.stub!(:get_modified_filepath_and_filename).with('filepath2').and_return(['mod_filepath2',:discard])
            VideoApi::Multipart::StringPart.should_receive(:new).at_least(1).times.and_return(mock_stream)
            File.should_receive(:open).with('mod_filepath1', 'rb')
            File.should_receive(:open).with('mod_filepath2', 'rb')
            VideoApi::Multipart::StreamPart.should_receive(:new).and_return(mock_stream)
            obj.send(meth, to_url, &stream_listener)
          end
        end
        context "for each pair in @params" do
          let(:obj) { klass.new([], params) }
          it "should append StringPart content for all non-image keys" do
            CGI.should_receive(:escape).with('key1')
            CGI.should_receive(:escape).with('key2')
            CGI.should_not_receive(:escape).with('image')
            VideoApi::Multipart::StringPart.should_receive(:new).exactly(3).times.and_return(mock_stream)
            # 3 rather than 2: 2 for each non-image key, plus 1 more for boundary
            obj.send(meth, to_url, &stream_listener)
          end
        end
        it "should instantiate a MultipartStream" do
          VideoApi::Multipart::MultipartStream.should_receive(:new).and_return(mock_stream)
          obj.send(meth, to_url, &stream_listener)
        end
        it "should URI.parse(to_url)" do
          URI.should_receive(:parse).with(to_url).and_return(mock_url)
          obj.send(meth, to_url, &stream_listener)
        end
        it "should post to that parsed url" do
          mock_url.should_receive(:path).and_return(:the_url_path)
          mock_url.should_receive(:query).and_return(:the_url_query)
          URI.stub!(:parse).with(to_url).and_return(mock_url)
          Net::HTTP::Post.should_receive(:new).with("the_url_path?the_url_query").and_return(mock_req)
          obj.send(meth, to_url, &stream_listener)
        end
        it "should call Net::HTTP.new with the resulting args" do
          mock_url.should_receive(:host).and_return(:the_url_host)
          mock_url.should_receive(:port).and_return(:the_url_port)
          URI.stub!(:parse).with(to_url).and_return(mock_url)
          Net::HTTP.should_receive(:new).with(:the_url_host, :the_url_port).and_return(mock_http)
          obj.send(meth, to_url, &stream_listener)
        end
        it "should start the new Net::HTTP instance" do
          Net::HTTP.stub!(:new).and_return(mock_http)
          mock_http.should_receive(:start)
          obj.send(meth, to_url, &stream_listener)
        end
      end
    end

    describe "#get_modified_filepath_and_filename" do
      let(:meth) { :get_modified_filepath_and_filename }
      context "when given a filepath" do
        let(:filepath)     { mock(Symbol) }
        let(:mock_length)  { mock(Symbol) }
        let(:mod_filepath) { mock(Symbol, :[] => nil, :length => 0, :rindex => 0) }
        let(:pos)          { mock(Symbol, :+ => 0, :coerce => [0, 0]) }
        context "and the filepath responds to values" do
          let(:values) { mock(Symbol, :first => mod_filepath) }
          before(:each) do filepath.stub!(:values).and_return(values) end
          it "should extract filepath.values.first -> mod_filepath" do
            values.should_receive(:first).and_return(mod_filepath)
            obj.send(meth, filepath)
          end
          it "should extract mod_filepath.rindex('/') -> pos" do
            mod_filepath.should_receive(:rindex).with('/').and_return(pos)
            obj.send(meth, filepath)
          end
          context "when pos is truthy" do
            before(:each) do mod_filepath.stub!(:rindex).with('/').and_return(pos) end
            it "should extract mod_filepath[pos+1, mod_filepath.length-pos] -> filename" do
              pos.should_receive(:+).with(1).and_return(:begin_pt)
              mod_filepath.should_receive(:length).and_return(mock_length)
              mock_length.should_receive(:-).with(pos).and_return(:end_pt)
              mod_filepath.should_receive(:[]).with(:begin_pt, :end_pt)
              obj.send(meth, filepath)
            end
            it "should return [mod_filepath, filename]" do
              pos.stub!(:+).with(1).and_return(:begin_pt)
              mod_filepath.stub!(:length).and_return(mock_length)
              mock_length.stub!(:-).with(pos).and_return(:end_pt)
              mod_filepath.should_receive(:[]).with(:begin_pt, :end_pt).and_return(:the_filename)
              obj.send(meth, filepath).should == [mod_filepath, :the_filename]
            end
          end
          context "when pos is NOT truthy" do
            before(:each) do mod_filepath.stub!(:rindex).with('/').and_return(false) end
            it "should return [mod_filepath, mod_filepath]" do
              obj.send(meth, filepath).should == [mod_filepath, mod_filepath]
            end
          end
        end
        context "and the filepath does NOT respond to values" do
          let(:filepath) { mock(Symbol, :[] => nil, :length => 0, :rindex => pos) }
          it "should extract filepath.rindex('/') -> pos" do
            filepath.should_receive(:rindex).with('/').and_return(pos)
            mock_length.stub!(:-).with(pos).and_return(:end_pt)
            obj.send(meth, filepath)
          end
          context "when pos is truthy" do
            before(:each) do mod_filepath.stub!(:rindex).with('/').and_return(pos) end
            it "should extract filepath[pos+1, mod_filepath.length-pos] -> filename" do
              pos.should_receive(:+).with(1).and_return(:begin_pt)
              filepath.should_receive(:length).and_return(mock_length)
              mock_length.should_receive(:-).with(pos).and_return(:end_pt)
              filepath.should_receive(:[]).with(:begin_pt, :end_pt)
              obj.send(meth, filepath)
            end
            it "should return [filepath, filename]" do
              pos.stub!(:+).with(1).and_return(:begin_pt)
              filepath.stub!(:length).and_return(mock_length)
              mock_length.stub!(:-).with(pos).and_return(:end_pt)
              filepath.should_receive(:[]).with(:begin_pt, :end_pt).and_return(:the_filename)
              obj.send(meth, filepath).should == [filepath, :the_filename]
            end
          end
          context "when pos is NOT truthy" do
            before(:each) do filepath.stub!(:rindex).with('/').and_return(false) end
            it "should return [mod_filepath, mod_filepath]" do
              obj.send(meth, filepath).should == [filepath, filepath]
            end
          end
        end
      end
    end

  end

end

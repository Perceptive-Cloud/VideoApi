require File.expand_path('../spec_helper', __FILE__)
%w(http_client multipart open-uri).each { |f| require(f) }

describe VideoApi::HttpClient do
  let(:klass) { VideoApi::HttpClient }

  describe "Constants"

  describe ".create_query_string" do
    let(:meth) { :create_query_string }
    it "should take a mandatory params Hash and an optional joiner String" do
      lambda { klass.send(meth)          }.should     raise_error(ArgumentError)
      lambda { klass.send(meth, :a)      }.should_not raise_error(ArgumentError)
      lambda { klass.send(meth, :a, :b)  }.should_not raise_error(ArgumentError)
      lambda { klass.send(meth,:a,:b,:c) }.should     raise_error(ArgumentError)
    end
    context "when given {}" do
      let(:params) { {} }
      it "should produce ''" do klass.send(meth, params).should == '' end
    end
    context "when given { :query => 'some_query' }" do
      let(:params) { { :query => 'some_query' } }
      expected_single_pair = 'query=some_query'
      it "should produce #{expected_single_pair}" do klass.send(meth, params).should == expected_single_pair end
    end
    context "when given { :query => 'some_query', :limit => 'some_limit' }" do
      let(:params) { { :query => 'some_query', :limit => 'some_limit' } }
      expected_no_nest = 'query=some_query&limit=some_limit'
      it "should produce #{expected_no_nest}" do klass.send(meth, params).should == expected_no_nest end
    end
    context "when given { :dynamic_playlist_filter => { 'query' => 'some_query', 'limit' => 'some_limit' } }" do
      let(:params) { { :dynamic_playlist_filter => { 'query' => 'some_query', 'limit' => 'some_limit' } } }
      expected_nest1 = 'dynamic_playlist_filter[query]=some_query&dynamic_playlist_filter[limit]=some_limit'
      it "should produce #{expected_nest1}" do klass.send(meth, params).should == expected_nest1 end
    end
    context "when given { :playlist => { 'dynamic_playlist_filter' => { 'query' => 'some_query', 'limit' => 'some_limit' } } }" do
      let(:params) { { :playlist => { 'dynamic_playlist_filter' => { 'query' => 'some_query', 'limit' => 'some_limit' } } } }
      expected_nest2 = 'playlist[dynamic_playlist_filter][query]=some_query&playlist[dynamic_playlist_filter][limit]=some_limit'
      it "should produce #{expected_nest2}" do klass.send(meth, params).should == expected_nest2 end
    end
  end

  describe "an instance" do
    let(:obj) { klass.new('some_host') }

    describe "#create_sub_url" do
      let(:meth) { :create_sub_url }
      context "when given path and params" do
        let(:path)   { :the_path }
        let(:params) { mock(Symbol) }
        context "and params is empty?" do
          before(:each) do params.stub!(:empty?).and_return(true) end
          it "should return path" do obj.send(meth, path, params).should == path end
        end
        context "and params is NOT empty?" do
          before(:each) do params.stub!(:empty?).and_return(false) end
          it 'should return "#{path}?#{HttpClient.create_query_string(params)}"' do
            klass.should_receive(:create_query_string).with(params).and_return(:created_query_string)
            obj.send(meth, path, params).should == "#{path}?created_query_string"
          end
        end
      end
      context "when given just path" do
        let(:path)   { :the_path }
        it "should return path" do obj.send(meth, path).should == path end
      end
    end

    describe "#create_url" do
      let(:meth) { :create_url }
      context "when given path and params" do
        let(:path)   { :the_path }
        let(:params) { :the_params  }
        it 'should return "http://#{server_host}:#{server_port}/#{create_sub_url path, params}"' do
          obj.should_receive(:server_host).and_return(:server_host)
          obj.should_receive(:server_port).and_return(:server_port)
          obj.should_receive(:create_sub_url).with(path, params).and_return(:created_sub_url)
          obj.send(meth, path, params).should == 'http://server_host:server_port/created_sub_url'
        end
      end
    end

    describe "#delete" do
      let(:meth) { :delete }
      context "when given sub_url and params" do
        let(:sub_url) { :the_sub_url }
        let(:params)  { :the_params  }
        it "should call get_response('DELETE', sub_url, params)" do
          obj.should_receive(:get_response).with('DELETE', sub_url, params).and_return(:expected)
          obj.send(meth, sub_url, params).should == :expected
        end
      end
    end

    describe "#download_file" do
      let(:meth) { :download_file }
      context "when give path, download_file_path" do
        let(:path) { mock(Object) }
        let(:download_file_path) { mock(File, :to_int => nil, :to_path => path) }
        before(:each) do obj.stub!(:trace) end
        it 'should trace("GET http://#{server_host}:#{server_port}/#{path}")' do
          File.stub!(:open)
          server_host = mock(Symbol)
          server_port = mock(Fixnum)
          obj.should_receive(:server_host).and_return(server_host)
          obj.should_receive(:server_port).and_return(server_port)
          obj.should_receive(:trace).with("GET http://#{server_host}:#{server_port}/#{path}")
          obj.send(meth, path, download_file_path)
        end
        it 'should File.open(download_file_path, "w")' do
          File.should_receive(:open).with(download_file_path, 'w')
          obj.send(meth, path, download_file_path)
        end
        it "should create_url(path)" do
          obj.stub!(:open)
          obj.should_receive(:create_url).with(path)
          obj.send(meth, path, download_file_path)
        end
        it "should open(create_url(path))" do
          obj.stub!(:create_url).with(path).and_return(:created_url)
          obj.should_receive(:open).with(:created_url)
          obj.send(meth, path, download_file_path)
        end
### FIXME OpenURI::HTTPError not accessible in spec. Debug.
=begin
        context 'when obj#trace raises an OpenURI::HTTPError' do
          #before(:each) do
          #  msg = mock(String)
          #  io  = mock(IO)
          #  obj.stub!(:trace).and_raise(OpenURI::HTTPError(msg, io))
          #end
          it "should raise an HttpClientException" do
            lambda {
              obj.send(meth, path, download_file_path)
            }.should raise_error(VideoApi::HttpClientException)
          end
        end
        context 'when File.open(download_file_path, "w") raises an OpenURI::HTTPError' do
          #before(:each) do File.stub!(:open).and_raise(OpenURI::HTTPError) end
          it "should raise an HttpClientException" do
            lambda {
              obj.send(meth, path, download_file_path)
            }.should raise_error(VideoApi::HttpClientException)
          end
        end
=end
      end
    end

    describe "#get" do
      let(:meth) { :get }
      context "when given sub_url and params" do
        let(:sub_url) { :the_sub_url }
        let(:params)  { :the_params  }
        it "should call get_response('GET', sub_url, params)" do
          obj.should_receive(:get_response).with('GET', sub_url, params).and_return(:expected)
          obj.send(meth, sub_url, params).should == :expected
        end
      end
    end

    describe "#get_response" do
      let(:meth)      { :get_response }
      let(:method)    { :method }
      let(:uri)       { :the_uri }
      let(:params)    { :the_params }
      let(:data)      { :the_data }
      let(:headers)   { :the_headers }
      let(:mock_body) { mock(Symbol) }
      let(:mock_c_i)  { mock(Symbol, :< => false, :>= => false) }
      let(:mock_code) { mock(Symbol, :to_i => mock_c_i) }
      let(:response)  { mock(Symbol, :code => mock_code, :body => mock_body) }
      let(:e)         { mock(RuntimeError) }
      let(:hce)       { mock(VideoApi::HttpClientException) }
      before(:each) do
        obj.stub!(:create_sub_url).and_return(:sub_url)
        obj.stub!(:send_request).and_return(response)
      end
      shared_examples_for "HttpClient#get_response common" do
### FIXME raise vs. throw
=begin
        context "when create_sub_url raises an Exception" do
          before(:each) do obj.stub!(:create_sub_url).and_raise(e) end
          it "should throw HttpClientException" do
            lambda { obj.send(meth, method, uri, params, data, headers) }.should raise_error(VideoApi::HttpClientException)
          end
        end
        context "when send_request raises an Exception e"
          it "should throw HttpClientException.from_exception e"
=end
        it "should response.code.to_i -> code" do
          response.should_receive(:code).and_return(mock_code)
          mock_code.should_receive(:to_i).and_return(mock_c_i)
          obj.send(meth, *args)
        end
        it 'should trace("response code=#{code}, body=#{body}")' do
          obj.should_receive(:trace).with("response code=#{mock_c_i}, body=#{mock_body}")
          obj.send(meth, *args)
        end
        it "should response.code.to_i -> code" do
          response.should_receive(:code).and_return(mock_code)
          mock_code.should_receive(:to_i).and_return(mock_c_i)
          obj.send(meth, *args)
        end
        it "should response.body -> body" do
          response.should_receive(:body).and_return(mock_body)
          obj.send(meth, *args)
        end
        it 'should trace("response code=#{code}, body=#{body}")' do
          obj.should_receive(:trace).with("response code=#{mock_c_i}, body=#{mock_body}")
          obj.send(meth, *args)
        end
        context "when code < 200" do
          before(:each) do mock_c_i.stub!(:<).with(200).and_return(true) end
          it "should raise HttpClientException.from_code(code, body)" do
            lambda { obj.send(meth, *args) }.should raise_error
          end
        end
        context "when code >= 400" do
          before(:each) do mock_c_i.stub!(:>=).with(400).and_return(true) end
          it "should raise HttpClientException.from_code(code, body)" do
            lambda { obj.send(meth, *args) }.should raise_error
          end
        end
        context "when code is between 200 and 399" do
          before(:each) do
            mock_c_i.stub!(:<).with(200).and_return(false)
            mock_c_i.stub!(:>=).with(400).and_return(false)
          end
          it "should return HttpResponse.new(body, code)" do
            VideoApi::HttpResponse.should_receive(:new).with(mock_body, mock_c_i).and_return(:expected)
            obj.send(meth, *args).should == :expected
          end
        end
      end
      context "when given method, uri, params, data, headers" do
        let(:args) { [method, uri, params, data, headers] }
        it_should_behave_like "HttpClient#get_response common"
        it "should create_sub_url(uri, params) -> sub_url" do
          obj.should_receive(:create_sub_url).with(uri, params).and_return(:sub_url)
          obj.send(meth, *args)
        end
        it "should send_request(method, sub_url, data, headers) -> response" do
          obj.should_receive(:send_request).with(method, :sub_url, data, headers).and_return(response)
          obj.send(meth, *args)
        end
      end
      context "when given method, uri, params, data" do
        let(:args) { [method, uri, params, data] }
        it_should_behave_like "HttpClient#get_response common"
        it "should create_sub_url(uri, params) -> sub_url" do
          obj.should_receive(:create_sub_url).with(uri, params).and_return(:sub_url)
          obj.send(meth, *args)
        end
        it "should send_request(method, sub_url, data, {}) -> response" do
          obj.should_receive(:send_request).with(method, :sub_url, data, {}).and_return(response)
          obj.send(meth, *args)
        end
      end
      context "when given method, uri, params" do
        let(:args) { [method, uri, params] }
        it_should_behave_like "HttpClient#get_response common"
        it "should create_sub_url(uri, params) -> sub_url" do
          obj.should_receive(:create_sub_url).with(uri, params).and_return(:sub_url)
          obj.send(meth, *args)
        end
        it "should send_request(method, sub_url, nil, {}) -> response" do
          obj.should_receive(:send_request).with(method, :sub_url, nil, {}).and_return(response)
          obj.send(meth, *args)
        end
      end
      context "when given method, uri" do
        let(:args) { [method, uri] }
        it_should_behave_like "HttpClient#get_response common"
        it "should create_sub_url(uri, {}) -> sub_url" do
          obj.should_receive(:create_sub_url).with(uri, {}).and_return(:sub_url)
          obj.send(meth, *args)
        end
        it "should send_request(method, sub_url, nil, {}) -> response" do
          obj.should_receive(:send_request).with(method, :sub_url, nil, {}).and_return(response)
          obj.send(meth, *args)
        end
      end
    end

    describe "#post" do
      let(:meth) { :post }
      let(:sub_url)      { :the_sub_url }
      let(:params)       { :the_params  }
      let(:data)         { :the_data    }
      let(:content_type) { :the_content_type }
      context "when given sub_url, params, data, content_type" do
        it "should call get_response('POST', sub_url, params, data, {'Content-type' => content_type})" do
          obj.should_receive(:get_response).with('POST', sub_url, params, data, {'Content-type' => content_type}).and_return(:expected)
          obj.send(meth, sub_url, params, data, content_type).should == :expected
        end
      end
      context "when given sub_url, params, and data" do
        it "should call get_response('POST', sub_url, params, data, {'Content-type' => 'application/x-www-form-urlencoded'})" do
          obj.should_receive(:get_response).with('POST', sub_url, params, data, {'Content-type' => 'application/x-www-form-urlencoded'}).and_return(:expected)
          obj.send(meth, sub_url, params, data).should == :expected
        end
      end
      context "when given sub_url and params" do
        it "should call get_response('POST', sub_url, params, '', {'Content-type' => 'application/x-www-form-urlencoded'})" do
          obj.should_receive(:get_response).with('POST', sub_url, params, '', {'Content-type' => 'application/x-www-form-urlencoded'}).and_return(:expected)
          obj.send(meth, sub_url, params).should == :expected
        end
      end
    end

    describe "#post_multipart_file_upload" do
      let(:meth)     { :post_multipart_file_upload }
      let(:url)      { :the_url }
      let(:filepath) { :the_filepath }
      let(:params)   { :the_params }
      let(:stream_listener) { lambda { 'I am the stream listener' } }
      context "when given url, filepath, params and &stream_listener" do
        it 'should trace("POST (multipart) #{create_url(url)}"' do
          obj.should_receive(:create_url).with(url).at_least(1).times.and_return('the_created_url')
          obj.should_receive(:trace).with('POST (multipart) the_created_url')
          VideoApi::Multipart::Multipart.stub!(:new).and_return(mock_multipart = mock(Symbol, :post => nil))
          obj.send(meth, url, filepath, params, &stream_listener)
        end
        it 'should instantiate a Multipart with image[original] => filepath, params' do
          obj.should_receive(:create_url).with(url).at_least(1).times.and_return('the_created_url')
          obj.stub!(:trace)
          VideoApi::Multipart::Multipart.should_receive(:new).with({'image[original]' => filepath}, params).and_return(mock_multipart = mock(Symbol, :post => nil))
          obj.send(meth, url, filepath, params, &stream_listener)
        end
        it 'should cleanup double directories for images' do
          mock_created_url = mock(Symbol)
          obj.should_receive(:create_url).with(url).at_least(1).times.and_return(mock_created_url)
          obj.stub!(:trace)
          VideoApi::Multipart::Multipart.stub!(:new).and_return(mock_multipart = mock(Symbol, :post => nil))
          mock_created_url.should_receive(:gsub).with(%r[//images], '/images')
          obj.send(meth, url, filepath, params, &stream_listener)
        end
        it 'should call multipart.post(url, &stream_listener)' do
          obj.stub!(:create_url).with(url).at_least(1).times.and_return('the_created_url')
          obj.stub!(:trace)
          VideoApi::Multipart::Multipart.stub!(:new).and_return(mock_multipart = mock(Symbol, :post => nil))
          mock_multipart.should_receive(:post).with('the_created_url', &stream_listener)
          obj.send(meth, url, filepath, params, &stream_listener)
        end
      end
      context "when given url, filepath and &stream_listener" do
        it 'should trace("POST (multipart) #{create_url(url)}"' do
          obj.should_receive(:create_url).with(url).at_least(1).times.and_return('the_created_url')
          obj.should_receive(:trace).with('POST (multipart) the_created_url')
          VideoApi::Multipart::Multipart.stub!(:new).and_return(mock_multipart = mock(Symbol, :post => nil))
          obj.send(meth, url, filepath, &stream_listener)
        end
        it 'should instantiate a Multipart with image[original] => filepath, {}' do
          obj.should_receive(:create_url).with(url).at_least(1).times.and_return('the_created_url')
          obj.stub!(:trace)
          VideoApi::Multipart::Multipart.should_receive(:new).with({'image[original]' => filepath}, {}).and_return(mock_multipart = mock(Symbol, :post => nil))
          obj.send(meth, url, filepath, &stream_listener)
        end
        it 'should cleanup double directories for images' do
          mock_created_url = mock(Symbol)
          obj.should_receive(:create_url).with(url).at_least(1).times.and_return(mock_created_url)
          obj.stub!(:trace)
          VideoApi::Multipart::Multipart.stub!(:new).and_return(mock_multipart = mock(Symbol, :post => nil))
          mock_created_url.should_receive(:gsub).with(%r[//images], '/images')
          obj.send(meth, url, filepath, &stream_listener)
        end
        it 'should call multipart.post(url, &stream_listener)' do
          obj.stub!(:create_url).with(url).at_least(1).times.and_return('the_created_url')
          obj.stub!(:trace)
          VideoApi::Multipart::Multipart.stub!(:new).and_return(mock_multipart = mock(Symbol, :post => nil))
          mock_multipart.should_receive(:post).with('the_created_url', &stream_listener)
          obj.send(meth, url, filepath, &stream_listener)
        end
      end
    end

    describe "#put" do
      let(:meth) { :put }
      context "when given sub_url and params" do
        let(:sub_url) { :the_sub_url }
        let(:params)  { :the_params  }
        it "should call get_response('PUT', sub_url, params, nil, {'Content-length' => '0'})" do
          obj.should_receive(:get_response).with('PUT', sub_url, params, nil, {'Content-length' => '0'}).and_return(:expected)
          obj.send(meth, sub_url, params).should == :expected
        end
      end
    end

    describe "#send_request" do
      let(:meth)        { :send_request }
      let(:method)      { :method }
      let(:url)         { :the_url }
      let(:data)        { :the_data }
      let(:headers)     { { 'key1' => 'value1', 'key2' => 'value2' } }
      let(:server_host) { :server_host }
      let(:server_port) { :server_port }
      let(:mock_http)   { mock(Symbol, :send_request => nil) }
      before(:each) do
        Net::HTTP.stub!(:new).and_return(mock_http)
        obj.stub!(:server_host).and_return(server_host)
        obj.stub!(:server_port).and_return(server_port)
      end
      context "when given method, url, data, headers" do
        it %q[should trace("#{method} http://#{server_host}:#{server_port}/#{url}, data=#{data}, headers: #{headers.map{|k,v| k + '=' + v}.join(', ')}")] do
          obj.should_receive(:server_host).at_least(1).times.and_return(server_host)
          obj.should_receive(:server_port).at_least(1).times.and_return(server_port)
          joined_headers = headers.map { |k,v| k + '=' + v }.join(', ')
          trace_exp = "#{method} http://#{server_host}:#{server_port}/#{url}, data=#{data}, headers: #{joined_headers}"
          obj.should_receive(:trace).with(trace_exp)
          obj.send(meth, method, url, data, headers)
        end
        it "should Net::HTTP.new(server_host, server_port) -> http" do
          Net::HTTP.should_receive(:new).with(server_host, server_port).and_return(mock_http)
          obj.send(meth, method, url, data, headers)
        end
        it 'should http.send_request(method, "/#{url}", data, headers)' do
          mock_http.should_receive(meth).with(method, "/#{url}", data, headers)
          obj.send(meth, method, url, data, headers)
        end
      end
    end

    describe "#trace" do
      let(:meth) { :trace }
      context "when given an arg" do
        let(:arg) { :the_arg }
        context "when @@trace is truthy" do
          before(:each) { klass.class_variable_set(:@@trace, true) }
          it "should return puts(arg)" do
            obj.should_receive(:puts).with(arg).and_return(:expected)
            obj.send(meth, arg).should == :expected
          end
        end
        context "when @@trace is falsey" do
          before(:each) { klass.class_variable_set(:@@trace, false) }
          it "should NOT call puts(arg) and should return nil" do
            obj.should_not_receive(:puts).with(arg)
            obj.send(meth, arg).should == nil
          end
        end
      end
    end

  end

end

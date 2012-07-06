require File.expand_path('../spec_helper', __FILE__)
%w(http_client multipart open-uri).each { |f| require(f) }

describe VideoApi::HttpClientException do
  let(:klass) { VideoApi::HttpClientException }

  describe "Constants"

  describe ".from_exception" do
    let(:meth) { :from_exception }
    let(:exception) { mock(Symbol) }
    context "when given exception" do
      it "should return self.new(nil, exception.message)" do
        exception.should_receive(:message).and_return(:the_msg)
        klass.should_receive(:new).with(nil, :the_msg).and_return(:expected)
        klass.send(meth, exception).should == :expected
      end
    end
  end

end

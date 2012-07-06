require File.expand_path('../spec_helper', __FILE__)
require 'object_from_hash'
require 'object_from_json'
require 'json'

describe VideoApi::ObjectFromJson do
  let(:klass) { VideoApi::ObjectFromJson }

  describe "Constants"

  describe ".from_json" do
    let(:meth) { :from_json }
    context "when given arg" do
      let(:arg) { mock(Symbol) }
      it "should call from_object(JSON.parse(arg))" do
        JSON.should_receive(:parse).with(arg).and_return(:parsed_arg)
        VideoApi::ObjectFromHash.should_receive(:from_object).with(:parsed_arg).and_return(:expected)
        klass.send(meth, arg).should == :expected
      end
    end
  end

end

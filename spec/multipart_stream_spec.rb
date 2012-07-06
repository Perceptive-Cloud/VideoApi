require File.expand_path('../spec_helper', __FILE__)
require 'media_api'

describe VideoApi::Multipart::MultipartStream do

  let(:klass) { VideoApi::Multipart::MultipartStream }

  describe "Constants"

  describe "an instance" do
    let(:obj)  { klass.new('parts_arg') }

    describe "#read" do
      let(:meth) { :read }
      let(:how_much) { mock(Symbol) }
      context "when given how_much" do
        context "and @part_no >= @parts.size" do
          before(:each) do
            obj.instance_variable_set(:@part_no, 10)
            obj.instance_variable_set(:@parts, mock(Symbol, :size => 10))
          end
          it "should return nil" do obj.send(meth, how_much).should == nil end
        end
      end
    end

  end

end

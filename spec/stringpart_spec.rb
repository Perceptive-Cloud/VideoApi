require File.expand_path('../spec_helper', __FILE__)
require 'media_api'

### FIXME: P in Part is capitalized here, but not for others. Standardize.
describe VideoApi::Multipart::StringPart do

  let(:klass) { VideoApi::Multipart::StringPart }

  describe "Constants"

  describe "an instance" do
    let(:obj)  { klass.new('str_arg') }

    describe "#read" do
      let(:meth) { :read }
      context "when given offest, how_much" do
        it "should return @str[offest, how_much]" do
          mock_str, offset, how_much = (1..3).to_a.map { mock(Symbol) }
          obj.instance_variable_set(:@str, mock_str)
          mock_str.should_receive(:[]).with(offset, how_much).and_return(:expected)
          obj.send(meth, offset, how_much).should == :expected
        end
      end
    end

  end

end

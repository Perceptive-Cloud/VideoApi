require File.expand_path('../spec_helper', __FILE__)
require 'media_api'

### FIXME: P in Part is capitalized here, but not for others. Standardize.
describe VideoApi::Multipart::StreamPart do

  let(:klass) { VideoApi::Multipart::StreamPart }

  let(:stream)            { mock(Symbol) }
  let(:size)              { mock(Symbol) }
  let(:progress_listener) { lambda { |x| "PL received #{x}" } }

  describe "Constants"

  describe "#initialize" do
    let(:meth) { :new }
    context "when given stream, size, &progress_listener" do
      it "should assign stream into @stream" do
        obj = klass.send(meth, stream, size, &progress_listener)
        obj.instance_variable_get(:@stream).should == stream
      end
      it "should assign size into @size" do
        obj = klass.send(meth, stream, size, &progress_listener)
        obj.instance_variable_get(:@size).should == size
      end
      it "should assign &progress_listener into @progress_listener" do
        obj = klass.send(meth, stream, size, &progress_listener)
        obj.instance_variable_get(:@progress_listener).should == progress_listener
      end
    end
  end

  describe "an instance" do
    let(:obj)  { klass.new(stream, size, &progress_listener) }

    describe "#read" do
      let(:meth) { :read }
      context "when given offset, how_much" do
        let(:offset)   { mock(Symbol) }
        let(:how_much) { mock(Symbol) }
        let(:data)     { mock(Symbol, :length => :data_length) }
        before(:each) do
          stream.stub!(:read).and_return(data)
          stream.stub!(:eof?).and_return(false)
        end
        it "should @stream.read(how_much) -> data" do
          stream.should_receive(:read).with(how_much).and_return(data)
          obj.send(meth, offset, how_much)
        end
        it "should return data" do
          obj.send(meth, offset, how_much).should == data
        end
        context "and @progress_listener is truthy" do
          it "should @progress_listener.call(data.length)" do
            data.should_receive(:length).and_return(:data_length)
            progress_listener.should_receive(:call).with(:data_length)
            obj.send(meth, offset, how_much)
          end
        end
        context "and @stream.eof? is truthy" do
          before(:each) do stream.stub!(:eof?).and_return(:something_truthy) end
          it "should close @stream" do
            stream.should_receive(:close)
            obj.send(meth, offset, how_much)
          end
        end
      end
    end

    describe "#size" do
      let(:meth) { :size }
      it "should return @size" do
        obj.instance_variable_set(:@size, :expected)
        obj.send(meth).should == :expected
      end
    end

  end

end

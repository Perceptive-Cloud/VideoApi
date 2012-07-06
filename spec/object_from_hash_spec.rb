require File.expand_path('../spec_helper', __FILE__)
require 'object_from_hash'

describe VideoApi::ObjectFromHash do
  let(:klass) { VideoApi::ObjectFromHash }
  let(:obj) { klass.new({ 'base_url' => 'http://example.com', 'company_id' => 'CoID', 'license_key' => 'the_key' }) }

  describe "Constants"

  describe ".from_object" do
    let(:meth) { :from_object }
    context "when given an Array" do
      let(:arg) { mock(Array) }
      it "should map over the elements" do
        klass.should_receive(:new).with({}).exactly(2).times # modelling Hash behavior, as it's the most easily distinguished from others
        klass.send(meth, [ {}, {} ])
      end
    end
    context "when given a Hash arg" do
      let(:arg) { mock(Hash) }
      it "should return the results of ObjectFromHash.new(arg)" do
        klass.should_receive(:new).with(arg).and_return(:expected)
        klass.new(arg).should == :expected
      end
    end
    context "when given a String arg" do
      let(:arg) { mock(String) }
      it "should return the arg unchanged" do klass.send(meth, arg).should == arg end
    end
  end

  describe "#initialize" do
    let(:meth) { :initialize }
    context "when given {}" do
      let(:hash_arg) { {} }
      it "should not define any new methods for the class" do
        klass.should_not_receive(:define_method)
        klass.new(hash_arg)
      end
    end
    hash_arg = { 'a_key' => :value1, 'another_key' => :value2, 'key3' => :value3, 'hyphen-key' => :value4 }
    context "when given #{hash_arg.inspect}" do
      it "should assign ObjectFromHash.from_object() for each of the values into their corresponding keys" do
        obj = klass.new(hash_arg)
        obj.instance_variable_get(:@a_key).should == klass.from_object(:value1)
        obj.instance_variable_get(:@another_key).should == klass.from_object(:value2)
        obj.instance_variable_get(:@key3).should == klass.from_object(:value3)
        obj.instance_variable_get(:@hyphen_key).should == klass.from_object(:value4)
      end
      it "should define getter and setter methods for the keys" do
        klass.should_receive(:define_method).with('a_key', anything)
        klass.should_receive(:define_method).with('a_key=', anything)
        klass.should_receive(:define_method).with('another_key', anything)
        klass.should_receive(:define_method).with('another_key=', anything)
        klass.should_receive(:define_method).with('key3', anything)
        klass.should_receive(:define_method).with('key3=', anything)
        klass.should_receive(:define_method).with('hyphen_key', anything)
        klass.should_receive(:define_method).with('hyphen_key=', anything)
        klass.new(hash_arg)
      end
      context "after instantiation" do
        let(:obj) { klass.new(hash_arg) }
        describe "#a_key" do
          let(:meth) { :a_key }
          it "should return the instance variable :@a_key" do
            obj.should_receive(:instance_variable_get).with('@a_key').and_return(:expected)
            obj.send(meth).should == :expected
          end
        end
        describe "#a_key=" do
          let(:meth) { :a_key= }
          it "should set the instance variable :@a_key" do
            obj.should_receive(:instance_variable_set).with('@a_key', 'the_new_val')
            obj.send(meth, 'the_new_val')
          end
        end
      end
    end
  end

  describe "#lean_key" do
    let(:meth) { :clean_key }
    the_regex = /[^a-zA-Z0-9_]/
    the_replacement = '_'
    it "should replace #{the_regex.inspect} with #{the_replacement.inspect}" do
      the_key = mock(Symbol)
      the_key.should_receive(:sub).with(the_regex, the_replacement).and_return(:expected)
      klass.new({}).send(meth, the_key).should == :expected
    end
  end

end

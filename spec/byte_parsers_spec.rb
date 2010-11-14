require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ByteParsers" do
  before(:all) do
    SimpleParser = ByteParser.new do
      add :fourcc, BP::UInt32, :endian => :big
      add :version, BP::UInt16, :endian => :little
      add :name, BP::CString
      add :tag, BP::FixedString, :size => 7
      add :weird_string, BP::String, :terminator => "4"
      add :number_terminated_string, BP::String, :terminator => proc {|x| x =~ /\d/}
    end
  end

  it "allows declarative class creation" do
    SimpleParser.should be_a(Class)
  end

  it 'has a #read method that reads in an IO' do
    SimpleParser.should respond_to(:read)
  end
  
  describe '#read' do
    it 'returns an object with readers for each field' do
      input = "\x01\x02\x03\x04ABMichael\0MJEMJEMThisEndsWith4EndsWith3okay"
      result = SimpleParser.read(StringIO.new(input))
      result.should respond_to(:fourcc)
      result.should respond_to(:version)
      result.should respond_to(:name)
      result.should respond_to(:tag)
      result.should respond_to(:weird_string)
      result.should respond_to(:number_terminated_string)
    end
    
    it 'parses basic input' do
      input = "\x01\x02\x03\x04ABMichael\0MJEMJEMThisEndsWith4EndsWith3okay"
      result = SimpleParser.read(StringIO.new(input))
      result.fourcc.should == 0x01020304
      result.version.should == 0x4241
      result.name.should == 'Michael'
      result.tag.should == 'MJEMJEM'
      result.weird_string.should == 'ThisEndsWith'
      result.number_terminated_string.should == 'EndsWith'
    end
  end
end
